# Next.js App Router のディレクトリ設計

「ここに置く、そこには置かない、違反したら Lint で弾く」を機械的に成立させることが目的です。

防ぐ failure mode は3つです。境界のあいまいさ（サーバー専用コードがクライアントへ漏れる）、Server Action のスパゲッティ化（機能とルートが密結合し再利用も削除も難しくなる）、ハイドレーションの崩壊（`"use client"` の付け忘れや付けすぎで意図せず全体が CSR になる）。設計判断に迷ったらこの3つを防げるかで判断します。

---

## 1. 全体構成

```
src/
├─ app/           ルート・レイアウト・メタデータのみ（薄く保つ）
├─ features/      ドメインごとの機能群
├─ shared/        共通UI（Atomic の層で分割）・provider・トークン
└─ external/      dto, handler, service, repository, client
```

| 層 | 責務 | 置かないもの |
|---|---|---|
| `app/` | ルーティング宣言、パラメータの型付け、メタデータ、レイアウト | データフェッチ、ビジネスロジック、UI の詳細 |
| `features/` | ドメインごとの UI とクライアントロジック | DB アクセス、外部 API の直接呼び出し |
| `shared/` | ドメイン非依存の共通 UI と provider | ドメイン固有の型やロジック |
| `external/` | 外部 I/O とビジネスロジック | React コンポーネント |

呼び出し方向は一方向に固定します。`features` から `service` と `repository` への直接 import は禁止で、`handler` が唯一の入口です。

```
features  →  external/handler  →  external/service  →  external/repository / client
                                        ↘  external/dto（全層から参照可）
```

## 2. app/ を薄く保つ

責務はルーティングと型変換のみです。ページ内でデータフェッチを行わず、型付きパラメータを features のテンプレートへ渡すだけにします。これを全ページで徹底します。

```tsx
// src/app/requests/[requestId]/page.tsx
import { RequestDetailPageTemplate } from '@/features/requests/components/server'

export default async function RequestDetailPage(props: PageProps) {
  const { requestId } = await props.params
  const searchParams = await props.searchParams
  const highlight = typeof searchParams.highlight === 'string' ? searchParams.highlight : undefined

  return <RequestDetailPageTemplate requestId={requestId} highlightCommentId={highlight} />
}
```

認証チェックと共通 UI は layout に一元化し、各 page で重複させません。

| ルートグループ | 対応状態 | 主なページ |
|---|---|---|
| `(guest)` | 未ログイン | ログイン、サインアップ、メール変更 |
| `(authenticated)` | ログイン済み | ダッシュボード、申請、承認、設定 |
| `(neutral)` | 誰でも可 | パスワードリセット、利用規約 |

## 3. features/ の構成

```
src/features/requests/
├─ components/
│  ├─ server/                        Server Components（ページテンプレート）
│  └─ client/{molecules,organisms}/  Container / Presenter / Hook
├─ hooks/        TanStack Query + クライアントロジック
├─ queries/      クエリキー + queryOptions
├─ actions/      Server Actions（薄いラッパー）
└─ types/        型定義・Enum
```

Container / Presenter / Hook は1部品1ディレクトリでまとめます。

```
components/client/organisms/RequestList/
├─ RequestListContainer.tsx   Hook を呼び、Props を Presenter へ渡す
├─ RequestListPresenter.tsx   純粋な描画。Hook 呼び出しとデータ取得を行わない
├─ useRequestList.ts          TanStack Query とローカル状態
├─ RequestList.test.tsx
└─ index.ts
```

| ファイル | 役割 | 禁止 |
|---|---|---|
| Container | Hook 呼び出しと Props 組み立て | JSX の分岐ロジックを持つこと |
| Presenter | Props を受けて描画するだけ | Hook 呼び出し、データ取得 |
| Hook | データ取得、ローカル状態、イベントハンドラ | JSX を返すこと |

Presenter が Props だけで完結していれば、テストと状態網羅の確認が容易になります。

## 4. Server と Client の使い分け

| 種別 | 置き場所 | 担当 |
|---|---|---|
| Server Component | `features/*/components/server/` | データフェッチ、認証チェック、`prefetchQuery` によるキャッシュ構築、`HydrationBoundary` での引き継ぎ |
| Client Component | `features/*/components/client/` | `useQuery` 経由のデータ参照、状態管理、インタラクション |

静的ビューにはハイドレーションを使いません。ハイドレーションを使わない判断も設計の一部です。

- 操作で状態が変わらない表示は Server Component のままにします。
- 再取得や楽観更新が必要な箇所のみ Client Component にします。
- `"use client"` は Container の階層に置き、Presenter まで巻き込みません。

```tsx
// src/features/requests/components/server/RequestDetailPageTemplate.tsx
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { getQueryClient } from '@/shared/lib/query/getQueryClient'
import { requestDetailQueryOptions } from '@/features/requests/queries/requestDetail'
import { RequestDetailContainer } from '@/features/requests/components/client/organisms/RequestDetail'

type Props = { requestId: string; highlightCommentId?: string }

export async function RequestDetailPageTemplate({ requestId, highlightCommentId }: Props) {
  const queryClient = getQueryClient()
  await queryClient.prefetchQuery(requestDetailQueryOptions(requestId))

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <RequestDetailContainer requestId={requestId} highlightCommentId={highlightCommentId} />
    </HydrationBoundary>
  )
}
```

## 5. queries と mutation

```ts
// src/features/requests/queries/requestDetail.ts
import { queryOptions } from '@tanstack/react-query'
import { fetchRequestDetail } from '@/external/handler/requests'

export const requestKeys = {
  all: ['requests'] as const,
  detail: (requestId: string) => [...requestKeys.all, 'detail', requestId] as const,
  list: (params: { page: number }) => [...requestKeys.all, 'list', params] as const,
}

export const requestDetailQueryOptions = (requestId: string) =>
  queryOptions({
    queryKey: requestKeys.detail(requestId),
    queryFn: () => fetchRequestDetail({ requestId }),
  })
```

`invalidateQueries` は影響範囲を明示的に限定します。全体を一括で無効化すると不要な再取得と再レンダリングが発生します。楽観更新の雛形は `assets/ui-baseline.md` にあります。

## 6. external/ と Server Actions

```
src/external/
├─ dto/           Zodスキーマ + TypeScript型
├─ handler/       Server Action や Server Component から呼ばれる入口
├─ service/       ドメインサービス
├─ repository/    DBアクセス
└─ client/        外部APIクライアント
```

Server Actions は `features/*/actions/` に置き、薄いラッパーに留めます。ロジックは `external/service` にあります。

```ts
// src/features/requests/actions/approveRequest.action.ts
'use server'

import { approveRequestHandler } from '@/external/handler/requests'
import { approveRequestInput } from '@/external/dto/requests'

export async function approveRequestAction(input: unknown) {
  return approveRequestHandler(approveRequestInput.parse(input))
}
```

`*.action.ts` は client と hooks からのみ利用できます。Server Component から直接呼びません。

## 7. import 境界の強制

配置ルールは機械的に強制しなければ守られません。`assets/eslint-boundaries.md` の設定を入れ、意図的な違反でエラーが出ることを確認します。

## 8. 命名とテスト

| 対象 | 規則 | 例 |
|---|---|---|
| Server Actions | `[動詞][対象].action.ts` | `approveRequest.action.ts` |
| Hooks | `use[対象].ts` | `useRequestList.ts` |
| Container | `[対象]Container.tsx` | `RequestListContainer.tsx` |
| Presenter | `[対象]Presenter.tsx` | `RequestListPresenter.tsx` |
| Server Template | `[対象]PageTemplate.tsx` | `RequestDetailPageTemplate.tsx` |
| クエリ定義 | `queries/[対象].ts` | `requestDetail.ts` |
| DTO | `dto/[ドメイン].ts` | `requests.ts` |
| テスト | 対象と同名 + `.test.tsx` | `RequestList.test.tsx` |

テストは対象と同じ階層に並置します。対象は Hooks、Presenter、Server Template を優先します。Container は前2つが個別に検証済みなら省略できます。

## 9. 新機能を追加する手順

1. `src/features/[domain]/` を作る。
2. `external/dto/[domain].ts` に Zod スキーマを定義する。
3. `external/repository` と `external/service` に実装し、`external/handler/[domain].ts` を入口として公開する。
4. `features/[domain]/queries/` に queryOptions とクエリキーを定義する。
5. `features/[domain]/components/client/organisms/[Name]/` に Container、Presenter、Hook、テストを作る。6状態をすべて実装する。
6. `features/[domain]/components/server/[Name]PageTemplate.tsx` で prefetch と HydrationBoundary を組む。
7. `app/` に page.tsx を作り、パラメータを型付けしてテンプレートへ渡すだけにする。
8. `scripts/verify.sh` を通す。

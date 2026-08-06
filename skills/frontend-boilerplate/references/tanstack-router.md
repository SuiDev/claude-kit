# TanStack Router / Start のディレクトリ設計

routes と features を併用します。Router の機能を活かしつつ、ドメインロジックを Router から独立させることが目的です。

判断に迷ったらこの一文に戻ります。

```
Router 依存なら routes、ドメインに関係するなら features
```

---

## 1. 全体構成

```
src/
├─ features/[domain]/
│  ├─ api/                       queryOptions、useSuspenseQuery、useMutation
│  ├─ server/                    createServerFn ラッパー、スキーマ、ロジック実体
│  ├─ hooks/                     フォーム処理などの画面ロジック
│  └─ components/{molecules,organisms}/
├─ shared/components/{atoms,molecules,organisms,templates}/
└─ routes/[route]/
   ├─ -components/
   │  ├─ fallbacks/              pending と error
   │  └─ Page.tsx
   └─ index.tsx
```

| 対象 | 置き場所 |
|---|---|
| `validateSearch`、`loader`、`beforeLoad`、`createFileRoute` | routes |
| `createServerFn` のラッパー、入出力スキーマ、サーバーロジック実体 | features/[domain]/server |
| queryOptions、useSuspenseQuery、useMutation | features/[domain]/api |
| フォーム処理などの画面ロジック | features/[domain]/hooks |
| View 断片 | features/[domain]/components |
| そのルート専用の Page とフォールバック | routes/[route]/-components |

## 2. ハイフン prefix によるコロケーション

ハイフンで始まるディレクトリはルートツリーから除外されます。URL を汚さずにルート専用のファイルを同じ場所へ置けます。

| ディレクトリ | 用途 |
|---|---|
| `-components/` | そのルートだけで使う Page |
| `-components/fallbacks/` | pending と error |
| `-api/` | そのルート専用の queryOptions、mutationOptions |
| `-hooks/` | Router に依存しない画面ロジック |

複数ルートで共有するものは features へ移します。共有し始めた時点が移動の合図です。

`pendingComponent` と `errorComponent` はルート定義から参照されるため Page と同じ粒度で存在しますが、Page 本体と混ぜると見通しが落ちるため `fallbacks/` に分離します。ローディングとエラーの表示を後から差し替える際も対象が1か所にまとまります。

## 3. routes 配下のコード

```tsx
// src/routes/contracts/index.tsx
import { createFileRoute } from '@tanstack/react-router'
import { z } from 'zod'
import { contractsQueryOptions } from '@/features/contracts/api/contracts'
import { Page } from './-components/Page'
import { ContractsPending, ContractsError } from './-components/fallbacks'

export const Route = createFileRoute('/contracts')({
  validateSearch: z.object({
    page: z.number().default(1),
    tab: z.enum(['active', 'archived']).default('active'),
  }),
  loader: ({ context }) => context.queryClient.ensureQueryData(contractsQueryOptions),
  pendingComponent: ContractsPending,
  errorComponent: ContractsError,
  component: Page,
})
```

このファイルに含めてよいのは上記の宣言だけです。データ整形、条件分岐、フォーム処理は features 側に置きます。

```tsx
// src/routes/contracts/-components/Page.tsx
import { Route } from '../index'
import { ContractList } from '@/features/contracts/components/organisms/ContractList'

export function Page() {
  const { page, tab } = Route.useSearch()
  return <ContractList page={page} tab={tab} />
}
```

## 4. api/ と server/

```ts
// src/features/contracts/api/contracts.ts
import { queryOptions, useSuspenseQuery } from '@tanstack/react-query'
import { listContracts } from '@/features/contracts/server/contract.functions'

export const contractKeys = {
  all: ['contracts'] as const,
  list: (params: { page: number; tab: string }) => [...contractKeys.all, 'list', params] as const,
}

export const contractsQueryOptions = queryOptions({
  queryKey: contractKeys.all,
  queryFn: () => listContracts(),
})

export function useContracts() {
  return useSuspenseQuery(contractsQueryOptions)
}
```

Server Function は3つの役割に分けます。

| ファイル | 役割 |
|---|---|
| `[entity].functions.ts` | `createServerFn` のラッパー。入力バリデータの結線とロジック呼び出しのみ |
| `[entity]-schema.ts` | 入出力バリデーション |
| `[動詞]-[entity].server.ts` | サーバーロジックの実装 |

```ts
// contract-schema.ts
export const createContractInput = z.object({ title: z.string().min(1), amount: z.number().int().positive() })
export type CreateContractInput = z.infer<typeof createContractInput>

// create-contract.server.ts
export async function createContractLogic(input: CreateContractInput) {
  return { id: 'generated-id', ...input }
}

// contract.functions.ts
import { createServerFn } from '@tanstack/react-start'
export const createContract = createServerFn({ method: 'POST' })
  .validator(createContractInput)
  .handler(({ data }) => createContractLogic(data))
```

この分割により、ラッパーを差し替えてもロジックとスキーマが影響を受けません。ロジックは Router も Start も知らない純粋な関数として単体テストできます。

## 5. 却下した構成

同じ判断を繰り返さないために残します。

| 案 | 却下理由 |
|---|---|
| features に寄せる（Page まで features、routes は薄いラッパー） | ハイフン prefix のコロケーションなど Router の機能を活かしきれない |
| routes に全部押し込む | 複数ルートで共有するドメインロジックの置き場がなくなる |
| ハイブリッド | 採用 |

Server Function の置き場も3案を比較しています。

| 案 | 却下理由 |
|---|---|
| `src/server` に集約 | ドメインとの対応が見えず、ドメイン単位の把握が難しい |
| routes にハイブリッド（ラッパーのみ routes） | features が routes に依存する逆転構造になり、ドメインロジックが分散する |
| features に寄せる | 採用 |

## 6. 命名

| 対象 | 規則 | 例 |
|---|---|---|
| Server Function ラッパー | `[entity].functions.ts` | `contract.functions.ts` |
| 入出力スキーマ | `[entity]-schema.ts` | `contract-schema.ts` |
| サーバーロジック | `[動詞]-[entity].server.ts` | `create-contract.server.ts` |
| ルート専用 Page | `-components/Page.tsx` | 同左 |
| フォールバック | `-components/fallbacks/` | `ContractsPending.tsx` |
| queryOptions | `api/[entity].ts` | `api/contracts.ts` |
| テスト | 対象と同名 + `.test.ts(x)` | `create-contract.server.test.ts` |

## 7. SPA 構成との差分

TanStack Router 単体（SPA）を選んだ場合は `features/[domain]/server/` を作らず、既存 API を叩く `api/` のみを置きます。あとは同一です。後から Server Function が必要になったら `server/` を追加するだけで移行できます。この移行しやすさがハイブリッドを採用する理由の1つです。

## 8. 新機能を追加する手順

1. `src/features/[domain]/` を作る。
2. Start を使う場合は `server/` に schema、logic、functions の3ファイルを作る。
3. `api/` に queryOptions とフックを定義する。
4. `components/` に View を作り、必要なら `hooks/` に画面ロジックを切り出す。6状態をすべて実装する。
5. `src/routes/[route]/index.tsx` に `createFileRoute` を書き、`validateSearch` と `loader` を宣言する。
6. `-components/Page.tsx` に search params の読み取りとアダプタを書く。
7. `-components/fallbacks/` に pending と error を作り、ルート定義から参照する。
8. `scripts/verify.sh` を通す。

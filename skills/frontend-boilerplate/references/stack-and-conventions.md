# スタック選定と共通規約

ユーザーがスタックを明示している場合は判定表を適用せず、指定を採用します。

---

## 1. 判定フロー

上から順に評価し、最初に一致した行を採用します。

| 順 | 条件 | 選定 |
|---|---|---|
| 1 | 未ログインユーザーに見せるページがあり、SEO・OG画像・初期表示速度のいずれかが要件 | Next.js App Router |
| 2 | ログイン後のみの画面で、サーバー処理（DBアクセス、秘匿API、ファイル処理）が必要 | TanStack Start |
| 3 | ログイン後のみの画面で、サーバーは既存APIに任せられる | TanStack Router（SPA） |
| 4 | 一覧のフィルタ・ページング・タブなど URL 状態が多く、型安全な search params を重視 | TanStack Router または TanStack Start |
| 5 | 上記のいずれにも当てはまらない | Next.js App Router |

| 依頼の例 | 選定 | 理由 |
|---|---|---|
| 社内向けの申請・承認管理画面 | TanStack Start | ログイン後のみで、承認処理にサーバー側ロジックが必要 |
| コーポレートサイトに問い合わせフォーム | Next.js App Router | 公開ページで SEO が要件 |
| 既存 REST API を叩くダッシュボード | TanStack Router | サーバー処理を既存 API に委譲できる |
| 詳細不明のツール | Next.js App Router | 条件5。詳細が判明した時点で再判定する |

静的サイト向けの別フレームワークは、必要になった時点で検討します。参照資料を持たないスタックを判定表に載せません。

### 採用しない構成

| 構成 | 理由 |
|---|---|
| 素の `index.html` に script タグ直書き | 型安全性、部品分割、テスト、ビルド最適化のいずれも得られない |
| CDN から React を読み込む | バージョン管理と型定義が効かない |
| Create React App | メンテナンスが終了している |
| Next.js Pages Router（新規） | App Router が標準 |
| 独自の webpack 手組み | 得られる制御に対して維持費用が見合わない |

### 選定結果の提示形式

```
スタック: TanStack Start
理由: ログイン後のみの管理画面で承認処理にサーバー側ロジックが必要なため（判定2）
```

## 2. 共通で採用するもの

除外する場合は理由を提示します。

| 領域 | 採用 | 補足 |
|---|---|---|
| 言語 | TypeScript（strict） | `strict` と `noUncheckedIndexedAccess` を有効にする |
| サーバー状態 | TanStack Query | Next.js App Router でもクライアント側キャッシュとして併用する |
| スキーマ | Zod | 型の単一情報源。TypeScript 型は `z.infer` で導出する |
| フォーム | React Hook Form + Zod resolver | 3項目以下で検証が単純なら素の state も許容 |
| スタイル | Tailwind CSS + トークン | トークンは `assets/ui-baseline.md` |
| UI 部品 | shadcn/ui | コード生成型。生成物を atoms と molecules へ層ごとに振り分ける |
| デザイントークン | CSS カスタムプロパティ（oklch） | 基準色・強調色・コントラストの3変数から導出する |
| 単体テスト | Vitest + React Testing Library | 対象ファイルと同階層に並置する |
| E2E と品質検証 | Playwright | ルートの `e2e/`。`assets/e2e-quality.spec.ts` を配置する |
| Lint | ESLint flat config | import 境界ルールと Hooks の静的検査（eslint-plugin-react-hooks）を必ず含める |
| 自動メモ化 | React Compiler | 新規作成では有効化する。有効化手順は採用時点の公式ドキュメントで確認する |
| フォーマット | Prettier | Lint と役割を分ける |

部品カタログの道具（Storybook 等）は、部品の一覧と検証が実際に必要になった時点で導入します。視覚的な破壊的変更の検出は Playwright の視覚回帰で足ります。

## 3. 貫く思想

1. 置き場所のルールは Lint で機械的に強制します。ドキュメントだけのルールは守られません。
2. 依存の向きは一方向に固定します。逆方向の import が必要になった時点で層の切り方が間違っています。
3. ルーティング層は薄く保ちます。フレームワーク依存の記述とドメインロジックを混ぜません。
4. 正常系だけを実装した時点は未完成です。状態網羅とアクセシビリティは工程の1つではなく完了の条件です。

## 4. 状態管理の優先順位

上から順に検討し、下位は上位で表現できないときだけ使います。

| 順 | 手段 | 使う場面 |
|---|---|---|
| 1 | URL（search params、path params） | フィルタ、ページング、タブ、選択中のID。共有と再現が必要な状態 |
| 2 | サーバー状態キャッシュ（TanStack Query） | API から取得したデータ、再取得、楽観更新 |
| 3 | コンポーネントローカル state | 入力中の値、開閉状態 |
| 4 | グローバルストア | 上記で表現できない横断的な UI 状態のみ |

サーバーから取得したデータをグローバルストアへ複製しません。二重管理は同期漏れの原因です。

## 5. TanStack Query

| 項目 | 規約 |
|---|---|
| クエリキー | ドメインごとに `[domain]Keys` オブジェクトへ集約し、文字列リテラルを散らさない |
| クエリ定義 | `queryOptions()` で定義し、prefetch と useQuery で共有する |
| 無効化 | `invalidateQueries` の対象を明示的に絞る。ドメイン全体の一括無効化は最後の手段 |
| エラー | `throwOnError` とエラーバウンダリの組み合わせで表示側の分岐を減らす |
| 既定値 | `staleTime` をプロジェクト共通で設定し、個別指定は理由がある場合のみ |

```ts
export const contractKeys = {
  all: ['contracts'] as const,
  list: (params: { page: number }) => [...contractKeys.all, 'list', params] as const,
  detail: (id: string) => [...contractKeys.all, 'detail', id] as const,
}
```

## 6. スキーマと型

Zod を単一の情報源とし、型は `z.infer` で導出します。同じ形を型定義とスキーマで二重に書きません。

```ts
export const contractInput = z.object({ title: z.string().min(1), amount: z.number().int().positive() })
export type ContractInput = z.infer<typeof contractInput>
```

外部との境界（API レスポンス、フォーム入力、環境変数、search params）では必ず parse を通します。内側では型を信頼します。`any` を使いません。外部由来は `unknown` で受けて parse します。

型の絞り込みは Narrowing（`typeof`、`in`、判別子の比較）と parse で行います。`as` による型アサーションは実行時の検証を伴わないため最後の手段とし、使う場合は根拠をコメントに残します。型注釈で型を広げずに適合だけを検査したい場合は `satisfies` を使います。

排他的な状態は boolean の組み合わせではなく、判別子を持つ Union（Tagged Union）でモデリングします。あり得ない組み合わせを型で表現できなくすることが目的です。

```ts
type FetchState<T> =
  | { kind: 'loading' }
  | { kind: 'success'; data: T }
  | { kind: 'error'; error: Error }
```

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "verbatimModuleSyntax": true,
    "paths": { "@/*": ["./src/*"] }
  }
}
```

## 7. React の実装規約

| 項目 | 規約 |
|---|---|
| データ取得 | `useEffect` で行わない。サーバー状態は TanStack Query（第5節）で扱う |
| `useEffect` の用途 | 外部システムとの同期（購読、タイマー、生の DOM API）のみ。props や state から導出できる値に使わない |
| 依存配列 | エフェクトが参照する値をすべて入れる。Lint の警告に従い、手で間引かない。間引きたくなった時点でエフェクトの設計を見直す |
| クリーンアップ | 購読・タイマー・接続を開始したエフェクトは、解除する関数を返す |
| メモ化 | 手動メモ化（`useMemo`、`useCallback`、`memo`）を既定で書かない。React Compiler に委ね、効いていないことが実測で示された箇所のみ手動化する |
| ref | 通常の prop として受け渡す。転送専用のラッパー API を使わない |
| Hooks の静的検査 | eslint-plugin-react-hooks をプロジェクトの初手で導入する。後からの導入は既存違反の一括修正を強いる。設定は `assets/eslint-boundaries.md` |

## 8. スタイル

トークンを前提に組みます。迂回するとテーマ切り替えと高コントラストが効きません。実装は `assets/ui-baseline.md`、設計は `references/design-system.md` 第7節です。

| 項目 | 規約 |
|---|---|
| トークン | 3層（原始値、意味、部品固有）を `shared/styles/tokens.css` に定義する |
| テーマ | 基準色・強調色・コントラストの3変数から導出する |
| 条件付きクラス | 分岐が2個以上なら CVA で variant として定義する |
| クラス結合 | `cn()`（clsx + tailwind-merge）を `shared/lib/` に置く |
| 任意値 | `w-[137px]` や `text-[#3b82f6]` を書かない。必要ならトークンを追加する |
| 部品の外側の余白 | 部品自身に `margin` を書かない。外側の余白は利用側が決める |

導出した色のコントラスト比は測定します。生成式は測定の代わりになりません。`assets/e2e-quality.spec.ts` が3テーマで自動判定します。

## 9. テスト

| 種別 | ツール | 配置 |
|---|---|---|
| 単体・コンポーネント | Vitest + React Testing Library | 対象ファイルと同階層に並置 |
| E2E と品質検証 | Playwright | ルートの `e2e/` |

並置の理由は、開いて変更してテストを回す流れが1か所で完結することです。優先順位はサーバーロジックとドメイン関数（純粋関数で費用対効果が最も高い）、Presenter（Props だけで完結する）、Hook（状態遷移と副作用）、Container（前2つが検証済みなら省略可）の順です。

実装の内部構造ではなく利用者から見た振る舞いを検証します。テストのためだけの props やクラス名を本体に足しません。

## 10. バレルエクスポートとコメント

Container / Presenter / Hook の1セットには `index.ts` を置いて窓口を1つにします。features 直下や layer 直下に巨大なバレルを作りません。循環参照とバンドル寸法の原因になります。

コメントは WHY が非自明な場合（隠れた制約、回避策、設計判断の根拠）にのみ書きます。値や識別子で意図が読める箇所には書きません。特定環境にだけ言及するコメントは書きません。環境が増えた時点で陳腐化します。

## 11. Docker とバージョン

ローカルへの依存インストールとローカルビルドを行いません。

| 用途 | コマンド |
|---|---|
| 依存追加 | `docker compose run --rm web npm install [pkg]` |
| 開発サーバー | `docker compose up -d` |
| 検証一括 | `bash ~/.claude/skills/frontend-boilerplate/scripts/verify.sh .` |

`node_modules` は名前付きボリュームに載せます。ホストとコンテナでネイティブモジュールのバイナリが異なるためです。Vite 系は `--host 0.0.0.0` を指定します。ファイル監視が効かない場合は polling を有効化します。

バージョンを固定で書きません。必要になった時点で確認します。

```bash
for p in next react @tanstack/react-router @tanstack/react-start @tanstack/react-query zod tailwindcss; do
  printf '%s: ' "$p"; npm view "$p" version
done
```

# import 境界と React Hooks の Lint 設定

配置ルールと Hooks のルールは機械的に強制しなければ守られません。

既定は ESLint 標準ルールのみで組む方式です。追加プラグインを要さないため、`eslint-plugin-import` の flat config 対応状況に左右されません。ゾーンとして宣言的に書きたい場合のみプラグインを使います。

同じ `files` に対して `no-restricted-imports` を二重に設定すると後勝ちで上書きされます。対象が重なる場合は1つの設定にまとめ、`patterns` を配列で並べます。

---

## 既定: no-restricted-imports のみ（Next.js App Router）

```js
// eslint.config.mjs
export default [
  {
    files: ['src/features/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          {
            group: ['@/external/service/**', '@/external/repository/**', '@/external/client/**'],
            message: 'features からの直接 import は禁止です。@/external/handler を経由してください。',
          },
        ],
      }],
    },
  },
  {
    files: ['src/shared/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@/features/**', '@/external/**'], message: 'shared はドメインと外部I/Oに依存できません。' },
        ],
      }],
    },
  },
  {
    files: ['src/external/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@/features/**', '@/app/**'], message: 'external は features と app に依存できません。依存の向きが逆転しています。' },
        ],
      }],
    },
  },
  {
    // app と Server Component から Server Actions を直接呼ばない。app でデータフェッチもしない
    files: ['src/app/**/*.{ts,tsx}', 'src/features/*/components/server/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@/external/**'], message: 'app でデータフェッチを行いません。features のページテンプレートへ委譲してください。' },
          { group: ['**/*.action', '**/*.action.ts'], message: 'Server Actions は client コンポーネントと hooks からのみ利用します。' },
        ],
      }],
    },
  },
]
```

## 既定: TanStack Router / Start

features が routes に依存する逆転構造を防ぐことが主目的です。

```js
// eslint.config.mjs
export default [
  {
    files: ['src/features/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@/routes/**'], message: 'features から routes を import できません。Router 依存の記述は routes 側に置いてください。' },
        ],
      }],
    },
  },
  {
    files: ['src/shared/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@/features/**', '@/routes/**'], message: 'shared はドメインと routes に依存できません。' },
        ],
      }],
    },
  },
]
```

## 任意: ゾーンとして宣言する

層構造の禁止関係をそのまま書けます。採用する前に、使う ESLint の版で flat config が動くことを確認します。`eslint-plugin-import` が動かない場合は保守されているフォークを検討し、いずれも不安定なら既定の方式に戻します。

```bash
docker compose run --rm web npm install -D eslint-plugin-import eslint-import-resolver-typescript
```

```js
// eslint.config.mjs
import importPlugin from 'eslint-plugin-import'

export default [
  {
    files: ['src/**/*.{ts,tsx}'],
    plugins: { import: importPlugin },
    settings: { 'import/resolver': { typescript: true } },
    rules: {
      'import/no-restricted-paths': ['error', {
        basePath: '.',
        zones: [
          { target: './src/features', from: './src/external/service', message: 'external/handler を経由してください。' },
          { target: './src/features', from: './src/external/repository', message: 'external/handler を経由してください。' },
          { target: './src/features', from: './src/external/client', message: 'external/handler を経由してください。' },
          { target: './src/shared', from: './src/features', message: 'shared はドメインに依存できません。' },
          { target: './src/shared', from: './src/external', message: 'shared は外部I/O層に依存できません。' },
          { target: './src/external', from: './src/features', message: '依存の向きが逆転しています。' },
          { target: './src/app', from: './src/external', message: 'app でデータフェッチを行いません。' },
        ],
      }],
    },
  },
]
```

## 任意: カスタムルール

境界の判定にファイル内容の解析が必要な場合のみ書きます。flat config ではプラグインオブジェクトとして直接渡せます。

```js
// eslint-local-rules/restrict-service-imports.js
export const restrictServiceImports = {
  meta: {
    type: 'problem',
    docs: { description: 'service層への直接importを禁止し、handler経由に限定します。' },
    schema: [],
    messages: { forbidden: 'service層への直接importは禁止です。external/handler を経由してください。' },
  },
  create(context) {
    const isHandler = context.filename.includes('/src/external/handler/')
    return {
      ImportDeclaration(node) {
        if (isHandler) return
        const source = node.source.value
        if (typeof source === 'string' && source.includes('external/service')) {
          context.report({ node, messageId: 'forbidden' })
        }
      },
    }
  },
}
```

```js
import { restrictServiceImports } from './eslint-local-rules/restrict-service-imports.js'

export default [
  {
    files: ['src/**/*.{ts,tsx}'],
    plugins: { local: { rules: { 'restrict-service-imports': restrictServiceImports } } },
    rules: { 'local/restrict-service-imports': 'error' },
  },
]
```

## 必須: React Hooks の静的検査

境界ルールと同じ `eslint.config.mjs` に、Hooks の静的検査を必ず含めます。プロジェクトの初手で導入します。後から導入すると、蓄積した既存違反の一括修正を強いられるためです。

```js
// eslint.config.mjs
import reactHooks from 'eslint-plugin-react-hooks'

export default [
  reactHooks.configs.flat.recommended,
  // ...import 境界の設定
]
```

- プリセットの名称と含まれるルールは版によって変わります。導入時点の公式ドキュメント（https://react.dev/reference/eslint-plugin-react-hooks ）で確認します。
- フレームワークの公式 ESLint 設定に同等の検査が含まれている場合は二重に追加しません。含まれているかは推測せず、次項の検証で依存配列の警告が実際に出ることを確認します。
- 依存配列の警告を抑止コメントで消しません。警告が出た時点でエフェクトの設計を見直します。

## 検証

設定を入れたら、意図的に違反する import を1行と、依存配列に入れ忘れのある `useEffect` を1つ書き、それぞれエラーと警告になることを確認します。設定したつもりで効いていない状態を防ぐための必須手順です。確認後、検証用のコードは必ず削除します。

```bash
docker compose run --rm web npm run lint
```

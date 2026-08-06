# UI 実装ベースライン

`references/ux-implementation.md` と `references/design-system.md` の規約を実装に落とした雛形です。数値は `budgets.json`（プロジェクトでは `e2e/budgets.json`）が単一情報源です。パッケージのバージョンは実行時に `npm view` で確認します。

視覚設計の規範は `references/visual-craft.md` にあります。トークンの実体は `assets/tokens.css` です。

---

## 1. デザイントークン

トークンの実体は `assets/tokens.css` です。そのまま `src/shared/styles/tokens.css` へ配置します。階調12段、活字、間隔、角丸、影、動き、密度、制御寸法を含みます。

変えるのは原則として3つだけです。`--hue-accent`、`--hue-gray`、`--contrast`。段の用途と使い分けの規範は `references/visual-craft.md` にあります。

Tailwind への接続は次の形です。参照元と定義先で名前が異なることが必須で、同名にすると自己参照になり解決できません。`tokens.css` 側は Tailwind の名前空間（`--color-*` `--text-*` `--font-*` `--radius-*` `--shadow-*` `--ease-*`）を避けた接頭辞にしてあります。

```css
/* src/shared/styles/globals.css */
@import 'tailwindcss';
@import './tokens.css';

@theme inline {
  /* 面と線と文字 */
  --color-canvas: var(--bg);
  --color-subtle: var(--bg-subtle);
  --color-comp: var(--comp);
  --color-comp-hover: var(--comp-hover);
  --color-comp-active: var(--comp-active);
  --color-line: var(--line);
  --color-edge: var(--edge);
  --color-edge-hover: var(--edge-hover);
  /* 部品の識別に必要な境界。装飾の罫線（段6・段7）と分けている */
  --color-edge-control: var(--edge-control);
  --color-fg: var(--fg);
  --color-fg-muted: var(--fg-muted);

  /* 強調色 */
  --color-primary: var(--acc-solid);
  --color-primary-hover: var(--acc-solid-hover);
  --color-primary-fg: var(--on-solid);
  --color-primary-subtle: var(--acc-bg);
  --color-primary-edge: var(--acc-edge);
  --color-primary-text: var(--acc-fg);

  /* 意味色 */
  --color-danger: var(--danger-9);
  --color-danger-hover: var(--danger-10);
  --color-danger-text: var(--danger-11);
  --color-warning: var(--warning-9);
  --color-warning-text: var(--warning-11);
  --color-success: var(--success-9);
  --color-success-text: var(--success-11);

  /* 活字 */
  --font-sans: var(--ff-sans);
  --font-mono: var(--ff-mono);
  --text-2xs: var(--fs-2xs);
  --text-xs: var(--fs-xs);
  --text-sm: var(--fs-sm);
  --text-md: var(--fs-md);
  --text-lg: var(--fs-lg);
  --text-xl: var(--fs-xl);
  --text-2xl: var(--fs-2xl);
  --text-3xl: var(--fs-3xl);
  --text-4xl: var(--fs-4xl);
  --leading-tight: var(--lh-tight);
  --leading-snug: var(--lh-snug);
  --leading-normal: var(--lh-normal);
  --tracking-tight: var(--ls-tight);
  --tracking-snug: var(--ls-snug);
  --tracking-wide: var(--ls-wide);

  /* 形と影と曲線 */
  --radius-2: var(--r-2);
  --radius-3: var(--r-3);
  --radius-4: var(--r-4);
  --radius-6: var(--r-6);
  --shadow-1: var(--elev-1);
  --shadow-2: var(--elev-2);
  --shadow-3: var(--elev-3);
  --ease-standard: var(--curve-standard);
  --ease-entrance: var(--curve-entrance);
  --ease-exit: var(--curve-exit);
}
```

`transition-all` を禁止する代わりに、対象を絞った遷移をユーティリティとして定義します。

```css
/* globals.css に追記 */
@utility transition-control {
  transition-property: color, background-color, border-color, box-shadow;
  transition-duration: var(--dur-1);
  transition-timing-function: var(--curve-standard);
}

/* フォーカスの可視化。任意値の直書きを避けるためユーティリティにする */
@utility focus-ring {
  box-shadow: var(--focus-ring);
}

/* 区画見出しの上に置く小さなラベル。区画の主従を作る */
@utility eyebrow {
  font-size: var(--fs-2xs);
  letter-spacing: var(--ls-caps);
  line-height: var(--lh-snug);
  color: var(--fg-muted);
  font-weight: 600;
  text-transform: uppercase;
}

/* 制御の高さ。数値を直書きすると data-density の切り替えが効かなくなる */
@utility control-sm {
  height: var(--control-sm);
}
@utility control-md {
  height: var(--control-md);
}
@utility control-lg {
  height: var(--control-lg);
}
```

数値の桁揃えは Tailwind の `tabular-nums` を使います。同じことをするユーティリティを自作しません。

本文の既定を当てます。日本語は字面が大きいため、英字向けの行間では詰まって見えます。

```css
/* globals.css に追記 */
:root {
  font-family: var(--ff-sans);
  /* Chrome で合字と文脈依存の異体が無効になる場合の補い */
  font-feature-settings: 'liga' 1, 'calt' 1;
  font-optical-sizing: auto;
}

body {
  background-color: var(--bg);
  color: var(--fg);
  font-size: var(--fs-md);
  line-height: var(--lh-normal);
}
```

shadcn/ui を導入する場合は、生成物が期待する変数名への別名をこの層で与えます。

```css
/* globals.css に追記 */
:root {
  --background: var(--bg);
  --foreground: var(--fg);
  --card: var(--bg-subtle);
  --card-foreground: var(--fg);
  --primary: var(--acc-solid);
  --primary-foreground: var(--on-solid);
  --secondary: var(--comp);
  --secondary-foreground: var(--fg);
  --muted: var(--comp);
  --muted-foreground: var(--fg-muted);
  --destructive: var(--danger-9);
  --border: var(--edge);
  --input: var(--edge);
  --ring: var(--accent-8);
  --radius: var(--r-4);
}
```

導出した色のコントラスト比は `assets/e2e-quality.spec.ts` が3テーマで測定します。生成式は測定の代わりになりません。

没入型で図や画像を扱う場合のみ、次を追記します。使わない画面には入れません。

```css
/* hover の応答を寸法と影で行う */
@utility transition-lift {
  transition-property: transform, box-shadow, background-color;
  transition-duration: var(--dur-3);
  transition-timing-function: var(--curve-entrance);
}

/* 図の上に文字を載せるときの覆い。可読性のための機能 */
@utility scrim {
  background-image: var(--scrim-bottom);
}
```

禁止: 任意値の色と寸法を直書きすること、部品固有トークンを網羅的に作ること、部品の外側に余白を書くこと、`transition-all` を使うこと。`scripts/ux-lint.sh` が検出します。

分岐点は `max-*` 変種で書きます。素の指定を基準幅（`budgets.json` の `viewport.designPx`）向けとし、狭い幅を上書きとして足します。部品の寸法に応じた分岐にはコンテナクエリ（`@container` と `@sm:` など）を使います。`ux-lint.sh` の UX26 が min-width 変種を検出します。

## 2. クラス結合と variant

```ts
// src/shared/lib/cn.ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'
export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)) }
```

```ts
// src/shared/components/atoms/Button/variants.ts
import { cva } from 'class-variance-authority'

export const buttonVariants = cva(
  // 操作対象の下限は budgets.json の target.minPx。min-w も併せて確保しないと図記号だけの
  // ボタンが下限を割る
  'inline-flex min-w-8 items-center justify-center gap-2 rounded-3 font-medium whitespace-nowrap ' +
    'transition-control focus-visible:outline-none focus-visible:focus-ring ' +
    'aria-disabled:pointer-events-none aria-disabled:opacity-45',
  {
    variants: {
      // 塗りは1画面に1つ。副は枠のみ、三次は文字のみ
      intent: {
        primary: 'bg-primary text-primary-fg hover:bg-primary-hover',
        secondary: 'bg-comp text-fg hover:bg-comp-hover active:bg-comp-active',
        ghost: 'text-fg-muted hover:bg-comp hover:text-fg active:bg-comp-hover',
        danger: 'bg-danger text-primary-fg hover:bg-danger-hover',
      },
      // 高さはトークン経由。数値を直書きすると密度の切り替えが効かない
      size: {
        sm: 'control-sm px-2.5 text-xs',
        md: 'control-md px-3.5 text-sm',
        lg: 'control-lg px-5 text-md',
      },
    },
    defaultVariants: { intent: 'secondary', size: 'md' },
  },
)
```

`--control-sm` は `budgets.json` の `target.minPx` と同じ値です。これより小さい制御を作る場合は、余白を含めた当たり判定で下限を満たします。

```tsx
// src/shared/components/atoms/Button/Button.tsx
import type { VariantProps } from 'class-variance-authority'
import { cn } from '@/shared/lib/cn'
import { buttonVariants } from './variants'

type Props = React.ComponentProps<'button'> & VariantProps<typeof buttonVariants>

export function Button({ intent, size, className, ...props }: Props) {
  return <button {...props} className={cn(buttonVariants({ intent, size }), className)} />
}
```

Button のように状態を持たない薄い部品は自前で書きます。重ね合わせ、選択、開閉、通知、表は自前で書かず部品ライブラリから生成します。境界は `references/ui-libraries.md` 第1節の表です。

アイコンは操作の意味を伝えるために置きます。文字だけのボタンが並ぶ画面は、情報量が同じでも未完成に見えます。

```tsx
import { Plus } from 'lucide-react'

// aria-hidden を付ける。ボタンの意味は文言が持っており、図は補助
<Button intent="primary">
  <Plus size={16} aria-hidden />
  追加する
</Button>

// 図だけのボタンは読み上げ用の名前を必ず持たせる
<Button aria-label="絞り込む">
  <Filter size={16} aria-hidden />
</Button>
```

寸法と線幅と配置の規約は `references/ui-libraries.md` 第3節です。

## 3. 理由のない無効化を作らない

`disabled` 属性はフォーカスも支援技術からの認識も奪うため、理由を伝える必要がある場合は使いません。`aria-disabled` で表現し、理由を画面上の要素として関連付けます。

### 3-1. まず無効化しないで済ませられないか

無効化は最後の手段です。次の順に検討し、上で解決できるならその形にします。

| 順 | 手段 | 例 |
|---|---|---|
| 1 | 操作を押せるままにし、押されたら誤りを示す | 未入力のまま送信を押したら、該当する欄に誤りを表示する |
| 2 | 操作自体を出さない | 権限がない機能は一覧に出さない |
| 3 | 無効化し、理由を添える | 申請者本人には承認操作を無効化し、理由を示す |

順1が既定です。入力が完了するまで送信を無効化する形は、なぜ押せないかを利用者に探させます。押せるようにして、押した時点で不足している箇所を示すほうが早く終わります。

### 3-2. 理由をどこに置くか

無効化する場合、理由の置き場所を次の表で選びます。ボタン直下の常時表示は既定ではありません。この形が適するのは、理由が操作の前提条件で、かつ読まないと解消できない場合だけです。

| 状況 | 置き場所 |
|---|---|
| 理由が入力内容に起因する | 原因となっている入力欄の直下。操作の近くには置かない |
| 理由が権限や状態に起因し、解消に他者の行動が必要 | 操作の直下に常時表示する。`GuardedAction` を使う |
| 理由が一時的（処理中、上限に達している） | 操作に隣接した位置。処理が終われば消える |
| 理由が自明（未選択の状態で一括操作を押せない） | 表示しない。`aria-disabled` と読み上げ用の説明だけ持たせる |

いずれの場合も、無効化されていない間は理由の要素を描画しません。`ux-implementation.md` 第12-1節の対象になります。

```tsx
// src/shared/components/molecules/GuardedAction/GuardedAction.tsx
type Props = {
  id: string
  /** 無効化するときは必須。理由のない無効化を型で防ぐ */
  disabledReason?: string
  children: (attrs: {
    'aria-disabled': true | undefined
    'aria-describedby': string | undefined
    onClickCapture: React.MouseEventHandler
  }) => React.ReactNode
}

export function GuardedAction({ id, disabledReason, children }: Props) {
  const blocked = !!disabledReason
  const reasonId = blocked ? `${id}-reason` : undefined

  return (
    <div className="flex flex-col gap-1">
      {children({
        'aria-disabled': blocked || undefined,
        'aria-describedby': reasonId,
        onClickCapture: (e) => { if (blocked) e.preventDefault() },
      })}
      {disabledReason && <p id={reasonId} className="text-sm text-fg-muted">{disabledReason}</p>}
    </div>
  )
}
```

```tsx
<GuardedAction id="approve" disabledReason={canApprove ? undefined : '承認は申請者以外のみ行えます'}>
  {(attrs) => <Button {...attrs} onClick={approve}>承認する</Button>}
</GuardedAction>
```

部品の中で無効化と理由が完全に閉じている場合は、この部品を使わず同じ組み合わせを直接書いてかまいません。満たすべき条件は `aria-disabled`、理由を表示する要素、その要素を指す `aria-describedby` の3点が揃っていることです。

```tsx
// 部品内で閉じている例。GuardedAction を挟むと逆に読みにくくなる
const noteId = `${id}-limit`
const note = atMin ? '下限に達しています' : atMax ? '上限に達しています' : undefined
// ...
<Button aria-disabled={atMin || undefined} aria-describedby={atMin ? noteId : undefined} onClick={dec}>−</Button>
{note && <p id={noteId} className="text-sm text-fg-muted">{note}</p>}
```

## 4. 状態網羅

6状態を型で強制します。`switch` に既定節を置かないことで、状態追加時の実装漏れが型エラーになります。

```ts
// src/shared/components/molecules/AsyncBoundary/types.ts
export type AsyncState<T> =
  | { kind: 'loading' }
  | { kind: 'empty' }
  | { kind: 'partial'; data: T; failedRanges: string[] }
  | { kind: 'error'; message: string; cause?: string; retry: () => void }
  | { kind: 'forbidden'; requiredRole: string; contact?: string }
  | { kind: 'success'; data: T }
```

```tsx
// src/shared/components/molecules/AsyncBoundary/AsyncBoundary.tsx
type Props<T> = {
  state: AsyncState<T>
  /** 空状態は「何が入る場所か」と「最初の一歩」を必ず示す */
  empty: { title: string; description: string; action?: React.ReactNode }
  children: (data: T) => React.ReactNode
}

export function AsyncBoundary<T>({ state, empty, children }: Props<T>) {
  switch (state.kind) {
    case 'loading':
      return <div className="min-h-40 animate-pulse rounded-4 bg-subtle" aria-busy="true" />
    case 'empty':
      return (
        <div className="flex flex-col items-center gap-3 py-12 text-center">
          <p className="font-medium text-fg">{empty.title}</p>
          <p className="max-w-prose text-sm text-fg-muted">{empty.description}</p>
          {empty.action}
        </div>
      )
    case 'partial':
      return (
        <>
          <div role="status" className="mb-3 rounded-4 bg-warning-bg p-3 text-sm text-warning-text">
            一部を取得できませんでした: {state.failedRanges.join('、')}
          </div>
          {children(state.data)}
        </>
      )
    case 'error':
      return (
        <div role="alert" className="flex flex-col items-start gap-3 rounded-4 bg-danger-bg p-5">
          <p className="font-medium text-danger-text">{state.message}</p>
          {state.cause && <p className="text-sm text-fg-muted">{state.cause}</p>}
          <Button intent="secondary" onClick={state.retry}>もう一度試す</Button>
        </div>
      )
    case 'forbidden':
      return (
        <div role="alert" className="rounded-4 bg-comp p-5">
          <p className="font-medium text-fg">この操作には{state.requiredRole}権限が必要です</p>
          {state.contact && <p className="mt-2 text-sm text-fg-muted">{state.contact}に権限の付与を依頼してください</p>}
        </div>
      )
    case 'success':
      return children(state.data)
  }
}
```

```ts
// src/features/[domain]/hooks/useAsyncState.ts
export function useAsyncState<T>(
  query: UseQueryResult<T[]>,
  options: { requiredRole?: string } = {},
): AsyncState<T[]> {
  if (query.isPending) return { kind: 'loading' }
  if (query.isError) {
    if (isForbidden(query.error) && options.requiredRole) {
      return { kind: 'forbidden', requiredRole: options.requiredRole }
    }
    // 例外の文言をそのまま表示しない
    return { kind: 'error', message: toUserMessage(query.error), cause: toCause(query.error), retry: () => query.refetch() }
  }
  if (query.data.length === 0) return { kind: 'empty' }
  return { kind: 'success', data: query.data }
}
```

## 5. 楽観更新

0.1秒以内に反応を返すために使います。失敗時に必ず元へ戻し、失敗した事実を伝えます。戻さない実装は禁止です。

```ts
export function useToggleDone(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: () => toggleDoneAction({ id }),
    onMutate: async () => {
      await queryClient.cancelQueries({ queryKey: taskKeys.detail(id) })
      const previous = queryClient.getQueryData(taskKeys.detail(id))
      queryClient.setQueryData(taskKeys.detail(id), (old) => ({ ...old, done: !old.done }))
      return { previous }
    },
    onError: (_e, _v, context) => {
      queryClient.setQueryData(taskKeys.detail(id), context.previous)
      toast.error('更新できませんでした。もう一度お試しください')
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: taskKeys.detail(id) }),
  })
}
```

## 6. フォーム

```tsx
// src/shared/components/molecules/Field/Field.tsx
type Props = {
  label: string
  htmlFor: string
  /** 入力欄の下に置くとキーボード表示時にも見え続ける */
  hint?: string
  error?: string
  required?: boolean
  children: (attrs: { id: string; 'aria-describedby': string | undefined; 'aria-invalid': boolean }) => React.ReactNode
}

export function Field({ label, htmlFor, hint, error, required, children }: Props) {
  const hintId = hint ? `${htmlFor}-hint` : undefined
  const errorId = error ? `${htmlFor}-error` : undefined
  const describedBy = [hintId, errorId].filter(Boolean).join(' ') || undefined

  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={htmlFor} className="text-sm font-medium text-fg">
        {label}
        {/* 必須を色だけで伝えない */}
        {required && <span className="ml-1 text-danger-text">（必須）</span>}
      </label>
      {children({ id: htmlFor, 'aria-describedby': describedBy, 'aria-invalid': !!error })}
      {hint && <p id={hintId} className="text-sm text-fg-muted">{hint}</p>}
      {error && <p id={errorId} role="alert" className="text-sm text-danger-text">{error}</p>}
    </div>
  )
}
```

未対応環境では無視されるため、属性を指定しない理由はありません。

| 用途 | type | inputMode | autoComplete | autoCapitalize | autoCorrect |
|---|---|---|---|---|---|
| メール | email | email | email | off | off |
| パスワード | password | text | current-password | off | off |
| URL | url | url | url | off | off |
| 電話番号 | tel | tel | tel | off | off |
| 数値 | text | numeric | off | off | off |
| 氏名 | text | text | name | words | off |
| 郵便番号 | text | numeric | postal-code | off | off |
| 自由記述 | textarea | text | off | sentences | on |

数値に `type="number"` を使わない理由は、スピナーの誤操作と貼り付け時の挙動差を避けるためです。検証は Zod 側で行います。

自由入力の文字列と数値には必ず上限をスキーマで定義します。利用者のデータは設計時の想定より必ず長くなり、上限のない入力は一覧とタイルの表示を壊します。文字数は `String.length` ではなく `Intl.Segmenter` の書記素単位で数えます。表示側の切り詰め（`truncate` と `title`）は防御であり、上限の代わりにはなりません。

```ts
const segmenter = new Intl.Segmenter('ja', { granularity: 'grapheme' })
const countGraphemes = (v: string) => [...segmenter.segment(v)].length

export const input = z.object({
  name: z.string().min(1).refine((v) => countGraphemes(v) <= 50, '50文字以内で入力してください'),
  amount: amountString.refine((n) => n <= 999_999_999, '999,999,999円以下で入力してください'),
})
```

日本語入力では確定前に検索や検証を走らせません。

```ts
// 確定前の入力で処理を走らせない
const onKeyDown = (e: React.KeyboardEvent) => {
  if (e.nativeEvent.isComposing) return
  if (e.key === 'Enter') submit()
}
```

賢い既定値を置きます。空欄と比べて4倍速く入力できたという報告があります。選択メニューは4回触れる操作になるため、選択肢2〜3個はラジオ、狭い範囲の数値は増減ボタン、日付は日付選択部品、選択肢が多い場合は全画面の検索付き一覧に置き換えます。

## 7. アクセシビリティの基底

```css
/* src/shared/styles/globals.css に追記 */
/* outline を消すだけの実装を防ぐため、代替の可視化を基底に置く */
:focus-visible { outline: none; box-shadow: var(--focus-ring); }

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

/* 日本語は英字より字面が大きいため、英字向けの行間では詰まって見える */
body { line-height: 1.7; }
```

本文へ飛ぶリンクはレイアウトの先頭に置きます。`sr-only` は寸法を1pxに潰すため、フォーカス時に操作対象の下限を割ります。画面外へ退避させて寸法を保つ形にします。

```tsx
{/* 画面外へ退避させつつ寸法は保ち、操作対象の下限を割らないようにする */}
<a
  href="#main"
  className="control-md absolute top-2 left-2 z-50 flex -translate-y-24 items-center rounded-3 bg-comp px-4 text-fg shadow-2 focus:translate-y-0"
>
  本文へ移動
</a>
```

読み上げのみに提示する文字列は Tailwind の `sr-only` を使います。同じことをする部品を自作しません。

```tsx
<caption className="sr-only">取引の一覧</caption>
```

## 8. テーマ切り替え

```ts
// src/shared/lib/theme.ts
export type Theme = 'system' | 'light' | 'dark'

export function applyTheme(theme: Theme) {
  const root = document.documentElement
  if (theme === 'system') root.removeAttribute('data-theme')
  else root.setAttribute('data-theme', theme)
}

export function applyHighContrast(enabled: boolean) {
  const root = document.documentElement
  if (enabled) root.setAttribute('data-contrast', 'high')
  else root.removeAttribute('data-contrast')
}
```

サーバー描画を行う場合は、初期表示のちらつきを避けるため描画前に属性を適用する処理を `head` 内に置きます。

## 9. 検証

```bash
bash ~/.claude/skills/frontend-boilerplate/scripts/verify.sh .
```

lint、型、テスト、ビルド、バンドル寸法、`ux-lint.sh`、`e2e/quality.spec.ts`（コントラスト3テーマ、視覚回帰、LCP、CLS、操作対象の寸法、最小対応幅での横スクロール）をまとめて判定します。人手でしか判定できない項目は `assets/ux-review-checklist.md` に残しています。

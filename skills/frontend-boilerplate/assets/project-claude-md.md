# プロジェクト CLAUDE.md テンプレート

生成したプロジェクトのルートに置く `CLAUDE.md` の雛形です。採用しなかったスタックの節を削り、角括弧の箇所を実際の値に置き換えます。数値は書き写さず、プロジェクトの `e2e/budgets.json` のキーで参照します。同期作業は存在しません。

以下の区切り線から下をコピーして使います。

---

# [プロジェクト名] フロントエンド

数値の基準（応答時間、寸法、コントラストなど）は `e2e/budgets.json` が単一情報源です。この文書は数値を書き写さず、そのキーで参照します。

デザインの意図（目的・ターゲット・参照物・トーン・Do's and Don'ts）は `DESIGN.md` が単一情報源です。視覚に関わる変更の前に読みます。トークンの実値は `src/shared/styles/tokens.css` にあり、`DESIGN.md` は値を持たず理由だけを持ちます。

## 技術スタック

| 領域 | 採用 |
|---|---|
| フレームワーク | [Next.js App Router / TanStack Start / TanStack Router] |
| 言語 | TypeScript（strict） |
| サーバー状態 | TanStack Query |
| 自動メモ化 | React Compiler（手動メモ化は効いていないことが実測で示された箇所のみ） |
| スキーマ | Zod |
| フォーム | React Hook Form + Zod resolver |
| スタイル | Tailwind CSS + トークン（oklch 3変数） |
| UI 部品 | shadcn/ui（重ね合わせ・選択・開閉・通知・表は自前で書かない） |
| アイコン | Lucide（1つの体系に統一する） |
| 動き | CSS の遷移。要素の出入りと並び替えが必要な画面でのみ Motion を動的 import |
| 図表 | shadcn/ui の図表部品（基盤は Recharts） |
| 単体テスト | Vitest + React Testing Library |
| E2E と品質検証 | Playwright |
| 実行環境 | Docker Compose |

## 開発コマンド

ローカルへの依存インストールとローカルビルドを行いません。

| 用途 | コマンド |
|---|---|
| 開発サーバー | `docker compose up -d` |
| ログ | `docker compose logs -f web` |
| 依存追加 | `docker compose run --rm web npm install [pkg]` |
| 検証一括 | `bash ~/.claude/skills/frontend-boilerplate/scripts/verify.sh .` |

`verify.sh` が lint、型、テスト、ビルド、バンドル寸法、UX 規約の機械検査、品質E2E をまとめて判定します。

## ディレクトリ構成

### Next.js App Router を採用した場合

```
src/
├─ app/           ルーティングと型変換のみ
├─ features/      ドメインごとの機能群
├─ shared/        共通UI・provider・トークン
└─ external/      dto, handler, service, repository, client
```

```
src/features/[domain]/
├─ components/
│  ├─ server/                          Server Components（ページテンプレート）
│  └─ client/{molecules,organisms}/[Name]/
│     ├─ [Name]Container.tsx           Hook を呼び Props を Presenter へ渡す
│     ├─ [Name]Presenter.tsx           JSX のみ。Hook 呼び出しとデータ取得を行わない
│     ├─ use[Name].ts                  データ取得・ローカル状態・イベントハンドラ
│     ├─ [Name].test.tsx
│     └─ index.ts
├─ hooks/  queries/  actions/  types/
```

依存の向き。`features` から `service` と `repository` を直接 import しません。

```
features → external/handler → external/service → external/repository / client
```

### TanStack Router / Start を採用した場合

```
src/
├─ features/[domain]/{api,server,hooks,components/{molecules,organisms}}/
├─ shared/components/{atoms,molecules,organisms,templates}/
└─ routes/[route]/{index.tsx,-components/{Page.tsx,fallbacks/}}
```

置き場所の判断は「Router 依存なら routes、ドメインに関係するなら features」です。`routes/[route]/index.tsx` に含めてよいのは `validateSearch`、`loader`、`beforeLoad`、各 component の指定のみです。ハイフンで始まるディレクトリはルートツリーから除外されます。複数ルートで共有し始めた時点で features へ移します。

依存の向きは `routes → features → shared` です。features から routes を import しません。

いずれも ESLint で機械的に強制しています。境界を越える必要が生じたら、設定を緩める前に層の切り方を見直します。

### 共通 UI の層

```
src/shared/components/{atoms,molecules,organisms,templates}/
```

| 順 | 条件 | 置き場所 |
|---|---|---|
| 1 | それ以上分解すると機能しない最小単位 | `shared/components/atoms/` |
| 2 | ドメイン語彙を含まず、複数ドメインで使える単純な組み合わせ | `shared/components/molecules/` |
| 3 | ドメイン語彙を含まず、界面の独立した区画 | `shared/components/organisms/` |
| 4 | 配置の骨格のみを持ち、実データを持たない | `shared/components/templates/` |
| 5 | ドメイン語彙を含み、単純な組み合わせ | `features/[domain]/components/molecules/` |
| 6 | ドメイン語彙を含み、界面の区画 | `features/[domain]/components/organisms/` |

atoms をドメイン側に作りません。判断に15分以上かかったら `features/[domain]/components/organisms/` に置き、共有され始めた時点で移します。

共有層の部品名は文脈と内容に依存させません（`HomepageCarousel` ではなく `Carousel`、`ProductCard` ではなく `Card`）。ドメイン層は意図的に文脈へ縛るため、ドメイン語彙を含む名前を使います。

## 命名規則

| 対象 | 規則 |
|---|---|
| Hooks | `use[対象].ts` |
| テスト | 対象と同名 + `.test.ts(x)` |
| コンポーネント | PascalCase |
| Server Actions（Next.js） | `[動詞][対象].action.ts` |
| Container / Presenter（Next.js） | `[対象]Container.tsx` / `[対象]Presenter.tsx` |
| Server Function（TanStack） | `[entity].functions.ts` / `[entity]-schema.ts` / `[動詞]-[entity].server.ts` |

## 状態管理の優先順位

URL、サーバー状態キャッシュ、ローカル state、グローバルストアの順に検討します。サーバーから取得したデータをグローバルストアへ複製しません。

## 状態網羅

正常系だけを実装した時点は未完成です。6状態すべてで完了とします。

| 状態 | 要件 |
|---|---|
| 読込中 | 押下に即時反応。レイアウトを確定させ表示後の変動を起こさない |
| 空 | 何が入る場所かと最初の一歩を示す。「データがありません」のみは不可 |
| 部分取得 | 取得できた分を表示し、失敗範囲を明示し、その範囲だけ再試行できる |
| エラー | 何が起きたか、なぜか、次に何をするかを平易な言葉で。エラーコードのみ不可。再試行を同じ場所に置く |
| 権限なし | 未認証と区別する。誰に依頼すれば使えるかを示す |
| 成功 | 完了を通知し、画面の状態にも反映する |

`shared/components/molecules/AsyncBoundary/` の判別共用体で表現します。`switch` に既定節を置きません。楽観更新は失敗時に必ず元へ戻し、失敗した事実を伝えます。

## 応答時間とパフォーマンス予算

| 対象 | 目標 |
|---|---|
| 開閉・選択・切替・並び替え | `response.directManipulationMs` 以内に反映 |
| 画面遷移・初期表示 | `response.flowMs` 以内 |
| `response.attentionMs` を超える処理 | 非同期化して進捗を表示 |
| 主要な単一作業の完了 | `response.simpleTaskSec` 以内 |
| 送信後の確認通知 | `response.notificationSec` 以内に届く |
| LCP / INP / CLS | `webVitals` の `lcpMs` / `inpMs` / `cls` 以内 |
| 初期 JavaScript | 圧縮後 `bundle.initialJsGzipKb` 以内 |

計測は対応ブラウザの実物と本番相当のビルドで行います。開発サーバーの数値は代替になりません。

## デザイントークン

トークンは `shared/styles/tokens.css` の3層（原始値、意味、部品固有）です。テーマは基準色・強調色・コントラストの3変数から導出します。

| 禁止 | 理由 |
|---|---|
| 任意値の色や寸法を直書きする | テーマ切り替えと高コントラストが効かなくなる |
| 部品固有トークンを網羅的に作る | 部品と変種の掛け算で増え管理できなくなる |
| 部品の外側に余白（`margin`）を書く | 隣接要素の配置に影響し破壊的変更になる |

共有層の色・活字・余白の変更は破壊的変更として扱います。特に、利用側の背景に載る文字色、利用側の文字が載る背景色、折り返しを引き起こす活字、部品の境界の外に出る余白です。視覚回帰テストが検出します。

## 視覚設計

外観プリセットは `data-appearance` で選びます。既定は没入型（暗色を地とし、骨格を無彩に寄せ、内容に彩度を持たせる）です。一覧20行以上か入力欄5個以上の画面は実務型にします。既定のテーマは暗色で、明色と高コントラストも同じトークンから導出します。

階調は12段で、段の用途で選びます。面は1〜5、装飾の罫線は6〜7、塗りは9〜10、文字は11〜12です。

| 用途 | 段 | 補足 |
|---|---|---|
| 画面の地 | 1 | 近黒 |
| 沈めた面・縞 | 2 | |
| 部品の面（通常・hover・押下） | 3 / 4 / 5 | |
| 装飾の区切り罫 | 6 / 7 | 12段体系はここに 3:1 を保証しない |
| 部品の識別に必要な境界 | `--edge-control` | 入力欄など。地に対して 3:1 を満たす専用段 |
| 塗り | 9 / 10 | 主要操作と現在位置のみ |
| 文字 | 11 / 12 | |

強調色は1画面に1箇所です。意味色（危険・注意・成功）から色相を30度以上離します。

活字は役に対応させます。主題は特大寸法で字間を強く詰め、付随情報は小さく淡くします。すべての見出しを同じ寸法と太さにしません。数値は `tabular-nums` で桁を揃え、単位は1段落とします。

動きは距離に比例させます。`transition-all` を使わず、対象を絞った `transition-control` と `transition-lift` を使います。hover は枠の色替えではなく寸法と影で応えます。

次を実装しません。汎用パレットの直用い、絵文字をアイコン代わりに置くこと、装飾のためのグラデーション、既定の影と角丸（トークンの段を使う）、塗りの主要操作を1画面に複数置くこと。`ux-lint.sh` が検出します。

## ポインタとキーボード

主入力はポインタとキーボードです。設計と検証は基準幅で行い、狭い幅は壊れないことだけを保証します。

| 項目 | 基準 |
|---|---|
| 基準幅 | `viewport.designPx`。分岐点は `max-*` 変種で書き、素の指定を基準幅向けとする |
| 最小対応幅 | `viewport.minSupportedPx`。この幅で横スクロールが出ない |
| レイアウト | 主題と付随情報を横に並べる。縦積みへ落とす境界は最小対応幅に合わせ、対応範囲内では1つのレイアウトを保つ |
| 折り返しの下限 | `viewport.reflowPx`。縦スクロールだけで内容と機能が失われない（WCAG 2.2 AA SC 1.4.10） |
| 操作対象の寸法 | `target.minPx` 以上（SC 2.5.8 の絶対下限と同値）。見た目は小さくてよく余白で確保する。本文中のインラインリンクは対象外 |
| 対象の間隔 | `target.gapPx` 以上 |
| 破壊的操作の位置 | 主要操作の隣に並べない |
| hover とフォーカス | 別の見た目にする。hover だけで開示しない |
| キーボード | 繰り返し使う操作に経路を用意する。`tabindex` に正の値を使わない |
| ラベル | 入力欄の上。`placeholder` をラベルの代わりに使わない |
| 補足説明 | 入力欄の下 |
| 入力属性 | 用途に合う `type` `inputMode` `autoComplete` `autoCapitalize` `autoCorrect` を指定する |
| 既定値 | 埋められる項目には既定値を入れる |
| 選択メニュー | 開く・探す・選ぶ・閉じるで4手。選択肢2〜3個はラジオ、狭い範囲の数値は増減ボタン、日付は日付選択部品 |
| 日本語入力 | 確定前（`isComposing`）に検索や検証を走らせない |

## 文章

分量は紙媒体に対して `text.maxRatioOfPrint` 以下。見出しは `text.headingLevels` の階層のみを使い、階層を飛ばさない。そこに何があるか分かる語にする。結論から書く。ボタン、エラー、空状態、確認の文言も同じ基準に従います。

## アクセシビリティ

例外を認めません。

| 項目 | 基準 |
|---|---|
| コントラスト | `contrast.text` 以上（大きい文字と UI 部品は `contrast.largeTextAndUi` 以上）。補足文字（`--fg-muted`）のみ `contrast.secondaryText` とし、視覚階層のために AA を意図的に外す |
| テーマ | 明色・暗色・高コントラストの3テーマすべてで基準を満たす |
| キーボード | すべての操作に到達でき閉じ込められない |
| フォーカス | 現在位置が常に分かる。`outline: none` の単独指定は禁止 |
| 色 | 状態・必須・エラーを色以外でも伝える |
| 画像 | 意味のある画像に代替テキスト、装飾は空の代替 |
| 見出し | 階層の順序を保つ |
| 動き | `prefers-reduced-motion` を尊重する |
| ラベル | `label` の `for` と入力欄の `id` を対応させる |

## 誠実さ

次を実装しません。実際には進んでいない進捗表示、意味のない待機演出、成功に見せて後で失敗する箇所、実際の機能より優れて見せる表現、理由のない `disabled`。

無効化には必ず理由と回復手順を添えます。`GuardedAction` を使います。

## コーディング方針

今必要ではない機能を作りません。同じコードを繰り返しません。シンプルに保ちます。`any` を使わず、外部由来は `unknown` で受けて Zod で parse します。コメントは WHY が非自明な場合にのみ書きます。特定環境にだけ言及するコメントは書きません。

### React

データ取得に `useEffect` を書きません。サーバー状態は TanStack Query で扱います。`useEffect` は外部システムとの同期（購読、タイマー、生の DOM API）のみに使い、エフェクトが参照する値はすべて依存配列に入れます。Lint の警告に従い、手で間引きません。購読やタイマーを開始したエフェクトはクリーンアップ関数を返します。

手動メモ化（`useMemo`、`useCallback`、`memo`）を既定で書きません。React Compiler に委ね、効いていないことが実測で示された箇所のみ書きます。ref は通常の prop として受け渡し、転送専用のラッパー API を使いません。

### TypeScript

型の絞り込みは Narrowing と parse で行います。`as` による型アサーションは実行時の検証を伴わないため最後の手段とし、使う場合は根拠をコメントに残します。型を広げずに適合だけを検査したい場合は `satisfies` を使います。排他的な状態は boolean の組み合わせではなく、判別子を持つ Union でモデリングします。

## 実装完了の条件

`verify.sh` が通り、対応ブラウザで確認し、機械判定できない項目のチェック表を通した状態を完了とします。未達がある状態で完了と報告しません。別課題にする場合も未達である事実を明記します。

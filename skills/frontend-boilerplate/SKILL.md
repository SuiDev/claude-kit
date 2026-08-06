---
name: frontend-boilerplate
description: "フロントエンドの新規作成・拡張を、スタック選定（Next.js App Router / TanStack）、Atomic Design、import境界Lint、デザイントークン、状態網羅、アクセシビリティ、Docker開発環境、機械検証まで規約付きで一括実行する。Triggers: アプリ・画面・管理画面・SPAの作成依頼, boilerplate, scaffold, ディレクトリ構成, UI/UX設計, デザインシステム, デザイントークン, Atomic Design, コンポーネント設計, アクセシビリティ対応, /frontend-boilerplate。起動しない場面: 仕様の質問のみ、既存コードの読解のみ、バックエンドのみの作業。"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, WebFetch, WebSearch
---

# frontend-boilerplate

フロントエンドの新規作成と拡張を、規約と機械検証つきで人の確認なしに完走させるスキルです。

---

## 自律実行の原則

停止して確認を取るのは次の3条件だけです。それ以外は既定値を選んで進み、選んだ内容を最後に報告します。

| 停止する条件 | 例 |
|---|---|
| 破壊的操作 | 既存ファイルの削除、既存ディレクトリの上書き、本番環境への操作 |
| 事実が確認できない | 公式手順が取得できない、パッケージのバージョンが確認できない |
| 既定値が定義されていない二者択一が残る | 下の既定値表に該当がなく、選択で成果物が大きく変わる |

### 既定値表

曖昧さはここで解決します。確認を取らずに適用します。

| 曖昧さ | 既定値 |
|---|---|
| スタック未指定 | `references/stack-and-conventions.md` の判定表。迷ったら Next.js App Router |
| ドメイン名が要件から読み取れない | ドメインを作らず空の `features/` を残す。推測で作らない |
| 主入力 | 机上ブラウザ（ポインタとキーボード）。基準幅と最小対応幅は `budgets.json` の `viewport`。分岐点は `max-*` 変種で書く。携帯端末が主要経路だと要件に明記された場合のみ切り替える |
| 外観プリセット | 没入型（暗色を地とし骨格を無彩に寄せる）。一覧20行以上か入力欄5個以上なら実務型。判断は `references/visual-craft.md` 第12節 |
| 様式が未指定 | `references/visual-styles.md` 第3節の組み合わせの型から、目的とターゲットに合うものを選ぶ。判断できない場合のみミニマル × Bento |
| 対象が消費者向け（認証なしで使える画面がある、または対象が一般の生活者） | `visual-styles.md` 第3-2節の消費者向けの既定を適用する。明色を地とし、骨格にわずかな彩度、角丸は大きめ、影を積極的に使い、アイコンと挿絵を置く。第4-7節の写像を出発点にする |
| 部品ライブラリ | shadcn/ui。重ね合わせ・選択・開閉・通知・表は自前で書かず生成する |
| アイコン | Lucide。1つの体系に統一し、複数を混ぜない |
| 動き | CSS の遷移で足りるものは CSS。要素の出入りと並び替えが必要な画面でのみ Motion を動的 import する |
| トーンが未指定 | 採用はモダン・クリーンの2語、回避は安っぽい・ごちゃごちゃしている の2語を既定とし、要件から読み取れる語で置き換える |
| 目的が複数あって順位が読み取れない | 最初に書かれたものを主とする。推測で並べ替えない |
| テーマ | 業務用は暗色、消費者向けは明色を初期値とする。いずれの場合も3種すべてを生成し、3種すべてで基準を満たす |
| 密度 | 一覧・表・管理画面は compact、読み物は expressive、それ以外は既定 |
| 言語 | 日本語。`lang="ja"`、`Intl` は `ja-JP` |
| 部品をどの層に置くか判断できない | `features/[domain]/components/organisms/`。共有され始めた時点で移す |
| Tailwind の設定方式 | Phase 2 で確認した版に対応する方式。判別できないときは CSS 主体を試し、失敗したら設定ファイル方式 |
| import 境界の実装方式 | `no-restricted-imports` のみ（追加プラグイン不要） |
| React Compiler | 新規作成では有効化する。既存拡張では既存設定に従い、未導入でも勝手に入れない。有効化手順は Phase 2 で公式ドキュメントを確認する |
| 生成に使う Node のイメージ | 現行 LTS の alpine（生成コマンドの実行にのみ使う） |
| 実行と検証に使うイメージ | Playwright 公式イメージ。Alpine は Playwright を公式サポートせず、検証を同一サービスで完結できないため |
| ポート | 3000。使用中なら 3001 以降 |
| 既存の `CLAUDE.md` がある | 上書きせず節として追記する |
| 既存の `DESIGN.md` がある | 上書きせず読んで従う。変更は差分を報告してから行う |
| 既存の compose ファイルがある | 上書きせず追記案を提示する |
| 対応ブラウザで確認できない | 未実施として報告する。自動検証が通ったことを人手確認の代替として書かない |
| 検証に未達がある | 完了と報告しない。未達を明記して別課題にする |
| 指針が対立する | `references/ux-principles.md` 第10節の分け方に従う |
| 数値を変えたい | プロジェクトの `e2e/budgets.json` のみを編集する。ドキュメントに数値を散らさない |

### 自己修復ループ

`scripts/verify.sh` が失敗したら、同一原因への修正を最大3回まで自分で試します。再実行は落ちたステップだけを `--only <step>`（lint / typecheck / test / build / bundle / ux-lint / e2e。カンマ区切りで複数可）で行い、すべて解消した後に引数なしのフルスイートを1回通して完了とします。`--only` の合格を完了の根拠にしません。3回で解決しないものは未達として原因と次の対処案を報告します。

方針そのものを変える判断（別スタックへの切り替え、規約を緩める、基準値を下げる）は自己修復に含めません。必ず停止して報告します。

---

## 最優先ルール

1. 素の HTML で書き始めません。`index.html` に script タグ直書き、CDN から React を読み込む構成は採用しません。フレームワーク名が明示されていなくても判定表で必ず決めます。
2. Create React App と、新規での Next.js Pages Router は採用しません。
3. ローカルへの依存インストールとローカルビルドを行いません。すべて Docker で実行します。`npm view` のようなインストールを伴わない参照コマンドはローカル実行してよいものとします。
4. バージョンをこのスキル内の記載値で決め打ちしません。Phase 2 で確認します。
5. `references/` と `assets/` は Read してから使います。記憶で再現しません。
6. 正常系だけを実装した時点は未完成です。6状態とアクセシビリティを満たして完了とします。
7. 無効化を最後の手段とします。まず押せるままにして押された時点で不足を示す形を検討します。無効化する場合のみ理由を添え、置き場所は `assets/ui-baseline.md` 第3-2節の表で選びます。操作できるボタンの下に説明文を常時表示しません。
8. 重ね合わせ・選択・開閉・通知・表を自前で実装しません。部品ライブラリから生成します。境界は `references/ui-libraries.md` 第1節です。
9. アイコン体系を必ず入れます。図のない画面は情報量が同じでも未完成に見えます。
10. 数値はプロジェクトの `e2e/budgets.json` が単一情報源です。`assets/budgets.json` は初期配置の雛形で、配置後は参照しません。他のファイルに数値を書き足しません。

例外はユーザーが明示的に別のスタックや別構成を指定した場合のみです。

---

## Phase 1: モード判定と読み込み

```bash
ls -1 package.json next.config.* vite.config.* app.config.* 2>/dev/null
test -d src/app && echo next-app-router
test -d src/routes && echo tanstack-router
test -d src/shared/components/atoms && echo atomic-dirs
```

| モード | 条件 | 実行する Phase |
|---|---|---|
| A. 新規作成 | プロジェクトがない、または空 | 2 から 7 のすべて |
| B. 既存拡張 | フロントのコードベースがある | 3、6、7（既存構成に合わせる。差分は報告のみでリファクタリングしない） |
| C. 規約整備のみ | 構成文書だけが欲しい | 3、6-5 |

読み込むファイルは変更規模で決めます。過剰に読みません。

| 規模 | 読むファイル |
|---|---|
| 部品1つの追加・修正 | `design-system.md` 第2節（層の判断）、`ux-implementation.md` 第2節（状態網羅）、`visual-craft.md`、`assets/ui-baseline.md` |
| 画面1つ | 上記 + 該当スタックの参照ファイル + `ux-implementation.md` 全体 + `visual-styles.md` + `ui-libraries.md` |
| ドメイン1つ、または新規作成 | 上記 + `stack-and-conventions.md` + `ux-principles.md` + `design-system.md` 全体 |
| 既存界面の整理から始める | 上記 + `assets/interface-inventory.md` |

## Phase 2: スタック選定とバージョン確認

`references/stack-and-conventions.md` を読み、判定表でスタックを決めます。選定結果と理由を1行で記録します。対応する参照ファイル（`nextjs-app-router.md` または `tanstack-router.md`）を読みます。

バージョン確認はスタック決定後に、採用したスタックの分だけを並列で行います。両スタック分を直列で確認しません。

```bash
# STACK_PKG は Next.js なら "next"、TanStack Router なら "@tanstack/react-router"、Start なら "@tanstack/react-start"
for p in react @tanstack/react-query zod tailwindcss vitest @playwright/test $STACK_PKG; do
  (echo "$p: $(npm view "$p" version)") &
done
wait
```

@playwright/test の版が判明したら、時間のかかるイメージ取得をこの時点でバックグラウンドで開始します。以降のフェーズと並行して落ちるため、初回実行の待ち時間が隠れます。

```bash
docker pull node:lts-alpine >/dev/null 2>&1 &
docker pull "mcr.microsoft.com/playwright:v<確認した版>-noble" >/dev/null 2>&1 &
```

新規作成時は公式手順を WebFetch で確認します。Next.js は https://nextjs.org/docs/app/getting-started/installation 、TanStack は https://tanstack.com/start/latest/docs/framework/react/quick-start です。React Compiler の有効化手順も採用スタックの公式ドキュメントで確認します（入口は https://react.dev/learn/react-compiler ）。取得できない場合のみ停止します。

## Phase 3: UX 方針の確定

`references/ux-principles.md`、`references/ux-implementation.md`、`references/design-system.md`、`references/visual-craft.md`、`references/visual-styles.md` を Phase 1 の表に従って読みます。視覚設計の判断を省くと、要素の視覚重量が均一になり階層が消えます。様式の判断を省くと、案件が違っても同じ既定値に落ちて無個性になります。

問題を1〜2文で書きます。設計案件が長引く最大の理由は問題が不明確なことです。

```
これは本当に解くべき問題か。やらなかったら何が起きるか。誰がこの問題を定義したか。
```

ストレス下で使われるかを判定します。障害対応・決済・削除確認・締切直前の入力なら、装飾を削り正しい操作を最も目立たせます。通常または肯定的なら、余白・活字・動きの質を機能への寄与として投資します。

プロジェクトに `DESIGN.md` が既にある場合は、まずそれを読み、記録された方針に従います。方針の再発明をしません。変更が必要な場合は差分を報告してから更新します。

`visual-styles.md` 第2節に従って、目的・ターゲット・トーン・様式の4つを言語化します。1つでも空欄にすると既定値の組み合わせに落ちます。トーンは採用する印象と避けたい印象の両方を書き、実在する様式・物・場面から参照物を1つ添えます。形容詞は方向の範囲しか指せず、具体的な参照物が値の背後の理由まで運びます。避けたい印象がないと、方向は合っていても行き過ぎたものができます。

「いい感じに」「おしゃれに」「今っぽく」だけが指定として渡された場合は、この4つのいずれも指定されていない状態です。既定値表と `visual-styles.md` の判定表から埋めて着手し、埋めた内容を報告します。

方針を記録して次へ進みます。承認は取りません。

```
[ux-plan] 問題: (1〜2文) / 利用状況: ストレス下 or 通常 / 主入力: 机上ブラウザ（既定）or 携帯端末
目的: (1つ。複数なら順位) / ターゲット: (年齢層・習熟度・利用場面・困りごと)
トーン: 採用(2〜3語) / 回避(1〜3語) / 参照物: (実在する様式・物・場面を1つ)
様式: (visual-styles.md 第3節から1〜3個) / トークンへの写像: (第4節のどれに準じたか)
状態網羅の対象: (画面と部品の一覧) / テーマ: 明色・暗色・高コントラスト
外観: 没入型 or 実務型 / 密度: 既定 or compact or expressive / 強調色の色相: (数値)
```

## Phase 4: プロジェクト生成

Docker 内で実行します。生成時に依存をインストールしません。bind mount へ書かれた `node_modules` は、compose の名前付きボリュームと二重実体になり、容量とファイル監視の無駄になるためです。依存は Phase 6 で compose 経由でインストールします。

```bash
docker run --rm -it -v "$PWD":/work -w /work node:lts-alpine \
  npx --yes create-next-app@latest <app-name> \
  --ts --app --src-dir --eslint --tailwind --import-alias "@/*" --use-npm --skip-install
```

TanStack は Phase 2 で確認した公式コマンドを使い、同様に依存インストールを省く指定を付けます。生成物が root 所有になる場合は `--user "$(id -u):$(id -g)"` を付けて再実行します。

生成後に `node_modules` がホスト側に残っている場合は削除します。

```bash
rm -rf <app-root>/node_modules
```

`.gitignore` を確認し、なければ作成します。`node_modules`、`.next`、`dist`、`test-results`、`.verify.log`、`playwright-report` を無視し、視覚回帰の基準画像（`e2e/*-snapshots/`）は無視しません。基準画像は差分検出の基準として残す必要があるためです。

## Phase 5: 骨格の作成

```bash
bash ~/.claude/skills/frontend-boilerplate/scripts/scaffold.sh nextjs <app-root> <domain...>
bash ~/.claude/skills/frontend-boilerplate/scripts/scaffold.sh tanstack <app-root> <domain...>
```

`shared/components/` は atoms / molecules / organisms / templates に分割されます。層の判断は `references/design-system.md` 第2節です。

## Phase 6: 規約と検証基盤の配置

時間のかかる処理を先に開始します。最初に 6-4 の compose 配置と `npm install` のバックグラウンド開始を行い、依存を使わない 6-1 と 6-2 のファイル作業をインストールと並行して進めます。6-1 の違反確認 lint と 6-3 の部品生成は、インストールの完了を待ってから実行します。

### 6-1. import 境界と Hooks の静的検査

`assets/eslint-boundaries.md` を読み、既定方式を `eslint.config.mjs` に反映します。Hooks の静的検査（eslint-plugin-react-hooks）も同じ設定に含めます。フレームワークの公式 ESLint 設定に同等の検査が含まれる場合は二重に追加しません。

意図的に違反する import と、依存配列に入れ忘れのある `useEffect` を書いてエラーと警告が出ることを確認し、確認後に削除します。設定したつもりで効いていない状態を防ぐための必須手順です。この確認の lint 実行は `npm install` の完了後に行います。

### 6-2. トークンと UI 基底

`assets/ui-baseline.md` を読み、次を配置します。

| 配置物 | 置き場所 |
|---|---|
| トークン定義 | `assets/tokens.css` を `src/shared/styles/tokens.css` へコピーする。中身を書き直さない |
| Tailwind への接続 | `src/shared/styles/globals.css` |
| クラス結合 | `src/shared/lib/cn.ts` |
| テーマ切り替え | `src/shared/lib/theme.ts` |
| 状態網羅 | `src/shared/components/molecules/AsyncBoundary/` |
| 無効化の理由表示 | `src/shared/components/molecules/GuardedAction/`。部品内で閉じる場合は `aria-disabled` と理由要素と `aria-describedby` の3点を直接書いてよい |
| フォーム項目 | `src/shared/components/molecules/Field/` |
| アクセシビリティ基底 | `globals.css` に追記、本文へ飛ぶリンクをレイアウト先頭に置く。読み上げ専用の文字列は Tailwind の `sr-only` を使い、同等の部品を自作しない |

Tailwind の `@theme inline` では参照元と定義先で名前を変えます。同名にすると自己参照になり動きません。

### 6-3. 部品ライブラリとアイコン

`references/ui-libraries.md` を読み、第6節の順序で導入します。トークンを配置し、生成物が期待する変数名への別名を与えてから初期化します。順序を逆にすると、生成物の色指定を書き換える作業が発生します。

その画面で使う部品だけを生成します。使わない部品を先回りで置きません。アイコンライブラリは必ず入れます。

重ね合わせ・選択・開閉・通知・表を自前で実装しません。生成物の振る舞いには触れず、見た目の調整は variant の追加で行います。

### 6-4. 検証基盤

compose のイメージタグは固定値で書きません。`npm view @playwright/test version` で確認した版に合わせます。ずれると検証時にブラウザの版が合わず落ちます。

```bash
S=~/.claude/skills/frontend-boilerplate
cp "$S/assets/docker-compose.yaml" <app-root>/docker-compose.yaml
# 確認した版へタグを合わせる
npm view @playwright/test version
mkdir -p <app-root>/e2e
cp "$S/assets/e2e-quality.spec.ts" <app-root>/e2e/quality.spec.ts
cp "$S/assets/budgets.json" <app-root>/e2e/budgets.json
```

配置後は `e2e/budgets.json` が数値の単一情報源です。数値を変えるときはこのファイルを直接編集します。`assets/budgets.json` は初期配置の雛形で、以後は参照しません。`verify.sh` もプロジェクト側を読みます。

依存のインストールは Phase 6 の冒頭でバックグラウンド開始しています（未開始ならここで開始します）。名前付きボリュームへ入るため、ホスト側に `node_modules` は現れません。

```bash
cd <app-root> && docker compose run --rm web npm install
```

TanStack Router（SPA）を採用した場合は、compose の `web-prod` サービスの command を `npx vite preview --host --port 3000` に変えます。品質E2Eはこの本番相当サービスに対して計測されます。

### 6-5. プロジェクト規約

`assets/project-claude-md.md` を読み、採用しなかったスタックの節を削って `CLAUDE.md` として配置します。

続けて、Phase 3 で確定した方針をプロジェクトルートに `DESIGN.md` として保存します。チャットに流れた方針は次のセッションに残らないため、デザインの意図はこのファイルを単一情報源にします。構成は次の順です。

1. 概要: 目的・ターゲット・参照物・トーンを散文で書く。参照物を中心に据える
2. 色・活字・レイアウト: 判断の理由を散文で書く。値は書き写さず `tokens.css` の変数名と `e2e/budgets.json` のキーで参照する
3. Do's and Don'ts: 参照物から導いた「やらないこと」を2〜5個。回避トーンに対応する具体的な禁止を書く

既存の `DESIGN.md` がある場合は上書きせず、差分を報告してから更新します。以後の拡張では視覚の判断の前に必ずこのファイルを読みます。

### 6-6. サンプル実装

ドメインを作った場合のみ、参照ファイルのコード例に沿って Container、Presenter、Hook、queryOptions の最小実装を置きます。6状態をすべて実装します。正常系だけのサンプルを置きません。ドメインを作っていない場合は置きません。

## Phase 7: 検証と報告

```bash
docker compose up -d
bash ~/.claude/skills/frontend-boilerplate/scripts/verify.sh .
```

`verify.sh` が lint、型、テスト、ビルド、バンドル寸法、UX 規約の機械検査、品質E2E（3テーマのコントラスト、視覚回帰、LCP、CLS、操作対象の寸法、最小対応幅での横スクロール）をまとめて判定し、各ステップの所要時間を表示します。品質E2Eは `web-prod`（本番相当ビルド）を自動起動して計測します。失敗したら自己修復ループに入ります。

視覚回帰は初回実行で基準画像を作ります。以降は共有部品の色・活字・余白の変更を検出します。

`verify.sh` が通ったら `assets/ux-review-checklist.md` の人手項目を実行します。対応ブラウザで確認できない場合は未実施として報告します。

### 報告形式

```
[frontend-boilerplate]
モード: A(新規) / スタック: Next.js App Router（理由: 公開ページのSEOが要件のため。判定1）
バージョン: next 16.2.x / react 19.x / @tanstack/react-query 5.x / tailwindcss 4.x
構成: src/{app,features,shared,external} / shared/components: atoms・molecules・organisms・templates
ドメイン: requests
既定値の適用: import境界は no-restricted-imports / テーマ3種 / ポート3000

verify.sh
  lint PASS / typecheck PASS / test PASS / build PASS
  bundle PASS (118KB / 150KB) / ux-lint PASS / e2e(quality) PASS

ux-review（人手）
  A 6/6  B 4/4  C 11/11  D 13/14  E 8/8  F 6/6  G 4/4  H 5/5  J 19/19  K 10/11  L 12/12  I 5/5

未達
- D: 一覧の操作列が hover でしか出ない。常時表示へ変える（別課題）

未実施
- 文字200%拡大の確認（対応ブラウザを1種しか用意できていない）
```

未達と未実施がある状態で完了と報告しません。

---

## エラーハンドリング

| 状況 | 対処 |
|---|---|
| Docker が起動していない | ユーザーに起動を依頼する。ローカル install へ切り替えない |
| 公式作成コマンドが失敗する | エラー全文と、Phase 2 で確認した公式手順との差分を報告してから次案を出す |
| 生成物が root 所有になる | `--user "$(id -u):$(id -g)"` を付けて再実行する |
| ホットリロードが効かない | compose の polling を有効化し、Vite 系は `--host 0.0.0.0` を確認する |
| 既存構成が推奨と異なる | 既存構成を優先する。差分は報告のみ |
| 層の判断に15分以上かかる | `features/[domain]/components/organisms/` に置く |
| Tailwind の設定方式が判別できない | CSS 主体を試し、失敗したら設定ファイル方式へ。推測で書かない |
| `@theme inline` が効かない | 参照元と定義先が同名になっていないか確認する |
| コントラストが基準を下回る | `tokens.css` の明度を調整して再測定する。基準を下げない |
| 視覚回帰が意図した変更で落ちる | 変更が破壊的変更の分類に該当するか判定し、該当するなら影響範囲を報告してから基準画像を更新する |
| ESLint プラグインが flat config で動かない | 既定の `no-restricted-imports` 方式に戻す |
| 最小対応幅で横スクロールが出る | 幅を固定している箇所を探す。最小対応幅を下げて基準を回避しない |
| 対応ブラウザで確認できない | 未実施として報告する |
| web-prod が起動しない | `docker compose --profile verify logs web-prod` を確認する。dev サーバーで実行された E2E の性能値は参考値として報告する |

---

## 制約

- スタック選定理由と UX 方針を必ず言語化します。理由なしに構成を決めません。
- ディレクトリを作るだけで終わらせず、import 境界の Lint とトークンと検証基盤まで入れて完了とします。配置ルールは機械的に強制されなければ守られません。
- 使わないディレクトリ、variant、トークンを先回りで作りません。「必要になるかもしれない」は過剰設計です。
- 画面に要素を足す提案には、何を減らすかを併記します。
- 進捗の偽装、無意味な待機演出、成功に見せて後で失敗する実装を作りません。
- 汎用パレット（`gray-*` `slate-*` `bg-white`）を直接使いません。段の用途で選びます。
- 絵文字をアイコン代わりに置きません。`transition-all` を使いません。装飾のためのグラデーションを使いません。
- 塗りの主要操作は1画面に1つです。副は枠のみ、三次は文字のみにします。
- 分岐点は `max-*` 変種で書きます。素の指定を基準幅向けとし、狭い幅を上書きとして足します。
- 数値を含む一覧と表では桁を揃えます。
- データ取得に `useEffect` を書きません。サーバー状態は TanStack Query で扱います。`useEffect` は外部システムとの同期のみに使い、依存配列は Lint の警告に従います。
- 手動メモ化（`useMemo`、`useCallback`、`memo`）を既定で書きません。React Compiler に委ね、効いていないことが実測で示された箇所のみ書きます。
- ref は通常の prop として受け渡します。転送専用のラッパー API を使いません。
- `as` による型アサーションを最後の手段とします。Narrowing と parse で絞り込み、排他的な状態は判別子を持つ Union でモデリングします。
- 動きは、何を伝えるか（階層・フィードバック・状態遷移・物語）を1文で言語化できる場合にのみ入れます。言語化できない動きは装飾であり、入れません。
- 生のスクロールイベントで状態を毎フレーム更新しません。IntersectionObserver、CSS のスクロール連動、または採用したライブラリの購読機構を使います。
- `visual-craft.md` 第10-2節の定型癖（全区画への小ラベル、等幅3カラムのカード列、左右交互の3連続、偽スクリーンショット、装飾ドット、スクロール促し）を既定として出しません。
- 生成するドキュメントとコメントはですます調で書き、太字表現を使いません。
- コメントは WHY が非自明な箇所にのみ書きます。

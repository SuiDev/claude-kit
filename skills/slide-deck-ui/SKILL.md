---
name: slide-deck-ui
description: "没入型UI規約（oklch 12段トークン・骨格無彩+強調1色・生成AI定型癖の排除）に準拠した登壇スライドをHTMLとPDFで生成する。規約は同梱referencesで自己完結し、frontend-boilerplateスキルがある環境では最新規約を優先参照する。挿絵SVGはCodexへ自動発注（不在時は自前描画）し、Docker上のChromium+CJKフォントで印刷欠落なくPDF化して代表ページを目視検証する。Triggers on: 'スライド作成', 'スライド作って', '登壇資料', 'プレゼン資料', '発表資料', 'slide deck', 'スライドをPDFで', 'LT資料'."
allowed-tools: Read, Write, Edit, Bash, Glob, WebSearch, WebFetch, AskUserQuestion, Agent
---

# slide-deck-ui - UI規約準拠のスライドデッキ生成

同梱のデザイン規約（oklch 12段トークンと没入型規範）に沿った登壇スライドを、HTML（インタラクティブ版）とPDF（16:9・1スライド1ページ）で生成するスキルです。

---

## 原則

1. デザイン規約は references/design-rules.md（本スキル同梱）を毎回Readしてから設計します。記憶で再現しません。frontend-boilerplateスキルが存在する環境（~/.claude/skills/frontend-boilerplate/ がある場合）では、references/visual-craft.md と references/visual-styles.md も追加でReadし、記述が矛盾する場合はそちらを優先します。無い環境では同梱版のみで続行します。
2. 題材が知識カットオフ以降の情報、または変化の速い技術情報の場合、WebSearchとWebFetchで事実確認をしてから構成します。出典はまとめスライドに記載します。
3. PDF変換と検証はDockerコンテナで実行します。ローカルへの依存インストールを行いません。ローカルChromeのheadless実行はサンドボックスと競合してハングする実績があるため試みません。
4. 既定の出力先は ~/Desktop です。ユーザーがパスを指定した場合はそちらを優先します。同名ファイルが既にある場合は上書きせず確認を取ります。
5. スライド文言はですます調を基本とし、体言止めの短句は見出しとラベルに限って使います。マークダウンの太字表現を使いません（CSSのfont-weightによる階層表現は使います）。
6. PPTXは生成しません。求められた場合は「画像貼付ベースになり編集できない」ことを伝えてから判断を仰ぎます。

---

## Phase 1: 入力整理と方針記録

ユーザーの依頼から次を確定します。不足があればAskUserQuestionで確認します。

- テーマ（何のスライドか、元ネタの文書やURLがあるか）
- 枚数（未指定なら内容量から12〜24枚で決定し、決定値を報告する）
- 聴衆（習熟度と利用場面。トーンと密度の判断材料）

確定後、visual-styles.md 第2節の様式で方針を記録します。

```
[ux-plan] 目的 / ターゲット / トーン(採用・回避・参照物) / 様式 / 外観(没入型が既定) / 強調色の色相(数値)
```

強調色の色相は題材のブランドカラーから選び、意味色（危険25・注意78・成功152）から30度以上離します。

## Phase 2: 事実収集

原則2に該当する題材はWebSearchで最新情報を収集します。数値・API名・日付は原典（公式ドキュメント）をWebFetchで確認します。

## Phase 3: 規約読込と構成設計

原則1の規約ファイルをReadし、次の要点を今回の設計に適用します。

- 骨格は無彩12段、強調色は1色。彩度は内容（挿絵・コード・主役数値）だけが持ちます
- 枠線より面の明度差（段1の地 / 段2の器 / 段3の主役）で階層を作ります
- 定型癖の禁止: 全区画への英大文字小ラベル、等幅3カラムのカード列、同型骨格の3連続、装飾グラデーション、絵文字アイコン
- 同一骨格は1デッキ最大2回。assets/deck-template.html の骨格カタログ（タイトル / Bento 1+2 / 扉 / 本文+挿絵 / コード / 横断バンド / 対比2面 / 表 / KPI主従 / CSS図版）から割り当てます
- 主役の特大化: KPIは1つだけ特大、表紙は題名だけ特大

20枚規模の標準構成: 表紙1 / アジェンダ1 / 扉3〜4 / 本文10〜12 / 表1〜2 / まとめ1。

## Phase 4: 挿絵の発注（並行実行）

Codexプラグインが使える場合、Agentツール（subagent_type: codex:codex-rescue）でSVGイラストをバックグラウンド発注し、Phase 5と並行させます。発注文には次の共通仕様を必ず含めます。

```
- viewBox="0 0 480 360" 固定。width / height属性は付けない
- 背景は透明。ダーク地（--bg相当の近黒）で映える配色
- パレットは[ux-plan]の強調色系4〜6色に限定（HEXで明示する）
- フラットな幾何学的テックイラスト。丸みのある形状、太めのストローク。子供っぽくしない
- text要素は原則禁止（1〜2文字の記号表現は可）
- image・外部フォント・script禁止。自己完結SVGのみ
- id を使う場合はファイル毎に一意のプレフィックス（1つのHTMLへインライン展開されるため）
- 完了前に全ファイルの存在とxmllintでの妥当性を自己検証して報告する
```

枚数の目安は表紙用1枚+セクションごと1枚です。発注先が無い、またはタイムアウト・不正SVGの場合は、同じ共通仕様で自前のSVG描画にフォールバックします（単純な図形の組み合わせに抑えます）。

## Phase 5: HTML生成

1. assets/deck-template.html をReadし、骨格カタログを使って本番HTMLを組み立てます。出力はスクラッチパッド（作業用一時ディレクトリ）に置きます
2. トークンの --hue-accent を[ux-plan]の色相に差し替えます
3. 挿絵の位置には仮マーカー（SVG名のHTMLコメント）を置き、挿絵が揃ったらpython3（標準ライブラリのみ）でインライン展開します。XML宣言は除去します
4. 完成したHTMLを出力先へコピーし、openで開いて確認します

## Phase 6: PDF変換

1. chrome-cjkイメージが無ければ assets/chrome-cjk.Dockerfile からビルドします

```bash
docker image inspect chrome-cjk >/dev/null 2>&1 || \
  docker build -q -t chrome-cjk -f ~/.claude/skills/slide-deck-ui/assets/chrome-cjk.Dockerfile ~/.claude/skills/slide-deck-ui/assets
```

2. 印刷用HTMLへ変換します。Chromiumの印刷経路はメディアクエリを狭い幅で評価して挿絵を非表示にし、インラインSVGを落とすことがあるため、この変換を省略しません

```bash
python3 ~/.claude/skills/slide-deck-ui/scripts/build_print_html.py 作業dir/deck.html 作業dir/deck-print.html
```

3. コンテナでPDF化します

```bash
docker run --rm -v "作業dir":/work chrome-cjk \
  --headless --no-sandbox --disable-gpu --hide-scrollbars \
  --no-pdf-header-footer --virtual-time-budget=20000 \
  --window-size=1920,1080 \
  --print-to-pdf=/work/deck.pdf file:///work/deck-print.html
```

## Phase 7: 検証

1. 代表ページ（表紙・挿絵入り本文・Bento・まとめの4枚以上）をPNG化します

```bash
docker run --rm -v "作業dir":/work -v ~/.claude/skills/slide-deck-ui/scripts:/skill:ro \
  python:3.12-slim bash -c \
  "pip install -q pypdfium2 pillow 2>/dev/null; python /skill/render_checks.py /work/deck.pdf /work 1 4 2 20"
```

2. 出力されたPNGをReadで目視し、次を確認します
   - ページ数が計画枚数と一致している
   - 挿絵がすべて描画されている（印刷経路での欠落が無い）
   - 器の面が地に溶けていない（扉と同じ地色のスライドに段2の器を置いていないか）
   - テキストのはみ出し・改行崩れが無い
3. 問題があれば修正して Phase 6 からやり直します。合格したPDFを出力先へコピーします

## Phase 8: 報告

```
[slide-deck-ui]
成果物: {HTMLパス} / {PDFパス}（{N}ページ）
[ux-plan]: {Phase 1の記録}
挿絵: Codex {n}枚 / フォールバック {n}枚
検証: ページ数一致 / 挿絵描画 / 階層 / はみ出し → 各OKまたは修正内容
出典: {Phase 2で使った情報源}
```

---

## エラーハンドリング

- Dockerデーモンが起動していない: ユーザーに起動を依頼します。ローカル実行へ切り替えません
- 印刷したPDFで挿絵が消える: build_print_html.py を通したか確認します。通していても消える場合はメディアクエリの残存とSVGのインライン残りを疑います
- Codex発注がタイムアウトまたは不正SVGを返す: 自前SVG描画へフォールバックし、報告に明記します
- references/design-rules.md が読めない: 停止して報告します。規約なしの生成を行いません
- 出力先に同名ファイルがある: 上書きせず、別名か上書きかをユーザーに確認します

## 制約・注意事項

- Mermaidや外部JSライブラリを使いません。CDNはGoogle Fontsのみ許可します
- 1画面あたりの骨格側の強調色は最大2箇所です
- スライド内スクロールを作りません。密度が超過したら分割します
- 検証PNGの目視を省略して完了報告をしません

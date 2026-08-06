#!/usr/bin/env bash
# UX 規約のうち文字列検査で判定できるものを機械的に検出する。
# 人手の判断が必要な項目は assets/ux-review-checklist.md に残している。
set -uo pipefail

ROOT="${1:-.}"
SRC="$ROOT/src"
FAIL=0
WARN=0

if [ ! -d "$SRC" ]; then
  echo "error: src not found under $ROOT" >&2
  exit 1
fi

CODE=$(find "$SRC" -type f \( -name '*.tsx' -o -name '*.ts' \) ! -name '*.test.*' 2>/dev/null)
CSS=$(find "$SRC" -type f -name '*.css' 2>/dev/null)

report() {
  local level="$1" id="$2" desc="$3" hits="$4"
  if [ -z "$hits" ]; then
    printf 'PASS %-6s %s\n' "$id" "$desc"
    return
  fi
  if [ "$level" = "fail" ]; then FAIL=$((FAIL + 1)); else WARN=$((WARN + 1)); fi
  printf '%s %-6s %s\n' "$(echo "$level" | tr '[:lower:]' '[:upper:]')" "$id" "$desc"
  echo "$hits" | sed 's|^|       |' | head -8
  local n
  n=$(echo "$hits" | wc -l | tr -d ' ')
  [ "$n" -gt 8 ] && echo "       ... 他 $((n - 8)) 件"
}

# 対象ファイルが空でも grep が全体を走査しないように守る
grep_code() {
  [ -z "$CODE" ] && return 0
  echo "$CODE" | tr '\n' '\0' | xargs -0 grep -nE "$1" 2>/dev/null
}

files_with() {
  [ -z "$CODE" ] && return 0
  echo "$CODE" | tr '\n' '\0' | xargs -0 grep -lE "$1" 2>/dev/null
}

echo "=== ux-lint: $ROOT ==="

# --- トークン迂回 ---
report fail UX01 "任意値の色の直書き（トークンを迂回するとテーマ切り替えが効かない）" \
  "$(grep_code '(text|bg|border|fill|stroke|from|to|via)-\[#|(text|bg|border)-\[(rgb|hsl|oklch)\(')"

report warn UX02 "任意値の寸法の直書き（繰り返すならトークン化する）" \
  "$(grep_code '\-\[[0-9]+(px|rem)\]')"

# --- アクセシビリティ ---
outline_hits=""
for f in $CSS $CODE; do
  if grep -qE 'outline: *none|outline-none' "$f" 2>/dev/null &&
    ! grep -qE 'focus-ring|box-shadow|focus-visible' "$f" 2>/dev/null; then
    outline_hits="${outline_hits}${f}: outline を消して代替の可視化がない
"
  fi
done
report fail UX03 "フォーカス可視化の削除" "$(echo "$outline_hits" | sed '/^$/d')"

img_hits=$(grep_code '<img ' | grep -v 'alt=' || true)
report fail UX04 "img の alt 欠落" "$img_hits"

report fail UX05 "prefers-reduced-motion の未実装" \
  "$(grep -rq 'prefers-reduced-motion' "$SRC" 2>/dev/null || echo 'src 配下に prefers-reduced-motion の指定がない')"

report warn UX06 "本文へ飛ぶリンクの欠落" \
  "$(grep -rqE 'href="#main"|#main-content' "$SRC" 2>/dev/null || echo 'skip link が見つからない')"

# Vite 系は index.html がプロジェクト直下にあるため、src と併せて検査する
report fail UX07 "html lang の未設定" \
  "$(grep -rqE '<html[^>]*lang=|lang: *[\"'"'"']' "$SRC" "$ROOT/index.html" 2>/dev/null || echo 'lang 属性が見つからない')"

# meta タグ直書きと、Next.js の viewport export の両方を許容する
report fail UX08 "meta viewport の未設定" \
  "$(grep -rqE 'device-width' "$SRC" "$ROOT/index.html" 2>/dev/null || echo 'device-width の指定が見つからない')"

# --- フォーム ---
ph_hits=""
for f in $(files_with 'placeholder='); do
  if ! grep -qE '<label|<Field|htmlFor' "$f" 2>/dev/null; then
    ph_hits="${ph_hits}${f}: placeholder があるがラベルがない
"
  fi
done
report fail UX09 "placeholder のラベル代用" "$(echo "$ph_hits" | sed '/^$/d')"

report warn UX10 "type=\"number\" の使用（スピナー誤操作と貼り付け差を避けるため inputMode=numeric を使う）" \
  "$(grep_code 'type="number"')"

report warn UX11 "入力欄の autoComplete 欠落" \
  "$(for f in $(files_with '<input'); do grep -q 'autoComplete' "$f" || echo "$f: input があるが autoComplete がない"; done)"

# --- 状態網羅と無効化 ---
state_hits=""
# useQueryClient を誤検出しないよう、呼び出しの開き括弧まで含めて一致させる
for f in $(files_with 'useQuery\(|useSuspenseQuery\(|useInfiniteQuery\('); do
  if ! grep -qE 'AsyncBoundary|AsyncState' "$f" 2>/dev/null; then
    state_hits="${state_hits}${f}: データ取得があるが状態網羅の実装が見つからない
"
  fi
done
report fail UX12 "6状態（読込中/空/部分取得/エラー/権限なし/成功）の未実装" "$(echo "$state_hits" | sed '/^$/d')"

# 素の disabled 属性のみを対象にする。aria-disabled と型定義中の disabled は対象外。
# 単語一致で拾うと注釈や props 型まで当たり、無効化していない箇所まで指摘してしまう
dis_hits=""
for f in $(files_with '(^|[[:space:]{])disabled(=\{|=\"|[[:space:]]*/?>|$)'); do
  if ! grep -qE 'GuardedAction|disabledReason|aria-disabled' "$f" 2>/dev/null; then
    dis_hits="${dis_hits}${f}: 素の disabled を使っており理由が添えられていない
"
  fi
done
report fail UX13 "理由のない無効化" "$(echo "$dis_hits" | sed '/^$/d')"

# 無効化の理由と誤りの表示だけが例外なので、条件付き描画になっているものは除外する
note_hits=""
for f in $CODE; do
  hits=$(awk '
    /<\/Button>|<\/button>/ { prev = NR; next }
    prev && NR == prev + 1 && /<(p|span|div)[^>]*text-(fg-)?muted/ && !/&&|\?|Reason|reason|error|Error|invalid/ {
      printf "%s:%d: ボタン直下に説明文を常時表示している\n", FILENAME, NR
    }
    { if (NR != prev) prev = 0 }
  ' "$f" 2>/dev/null)
  [ -n "$hits" ] && note_hits="${note_hits}${hits}
"
done
report fail UX27 "操作できるボタンの下の常時表示の説明文（ux-implementation.md 第12-1節）" \
  "$(echo "$note_hits" | sed '/^$/d')"

icon_hits=""
if [ -n "$(files_with '<Button|<button')" ] && [ -z "$(files_with "from '(lucide-react|@radix-ui/react-icons|@heroicons)")" ]; then
  icon_hits="ボタンはあるがアイコンライブラリの import がない"
fi
report warn UX28 "アイコン体系の不在（ui-libraries.md 第3節）" "$icon_hits"

# --- デザインシステム整合 ---
margin_hits=""
if [ -d "$SRC/shared/components" ]; then
  margin_hits=$(grep -rnE 'className="[^"]*\bm[trblxy]?-[0-9]' "$SRC/shared/components" 2>/dev/null || true)
fi
report fail UX14 "共有部品の外側余白（隣接要素の配置に影響し破壊的変更になる）" "$margin_hits"

report fail UX15 "トークン定義の未配置" \
  "$([ ! -f "$SRC/shared/styles/tokens.css" ] && echo 'src/shared/styles/tokens.css がない')"

# --- 衛生 ---
report fail UX16 "dangerouslySetInnerHTML の使用" "$(grep_code 'dangerouslySetInnerHTML')"
report warn UX17 "console.log の残存" "$(grep_code 'console\.log\(')"

# --- 視覚設計の癖（references/visual-craft.md 第10節） ---
report fail UX18 "汎用パレットの直用い（段の用途が決まらず面と枠と文字の役割が混ざる）" \
  "$(grep_code '(bg|text|border|ring|divide|from|to)-(gray|slate|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-[0-9]|(bg|text|border)-(white|black)([^a-z-]|$)')"

report fail UX19 "transition-all の使用（用途と距離に対応しない一律の動き）" \
  "$(grep_code 'transition-all')"

report warn UX20 "既定の影と角丸（トークンの段を使っていない）" \
  "$(grep_code 'shadow-(sm|md|lg|xl|2xl)([^a-z-]|$)|rounded-(sm|md|lg|xl|2xl|3xl)([^a-z-]|$)')"

report warn UX21 "装飾のためのグラデーション" \
  "$(grep_code 'bg-gradient|bg-linear|bg-radial')"

report warn UX22 "絵文字をアイコン代わりに使っている疑い（線幅と光学寸法が本文と揃わない）" \
  "$([ -n "$CODE" ] && echo "$CODE" | tr '\n' '\0' | LC_ALL=C xargs -0 grep -nE $'\xf0\x9f|\xe2\x9c\xa8|\xe2\x9d\x8c|\xe2\xad\x90' 2>/dev/null)"

num_hits=""
for f in $(files_with '<table|<td|<Td'); do
  if ! grep -qE 'nums|tabular-nums' "$f" 2>/dev/null; then
    num_hits="${num_hits}${f}: 表があるが桁を揃える指定がない
"
  fi
done
report warn UX23 "数値列の桁揃えがない（比例数字のままで比較できない）" "$(echo "$num_hits" | sed '/^$/d')"

undef_hits=""
THEME_CSS=$(find "$SRC" -name 'globals.css' -o -name 'theme.css' 2>/dev/null | head -1)
if [ -n "$THEME_CSS" ] && [ -n "$CODE" ]; then
  DEFINED=$(grep -oE '^[[:space:]]*--color-[a-z0-9-]+' "$THEME_CSS" 2>/dev/null | sed 's/.*--color-//' | sort -u)
  # Tailwind の色以外のユーティリティ接尾辞
  ALLOW='none|full|auto|current|transparent|inherit|black|white|center|left|right|start|end|top|bottom|clip|ellipsis|balance|pretty|wrap|nowrap|hidden|visible|collapse|separate|solid|dashed|dotted|double|2xs|xs|sm|md|lg|xl|2xl|3xl|4xl|5xl|hero|tight|snug|normal|wide|caps|loose'
  for u in $(echo "$CODE" | tr '\n' '\0' | xargs -0 grep -ohE '(stroke|fill|divide)-[a-z][a-z0-9-]*' 2>/dev/null | sort -u); do
    name="${u#*-}"
    echo "$name" | grep -qE "^($ALLOW)$" && continue
    echo "$DEFINED" | grep -qx "$name" && continue
    undef_hits="${undef_hits}${u}: @theme に --color-${name} が無い
"
  done
fi
report fail UX25 "@theme に無い色名の参照（静かに無効化され描画されない）" "$(echo "$undef_hits" | sed '/^$/d')"

primary_hits=""
for f in $(files_with 'intent="primary"'); do
  n=$(grep -c 'intent="primary"' "$f" 2>/dev/null || echo 0)
  [ "$n" -gt 1 ] && primary_hits="${primary_hits}${f}: 塗りの主要操作が ${n} 個（主役が決まっていない）
"
done
report warn UX24 "1画面に塗りの主要操作が複数" "$(echo "$primary_hits" | sed '/^$/d')"

# 変種はコロンの直後に空白を置かないため、cva の size キー（sm: 'h-8'）とは区別できる。
# コンテナクエリ（@sm: など）は部品の寸法に応じた分岐なので対象外。
report warn UX26 "min-width 変種の使用（狭い画面は max-* で上書きする）" \
  "$(grep_code '(^|[^a-z@:-])(sm|md|lg|xl|2xl):[[a-z]|(^|[^a-z@:-])min-\[[0-9]')"

echo
echo "fail=$FAIL warn=$WARN"
[ "$FAIL" -gt 0 ] && exit 1
exit 0

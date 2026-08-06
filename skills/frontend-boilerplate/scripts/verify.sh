#!/usr/bin/env bash
# 1コマンドで合否を出す。AI が人の確認なしで自己判定できるようにするための入口。
# --only <step>[,<step>] で失敗したステップだけを再実行できる。
# ステップ名: lint / typecheck / test / build / bundle / ux-lint / e2e
set -uo pipefail

ROOT="."
SKIP_E2E=0
ONLY=""
EXPECT_ONLY=0
for arg in "$@"; do
  if [ "$EXPECT_ONLY" -eq 1 ]; then
    ONLY="$arg"
    EXPECT_ONLY=0
    continue
  fi
  case "$arg" in
    --skip-e2e) SKIP_E2E=1 ;;
    --only=*) ONLY="${arg#--only=}" ;;
    --only) EXPECT_ONLY=1 ;;
    *) ROOT="$arg" ;;
  esac
done

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# 数値の単一情報源はプロジェクト側。skill 側 assets は初期配置の雛形にすぎない
BUDGETS="$ROOT/e2e/budgets.json"
if [ ! -f "$BUDGETS" ]; then
  mkdir -p "$ROOT/e2e"
  cp "$SKILL_DIR/assets/budgets.json" "$BUDGETS"
fi
FAIL=0
LOG="$ROOT/.verify.log"
: > "$LOG"
TOTAL_START=$(date +%s)

should_run() {
  [ -z "$ONLY" ] && return 0
  case ",$ONLY," in
    *",$1,"*) return 0 ;;
  esac
  return 1
}

dc() { (cd "$ROOT" && docker compose run --rm -T web "$@"); }
dce() { (cd "$ROOT" && docker compose run --rm -T "$@"); }
compose_v() { (cd "$ROOT" && docker compose --profile verify "$@"); }

step() {
  local name="$1"; shift
  should_run "$name" || return 0
  local start
  start=$(date +%s)
  printf '%-22s ' "$name"
  if "$@" >>"$LOG" 2>&1; then
    echo "PASS ($(($(date +%s) - start))s)"
  else
    echo "FAIL ($(($(date +%s) - start))s)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== verify: $ROOT ==="
docker info >/dev/null 2>&1 || { echo "error: Docker が起動していません" >&2; exit 2; }

step "lint" dc npm run lint
step "typecheck" dc npx tsc --noEmit
step "test" dc npm run test -- --run
step "build" dc npm run build

# バンドル寸法。Next.js 16 はビルド出力から寸法列を廃止したためマニフェストから算出する。
# chunks 全体の合計は経路ごとの初期ロードを大きく超えるため使わない。
# 予算の読み取りと計測を1回のコンテナ起動にまとめ、ホストのランタイムには依存しない。
if should_run bundle; then
  START=$(date +%s)
  printf '%-22s ' "bundle"
  MEASURED=$(dc node -e '
const fs = require("fs"), path = require("path"), zlib = require("zlib")
const limit = require("./e2e/budgets.json")["bundle"]["initialJsGzipKb"]
const gz = (files) =>
  files.filter((f) => fs.existsSync(f)).reduce((t, f) => t + zlib.gzipSync(fs.readFileSync(f)).length, 0)
const out = (kb, how) => { console.log(kb + " " + how + " " + limit); process.exit(0) }

// Next.js: rootMainFiles が初期ロード。polyfillFiles は nomodule で近代ブラウザは取得しない
const bm = ".next/build-manifest.json"
if (fs.existsSync(bm)) {
  const m = JSON.parse(fs.readFileSync(bm, "utf8"))
  const files = (m.rootMainFiles || []).map((f) => path.join(".next", f))
  if (files.length) out(Math.floor(gz(files) / 1024), "next:rootMainFiles")
}

// Vite: manifest からエントリの chunk を辿る
for (const mp of ["dist/.vite/manifest.json", "dist/manifest.json"]) {
  if (!fs.existsSync(mp)) continue
  const m = JSON.parse(fs.readFileSync(mp, "utf8"))
  const seen = new Set()
  const stack = Object.keys(m).filter((k) => m[k].isEntry)
  while (stack.length) {
    const k = stack.pop()
    if (seen.has(k)) continue
    seen.add(k)
    if (m[k]) stack.push(...(m[k].imports || []))
  }
  const files = [...seen].filter((k) => m[k]).map((k) => path.join("dist", m[k].file))
  if (files.length) out(Math.floor(gz(files) / 1024), "vite:entry")
}

// 最後の手段。過大評価になるため参考値として扱う
for (const d of [".next/static/chunks", "dist/assets", "build/assets"]) {
  if (!fs.existsSync(d)) continue
  const files = fs.readdirSync(d).filter((f) => f.endsWith(".js")).map((f) => path.join(d, f))
  out(Math.floor(gz(files) / 1024), "fallback:all-chunks")
}
console.log("- none " + limit)
')
  KB=$(echo "$MEASURED" | cut -d' ' -f1)
  HOW=$(echo "$MEASURED" | cut -d' ' -f2)
  LIMIT_KB=$(echo "$MEASURED" | cut -d' ' -f3)
  DUR=$(($(date +%s) - START))
  if [ "$KB" = "-" ]; then
    echo "SKIP (ビルド成果物が見つからない)"
  elif [ "$HOW" = "fallback:all-chunks" ]; then
    echo "WARN (${KB}KB / ${LIMIT_KB}KB, 全chunk合計のため過大評価。手動で確認する) (${DUR}s)"
  elif [ "$KB" -le "$LIMIT_KB" ]; then
    echo "PASS (${KB}KB / ${LIMIT_KB}KB, ${HOW}) (${DUR}s)"
  else
    echo "FAIL (${KB}KB / ${LIMIT_KB}KB, ${HOW}) (${DUR}s)"
    FAIL=$((FAIL + 1))
  fi
fi

step "ux-lint" bash "$SKILL_DIR/scripts/ux-lint.sh" "$ROOT"

# 品質E2E。計測は本番相当のビルド（web-prod）に対して行う。
has_web_prod() { compose_v config --services 2>/dev/null | grep -qx "web-prod"; }

wait_for_prod() {
  local tries=60
  while [ "$tries" -gt 0 ]; do
    if compose_v exec -T web-prod node -e 'fetch("http://localhost:3000").then(() => process.exit(0)).catch(() => process.exit(1))' >/dev/null 2>&1; then
      return 0
    fi
    tries=$((tries - 1))
    sleep 1
  done
  return 1
}

if [ "$SKIP_E2E" -eq 1 ]; then
  should_run e2e && printf '%-22s SKIP\n' "e2e(quality)"
elif [ ! -f "$ROOT/e2e/quality.spec.ts" ]; then
  should_run e2e && printf '%-22s SKIP (e2e/quality.spec.ts が未配置)\n' "e2e(quality)"
elif should_run e2e; then
  START=$(date +%s)
  printf '%-22s ' "e2e(quality)"
  E2E_TARGET=(web)
  PROD_UP=0
  NOTE=""
  if has_web_prod; then
    if compose_v up -d web-prod >>"$LOG" 2>&1 && wait_for_prod; then
      E2E_TARGET=(-e BASE_URL=http://web-prod:3000 web)
      PROD_UP=1
    else
      NOTE=" (web-prod が起動せず dev サーバーで実行。性能値は参考値)"
    fi
  else
    NOTE=" (web-prod 未定義のため dev サーバーで実行。性能値は参考値)"
  fi
  # 基準画像が無い初回は比較対象が無く必ず失敗するため、先に明示的に作成してから本実行する
  if ! ls -d "$ROOT"/e2e/*-snapshots >/dev/null 2>&1; then
    dce "${E2E_TARGET[@]}" npx playwright test e2e/quality.spec.ts --update-snapshots >>"$LOG" 2>&1
    NOTE="$NOTE (基準画像を新規作成)"
  fi
  if dce "${E2E_TARGET[@]}" npx playwright test e2e/quality.spec.ts >>"$LOG" 2>&1; then
    echo "PASS$NOTE ($(($(date +%s) - START))s)"
  else
    echo "FAIL$NOTE ($(($(date +%s) - START))s)"
    FAIL=$((FAIL + 1))
  fi
  [ "$PROD_UP" -eq 1 ] && compose_v stop web-prod >>"$LOG" 2>&1
fi

echo
echo "fail=$FAIL  total=$(($(date +%s) - TOTAL_START))s  詳細: $LOG"
if [ -n "$ONLY" ]; then
  echo "--only の実行は完了条件にならない。最後に引数なしのフルスイートを1回通すこと"
else
  echo "人手でしか判定できない項目は assets/ux-review-checklist.md を実行する"
fi
[ "$FAIL" -gt 0 ] && exit 1
exit 0

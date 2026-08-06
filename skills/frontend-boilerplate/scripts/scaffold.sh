#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scaffold.sh <stack> <app-root> [domain ...]

  stack     nextjs | tanstack
  app-root  プロジェクトルート（package.json のある階層）
  domain    作成するドメイン名。省略した場合は features/ を空で残します

例:
  scaffold.sh nextjs ./my-app requests approvals
  scaffold.sh tanstack ./admin contracts
EOF
}

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

STACK="$1"
ROOT="$2"
shift 2
DOMAINS=("$@")

case "$STACK" in
  nextjs|tanstack) ;;
  *) echo "error: unknown stack '$STACK' (nextjs | tanstack)" >&2; exit 1 ;;
esac

if [ ! -d "$ROOT" ]; then
  echo "error: app-root not found: $ROOT" >&2
  exit 1
fi

SRC="$ROOT/src"

created=()
kept=()

ensure_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    kept+=("${dir#"$ROOT"/}")
  else
    mkdir -p "$dir"
    created+=("${dir#"$ROOT"/}")
  fi
}

common_dirs() {
  ensure_dir "$SRC/shared/components/atoms"
  ensure_dir "$SRC/shared/components/molecules"
  ensure_dir "$SRC/shared/components/organisms"
  ensure_dir "$SRC/shared/components/templates"
  ensure_dir "$SRC/shared/hooks"
  ensure_dir "$SRC/shared/lib"
  ensure_dir "$SRC/shared/providers"
  ensure_dir "$SRC/shared/styles"
  ensure_dir "$ROOT/e2e"
}

nextjs_dirs() {
  ensure_dir "$SRC/app/(guest)"
  ensure_dir "$SRC/app/(authenticated)"
  ensure_dir "$SRC/app/(neutral)"
  ensure_dir "$SRC/features"
  ensure_dir "$SRC/external/dto"
  ensure_dir "$SRC/external/handler"
  ensure_dir "$SRC/external/service"
  ensure_dir "$SRC/external/repository"
  ensure_dir "$SRC/external/client"
}

nextjs_domain() {
  local d="$1"
  ensure_dir "$SRC/features/$d/components/server"
  ensure_dir "$SRC/features/$d/components/client/molecules"
  ensure_dir "$SRC/features/$d/components/client/organisms"
  ensure_dir "$SRC/features/$d/hooks"
  ensure_dir "$SRC/features/$d/queries"
  ensure_dir "$SRC/features/$d/actions"
  ensure_dir "$SRC/features/$d/types"
}

tanstack_dirs() {
  ensure_dir "$SRC/routes"
  ensure_dir "$SRC/features"
}

tanstack_domain() {
  local d="$1"
  ensure_dir "$SRC/features/$d/api"
  ensure_dir "$SRC/features/$d/server"
  ensure_dir "$SRC/features/$d/hooks"
  ensure_dir "$SRC/features/$d/components/molecules"
  ensure_dir "$SRC/features/$d/components/organisms"
  ensure_dir "$SRC/routes/$d/-components/fallbacks"
}

common_dirs

if [ "$STACK" = "nextjs" ]; then
  nextjs_dirs
  for d in ${DOMAINS[@]+"${DOMAINS[@]}"}; do nextjs_domain "$d"; done
else
  tanstack_dirs
  for d in ${DOMAINS[@]+"${DOMAINS[@]}"}; do tanstack_domain "$d"; done
fi

echo "[scaffold] stack: $STACK"
echo "[scaffold] root:  $ROOT"
if [ ${#DOMAINS[@]} -gt 0 ]; then
  echo "[scaffold] domains: ${DOMAINS[*]}"
else
  echo "[scaffold] domains: (none)"
fi

echo
echo "created:"
if [ ${#created[@]} -gt 0 ]; then
  printf '  %s\n' ${created[@]+"${created[@]}"}
else
  echo "  (none)"
fi

echo "already existed:"
if [ ${#kept[@]} -gt 0 ]; then
  printf '  %s\n' ${kept[@]+"${kept[@]}"}
else
  echo "  (none)"
fi

#!/usr/bin/env sh
set -eu

skill_name=scala-react-functional-course
harness=dsh
scope=user
project=$(pwd)
dry=0

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--harness dsh|codex|claude|all] [--scope user|project] [--project DIR] [--dry-run]

Remove this skill from coding-agent skill directories. Only a link that points at
this repository, or a copied directory carrying this repository's install marker
(.skill-install.json), is removed; anything else is reported and left alone.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --harness) harness=$2; shift 2 ;;
    --scope) scope=$2; shift 2 ;;
    --project) project=$2; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$harness" in dsh|codex|claude|all) ;; *) echo "invalid harness: $harness" >&2; exit 2 ;; esac
case "$scope" in user|project) ;; *) echo "invalid scope: $scope" >&2; exit 2 ;; esac

repo_root=$(cd "$(dirname "$0")/.." && pwd -P)
marker_name=.skill-install.json

resolve_root() {
  h=$1
  case "$h" in
    dsh) base=${DSH_HOME:-$HOME/.dsh}; suffix=.dsh ;;
    codex) base=${CODEX_HOME:-$HOME/.codex}; suffix=.codex ;;
    claude) base=$HOME/.claude; suffix=.claude ;;
  esac
  if [ "$scope" = project ]; then
    printf '%s/%s/skills\n' "$project" "$suffix"
  else
    printf '%s/skills\n' "$base"
  fi
}

same_path() {
  a=$(cd "$1" 2>/dev/null && pwd -P) || return 1
  b=$(cd "$2" 2>/dev/null && pwd -P) || return 1
  [ "$a" = "$b" ]
}

if [ "$harness" = all ]; then
  harnesses="dsh codex claude"
else
  harnesses=$harness
fi

for h in $harnesses; do
  root=$(resolve_root "$h")
  target="$root/$skill_name"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    echo "Not installed: $target"
    continue
  fi

  if [ -L "$target" ]; then
    if ! same_path "$target" "$repo_root"; then
      echo "Skipping $target: the link points at another directory." >&2
      continue
    fi
    if [ "$dry" = 1 ]; then
      echo "Would remove link $target"
      continue
    fi
    rm "$target"
    echo "Removed link $target"
    continue
  fi

  if [ ! -f "$target/$marker_name" ]; then
    echo "Skipping $target: no install marker, so this script did not create it." >&2
    continue
  fi
  if ! grep -q "\"repo\": \"$repo_root\"" "$target/$marker_name"; then
    echo "Skipping $target: it was installed from another repository." >&2
    continue
  fi
  if [ "$dry" = 1 ]; then
    echo "Would remove copied directory $target"
    continue
  fi
  rm -rf "$target"
  echo "Removed copied directory $target"
done

echo 'Restart the harness or wait for its skill catalog to refresh.'

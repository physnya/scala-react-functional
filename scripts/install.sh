#!/usr/bin/env sh
set -eu

skill_name=scala-react-functional-course
harness=dsh
scope=user
project=$(pwd)
copy=0
dry=0

usage() {
  cat <<'EOF'
Usage: install.sh [--harness dsh|codex|claude|all] [--scope user|project] [--project DIR] [--copy] [--dry-run]

Install this skill into coding-agent skill directories:
  dsh    -> ${DSH_HOME:-$HOME/.dsh}/skills      (project: DIR/.dsh/skills)
  codex  -> ${CODEX_HOME:-$HOME/.codex}/skills  (project: DIR/.codex/skills)
  claude -> $HOME/.claude/skills                (project: DIR/.claude/skills)

The script links the repository into <root>/scala-react-functional-course by
default; --copy copies the skill files instead and records an install marker.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --harness) harness=$2; shift 2 ;;
    --scope) scope=$2; shift 2 ;;
    --project) project=$2; shift 2 ;;
    --copy) copy=1; shift ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$harness" in dsh|codex|claude|all) ;; *) echo "invalid harness: $harness" >&2; exit 2 ;; esac
case "$scope" in user|project) ;; *) echo "invalid scope: $scope" >&2; exit 2 ;; esac

repo_root=$(cd "$(dirname "$0")/.." && pwd -P)
marker_name=.skill-install.json

if [ ! -f "$repo_root/SKILL.md" ]; then
  echo "SKILL.md not found in $repo_root; run this script from a clone of the skill repository." >&2
  exit 1
fi

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

copy_skill() {
  target=$1
  mkdir -p "$target"
  for entry in SKILL.md references agents LICENSE README.md; do
    if [ -e "$repo_root/$entry" ]; then
      cp -R "$repo_root/$entry" "$target/"
    fi
  done
  printf '{\n  "repo": "%s",\n  "harness": "%s",\n  "scope": "%s"\n}\n' \
    "$repo_root" "$harness" "$scope" > "$target/$marker_name"
}

if [ "$harness" = all ]; then
  harnesses="dsh codex claude"
else
  harnesses=$harness
fi

for h in $harnesses; do
  root=$(resolve_root "$h")
  target="$root/$skill_name"

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] && same_path "$target" "$repo_root"; then
      echo "Already installed: $target"
      continue
    fi
    echo "Skipping $target: it exists and was not installed from this repository." >&2
    continue
  fi

  if [ "$dry" = 1 ]; then
    echo "Would link $target -> $repo_root"
    continue
  fi

  mkdir -p "$root"
  if [ "$copy" = 1 ]; then
    copy_skill "$target"
    echo "Copied skill files into $target"
    continue
  fi
  if ln -s "$repo_root" "$target" 2>/dev/null; then
    echo "Linked $target -> $repo_root"
  else
    echo "Link creation failed; copying the skill files instead." >&2
    copy_skill "$target"
    echo "Copied skill files into $target"
  fi
done

echo 'Restart the harness or wait for its skill catalog to refresh.'

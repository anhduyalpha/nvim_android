#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dry_run=false
clean_cache=false

usage() {
  cat <<'EOF'
Usage: ./clean.sh [--dry-run] [--cache]

Safely removes generated files from this repository.
  --dry-run  Print what would be removed.
  --cache    Also clear Neovim's cache directory (plugins are kept).

Tracked source files and tests/ are never deleted.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --cache) clean_cache=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

remove_path() {
  local path="$1"
  [ -e "$path" ] || [ -L "$path" ] || return 0
  if $dry_run; then
    printf 'would remove: %s\n' "$path"
  else
    rm -rf -- "$path"
    printf 'removed: %s\n' "$path"
  fi
}

cd "$repo_root"

# Root-level generated directories already ignored by the repository.
for path in .tests .repro data debug build performance_report.txt; do
  remove_path "$repo_root/$path"
done

# Editor leftovers and generated reports. Exclude .git and all tracked test sources.
while IFS= read -r -d '' path; do
  remove_path "$path"
done < <(
  find "$repo_root" \
    -path "$repo_root/.git" -prune -o \
    -path "$repo_root/tests" -prune -o \
    -type f \( \
      -name '*.log' -o \
      -name '*.tmp' -o \
      -name '*.swp' -o \
      -name '*.swo' -o \
      -name '*~' -o \
      -name '.DS_Store' -o \
      -name 'performance_report*.txt' \
    \) -print0
)

if $clean_cache; then
  cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
  remove_path "$cache_root"
fi

if $dry_run; then
  echo "Dry run complete. No files were deleted."
else
  echo "Repository cleanup complete."
fi

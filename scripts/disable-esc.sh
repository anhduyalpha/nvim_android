#!/usr/bin/env bash
set -euo pipefail

mode="${1:---apply}"
termux_dir="$HOME/.termux"
termux_properties="$termux_dir/termux.properties"
tmux_config="$HOME/.tmux.conf"
timestamp="$(date +%Y%m%d%H%M%S)"

termux_begin="# BEGIN nvim_android no-escape keys"
termux_end="# END nvim_android no-escape keys"
tmux_begin="# BEGIN nvim_android mobile input"
tmux_end="# END nvim_android mobile input"

strip_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local output="$4"

  if [ ! -f "$file" ]; then
    : > "$output"
    return
  fi

  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$file" > "$output"
}

backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.nvim-android.$timestamp.bak"
    echo "Backup: $file.nvim-android.$timestamp.bak"
  fi
}

reload_termux() {
  if command -v termux-reload-settings >/dev/null 2>&1; then
    termux-reload-settings || true
  fi
}

reload_tmux() {
  if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$tmux_config" || true
  fi
}

mkdir -p "$termux_dir"
termux_tmp="$(mktemp)"
tmux_tmp="$(mktemp)"
trap 'rm -f "$termux_tmp" "$tmux_tmp"' EXIT

strip_block "$termux_properties" "$termux_begin" "$termux_end" "$termux_tmp"
strip_block "$tmux_config" "$tmux_begin" "$tmux_end" "$tmux_tmp"

case "$mode" in
  --apply)
    backup_file "$termux_properties"
    backup_file "$tmux_config"

    if [ -s "$termux_tmp" ]; then
      printf '\n' >> "$termux_tmp"
    fi
    cat >> "$termux_tmp" <<'EOF'
# BEGIN nvim_android no-escape keys
# Mobile coding row without ESC. Use jk or jj to leave Insert mode in Neovim.
extra-keys = [['CTRL','ALT','TAB','HOME','UP','END','PGUP'],['/','-','LEFT','DOWN','RIGHT','PGDN','KEYBOARD']]
# END nvim_android no-escape keys
EOF
    mv "$termux_tmp" "$termux_properties"
    termux_tmp="$(mktemp)"

    if [ -s "$tmux_tmp" ]; then
      printf '\n' >> "$tmux_tmp"
    fi
    cat >> "$tmux_tmp" <<'EOF'
# BEGIN nvim_android mobile input
# Resolve Alt/Meta combinations immediately while Neovim itself blocks raw ESC.
set -sg escape-time 0
set -g focus-events on
# END nvim_android mobile input
EOF
    mv "$tmux_tmp" "$tmux_config"
    tmux_tmp="$(mktemp)"

    reload_termux
    reload_tmux
    echo "ESC removed from the managed Termux extra-key row."
    echo "Neovim uses jk/jj to leave Insert mode; q closes windows and buffers."
    ;;

  --restore)
    backup_file "$termux_properties"
    backup_file "$tmux_config"
    mv "$termux_tmp" "$termux_properties"
    termux_tmp="$(mktemp)"
    mv "$tmux_tmp" "$tmux_config"
    tmux_tmp="$(mktemp)"
    reload_termux
    reload_tmux
    echo "Removed nvim_android no-ESC configuration blocks."
    ;;

  *)
    echo "Usage: $0 [--apply|--restore]" >&2
    exit 2
    ;;
esac

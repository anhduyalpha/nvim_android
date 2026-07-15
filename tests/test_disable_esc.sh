#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

mkdir -p "$test_home/.termux"
printf '%s\n' \
  'font-size=14' \
  "extra-keys = [['ESC','CTRL']]" \
  > "$test_home/.termux/termux.properties"
printf '%s\n' 'set -g mouse on' > "$test_home/.tmux.conf"

HOME="$test_home" bash "$repo_root/scripts/disable-esc.sh" --apply

[ "$(grep -c '^# BEGIN nvim_android no-escape keys$' "$test_home/.termux/termux.properties")" -eq 1 ]
[ "$(grep -c '^# BEGIN nvim_android mobile input$' "$test_home/.tmux.conf")" -eq 1 ]
grep '^extra-keys' "$test_home/.termux/termux.properties" | tail -n 1 | grep -vq 'ESC'
grep -q '^set -sg escape-time 0$' "$test_home/.tmux.conf"

first_termux_backups="$(find "$test_home/.termux" -name '*.bak' | wc -l)"
first_tmux_backups="$(find "$test_home" -maxdepth 1 -name '.tmux.conf*.bak' | wc -l)"

HOME="$test_home" bash "$repo_root/scripts/disable-esc.sh" --apply

[ "$(grep -c '^# BEGIN nvim_android no-escape keys$' "$test_home/.termux/termux.properties")" -eq 1 ]
[ "$(grep -c '^# BEGIN nvim_android mobile input$' "$test_home/.tmux.conf")" -eq 1 ]
[ "$(find "$test_home/.termux" -name '*.bak' | wc -l)" -eq "$first_termux_backups" ]
[ "$(find "$test_home" -maxdepth 1 -name '.tmux.conf*.bak' | wc -l)" -eq "$first_tmux_backups" ]

HOME="$test_home" bash "$repo_root/scripts/disable-esc.sh" --restore

! grep -q '^# BEGIN nvim_android no-escape keys$' "$test_home/.termux/termux.properties"
! grep -q '^# BEGIN nvim_android mobile input$' "$test_home/.tmux.conf"
grep -q "extra-keys = \[\['ESC','CTRL'\]\]" "$test_home/.termux/termux.properties"
grep -q '^set -g mouse on$' "$test_home/.tmux.conf"

echo 'PASS: no-ESC Termux/tmux setup is idempotent and reversible'

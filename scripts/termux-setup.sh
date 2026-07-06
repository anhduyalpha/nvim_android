#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dir="$HOME/.config/nvim"
backup_dir="$HOME/.config/nvim.old.$(date +%Y%m%d%H%M%S)"

if ! command -v pkg >/dev/null 2>&1; then
  echo "Run this inside Termux. Missing: pkg"
  exit 1
fi

pkg update -y
pkg install -y git neovim clang lld ripgrep fd python nodejs unzip zip lazygit
for pkg_name in lua-language-server stylua shfmt; do
  pkg install -y "$pkg_name" || echo "Optional package skipped: $pkg_name"
done
command -v npm >/dev/null 2>&1 && npm install -g pyright || true

mkdir -p "$HOME/.config"
if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
  mv "$config_dir" "$backup_dir"
  echo "Moved existing config to $backup_dir"
fi

ln -s "$repo_root" "$config_dir"
chmod +x "$repo_root/check_performance.sh" "$repo_root/backup_recovery.sh"

nvim --headless "+Lazy! sync" +qa
(cd "$repo_root" && ./check_performance.sh)

echo "Neovim Android setup ready. Start with: nvim"

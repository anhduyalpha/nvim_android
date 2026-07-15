#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dir="$HOME/.config/nvim"
backup_dir="$HOME/.config/nvim.old.$(date +%Y%m%d%H%M%S)"

if ! command -v pkg >/dev/null 2>&1; then
  echo "Run this script inside Termux. Missing command: pkg" >&2
  exit 1
fi

pkg install -y git neovim clang lld ripgrep fd python nodejs unzip zip lazygit
for pkg_name in lua-language-server stylua shfmt; do
  pkg install -y "$pkg_name" || echo "Optional package unavailable: $pkg_name"
done

if command -v npm >/dev/null 2>&1 && ! command -v pyright-langserver >/dev/null 2>&1; then
  npm install -g pyright || echo "Optional pyright installation failed"
fi

mkdir -p "$HOME/.config"

linked_repo=""
if [ -L "$config_dir" ]; then
  linked_repo="$(readlink -f "$config_dir" 2>/dev/null || true)"
fi

if [ "$linked_repo" = "$repo_root" ]; then
  echo "Neovim config already points to this repository."
elif [ "$(readlink -f "$config_dir" 2>/dev/null || true)" = "$repo_root" ]; then
  echo "Repository is already installed at $config_dir."
else
  if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
    mv "$config_dir" "$backup_dir"
    echo "Moved existing config to $backup_dir"
  fi
  ln -s "$repo_root" "$config_dir"
  echo "Linked $config_dir -> $repo_root"
fi

chmod +x \
  "$repo_root/check_performance.sh" \
  "$repo_root/backup_recovery.sh" \
  "$repo_root/clean.sh" \
  "$repo_root/scripts/termux-setup.sh"

nvim --headless "+Lazy! sync" +qa
(cd "$repo_root" && ./check_performance.sh)

echo "Neovim Android setup ready. Start with: nvim"

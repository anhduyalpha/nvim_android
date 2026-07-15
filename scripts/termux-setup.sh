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

# Keep the user's clangd settings and replace only this repository's managed fragment.
clangd_dir="$HOME/.config/clangd"
clangd_config="$clangd_dir/config.yaml"
begin_marker="# BEGIN nvim_android bits compatibility"
end_marker="# END nvim_android bits compatibility"
mkdir -p "$clangd_dir"
tmp_config="$(mktemp)"

if [ -f "$clangd_config" ]; then
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$clangd_config" > "$tmp_config"
fi

if [ -s "$tmp_config" ]; then
  printf '\n' >> "$tmp_config"
fi
cat >> "$tmp_config" <<EOF
$begin_marker
---
If:
  PathMatch: .*\\.(cc|cpp|cxx|h|hh|hpp)$
CompileFlags:
  Add: ["-I$repo_root/include"]
$end_marker
EOF
mv "$tmp_config" "$clangd_config"
echo "Configured clangd compatibility include: $repo_root/include"

chmod +x \
  "$repo_root/check_performance.sh" \
  "$repo_root/backup_recovery.sh" \
  "$repo_root/clean.sh" \
  "$repo_root/scripts/termux-setup.sh"

# Verify that Termux clang++ and the compatibility header work together.
probe="${TMPDIR:-$PREFIX/tmp}/nvim_android_bits_$$.cpp"
trap 'rm -f "$probe"' EXIT
cat > "$probe" <<'EOF'
#include <bits/stdc++.h>
int main() {
  std::vector<int> values{3, 1, 2};
  std::sort(values.begin(), values.end());
  return values.front() == 1 ? 0 : 1;
}
EOF
clang++ -std=c++20 -I"$repo_root/include" -fsyntax-only "$probe"
rm -f "$probe"
trap - EXIT

echo "bits/stdc++.h compatibility check passed."
nvim --headless "+Lazy! sync" +qa
(cd "$repo_root" && ./check_performance.sh)

echo "Neovim Android setup ready. Start with: nvim"

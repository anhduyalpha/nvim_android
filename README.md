# Neovim Android/Termux Setup

LazyVim config tuned for Android: low-RAM LSP, touch-friendly keys, C/C++ compile/run flow, backup/recovery, diagnostics, and performance checks.

## Install on Android

```sh
pkg install -y git
mkdir -p ~/code
cd ~/code
git clone https://github.com/anhduyalpha/nvim_android.git
cd nvim_android
bash scripts/termux-setup.sh
```

The script installs core Termux packages, links this repo to `~/.config/nvim`, syncs Lazy plugins, and runs the health check. Existing `~/.config/nvim` is moved to `~/.config/nvim.old.<timestamp>` before linking.

## Verify

```sh
./check_performance.sh
```

Run all repo tests:

```sh
for test in tests/*.lua; do nvim --headless -c "luafile $test" -c "qa"; done
```

## Daily keys

- `q`: close floating/special buffer, then normal buffer, then explorer, then quit
- `<leader>z`: mobile action menu
- `<leader>h`: mobile C++ help
- `<M-Left>` / `<M-Right>`: previous/next buffer
- `gl`, `]d`, `[d`: diagnostics
- C/C++ buffers: `ct` compile/run, `cs` compile/run with time, `cv` UBSan, `cm` debug/release, `cx` rerun

## Backup and recovery

Inside Neovim:

```vim
:NvimBackup
```

Restore latest backup in Termux:

```sh
./backup_recovery.sh
```

Backups go to `$HOME/storage/shared/NvimBackups` when Termux storage is enabled, else `$HOME/NvimBackups`.

## Update

```sh
cd /path/to/nvim_android
git pull
bash scripts/termux-setup.sh
```

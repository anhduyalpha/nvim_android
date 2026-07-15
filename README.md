# Neovim Android / Termux

A LazyVim configuration tuned for coding on Android with limited RAM, a small screen, Termux, and tmux. It includes C/C++ compile/run workflows, LSP, formatting, Git tools, backups, diagnostics, performance checks, debounced auto save, a no-ESC input workflow, and a native mobile action menu.

## Install

Run inside Termux:

```sh
pkg install -y git
mkdir -p ~/code
cd ~/code
git clone https://github.com/anhduyalpha/nvim_android.git
cd nvim_android
bash scripts/termux-setup.sh
```

The setup script installs the required packages, safely links this repository to `~/.config/nvim`, configures clangd compatibility, removes `ESC` from the managed Termux extra-key row, tunes tmux input latency, syncs plugins, and runs the health check.

## Smooth-mobile defaults

- Native Lua module caching is enabled before the plugin graph loads.
- Lazy plugin update checks and config change polling are disabled on Android.
- Memory monitoring starts after startup and never runs while typing.
- Large files automatically disable expensive syntax, Treesitter, diagnostics, and persistent undo.
- Cursorline rendering pauses in Insert mode.
- Plugin installation concurrency is limited on Android.
- clangd and completion redraw work are reduced on Android.
- Modified files are saved 1.8 seconds after the last edit.
- Auto save temporarily skips format-on-save to prevent cursor jumps and typing stalls.
- The physical `ESC` key is disabled inside Neovim; use `jk` or `jj` instead.

## Touch-first keys

| Key | Action |
|---|---|
| `q` | Smart close: popup → special window → code buffer → Explorer → Neovim |
| `d` | Delete the current line |
| `D` | Delete to the end of the line |
| `t` | Toggle Snacks Explorer |
| `U` | Focus Explorer, or open it when closed |
| `Ctrl+A` | Select all |
| `Tab` / `Shift+Tab` | Indent / outdent line or selection |
| `Ctrl+G` | Start native Vim macro recording |
| `jk` or `jj` | Leave Insert mode without pressing `ESC` |
| `<leader>z` | Open the mobile action menu |
| `<leader>h` | Open the mobile quick guide |
| `<leader>Q` | Smart-close alias |
| `<M-Left>` / `<M-Right>` | Previous / next buffer |
| `<M-Up>` / `<M-Down>` | Move the current line or selection |
| `<leader>cf` | Format the current file manually |
| `gl` | Show diagnostics at the cursor |
| `]d` / `[d` | Next / previous diagnostic |
| `]t` / `[t` | Next / previous TODO comment |

LazyVim's standard LSP keys such as `gd`, `gr`, `K`, code actions, rename, and picker shortcuts remain available.

## Auto save

Auto save is enabled by default.

- Text changes are debounced for 1.8 seconds, so the editor does not write on every keystroke.
- Leaving a buffer or switching away from Termux saves immediately.
- Large files, unnamed buffers, readonly buffers, and special plugin windows are skipped.
- Manual `:w` and `<leader>cf` still run your normal formatting workflow.

Commands:

```vim
:AutoSaveNow
:AutoSaveToggle
```

Change the delay in Lua before `autocmds.lua` loads:

```lua
vim.g.android_autosave_delay = 2500
```

## Disable the ESC key in Termux and tmux

The setup script applies this automatically. Run it again manually with:

```sh
bash scripts/disable-esc.sh --apply
```

This script:

- creates timestamped backups of existing Termux and tmux configuration files;
- adds a Termux extra-key layout without `ESC`;
- keeps useful mobile keys such as `CTRL`, `ALT`, arrows, `TAB`, page navigation, and keyboard toggle;
- sets tmux `escape-time` to zero so Alt/Meta key combinations remain responsive;
- reloads Termux settings and the current tmux server when available.

Remove only the managed configuration blocks with:

```sh
bash scripts/disable-esc.sh --restore
```

Inside Neovim, raw `ESC` is mapped to no operation in Normal, Insert, Visual, Select, Operator-pending, Command-line, and Terminal mode. The non-recursive `jk` and `jj` mappings still execute the real Insert-mode exit action.

## C and C++ workflow

| Key | Action |
|---|---|
| `ct` | Compile and run |
| `cs` | Compile, run, and measure execution time |
| `cv` | Compile with UBSan |
| `cm` | Toggle Debug / Release mode |
| `cx` | Run the most recent binary again |
| `ce` | Open compiler errors in Quickfix |
| `cR` | Restart clangd |

Recommended Termux packages:

```sh
pkg install clang lld clangd
```

### `bits/stdc++.h` on Termux

Termux uses Clang with libc++, which does not provide GNU's non-standard `bits/stdc++.h`. This repository includes a compatibility header at:

```text
include/bits/stdc++.h
```

The setup connects that header to both compiler jobs and clangd. It also compiles a real probe during installation, so a broken include configuration fails immediately.

## Verify the configuration

Run the performance and health report:

```sh
./check_performance.sh
```

Run all headless Lua tests:

```sh
for test in tests/*.lua; do
  nvim --headless -c "luafile $test" -c "qa"
done
```

Inside Neovim, force a safe Lua memory cleanup with:

```vim
:NvimOptimize
```

Use `:Lazy profile` to inspect plugin startup cost and `:checkhealth` when a language server, formatter, clipboard provider, or terminal integration is not working.

## Safe repository cleanup

Preview generated files without deleting anything:

```sh
./clean.sh --dry-run
```

Remove generated reports, logs, swap files, scratch directories, and build output:

```sh
./clean.sh
```

Also clear Neovim's cache while keeping installed plugins and source files untouched:

```sh
./clean.sh --cache
```

The cleanup script never deletes `tests/` or tracked source files.

## Backup and recovery

Create a backup inside Neovim:

```vim
:NvimBackup
```

Restore the latest backup in Termux:

```sh
./backup_recovery.sh
```

Backups are written to `$HOME/storage/shared/NvimBackups` when Termux storage is available, otherwise to `$HOME/NvimBackups`.

## Update

```sh
cd /path/to/nvim_android
git pull
bash scripts/termux-setup.sh
```

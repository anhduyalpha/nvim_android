# Neovim Android / Termux

A LazyVim configuration tuned for coding on Android with limited RAM, a small screen, and touch-oriented terminal input. It includes C/C++ compile/run workflows, LSP, formatting, Git tools, backups, diagnostics, performance checks, and a native mobile action menu.

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

The setup script installs the required packages, moves an existing Neovim config to a timestamped backup, links this repository to `~/.config/nvim`, syncs plugins, configures clangd, verifies `bits/stdc++.h`, and runs the health check.

## Smooth-mobile defaults

- Native Lua module caching is enabled before the plugin graph loads.
- Lazy plugin update checks and config change polling are disabled on Android.
- Memory monitoring starts after startup and never runs while typing.
- Large files automatically disable expensive syntax, Treesitter, diagnostics, and persistent undo.
- Cursorline rendering pauses in Insert mode.
- Plugin installation concurrency is limited on Android.
- C/C++ files are no longer written every time Insert mode closes. Smart save runs when leaving the buffer or switching away from Termux.
- Automatic completion documentation and signature popups are disabled on Android to reduce UI redraw and LSP work.

## Optimized custom keys

This configuration intentionally uses a touch-first editing model instead of native Vim behavior for several single-key commands.

| Key | Action |
|---|---|
| `q` | Smart-close a float, special window, current buffer, or Neovim |
| `d` | Delete the current line |
| `D` | Delete from the cursor to the end of the line |
| `t` | Toggle Snacks Explorer |
| `U` | Open or focus Snacks Explorer |
| `Ctrl-a` | Select the entire file |
| `Tab` / `Shift-Tab` | Indent / outdent the line or selected block |
| `Ctrl-g` | Start native macro recording, replacing the original `q` entry point |
| `<leader>z` | Open the mobile action menu |
| `<leader>h` | Open the mobile quick guide |
| `<leader>Q` | Smart-close alias |
| `<leader>e` | Toggle Snacks Explorer alias |
| `<M-Left>` / `<M-Right>` | Previous / next buffer |
| `<M-Up>` / `<M-Down>` | Move the current line or selection |
| `<leader>cf` | Format the current file |
| `gl` | Show diagnostics at the cursor |
| `]d` / `[d` | Next / previous diagnostic |
| `]t` / `[t` | Next / previous TODO comment |
| `jk` or `jj` | Leave Insert mode |

LazyVim's standard LSP keys such as `gd`, `gr`, `K`, code actions, rename, and picker shortcuts remain available.

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
pkg install clang lld
```

### `bits/stdc++.h` on Termux

Termux uses Clang with libc++, so GNU's non-standard `bits/stdc++.h` header is not normally installed. This repository provides a compatibility header at:

```text
~/.config/nvim/include/bits/stdc++.h
```

The setup and Neovim configuration expose that directory to both `clang++` and clangd. After updating the repository, run:

```sh
bash scripts/termux-setup.sh
```

Then this works with the built-in compile commands:

```cpp
#include <bits/stdc++.h>
using namespace std;

int main() {
    vector<int> values{3, 1, 2};
    sort(values.begin(), values.end());
}
```

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

Use `:Lazy profile` to inspect plugin startup cost and `:checkhealth` when a language server, formatter, clipboard provider, or terminal integration is not working.

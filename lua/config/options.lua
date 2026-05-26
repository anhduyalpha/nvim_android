-- options.lua — Neovim options tuned for Android/Termux environment
-- Optimized for limited RAM, no system daemons, and mobile usage

local android = require("util.android")
local settings = android.get_platform_settings()

-- ── General ──────────────────────────────────────────────
vim.opt.mouse = "a" -- Enable mouse (useful for touch)
vim.opt.clipboard = android.is_termux() and "unnamedplus" or ""
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.confirm = true -- Confirm before exiting modified buffer
vim.opt.hidden = true -- Allow hidden buffers
vim.opt.autowrite = true -- Auto-write on certain events

-- ── UI ───────────────────────────────────────────────────
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Relative numbers for easy navigation
vim.opt.cursorline = true -- Highlight current line
vim.opt.signcolumn = "yes" -- Always show sign column
vim.opt.termguicolors = true -- True color support
vim.opt.showmode = false -- Don't show mode (lualine handles it)
vim.opt.showcmd = false -- Don't show partial commands
vim.opt.ruler = false -- Don't show ruler (lualine handles it)
vim.opt.laststatus = 3 -- Global statusline
vim.opt.scrolloff = 8 -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
vim.opt.pumheight = 10 -- Popup menu height
vim.opt.pumblend = 0 -- No popup blend (save performance)
vim.opt.winblend = 0 -- No window blend
vim.opt.splitbelow = true -- Horizontal split below
vim.opt.splitright = true -- Vertical split right
vim.opt.fillchars = { eob = " " } -- Hide ~ in empty lines

-- ── Search ───────────────────────────────────────────────
vim.opt.ignorecase = true -- Case-insensitive search
vim.opt.smartcase = true -- ...unless uppercase is used
vim.opt.hlsearch = true -- Highlight search results
vim.opt.incsearch = true -- Incremental search

-- ── Indentation ──────────────────────────────────────────
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 2 -- Indent width
vim.opt.tabstop = 2 -- Tab width
vim.opt.smartindent = true -- Smart indentation
vim.opt.autoindent = true -- Auto indentation
vim.opt.shiftround = true -- Round indent to shiftwidth

-- ── Performance (Android-optimized) ─────────────────────
vim.opt.updatetime = settings.update_time -- Increased from 250ms
vim.opt.timeoutlen = 100 -- Instant leader key response
vim.opt.ttimeoutlen = 10 -- Key code timeout
vim.opt.synmaxcol = 200 -- Limit syntax highlight columns
vim.opt.regexpengine = 0 -- Auto-select regexp engine

-- ── Files & Undo ─────────────────────────────────────────
vim.opt.swapfile = false -- Disable swapfile (save I/O)
vim.opt.backup = false -- Disable backup
vim.opt.writebackup = false -- Disable write backup
vim.opt.undofile = true -- Enable persistent undo
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undolevels = settings.undo_levels -- Limited undo levels
vim.opt.undoreload = 100 -- Lines to reload for undo

-- ── Folding (indent-based, no treesitter required) ─────
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99 -- Open all folds by default
vim.opt.foldlevelstart = 99
vim.opt.foldenable = false -- Disable folding on open

-- ── Session & Shada ──────────────────────────────────────
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
vim.opt.shada = "!,'100,<50,s10,h" -- Limited shada for faster I/O

-- ── Format Options ───────────────────────────────────────
vim.opt.formatoptions:remove({ "c", "r", "o" }) -- Don't auto-comment on newline

-- ── Disable some heavy features on Android ───────────────
if android.is_android() then
  vim.g.loaded_matchparen = 1 -- Disable matchparen
  vim.g.loaded_matchit = 1 -- Disable matchit
  vim.g.did_install_syntax_menu = 1 -- Disable syntax menu
  vim.g.loaded_spellfile_plugin = 1 -- Disable spellfile plugin
  vim.g.loaded_2html_plugin = 1 -- Disable 2html plugin
  vim.g.loaded_tutor_mode_plugin = 1 -- Disable tutor
end

-- ── Clipboard integration for Termux (Optimized with OSC 52) ────
if android.is_termux() then
  vim.g.clipboard = {
    name = "termux-osc52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
    cache_enabled = 1,
  }
end

-- ── Disable ALL LazyVim default <leader>c* keymaps ────
-- <leader>c is reserved for C++ keymaps (defined in ftplugin/cpp.lua)
vim.g.lazyvim_keys_lsp = false
vim.g.lazyvim_keys_code = false

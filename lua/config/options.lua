local android = require("util.android")
local settings = android.get_platform_settings()

-- General
vim.opt.mouse = "a"
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.confirm = true
vim.opt.hidden = true
vim.opt.autowrite = true

-- UI
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.showcmd = false
vim.opt.ruler = false
vim.opt.laststatus = 3
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 4
vim.opt.pumheight = 8
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.fillchars = { eob = " " }

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.shiftround = true

-- Responsive without making multi-key mappings unreliable on a touchscreen.
vim.opt.updatetime = settings.update_time
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 20
vim.opt.synmaxcol = 300
vim.opt.regexpengine = 0
vim.opt.redrawtime = 500

-- Files and undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.fn.mkdir(vim.fn.stdpath("data") .. "/undodir", "p")
vim.opt.undolevels = settings.undo_levels
vim.opt.undoreload = 200

-- Folding stays off until explicitly requested. Manual folding avoids startup scans.
vim.opt.foldmethod = "manual"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = false

vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
vim.opt.shada = "!,'50,<30,s5,h"
vim.opt.formatoptions:remove({ "c", "r", "o" })

-- Disable bundled runtime plugins that are not useful in the Termux workflow.
if android.is_android() then
  local disabled = {
    "matchparen",
    "matchit",
    "netrw",
    "netrwPlugin",
    "gzip",
    "tarPlugin",
    "zipPlugin",
    "2html_plugin",
    "tutor_mode_plugin",
    "spellfile_plugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "logipat",
    "rrhelper",
  }
  for _, name in ipairs(disabled) do
    vim.g["loaded_" .. name] = 1
  end
end

-- OSC52 keeps copying fast and dependency-free in terminals that support it.
if android.is_termux() then
  vim.opt.clipboard = "unnamedplus"
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok then
    vim.g.clipboard = {
      name = "termux-osc52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = osc52.paste("+"),
        ["*"] = osc52.paste("*"),
      },
      cache_enabled = 1,
    }
  end
end

vim.diagnostic.config({
  underline = true,
  virtual_text = {
    spacing = 2,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- A native winbar is cheaper than a breadcrumb plugin and is hidden in special buffers.
if android.is_android() then
  local devicons
  local devicons_loaded

  _G.get_winbar = function()
    local ok, value = pcall(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local ft = vim.bo[bufnr].filetype
      local bt = vim.bo[bufnr].buftype
      if bt ~= "" or ft == "" or ft == "dashboard" or ft == "lazy" or ft == "help" or ft:match("snacks") then
        return ""
      end

      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == "" then
        return ""
      end

      if devicons_loaded == nil then
        devicons_loaded, devicons = pcall(require, "nvim-web-devicons")
      end

      local filename = vim.fn.fnamemodify(name, ":t")
      local icon = ""
      if devicons_loaded then
        local file_icon = devicons.get_icon(filename, nil, { default = true })
        icon = file_icon and (file_icon .. " ") or ""
      end
      local modified = vim.bo[bufnr].modified and " ●" or ""
      return "  " .. icon .. filename .. modified
    end)
    return ok and value or ""
  end

  vim.opt.winbar = "%{%v:lua.get_winbar()%}"
end

local map = vim.keymap.set
local mobile = require("util.mobile")

-- Fast Insert-mode escape without changing core Normal-mode commands.
map("i", "jk", "<Esc>", { desc = "Exit Insert mode" })
map("i", "jj", "<Esc>", { desc = "Exit Insert mode" })

-- Mobile entry points. Native q, d, t, U, Ctrl-a and Tab stay untouched.
map("n", "<leader>z", mobile.action_menu, { desc = "Mobile Action Menu" })
map("n", "<leader>h", mobile.show_help, { desc = "C++ Mobile Guide" })
map("n", "<leader>Q", mobile.smart_close, { desc = "Smart Close" })
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorer" })

_G.open_mobile_action_menu = mobile.action_menu
_G.show_cpp_mobile_help = mobile.show_help
vim.api.nvim_create_user_command("MobileActionMenu", mobile.action_menu, {})
vim.api.nvim_create_user_command("MobileHelp", mobile.show_help, {})

-- Keep the selection after indenting.
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

-- Move lines and selected blocks without opening command-line history.
map("n", "<M-Down>", "<cmd>move .+1<cr>==", { silent = true, desc = "Move line down" })
map("n", "<M-Up>", "<cmd>move .-2<cr>==", { silent = true, desc = "Move line up" })
map("i", "<M-Down>", "<Esc><cmd>move .+1<cr>==gi", { silent = true, desc = "Move line down" })
map("i", "<M-Up>", "<Esc><cmd>move .-2<cr>==gi", { silent = true, desc = "Move line up" })
map("x", "<M-Down>", ":move '>+1<cr>gv=gv", { silent = true, desc = "Move selection down" })
map("x", "<M-Up>", ":move '<-2<cr>gv=gv", { silent = true, desc = "Move selection up" })

-- Touch-friendly buffer and window navigation.
map("n", "<M-Left>", "<cmd>bprevious<cr>", { silent = true, desc = "Previous Buffer" })
map("n", "<M-Right>", "<cmd>bnext<cr>", { silent = true, desc = "Next Buffer" })
map("n", "<M-S-Left>", "<C-w>h", { desc = "Window left" })
map("n", "<M-S-Right>", "<C-w>l", { desc = "Window right" })
map("n", "<M-S-Up>", "<C-w>k", { desc = "Window up" })
map("n", "<M-S-Down>", "<C-w>j", { desc = "Window down" })

-- Explicit format shortcut; LazyVim's LSP mappings remain the source of truth.
map({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format File" })

local function diagnostic_jump(count)
  if vim.diagnostic.jump then
    vim.diagnostic.jump({ count = count, float = true })
  elseif count > 0 then
    vim.diagnostic.goto_next({ float = { border = "rounded", source = "always" } })
  else
    vim.diagnostic.goto_prev({ float = { border = "rounded", source = "always" } })
  end
end

map("n", "]d", function()
  diagnostic_jump(1)
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
  diagnostic_jump(-1)
end, { desc = "Previous Diagnostic" })
map("n", "gl", function()
  vim.diagnostic.open_float({ border = "rounded", source = "always" })
end, { desc = "Line Diagnostic" })

map("n", "]t", function()
  local ok, todo = pcall(require, "todo-comments")
  if ok then
    todo.jump_next()
  end
end, { desc = "Next TODO" })
map("n", "[t", function()
  local ok, todo = pcall(require, "todo-comments")
  if ok then
    todo.jump_prev()
  end
end, { desc = "Previous TODO" })

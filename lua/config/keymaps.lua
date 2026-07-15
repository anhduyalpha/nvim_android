local map = vim.keymap.set
local mobile = require("util.mobile")

local function is_explorer_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local ft = vim.bo[buf].filetype
  return ft == "snacks_picker_list" or ft:match("^snacks_explorer") ~= nil or ft:match("^snacks_layout") ~= nil
end

local function find_explorer_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and is_explorer_buffer(vim.api.nvim_win_get_buf(win)) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative == "" then
        return win
      end
    end
  end
end

local function toggle_explorer()
  local win = find_explorer_window()
  if win then
    local ok = pcall(function()
      Snacks.explorer.close()
    end)
    if not ok and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    return
  end
  Snacks.explorer()
end

local function focus_explorer()
  local win = find_explorer_window()
  if win then
    vim.api.nvim_set_current_win(win)
    return
  end

  Snacks.explorer()
  vim.schedule(function()
    local opened = find_explorer_window()
    if opened then
      pcall(vim.api.nvim_set_current_win, opened)
    end
  end)
end

-- Fast Insert-mode escape.
map("i", "jk", "<Esc>", { desc = "Exit Insert mode" })
map("i", "jj", "<Esc>", { desc = "Exit Insert mode" })

-- Optimized touch-first key workflow.
map("n", "q", mobile.smart_close, { silent = true, nowait = true, desc = "Smart Quit" })
map("n", "<C-g>", "q", { silent = true, desc = "Record Macro" })
map("n", "d", "dd", { silent = true, desc = "Delete Line" })
map("n", "D", "d$", { silent = true, desc = "Delete to Line End" })
map("n", "t", toggle_explorer, { silent = true, nowait = true, desc = "Toggle Explorer" })
map("n", "U", focus_explorer, { silent = true, nowait = true, desc = "Focus Explorer" })
map({ "n", "x" }, "<C-a>", "ggVG", { silent = true, desc = "Select All" })
map("n", "<Tab>", ">>", { silent = true, desc = "Indent Line" })
map("n", "<S-Tab>", "<<", { silent = true, desc = "Outdent Line" })
map("x", "<Tab>", ">gv", { silent = true, desc = "Indent Selection" })
map("x", "<S-Tab>", "<gv", { silent = true, desc = "Outdent Selection" })

-- Mobile entry points and discoverable aliases.
map("n", "<leader>z", mobile.action_menu, { desc = "Mobile Action Menu" })
map("n", "<leader>h", mobile.show_help, { desc = "C++ Mobile Guide" })
map("n", "<leader>Q", mobile.smart_close, { desc = "Smart Close" })
map("n", "<leader>e", toggle_explorer, { desc = "Toggle Explorer" })

_G.open_mobile_action_menu = mobile.action_menu
_G.show_cpp_mobile_help = mobile.show_help
vim.api.nvim_create_user_command("MobileActionMenu", mobile.action_menu, {})
vim.api.nvim_create_user_command("MobileHelp", mobile.show_help, {})

-- Keep the selection after indenting with the native operators too.
map("x", "<", "<gv", { desc = "Indent Left" })
map("x", ">", ">gv", { desc = "Indent Right" })

-- Move lines and selected blocks without opening command-line history.
map("n", "<M-Down>", "<cmd>move .+1<cr>==", { silent = true, desc = "Move Line Down" })
map("n", "<M-Up>", "<cmd>move .-2<cr>==", { silent = true, desc = "Move Line Up" })
map("i", "<M-Down>", "<Esc><cmd>move .+1<cr>==gi", { silent = true, desc = "Move Line Down" })
map("i", "<M-Up>", "<Esc><cmd>move .-2<cr>==gi", { silent = true, desc = "Move Line Up" })
map("x", "<M-Down>", ":move '>+1<cr>gv=gv", { silent = true, desc = "Move Selection Down" })
map("x", "<M-Up>", ":move '<-2<cr>gv=gv", { silent = true, desc = "Move Selection Up" })

-- Touch-friendly buffer and window navigation.
map("n", "<M-Left>", "<cmd>bprevious<cr>", { silent = true, desc = "Previous Buffer" })
map("n", "<M-Right>", "<cmd>bnext<cr>", { silent = true, desc = "Next Buffer" })
map("n", "<M-S-Left>", "<C-w>h", { desc = "Window Left" })
map("n", "<M-S-Right>", "<C-w>l", { desc = "Window Right" })
map("n", "<M-S-Up>", "<C-w>k", { desc = "Window Up" })
map("n", "<M-S-Down>", "<C-w>j", { desc = "Window Down" })

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

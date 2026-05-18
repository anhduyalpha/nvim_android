-- ~/.config/nvim/lua/config/keymaps.lua
-- =============================================
--  PHÍM TẮT TÙY CHỈNH - LAZYVIM STARTER
-- =============================================

local map = vim.keymap.set

-- ─────────────────────────────────────────────
--  1. THOÁT NHANH INSERT MODE
--     jk / jj  →  <Esc>
-- ─────────────────────────────────────────────
map("i", "jk", "<Esc>", { desc = "Thoát insert mode (jk)" })
map("i", "jj", "<Esc>", { desc = "Thoát insert mode (jj)" })

-- ─────────────────────────────────────────────
--  2. t  -  ĐÓNG / MỞ SNACKS EXPLORER
--     Nhấn t lần nữa sẽ đóng lại
--     ⚠ Ghi đè Vim `t` motion (till char)
-- ─────────────────────────────────────────────
map("n", "t", function()
  Snacks.explorer()
end, { desc = "Toggle Snacks Explorer" })

-- ─────────────────────────────────────────────
--  3. Shift+U  -  FOCUS VÀO SNACKS EXPLORER
--     Đã mở  → nhảy vào cửa sổ explorer
--     Chưa mở → mở mới rồi focus
--     ⚠ Ghi đè Vim `U` (undo line)
-- ─────────────────────────────────────────────
map("n", "U", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if ft:match("snacks") then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  -- Chưa mở → mở mới
  Snacks.explorer()
end, { desc = "Focus Snacks Explorer" })

-- ─────────────────────────────────────────────
--  4. q  -  UNIVERSAL QUIT
--     Ưu tiên: floating → special buf → buffer → quit
--     ⚠ Ghi đè Vim `q` (macro recording)
--        Ghi macro bằng @ hoặc dùng <leader>q nếu cần
-- ─────────────────────────────────────────────

-- Danh sách filetype/buftype đặc biệt → chỉ cần nhấn q để đóng
local closeable_ft = {
  "help",
  "man",
  "qf",
  "lspinfo",
  "notify",
  "snacks_notif",
  "snacks_win",
  "lazy",
  "mason",
  "checkhealth",
  "startuptime",
  "Trouble",
  "trouble",
  "neotest-summary",
  "neotest-output-panel",
}

local closeable_bt = {
  "help",
  "quickfix",
  "nofile",
  "terminal",
}

local function is_closeable()
  local ft = vim.bo.filetype
  local bt = vim.bo.buftype

  for _, v in ipairs(closeable_ft) do
    if ft == v or ft:match(v) then
      return true
    end
  end
  for _, v in ipairs(closeable_bt) do
    if bt == v then
      return true
    end
  end
  return false
end

map("n", "q", function()
  -- ① Đóng cửa sổ floating (notification, preview, etc.)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, config = pcall(vim.api.nvim_win_get_config, win)
    if ok and config.relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
      return
    end
  end

  -- ② Dismiss Snacks notifier (nếu có)
  pcall(function()
    Snacks.notifier.hide()
  end)

  -- ③ Đóng buffer đặc biệt (help, man, quickfix, lsp, etc.)
  if is_closeable() then
    vim.cmd("close")
    return
  end

  -- ④ Đóng buffer thường
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  if #listed > 1 then
    vim.cmd("bdelete")
  else
    vim.cmd("q")
  end
end, { desc = "Universal Quit" })

-- ─────────────────────────────────────────────
--  5. d  -  UNIVERSAL DELETE
--     normal mode: d → xóa cả dòng
--     visual mode: d → xóa vùng chọn
--     ⚠ Mất native Vim d operator (dw, d$, dip...)
--        Nếu cần d operator gốc, dùng gc hoặc remap lại
-- ─────────────────────────────────────────────
map("n", "d", "dd", { noremap = true, silent = true, desc = "Delete line" })
map("n", "D", "d$", { noremap = true, silent = true, desc = "Delete to end of line" })
map("v", "d", "d", { noremap = true, silent = true, desc = "Delete selection" })

-- ─────────────────────────────────────────────
--  BONUS: Bật lại macro recording cho ai cần
--     Nhấn Ctrl+q để ghi macro (thay cho q cũ)
-- ─────────────────────────────────────────────
map("n", "<C-q>", "q", { noremap = true, silent = true, desc = "Record macro" })

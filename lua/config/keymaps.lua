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

-- Hàm kiểm tra buffer đặc biệt có thể đóng nhanh (ngoại trừ Snacks Explorer)
local function is_closeable()
  local ft = vim.bo.filetype
  local bt = vim.bo.buftype

  -- Không đóng Snacks Explorer thông qua danh sách đóng nhanh này để xử lý riêng biệt
  -- Snacks Explorer thực tế sử dụng filetype snacks_picker_list vì bản chất là picker
  if ft == "snacks_picker_list" or ft:match("snacks_layout") or ft:match("snacks_explorer") then
    return false
  end

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

-- Lấy danh sách buffer thường (đang load, listed, không phải snacks/dashboard/etc.)
local function get_normal_buffers()
  local normal_bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local bt = vim.bo[buf].buftype
      local ft = vim.bo[buf].filetype
      -- Buffer thường: buftype rỗng, không phải snacks, dashboard, alpha
      if bt == "" and ft ~= "dashboard" and ft ~= "alpha" and ft ~= "snacks_picker_list" and not ft:match("snacks") then
        table.insert(normal_bufs, buf)
      end
    end
  end
  return normal_bufs
end

-- Lấy window đang hiển thị Snacks Explorer (chỉ tính window dạng sidebar/split thường, không tính dạng floating)
local function get_snacks_explorer_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      local config = vim.api.nvim_win_get_config(win)
      if (ft == "snacks_picker_list" or ft:match("snacks_layout") or ft:match("snacks_explorer"))
         and config.relative == "" then
        return win
      end
    end
  end
  return nil
end

local function universal_quit()
  -- ① Đóng cửa sổ floating (notification, picker dạng floating, preview, etc.)
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

  -- ③ Đóng buffer đặc biệt (help, man, quickfix, lsp, v.v. ngoại trừ Snacks Explorer)
  if is_closeable() then
    vim.cmd("close")
    return
  end

  -- ④ Đóng buffer thường hoặc Snacks Explorer theo thứ tự ưu tiên
  local explorer_win = get_snacks_explorer_win()
  local normal_bufs = get_normal_buffers()

  if explorer_win and #normal_bufs > 0 then
    -- Snacks Explorer và buffer thường đang mở đồng thời
    local cur_win = vim.api.nvim_get_current_win()
    if cur_win == explorer_win then
      -- Nếu đang focus ở Snacks Explorer: tự động focus sang window buffer thường trước khi xóa
      local target_win = nil
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= explorer_win and vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local bt = vim.bo[buf].buftype
          local ft = vim.bo[buf].filetype
          if bt == "" and ft ~= "dashboard" and ft ~= "alpha" and ft ~= "snacks_picker_list" and not ft:match("snacks") then
            target_win = win
            break
          end
        end
      end
      if target_win then
        vim.api.nvim_set_current_win(target_win)
      end
    end

    -- Xóa buffer thường đang hiển thị
    if #normal_bufs > 1 then
      vim.cmd("bdelete")
    else
      -- Chỉ còn 1 buffer thường: xóa buffer thường
      local cur_buf = vim.api.nvim_get_current_buf()
      local modified = vim.bo[cur_buf].modified
      vim.cmd("bdelete")
      -- Nếu bdelete thành công (không bị chặn do chưa lưu file) thì đóng cửa sổ thường đó để chỉ còn lại sidebar explorer
      if not modified and #vim.api.nvim_list_wins() > 1 then
        pcall(vim.cmd, "close")
      end
    end
  else
    -- Không có sự kết hợp đồng thời (hoặc chỉ có explorer, hoặc chỉ có buffer thường)
    local listed = vim.fn.getbufinfo({ buflisted = 1 })
    if #listed > 1 then
      vim.cmd("bdelete")
    else
      vim.cmd("q")
    end
  end
end

local function save_and_close_buffer()
  -- ① Đóng cửa sổ floating trước (nếu có)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, config = pcall(vim.api.nvim_win_get_config, win)
    if ok and config.relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
      return
    end
  end

  -- ② Nếu là buffer đặc biệt (help, man, quickfix, lsp, etc.) thì đóng nhanh
  if is_closeable() then
    pcall(vim.cmd, "close")
    return
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[cur_buf].filetype
  local bt = vim.bo[cur_buf].buftype

  -- Không đóng Snacks Explorer trực tiếp ở đây
  if ft == "snacks_picker_list" or ft:match("snacks_layout") or ft:match("snacks_explorer") then
    pcall(function()
      Snacks.explorer.close()
    end)
    return
  end

  -- ③ Nếu là buffer thường (buftype rỗng) thì tự động lưu nếu có thay đổi và đóng buffer
  if bt == "" and ft ~= "dashboard" and ft ~= "alpha" then
    if vim.bo[cur_buf].modified then
      pcall(vim.cmd, "write")
    end
    pcall(vim.cmd, "bdelete")
  else
    pcall(vim.cmd, "bdelete")
  end
end

map("n", "q", universal_quit, { desc = "Universal Quit (Prioritized buffers before Snacks Explorer)" })
map("n", "<C-q>", save_and_close_buffer, { desc = "Save and Close Buffer" })
map("n", "<C-x>", "<cmd>close<cr>", { noremap = true, silent = true, desc = "Close active window" })

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

map("n", "<C-g>", "q", { noremap = true, silent = true, desc = "Record macro (C-g)" })

-- ─────────────────────────────────────────────
--  6. TỐI ƯU HÓA THAO TÁC SOẠN THẢO VÀ CHỌN (Normal/Visual Mode)
-- ─────────────────────────────────────────────
-- Chọn tất cả (Select All) bằng Ctrl+a trong Normal và Visual (x) Mode
map({ "n", "x" }, "<C-a>", "ggVG", { desc = "Select All" })

-- Giữ nguyên vùng chọn Visual khi dùng lệnh thụt lề (< và >)
map("x", "<", "<gv", { desc = "Thụt lề trái (giữ vùng chọn)" })
map("x", ">", ">gv", { desc = "Thụt lề phải (giữ vùng chọn)" })

-- Thụt lề nhanh bằng Tab / Shift-Tab trong Normal và Visual (x) Mode
map("n", "<Tab>", ">>", { noremap = true, silent = true, desc = "Indent line" })
map("n", "<S-Tab>", "<<", { noremap = true, silent = true, desc = "De-indent line" })
map("x", "<Tab>", ">gv", { noremap = true, silent = true, desc = "Indent block (keep selection)" })
map("x", "<S-Tab>", "<gv", { noremap = true, silent = true, desc = "De-indent block (keep selection)" })

-- ─────────────────────────────────────────────
--  7. HỖ TRỢ DI CHUYỂN CỬA SỔ (Alt+Shift+Arrows)
-- ─────────────────────────────────────────────
map("n", "<M-S-Left>", "<C-w>h", { desc = "Navigate to left window" })
map("n", "<M-S-Right>", "<C-w>l", { desc = "Navigate to right window" })
map("n", "<M-S-Up>", "<C-w>k", { desc = "Navigate to upper window" })
map("n", "<M-S-Down>", "<C-w>j", { desc = "Navigate to lower window" })

-- ─────────────────────────────────────────────
--  8. DI CHUYỂN DÒNG & KHỐI CODE (Alt+Up/Down)
-- ─────────────────────────────────────────────
map("n", "<M-Down>", "<cmd>silent! m .+1<cr>==", { desc = "Move line down" })
map("n", "<M-Up>", "<cmd>silent! m .-2<cr>==", { desc = "Move line up" })
map("i", "<M-Down>", "<esc><cmd>silent! m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<M-Up>", "<esc><cmd>silent! m .-2<cr>==gi", { desc = "Move line up" })
map("x", "<M-Down>", ":silent! m '>+1<cr>gv=gv", { desc = "Move block down" })
map("x", "<M-Up>", ":silent! m '<-2<cr>gv=gv", { desc = "Move block up" })

-- ─────────────────────────────────────────────
--  9. LSP NAVIGATIONS (gd, gr, K, etc.) - Tự động kích hoạt khi có LSP
-- ─────────────────────────────────────────────
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserGlobalLspConfig", { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    
    -- gd: Đi tới định nghĩa (Goto Definition)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "LSP: Goto Definition" }))
    
    -- gD: Đi tới khai báo (Goto Declaration)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "LSP: Goto Declaration" }))
    
    -- gr: Tìm các tham chiếu (Goto References)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "LSP: Goto References" }))
    
    -- gI: Đi tới triển khai (Goto Implementation)
    vim.keymap.set("n", "gI", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "LSP: Goto Implementation" }))
    
    -- gy: Đi tới định nghĩa kiểu (Goto Type Definition)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "LSP: Goto Type Definition" }))
    
    -- K: Hiển thị tài liệu/hover (Hover Documentation)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP: Hover Documentation" }))
    
    -- gK: Hiển thị chữ ký hàm (Signature Help)
    vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP: Signature Help" }))
    
    -- <leader>ca: Code Action
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP: Code Action" }))
    
    -- <leader>cr: Rename Symbol
    vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP: Rename Symbol" }))
  end,
})

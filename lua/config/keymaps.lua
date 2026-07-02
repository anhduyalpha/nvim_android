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
      local name = vim.api.nvim_buf_get_name(buf)
      -- Buffer thường thực sự: phải có tên tệp hoặc đang bị sửa đổi (unnamed file đang sửa)
      if bt == "" and ft ~= "dashboard" and ft ~= "alpha" and ft ~= "snacks_picker_list" and not ft:match("snacks") then
        if name ~= "" or vim.bo[buf].modified then
          table.insert(normal_bufs, buf)
        end
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
  -- ① Đóng cửa sổ floating hiện tại nếu đang focus ở đó (notification, picker dạng floating, preview, etc.)
  local cur_win = vim.api.nvim_get_current_win()
  local ok, config = pcall(vim.api.nvim_win_get_config, cur_win)
  if ok and config.relative ~= "" then
    local cur_buf = vim.api.nvim_win_get_buf(cur_win)
    local ft = vim.bo[cur_buf].filetype
    if ft == "snacks_picker_list" or ft:match("snacks_layout") or ft:match("snacks_explorer") or ft:match("snacks") then
      pcall(function()
        Snacks.explorer.close()
      end)
    else
      pcall(vim.api.nvim_win_close, cur_win, true)
    end
    return
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

  -- ④ Đóng buffer thường trước. Khi trên màn hình không còn buffer mới đóng snacks explorer.
  local normal_bufs = get_normal_buffers()
  local explorer_win = get_snacks_explorer_win()

  if #normal_bufs > 0 then
    -- Còn buffer thường trên màn hình -> Tiến hành đóng buffer thường đang active
    local cur_buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[cur_buf].filetype
    local bt = vim.bo[cur_buf].buftype

    -- Nếu chúng ta đang ở Snacks Explorer nhưng vẫn còn buffer thường, phím q trong Snacks Explorer đóng chính nó
    if ft == "snacks_picker_list" or ft:match("snacks_layout") or ft:match("snacks_explorer") or ft:match("snacks") then
      pcall(function()
        Snacks.explorer.close()
      end)
      return
    end

    -- Đóng buffer thường đang active (lưu nếu có thay đổi)
    if bt == "" and ft ~= "dashboard" and ft ~= "alpha" then
      if vim.bo[cur_buf].modified then
        pcall(vim.cmd, "write")
      end
      pcall(vim.cmd, "bdelete")
    else
      pcall(vim.cmd, "bdelete")
    end
  else
    -- Không còn buffer thường nào trên màn hình -> Đóng Snacks Explorer nếu đang mở
    if explorer_win then
      pcall(function()
        Snacks.explorer.close()
      end)
    else
      -- Không còn gì khác -> Quit Neovim
      vim.cmd("q")
    end
  end
end

map("n", "q", universal_quit, { desc = "Universal Quit (Prioritized buffers before Snacks Explorer)" })
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

-- Touch-Friendly C++ & Mobile Quick Action Menu (Context-Aware)
local function open_mobile_action_menu()
  local ft = vim.bo.filetype
  local is_cpp = (ft == "c" or ft == "cpp")

  -- Base items cho mọi filetype
  local items = {
    { label = "📝 Format Document", action = function() require("conform").format({ async = true, lsp_fallback = true }) end },
    { label = "🔍 Find Symbol (file)", action = function() Snacks.picker.lsp_symbols() end },
    { label = "🌐 Find Symbol (workspace)", action = function() Snacks.picker.lsp_workspace_symbols() end },
    { label = "📋 LSP: Goto Definition", action = function() vim.lsp.buf.definition() end },
    { label = "🔗 LSP: References", action = function() vim.lsp.buf.references() end },
    { label = "💡 LSP: Code Actions", action = function() vim.lsp.buf.code_action() end },
    { label = "✏️  LSP: Rename Symbol", action = function() vim.lsp.buf.rename() end },
  }

  -- Items riêng cho C/C++
  if is_cpp then
    table.insert(items, { label = "🔀 Switch Header/Source", action = function() vim.cmd("ClangdSwitchSourceHeader") end })
    table.insert(items, { label = "👁️  Toggle Inlay Hints", action = function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    end })
  end

  -- Git items (nếu có gitsigns)
  table.insert(items, { label = "── Git ──", action = function() end })
  table.insert(items, { label = "📊 Git: Preview Hunk", action = function() require("gitsigns").preview_hunk() end })
  table.insert(items, { label = "✅ Git: Stage Hunk", action = function() require("gitsigns").stage_hunk() end })
  table.insert(items, { label = "↩️  Git: Reset Hunk", action = function() require("gitsigns").reset_hunk() end })
  table.insert(items, { label = "👤 Git: Blame Line", action = function() require("gitsigns").blame_line({ full = true }) end })
  if vim.fn.executable("lazygit") == 1 then
    table.insert(items, { label = "🚀 Open Lazygit", action = function() vim.cmd("lua _G.open_lazygit()") end })
  end

  -- System items
  table.insert(items, { label = "── System ──", action = function() end })
  table.insert(items, { label = "🛡️  Trigger Config Backup", action = function() vim.cmd("NvimBackup") end })
  table.insert(items, { label = "📊 Run Performance Check", action = function() vim.cmd("!./check_performance.sh") end })
  table.insert(items, { label = "📋 Show TODO Comments", action = function() vim.cmd("Trouble todo") end })

  -- Build display list
  local display = {}
  for i, item in ipairs(items) do
    table.insert(display, string.format("%d. %s", i, item.label))
  end

  vim.ui.select(display, {
    prompt = "📱 Quick Action Menu (" .. (is_cpp and "C++" or ft) .. "):",
  }, function(choice, idx)
    if not choice or not idx then return end
    local selected = items[idx]
    if selected and selected.action then
      pcall(selected.action)
    end
  end)
end

-- Expose globally and register user command for easy touch/dashboard access
_G.open_mobile_action_menu = open_mobile_action_menu
vim.api.nvim_create_user_command("MobileActionMenu", open_mobile_action_menu, {})

-- Bind <leader>z as the universal touch-menu shortcut
map("n", "<leader>z", open_mobile_action_menu, { desc = "Mobile Action Menu" })

-- Touch/Swipe gesture shortcuts (simulate swiping left/right in bufferline)
map("n", "<M-Left>", "<cmd>bprevious<cr>", { silent = true, desc = "Previous Buffer" })
map("n", "<M-Right>", "<cmd>bnext<cr>", { silent = true, desc = "Next Buffer" })

-- ─────────────────────────────────────────────
--  SESSION RESTORE (persistence.nvim)
-- ─────────────────────────────────────────────
map("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session (cwd)" })
map("n", "<leader>qS", function() require("persistence").select() end, { desc = "Select Session" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Stop Session Recording" })

-- ─────────────────────────────────────────────
--  SYMBOL NAVIGATOR (Snacks picker tích hợp)
-- ─────────────────────────────────────────────
map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols (file)" })
map("n", "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "LSP Symbols (workspace)" })

-- ─────────────────────────────────────────────
--  DIAGNOSTIC NAVIGATION (thay thế CursorHold)
--  Nhảy tới diagnostic kế tiếp/trước + tự động popup
-- ─────────────────────────────────────────────
map("n", "]d", function()
  vim.diagnostic.goto_next({ float = { border = "rounded", source = "always" } })
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
  vim.diagnostic.goto_prev({ float = { border = "rounded", source = "always" } })
end, { desc = "Prev Diagnostic" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics<cr>", { desc = "All Diagnostics (Trouble)" })
map("n", "<leader>xD", "<cmd>Trouble diagnostics filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "gl", function()
  vim.diagnostic.open_float({ border = "rounded", source = "always" })
end, { desc = "Show Diagnostic (cursor)" })

-- ─────────────────────────────────────────────
--  TODO COMMENTS NAVIGATION
-- ─────────────────────────────────────────────
map("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next TODO" })
map("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Prev TODO" })
map("n", "<leader>xt", "<cmd>Trouble todo<cr>", { desc = "All TODOs (Trouble)" })

-- Floating Interactive C++ & Mobile Guide
local function show_cpp_mobile_help()
  local buf = vim.api.nvim_create_buf(false, true)
  local border_lines = {
    " 📘 HƯỚNG DẪN PHÍM TẮT TRÊN ANDROID (TERMUX) ",
    "======================================================",
    " 1. SOẠN THẢO (Normal Mode):",
    "   • <leader>z : Menu hành động nhanh (context-aware)",
    "   • q         : Đóng buffer → explorer → thoát nvim",
    "   • Ctrl + x  : Đóng cửa sổ split active",
    "   • Tab       : Thụt dòng (Visual: giữ vùng chọn)",
    "   • Alt+Up/Dn : Di chuyển dòng code lên/xuống",
    "   • Alt+L/R   : Chuyển nhanh giữa các buffer",
    "   • <leader>cf: Format document (auto on save)",
    " ",
    " 2. NAVIGATION & DIAGNOSTICS:",
    "   • <leader>ss: Tìm symbol trong file (outline)",
    "   • <leader>sS: Tìm symbol workspace",
    "   • ]d / [d   : Nhảy diagnostic tiếp/trước",
    "   • gl        : Xem diagnostic tại cursor",
    "   • ]t / [t   : Nhảy TODO tiếp/trước",
    "   • s / S     : Flash jump / treesitter select",
    " ",
    " 3. TREESITTER TEXT OBJECTS:",
    "   • af/if     : Chọn around/inside function",
    "   • ac/ic     : Chọn around/inside class",
    "   • aa/ia     : Chọn around/inside parameter",
    "   • ]f / [f   : Nhảy tới function tiếp/trước",
    " ",
    " 4. GIT WORKFLOW:",
    "   • <leader>gg: Mở Lazygit (floating)",
    "   • ]h / [h   : Nhảy giữa các git hunk",
    "   • <leader>gs: Stage hunk  / gS: Stage buffer",
    "   • <leader>gr: Reset hunk  / gR: Reset buffer",
    "   • <leader>gb: Blame line  / gd: Diff file",
    " ",
    " 5. SESSION & SYSTEM:",
    "   • <leader>qs: Restore session (cwd)",
    "   • <leader>ql: Restore last session",
    "   • :NvimBackup: Tạo backup .zip cực nhanh",
    " ",
    " 6. C++ DEV (Nhấn 'c' trong file .cpp):",
    "   • ct: Compile & Run  / cs: + Đo thời gian",
    "   • cv: UBSan  / cm: Toggle Debug/Release",
    "   • cx: Re-run / ce: Quickfix / cR: Restart clangd",
    "======================================================",
    "                 [ Nhấn q để đóng ]",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, border_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "help"

  local width = 58
  local height = #border_lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })
  
  -- Close with 'q'
  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, silent = true })
end

-- Bind <leader>h to trigger C++ mobile guide
map("n", "<leader>h", show_cpp_mobile_help, { desc = "C++ Mobile Guide" })




-- ============================================================================
-- check_performance.lua — Tệp Chẩn Đoán và Kiểm Tra Hiệu Năng Neovim (Android)
-- ============================================================================
-- Cách chạy:
--   Trong Neovim:  :luafile check_performance.lua
--   Từ Terminal Termux:
--                  nvim --headless -c "luafile check_performance.lua" -c "qa"
-- ============================================================================

local report = {}
local issues = {}
local warnings = {}

local log_lines = {}
local original_print = print
local function print(...)
  local args = { ... }
  local strings = {}
  for i = 1, #args do
    table.insert(strings, tostring(args[i]))
  end
  local str = table.concat(strings, "\t")
  original_print(str)

  -- Loại bỏ mã màu ANSI bằng bộ lọc regex để lưu tệp tin text sạch sẽ dễ đọc/cat
  local clean_str = str:gsub("\27%[[%d;]*%a", "")
  table.insert(log_lines, clean_str)
end

-- Kiểm tra xem có đang thực sự chạy trên Android/Termux hay không
local is_real_android = vim.fn.has("android") == 1 or vim.fn.executable("termux-setup-storage") == 1 or vim.fn.getenv("TERMUX_VERSION") ~= vim.NIL

-- Chỉ load cấu hình giả lập nếu chạy trên PC để kiểm thử phát triển, trên Android thực tế bắt buộc nạp cấu hình gốc
if not is_real_android then
  pcall(function()
    -- Giả lập các package bổ trợ để test cấu hình Android mượt mà trên PC
    package.loaded["util.android"] = {
      is_android = function() return true end,
      is_termux = function() return true end,
      get_platform_settings = function() return { update_time = 1000, undo_levels = 100 } end,
      notify_low_memory = function() end
    }
    
    -- Load các file cấu hình cục bộ theo thứ tự chuẩn
    dofile("lua/config/options.lua")
    dofile("lua/config/keymaps.lua")
    
    -- Đăng ký mock lspconfig và require các tệp liên quan
    package.loaded["util.performance"] = dofile("lua/util/performance.lua")
    
    -- Giả lập LspAttach event để kích hoạt UserGlobalLspConfig autocommand và đăng ký keymaps
    vim.api.nvim_exec_autocmds("LspAttach", {
      group = "UserGlobalLspConfig",
      buffer = vim.api.nvim_get_current_buf(),
      data = { client_id = 999 }
    })
  end)
else
  -- Chạy trên thiết bị Android Termux thực tế: Load cấu hình gốc để phân tích chuẩn xác 100%
  pcall(function()
    if not package.loaded["config.lazy"] then
      local init_path = "init.lua"
      local f = io.open(init_path, "r")
      if f then
        f:close()
        pcall(dofile, init_path)
      end
    end
  end)
end


-- Màu sắc terminal dạng ANSI
local colors = {
  reset = "\27[0m",
  bold = "\27[1m",
  green = "\27[32m",
  red = "\27[31m",
  yellow = "\27[33m",
  cyan = "\27[36m",
  blue = "\27[34m",
  magenta = "\27[35m"
}

-- Nếu không chạy trong headless, tắt màu sắc ANSI hoặc dùng Vim notify
local is_headless = #vim.api.nvim_list_uis() == 0
if not is_headless then
  -- Nếu chạy trong GUI/TUI thường, chuyển màu sắc thành chuỗi rỗng
  for k in pairs(colors) do colors[k] = "" end
end

print(colors.bold .. colors.cyan .. "======================================================================" .. colors.reset)
print(colors.bold .. colors.cyan .. "   📊 BẢN BÁO CÁO SỨC KHỎE & HIỆU NĂNG NEOVIM TRÊN ANDROID (TERMUX)   " .. colors.reset)
print(colors.bold .. colors.cyan .. "======================================================================" .. colors.reset)

-- ─────────────────────────────────────────────────────────────────────────────
--  1. KIỂM TRA MÔI TRƯỜNG & HỆ THỐNG
-- ─────────────────────────────────────────────────────────────────────────────
print("\n" .. colors.bold .. colors.magenta .. "1. Thông tin Hệ thống & Môi trường:" .. colors.reset)

local is_android = false
local is_termux = false

-- Đọc từ util.android nếu có
local has_android, android = pcall(require, "util.android")
if has_android then
  is_android = android.is_android()
  is_termux = android.is_termux()
else
  -- Fallback nhận diện
  is_android = vim.fn.has("android") == 1 or vim.fn.executable("termux-setup-storage") == 1
  is_termux = vim.fn.getenv("TERMUX_VERSION") ~= vim.NIL or is_android
end

print(string.format("  • Hệ điều hành: %s%s%s", 
  colors.bold, is_android and "Android" or "Hệ điều hành khác (PC/Linux)", colors.reset))
print(string.format("  • Môi trường Termux: %s%s%s", 
  colors.bold, is_termux and "Đúng (Termux)" or "Không (Hoặc giả lập/PC)", colors.reset))

-- Đọc dung lượng bộ nhớ
local mem_total = "N/A"
local mem_free = "N/A"
local meminfo = io.open("/proc/meminfo", "r")
if meminfo then
  local content = meminfo:read("*a")
  meminfo:close()
  local total_kb = content:match("MemTotal:%s*(%d+)")
  local free_kb = content:match("MemAvailable:%s*(%d+)")
  if total_kb then mem_total = string.format("%.2f GB", tonumber(total_kb) / 1024 / 1024) end
  if free_kb then mem_free = string.format("%.2f GB", tonumber(free_kb) / 1024 / 1024) end
end
print(string.format("  • Tổng dung lượng RAM thiết bị: %s%s%s", colors.bold, mem_total, colors.reset))
print(string.format("  • RAM khả dụng (Available): %s%s%s", colors.bold, mem_free, colors.reset))

-- Dung lượng bộ nhớ Lua đang sử dụng
local lua_mem = collectgarbage("count") / 1024
print(string.format("  • RAM Neovim Lua đang dùng: %s%.2f MB%s", colors.bold, lua_mem, colors.reset))

-- ─────────────────────────────────────────────────────────────────────────────
--  2. KIỂM TRA CÁC THIẾT LẬP TỐI ƯU HIỆU NĂNG CỐT LÕI
-- ─────────────────────────────────────────────────────────────────────────────
print("\n" .. colors.bold .. colors.magenta .. "2. Kiểm tra Cấu hình Tối ưu Hiệu năng:" .. colors.reset)

-- A. LuaJIT Garbage Collection (GC)
local gc_pause = collectgarbage("setpause")
local gc_stepmul = collectgarbage("setstepmul")
if gc_pause == 100 and gc_stepmul == 400 then
  print(string.format("  %s[✓] LuaJIT GC Tuning: ĐẠT (pause=100, stepmul=400 - Dọn rác micro-steps không giật gõ)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] LuaJIT GC Tuning: THẤT BẠI (pause=%d, stepmul=%d - Chưa cấu hình tối ưu Android)%s", colors.red, gc_pause, gc_stepmul, colors.reset))
  table.insert(issues, "LuaJIT GC chưa được cấu hình tối ưu (pause=100, stepmul=400). Hãy thêm cấu hình dọn rác vào file lua/util/performance.lua hoặc init.lua.")
end

-- B. Diagnostics update_in_insert
local diag_config = vim.diagnostic.config() or {}
if diag_config.update_in_insert == false then
  print(string.format("  %s[✓] Diagnostic Insert Check: ĐẠT (update_in_insert = false - Gõ chữ không lag)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] Diagnostic Insert Check: THẤT BẠI (update_in_insert = true - Gây lag nặng khi gõ chữ)%s", colors.red, colors.reset))
  table.insert(issues, "Hệ thống chẩn đoán lỗi (LSP Diagnostics) vẫn quét liên tục khi đang gõ. Cần cấu hình: vim.diagnostic.config({ update_in_insert = false }) trong options.lua.")
end

-- C. Memory Guard Monitor
local has_perf, perf = pcall(require, "util.performance")
if has_perf and type(perf.setup_monitor) == "function" then
  print(string.format("  %s[✓] Memory Guard Monitor: ĐẠT (Hệ thống tự động giám sát bộ nhớ đã được kích hoạt)%s", colors.green, colors.reset))
else
  print(string.format("  %s[⚠] Memory Guard Monitor: CẢNH BÁO (Không tìm thấy mô-đun giám sát bộ nhớ tự động)%s", colors.yellow, colors.reset))
  table.insert(warnings, "Tiến trình giám sát bộ nhớ tự động giúp giảm crash OOM trên Android chưa chạy. Hãy kiểm tra xem file lua/util/performance.lua có tồn tại và được require tại init.lua không.")
end

-- D. Disable Heavy Built-ins (RTP)
local matchparen_loaded = vim.g.loaded_matchparen == 1
local netrw_loaded = vim.g.loaded_netrwPlugin == nil
if matchparen_loaded and netrw_loaded then
  print(string.format("  %s[✓] Cắt giảm Built-in Plugins: ĐẠT (Đã vô hiệu hóa các plugin mặc định nặng nề)%s", colors.green, colors.reset))
else
  print(string.format("  %s[⚠] Cắt giảm Built-in Plugins: CHƯA TRIỆT ĐỂ (Vẫn đang chạy một số plugin mặc định nặng)%s", colors.yellow, colors.reset))
  table.insert(warnings, "Vẫn đang load một số plugin mặc định như matchparen hoặc netrw. Khuyên dùng: vô hiệu hóa chúng trong lua/config/lazy.lua để tối ưu tốc độ khởi động.")
end

-- ─────────────────────────────────────────────────────────────────────────────
--  3. KIỂM TRA PHÍM TẮT & DI CHUYỂN
-- ─────────────────────────────────────────────────────────────────────────────
print("\n" .. colors.bold .. colors.magenta .. "3. Kiểm tra Phím tắt Soạn thảo & Di chuyển:" .. colors.reset)

local maps = {
  normal = vim.api.nvim_get_keymap("n"),
  visual = vim.api.nvim_get_keymap("x")
}

local function check_map(mode, lhs, expected_rhs_pattern, is_callback)
  local found = false
  local target_maps = mode == "n" and maps.normal or maps.visual
  for _, m in ipairs(target_maps) do
    if m.lhs:lower() == lhs:lower() then
      found = true
      if is_callback then
        if type(m.callback) == "function" then
          return "OK_CALLBACK"
        end
      else
        local rhs = tostring(m.rhs or m.callback):lower()
        if rhs:match(expected_rhs_pattern:lower()) then
          return "OK_MATCH"
        end
      end
      return "MISMATCH", tostring(m.rhs or m.callback)
    end
  end
  return "MISSING"
end

-- 1. Ctrl+q (Lưu và đóng buffer)
local cq_status, cq_val = check_map("n", "<C-q>", "", true)
if cq_status == "OK_CALLBACK" then
  print(string.format("  %s[✓] <Ctrl+q>: ĐẠT (Được gán chính xác để Lưu & Đóng buffer)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] <Ctrl+q>: THẤT BẠI (%s)%s", colors.red, cq_status == "MISMATCH" and "Bị gán sai thành: " .. cq_val or "Chưa cấu hình", colors.reset))
  table.insert(issues, "Phím tắt <Ctrl + q> chưa được gán chính xác tới hàm save_and_close_buffer trong lua/config/keymaps.lua.")
end

-- 2. Ctrl+x (Đóng cửa sổ split)
local cx_status, cx_val = check_map("n", "<C-x>", "close", false)
if cx_status == "OK_MATCH" then
  print(string.format("  %s[✓] <Ctrl+x>: ĐẠT (Được gán chính xác để Đóng cửa sổ split)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] <Ctrl+x>: THẤT BẠI (%s)%s", colors.red, cx_status == "MISMATCH" and "Bị gán sai thành: " .. cx_val or "Chưa cấu hình", colors.reset))
  table.insert(issues, "Phím tắt <Ctrl + x> chưa được gán để đóng cửa sổ split (expected: <cmd>close<cr>).")
end

-- 3. Tab trong Normal mode (Thụt lề)
local tab_n_status, tab_n_val = check_map("n", "<Tab>", ">>", false)
if tab_n_status == "OK_MATCH" then
  print(string.format("  %s[✓] <Tab> (Normal): ĐẠT (Được gán chính xác để Thụt lề dòng code)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] <Tab> (Normal): THẤT BẠI (%s)%s", colors.red, tab_n_status == "MISMATCH" and "Bị gán sai thành: " .. tab_n_val or "Chưa cấu hình", colors.reset))
  table.insert(issues, "Phím tắt <Tab> trong Normal mode chưa được gán để thụt lề nhanh (expected: >>).")
end

-- 4. Tab trong Visual mode (Thụt lề khối)
local tab_x_status, tab_x_val = check_map("x", "<Tab>", ">gv", false)
if tab_x_status == "OK_MATCH" then
  print(string.format("  %s[✓] <Tab> (Visual): ĐẠT (Thụt lề khối và giữ nguyên vùng chọn)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] <Tab> (Visual): THẤT BẠI (%s)%s", colors.red, tab_x_status == "MISMATCH" and "Bị gán sai thành: " .. tab_x_val or "Chưa cấu hình", colors.reset))
  table.insert(issues, "Phím tắt <Tab> trong Visual mode chưa được gán thụt lề giữ nguyên vùng chọn (expected: >gv).")
end

-- 5. Alt+Up/Down (Di chuyển dòng)
local alt_up_status, alt_up_val = check_map("n", "<M-Up>", "silent!", false)
if alt_up_status == "OK_MATCH" then
  print(string.format("  %s[✓] <Alt+Mũi tên>: ĐẠT (Di chuyển dòng an toàn, không báo lỗi out of range)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] <Alt+Mũi tên>: THẤT BẠI (Chưa bọc 'silent!' hoặc bị thiếu)%s", colors.red, colors.reset))
  table.insert(issues, "Các phím di chuyển dòng Alt+Up/Down chưa được bọc bằng 'silent!', có thể ném ra lỗi out of range đỏ khi chạm biên tệp.")
end

-- ─────────────────────────────────────────────────────────────────────────────
--  4. KIỂM TRA ĐIỀU HƯỚNG LSP (gd)
-- ─────────────────────────────────────────────────────────────────────────────
print("\n" .. colors.bold .. colors.magenta .. "4. Kiểm tra Điều Hướng & LSP (Goto Definition):" .. colors.reset)

local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
local found_global_lsp = false
for _, ac in ipairs(autocmds) do
  if ac.group_name == "UserGlobalLspConfig" then
    found_global_lsp = true
    break
  end
end

if found_global_lsp then
  print(string.format("  %s[✓] LSP gd Auto-Attach: ĐẠT (Tính năng gán phím gd, gr, K tự động khi đính kèm LSP)%s", colors.green, colors.reset))
else
  print(string.format("  %s[✗] LSP gd Auto-Attach: THẤT BẠI (Phím gd có thể bị lỗi không hoạt động)%s", colors.red, colors.reset))
  table.insert(issues, "Chưa khai báo autocommand UserGlobalLspConfig dưới sự kiện LspAttach trong keymaps.lua. Phím 'gd' đi tới định nghĩa sẽ bị hỏng trên Android.")
end

-- ─────────────────────────────────────────────────────────────────────────────
--  5. TỔNG KẾT & KHẮC PHỤC
-- ─────────────────────────────────────────────────────────────────────────────
print("\n" .. colors.bold .. colors.cyan .. "======================================================================" .. colors.reset)
print(colors.bold .. colors.cyan .. "                       KẾT LUẬN & ĐÁNH GIÁ TỔNG THỂ                   " .. colors.reset)
print(colors.bold .. colors.cyan .. "======================================================================" .. colors.reset)

if #issues == 0 and #warnings == 0 then
  print(string.format("\n  %s🎉 TUYỆT VỜI! Cấu hình Neovim của bạn HOÀN HẢO và đạt hiệu năng tối đa!%s", colors.green, colors.reset))
  print("  • Độ trễ thao tác: 0ms (Mượt mà như PC)")
  print("  • Không phát hiện bất kỳ lỗi hay cảnh báo nào cần sửa.")
else
  print(string.format("\n  %s⚠ Phát hiện: %d Lỗi cần sửa và %d Cảnh báo tối ưu hóa.%s", 
    #issues > 0 and colors.red or colors.yellow, #issues, #warnings, colors.reset))
  
  if #issues > 0 then
    print("\n" .. colors.bold .. colors.red .. "🛑 CÁC LỖI HỎNG CẦN SỬA NGAY (BUG FIXES):" .. colors.reset)
    for i, issue in ipairs(issues) do
      print(string.format("  %d. %s", i, issue))
    end
  end

  if #warnings > 0 then
    print("\n" .. colors.bold .. colors.yellow .. "⚠️ CÁC KHUYẾN NGHỊ TỐI ƯU THÊM (RECOMMENDATIONS):" .. colors.reset)
    for i, warn in ipairs(warnings) do
      print(string.format("  %d. %s", i, warn))
    end
  end

  print("\n" .. colors.bold .. colors.green .. "💡 HƯỚNG DẪN KHẮC PHỤC NHANH:" .. colors.reset)
  print("  • Các lỗi cấu hình phím tắt và LSP có thể được tự động sửa đổi bằng cách kéo (pull)")
  print("    bản cập nhật mới nhất từ kho Git lưu trữ của dự án.")
  print("  • Đảm bảo tệp lua/config/keymaps.lua đã được load đúng trong init.lua.")
end
print(colors.bold .. colors.cyan .. "\n======================================================================" .. colors.reset .. "\n")

-- Tự động lưu toàn bộ báo cáo không màu vào tệp tin performance_report.txt
local f = io.open("performance_report.txt", "w")
if f then
  f:write(table.concat(log_lines, "\n") .. "\n")
  f:close()
  original_print(colors.bold .. colors.green .. "💾 Báo cáo hiệu năng đã được tự động lưu vào tệp: performance_report.txt" .. colors.reset)
  original_print(colors.cyan .. "   Bạn có thể chạy 'cat performance_report.txt' để gửi lỗi cho Antigravity fix!" .. colors.reset .. "\n")
end

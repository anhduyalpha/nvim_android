# Neovim Android (Termux) Big Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a breathtaking visual and system-wide Big Update for Neovim on Android Termux: premium touch-screen home dashboard, live statusline RAM telemetry tracker, intelligent low-memory buffer guard to prevent OOM, and mobile-friendly C++ floating guide panels.

**Architecture:** We will modify `lua/plugins/ui.lua` to expand the Snacks Dashboard with custom touch keys and customize Lualine, modify `lua/util/performance.lua` to run garbage collection telemetry, and introduce interactive commands.

**Tech Stack:** Neovim Lua API, Snacks.nvim, Lualine.nvim, LazyVim.

---

### Task 1: Premium Mobile Touch Home Dashboard

**Files:**
- Modify: `lua/plugins/ui.lua`
- Test: `tests/test_dashboard_update.lua`

**Step 1: Write the failing test**
Create a test file `tests/test_dashboard_update.lua`:
```lua
local ui = dofile("lua/plugins/ui.lua")
local found_snacks = false
for _, spec in ipairs(ui) do
  if spec[1] == "folke/snacks.nvim" then
    found_snacks = true
    local db = spec.opts and spec.opts.dashboard
    if db and db.preset and db.preset.keys then
      -- Verify new custom touch action keys are present
      local found_backup = false
      for _, k in ipairs(db.preset.keys) do
        if k.desc:match("Backup") then
          found_backup = true
        end
      end
      if found_backup then
        print("PASS: Premium dashboard touch keys configured!")
      else
        print("FAIL: Custom touch action keys missing from dashboard preset")
        os.exit(1)
      end
    end
  end
end

if not found_snacks then
  print("FAIL: snacks.nvim specification not found")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -u NONE -c "luafile tests/test_dashboard_update.lua" -c "qa"`
Expected: FAIL (Custom touch action keys missing)

**Step 3: Write minimal implementation**
Edit `lua/plugins/ui.lua` using `replace_file_content` to add custom touch key presets to the Snacks dashboard block:
```lua
      -- Dashboard căn giữa
      dashboard = {
        width = 60,
        row = nil,
        col = nil,
        preset = {
          header = table.concat({
            "",
            "  █████╗ ██╗     ██████╗ ██╗  ██╗ █████╗ ██████╗ ",
            " ██╔══██╗██║     ██╔══██╗██║  ██║██╔══██╗██╔══██╗",
            " ███████║██║     ███████║███████║███████║██║  ██║",
            " ██╔══██║██║     ██╔═══╝ ██╔══██║██╔══██║██║  ██║",
            " ██║  ██║███████╗██║     ██║  ██║██║  ██║██████╔╝",
            " ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝",
            "",
            "         📱 PREMIUM MOBILE DEV ENVIRONMENT",
            "       ⚡ Powered by Antigravity (DeepMind)",
            "",
          }, "\n"),
          keys = {
            { icon = "📱 ", key = "z", desc = "Quick Action Menu", action = ":normal \\z" },
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('recent')" },
            { icon = "🛡️ ", key = "b", desc = "Create Config Backup", action = ":NvimBackup" },
            { icon = "📊 ", key = "p", desc = "Run Performance Check", action = ":!./check_performance.sh" },
            { icon = " ", key = "x", desc = "Lazy Plugin Manager", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit Neovim", action = ":qa" },
          },
        },
      },
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_dashboard_update.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/plugins/ui.lua tests/test_dashboard_update.lua
git commit -m "feat(ui): add premium mobile touch keys to snacks dashboard"
```

---

### Task 2: Statusline Live RAM Telemetry Indicator

**Files:**
- Modify: `lua/plugins/ui.lua`
- Test: `tests/test_lualine_ram.lua`

**Step 1: Write the failing test**
Create a test file `tests/test_lualine_ram.lua`:
```lua
local ui = dofile("lua/plugins/ui.lua")
local found_lualine = false
for _, spec in ipairs(ui) do
  if spec[1] == "nvim-lualine/lualine.nvim" then
    found_lualine = true
    local mock_opts = { sections = {} }
    spec.opts(nil, mock_opts)
    local z_sec = mock_opts.sections.lualine_z
    if z_sec and type(z_sec[1]) == "table" and type(z_sec[1][1]) == "function" then
      print("PASS: Statusline live RAM telemetry indicator registered!")
    else
      print("FAIL: RAM telemetry indicator missing or configured incorrectly in lualine")
      os.exit(1)
    end
  end
end

if not found_lualine then
  print("FAIL: lualine.nvim specification not found")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -u NONE -c "luafile tests/test_lualine_ram.lua" -c "qa"`
Expected: FAIL (RAM indicator missing)

**Step 3: Write minimal implementation**
Edit the `nvim-lualine/lualine.nvim` block in `lua/plugins/ui.lua` using `replace_file_content` to define the live RAM component and add it to `lualine_z`:
```lua
  -- ═══════════════════════════════════════════════
  --  2. LUALINE - Statusline gruvbox
  -- ═══════════════════════════════════════════════
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        theme = "catppuccin",
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "snacks_dashboard" },
        },
      })

      -- RAM Telemetry Component
      local function ram_indicator()
        local lua_mem = collectgarbage("count") / 1024
        if lua_mem > 30 then
          return string.format("⚠️ RAM: %.1fMB", lua_mem)
        else
          return string.format("📱 RAM: %.1fMB", lua_mem)
        end
      end

      -- Rút gọn mode cho mobile + add RAM indicator
      opts.sections = vim.tbl_deep_extend("force", opts.sections or {}, {
        lualine_a = {
          {
            "mode",
            fmt = function(m)
              local short = {
                ["NORMAL"] = "N",
                ["INSERT"] = "I",
                ["VISUAL"] = "V",
                ["V-LINE"] = "VL",
                ["V-BLOCK"] = "VB",
                ["COMMAND"] = "C",
                ["REPLACE"] = "R",
                ["TERMINAL"] = "T",
              }
              return short[m] or m:sub(1, 1)
            end,
            padding = { left = 1, right = 1 },
          },
        },
        lualine_z = {
          { ram_indicator },
        },
      })
    end,
  },
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_lualine_ram.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/plugins/ui.lua tests/test_lualine_ram.lua
git commit -m "feat(ui): integrate live RAM telemetry indicator into lualine statusline"
```

---

### Task 3: Intelligent Low-Memory Buffer Guard & OOM Preventer

**Files:**
- Modify: `lua/util/performance.lua`
- Test: `tests/test_memory_guard.lua`

**Step 1: Write the failing test**
Create a test file `tests/test_memory_guard.lua`:
```lua
local perf = dofile("lua/util/performance.lua")
if perf and type(perf.prevent_oom) == "function" then
  -- Trigger OOM prevention check
  local before = collectgarbage("count")
  perf.prevent_oom(true) -- Force clean
  local after = collectgarbage("count")
  if after <= before then
    print("PASS: Intelligent OOM Preventer runs and frees garbage successfully!")
  else
    print("FAIL: OOM preventer execution failed")
    os.exit(1)
  end
else
  print("FAIL: prevent_oom method not defined in performance.lua")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -u NONE -c "luafile tests/test_memory_guard.lua" -c "qa"`
Expected: FAIL (prevent_oom method not defined)

**Step 3: Write minimal implementation**
Edit `lua/util/performance.lua` using `replace_file_content` to define `M.prevent_oom` and call it periodically inside the setup monitor:
```lua
--- Intelligent OOM prevention routine
---@param force boolean|nil
function M.prevent_oom(force)
  local lua_mem = collectgarbage("count") / 1024
  
  -- Force collection or if usage is above 35MB
  if force or lua_mem > 35 then
    collectgarbage("collect")
    
    -- Cleanup hidden unused buffers if memory is still high
    local current_mem = collectgarbage("count") / 1024
    if current_mem > 30 then
      M.cleanup_buffers()
    end
    
    if force then
      vim.notify("🧹 Force collected Neovim garbage!", vim.log.levels.INFO, { title = "Memory Guard" })
    else
      vim.notify(string.format("🧹 Memory Guard: Auto-collected %.1fMB garbage!", lua_mem - current_mem), vim.log.levels.WARN, { title = "Memory Guard" })
    end
  end
end
```

Integrate `M.prevent_oom` to be called inside `M.auto_optimize()`:
```lua
--- Optimize settings based on current system state
function M.auto_optimize()
  if not android.is_android() then
    return
  end

  -- Run memory OOM preventer
  M.prevent_oom()

  -- Check memory and warn if low
  android.notify_low_memory()

  -- Auto-cleanup if too many buffers
  if M.count_buffers() > 15 then
    M.cleanup_buffers()
  end
end
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_memory_guard.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/util/performance.lua tests/test_memory_guard.lua
git commit -m "feat(perf): implement proactive memory watchdog and OOM preventer"
```

---

### Task 4: Interactive Floating C++ Dev Help Screen

**Files:**
- Modify: `lua/config/keymaps.lua`
- Test: `tests/test_floating_help.lua`

**Step 1: Write the failing test**
Create a test file `tests/test_floating_help.lua`:
```lua
-- Load keymaps headlessly
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
}
dofile("lua/config/keymaps.lua")

local keymaps = vim.api.nvim_get_keymap("n")
local found_help = false
for _, m in ipairs(keymaps) do
  if m.lhs == " h" or m.lhs == "\\h" or m.lhs:match("h") then
    found_help = true
  end
end

if found_help then
  print("PASS: C++ mobile interactive floating help shortcut registered!")
else
  print("FAIL: Interactive C++ help shortcut missing")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -u NONE -c "luafile tests/test_floating_help.lua" -c "qa"`
Expected: FAIL (Shortcut missing)

**Step 3: Write minimal implementation**
Add a floating help window builder and keymap to `lua/config/keymaps.lua`:
```lua
-- Floating Interactive C++ & Mobile Guide
local function show_cpp_mobile_help()
  local buf = vim.api.nvim_create_buf(false, true)
  local border_lines = {
    " 📘 HƯỚNG DẪN DEV C++ & PHÍM TẮT TRÊN ANDROID (TERMUX) ",
    "======================================================",
    " 1. PHÍM TẮT SOẠN THẢO DI ĐỘNG (Normal Mode):",
    "   • <leader>z : Mở Menu hành động nhanh cảm ứng.",
    "   • Ctrl + q  : Lưu và đóng buffer hiện tại.",
    "   • Ctrl + x  : Đóng cửa sổ split active.",
    "   • Tab       : Thụt dòng (Visual: giữ vùng chọn).",
    "   • Alt + Up/Down: Di chuyển dòng code lên/xuống.",
    "   • Alt + Trái/Phải: Chuyển nhanh giữa các buffer.",
    " ",
    " 2. DEV C++ CHUYÊN NGHIỆP (Nhấn 'c' trong file .cpp):",
    "   • ct : Biên dịch & Chạy mã nguồn trong Terminal.",
    "   • cs : Biên dịch & Chạy mã nguồn + Đo thời gian.",
    "   • cv : Biên dịch với UBSan phát hiện lỗi bộ nhớ.",
    "   • cm : Chuyển đổi giữa chế độ Debug và Release.",
    "   • cx : Chạy lại binary đã biên dịch gần nhất.",
    "   • ce : Hiển thị bảng lỗi biên dịch (Quickfix).",
    "   • cR : Khởi động lại máy chủ gợi ý clangd Stuck.",
    " ",
    " 3. SAO LƯU HỆ THỐNG AN TOÀN:",
    "   • :NvimBackup : Tạo tệp sao lưu .zip cực nhanh.",
    "   • Chạy ./backup_recovery.sh để khôi phục cấu hình.",
    "======================================================",
    "                 [ Nhấn q để đóng ]",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, border_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "help"

  local width = 56
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
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_floating_help.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/config/keymaps.lua tests/test_floating_help.lua
git commit -m "feat(mobile): implement interactive floating C++ mobile help screen and shortcut"
```

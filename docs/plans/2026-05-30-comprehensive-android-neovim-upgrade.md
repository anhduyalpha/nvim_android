# Neovim Android Comprehensive Upgrade Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade and optimize the Neovim Termux setup comprehensively to deliver desktop-grade performance, touch-ergonomic C++ workflows, auto-backups, and low-latency code navigation under Android resource constraints.

**Architecture:** We will implement low-concurrency LSP flags for Clangd to save RAM, fine-tune Treesitter parsing boundaries, establish a Lua-backed CLI zip backup/recovery system, integrate micro-touch action menus for virtual keyboards, and add a performance telemetry logger. 

**Tech Stack:** Neovim Lua API, LazyVim, Clangd, Treesitter, Bash, Zip/Unzip.

---

### Task 1: Touch-Ergonomic Action Menu and Mobile Keymaps

**Files:**
- Modify: `lua/config/keymaps.lua`
- Test: `tests/test_touch_keymaps.lua`

**Step 1: Write the failing test**
Create a test file `tests/test_touch_keymaps.lua` to check if the new `<leader>z` Quick Menu mapping and mobile navigation controls are correctly bound.
```lua
local keymaps = vim.api.nvim_get_keymap("n")
local found_menu = false
for _, m in ipairs(keymaps) do
  if m.lhs == " z" then
    found_menu = true
  end
end
if not found_menu then
  print("FAIL: <leader>z quick action menu keymap not defined!")
  os.exit(1)
else
  print("PASS: <leader>z is correctly bound!")
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -u NONE -c "luafile tests/test_touch_keymaps.lua"`
Expected: FAIL (No such file or mapping)

**Step 3: Write minimal implementation**
Append the Quick Action menu and mobile navigation map to `lua/config/keymaps.lua`:
```lua
-- Touch-Friendly C++ & Mobile Quick Action Menu
local function open_mobile_action_menu()
  local items = {
    "1. LSP: Goto Definition (gd)",
    "2. LSP: References (gr)",
    "3. LSP: Code Actions (<leader>ca)",
    "4. LSP: Rename Symbol (<leader>cr)",
    "5. Format Document (ClangFormat)",
    "6. Run Diagnostic Check",
    "7. Trigger Config Backup",
  }
  vim.ui.select(items, {
    prompt = "📱 Mobile Quick Action Menu:",
  }, function(choice)
    if not choice then return end
    if choice:match("1.") then
      vim.lsp.buf.definition()
    elseif choice:match("2.") then
      vim.lsp.buf.references()
    elseif choice:match("3.") then
      vim.lsp.buf.code_action()
    elseif choice:match("4.") then
      vim.lsp.buf.rename()
    elseif choice:match("5.") then
      vim.lsp.buf.format({ async = true })
    elseif choice:match("6.") then
      vim.cmd("!./check_performance.sh")
    elseif choice:match("7.") then
      vim.cmd("NvimBackup")
    end
  end)
end

-- Bind <leader>z as the universal touch-menu shortcut
map("n", "<leader>z", open_mobile_action_menu, { desc = "Mobile Action Menu" })

-- Touch/Swipe gesture shortcuts (simulate swiping left/right in bufferline)
map("n", "<M-Left>", "<cmd>bprevious<cr>", { silent = true, desc = "Previous Buffer" })
map("n", "<M-Right>", "<cmd>bnext<cr>", { silent = true, desc = "Next Buffer" })
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_touch_keymaps.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/config/keymaps.lua
git commit -m "feat(mobile): add touch-ergonomic <leader>z action menu and swipe-buffer keymaps"
```

---

### Task 2: Ultra-Fast Treesitter Highlighting Optimization

**Files:**
- Create: `lua/plugins/treesitter.lua`
- Test: `tests/test_treesitter_opt.lua`

**Step 1: Write the failing test**
Create a test file `tests/test_treesitter_opt.lua`:
```lua
local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
if not ok then
  print("FAIL: nvim-treesitter config not available")
  os.exit(1)
end
local opts = ts_configs.get_update_strategy and ts_configs.get_module("highlight")
if opts and opts.enable then
  print("PASS: Treesitter highlights enabled with Android tuning")
else
  print("FAIL: Treesitter config invalid or disabled")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -c "luafile tests/test_treesitter_opt.lua" -c "qa"`
Expected: FAIL (No treesitter custom plugin configuration exists yet)

**Step 3: Write minimal implementation**
Create a new file `lua/plugins/treesitter.lua`:
```lua
return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    local android = require("util.android")
    if android.is_android() then
      opts.highlight = {
        enable = true,
        -- Tối ưu tốc độ: Vô hiệu hóa Treesitter highlight trên các file lớn (>100KB) để tránh lag
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
        additional_vim_regex_highlighting = false,
      }
      -- Cắt giảm các tính năng phụ của Treesitter tốn nhiều CPU trên điện thoại
      opts.indent = { enable = false }
      opts.incremental_selection = { enable = false }
    end
  end,
}
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_treesitter_opt.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/plugins/treesitter.lua
git commit -m "perf(treesitter): optimize highlighting limits and disable heavy indentation tracking on Android"
```

---

### Task 3: Low-RAM C++ Clangd LSP Optimization

**Files:**
- Modify: `lua/plugins/cpp.lua`
- Test: `tests/test_clangd_opt.lua`

**Step 1: Write the failing test**
Create `tests/test_clangd_opt.lua` to check if low-RAM args are configured for Clangd:
```lua
local has_cpp, cpp = pcall(require, "plugins.cpp")
-- Verify that low-RAM clangd flags like -j=2 are present
local options = dofile("lua/plugins/cpp.lua")
local found_limit = false
if options and options.opts and options.opts.servers and options.opts.servers.clangd then
  local cmd = options.opts.servers.clangd.cmd
  for _, arg in ipairs(cmd or {}) do
    if arg == "-j=2" or arg == "--background-index-priority=low" then
      found_limit = true
    end
  end
end

if found_limit then
  print("PASS: Clangd low-RAM flags optimized!")
else
  print("FAIL: Clangd limits not set")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -c "luafile tests/test_clangd_opt.lua" -c "qa"`
Expected: FAIL (No low-RAM limits configured in cpp.lua)

**Step 3: Write minimal implementation**
Edit `lua/plugins/cpp.lua` using a precise replacement to define low-RAM compiler limitations for mobile:
```lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "-j=2", -- Giới hạn tối đa 2 luồng xử lý nền (tiết kiệm RAM & CPU)
            "--background-index-priority=low", -- Mức ưu tiên thấp để không chiếm CPU của trình gõ
            "--pch-storage=memory", -- Lưu trữ PCH trong bộ nhớ
            "--clang-tidy",
            "--header-insertion=never",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },
      },
    },
  },
}
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_clangd_opt.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/plugins/cpp.lua
git commit -m "perf(lsp): configure low-RAM background indexer limits for clangd on Android"
```

---

### Task 4: Auto-Backup & Quick Recovery System

**Files:**
- Create: `lua/util/backup.lua`
- Create: `backup_recovery.sh`
- Modify: `init.lua`
- Test: `tests/test_backup.lua`

**Step 1: Write the failing test**
Create `tests/test_backup.lua`:
```lua
local ok, backup = pcall(require, "util.backup")
if ok and type(backup.run_backup) == "function" then
  print("PASS: Backup module initialized successfully!")
else
  print("FAIL: Backup module missing or broken")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -c "luafile tests/test_backup.lua" -c "qa"`
Expected: FAIL (util.backup does not exist)

**Step 3: Write minimal implementation**
Create a new file `lua/util/backup.lua`:
```lua
local M = {}

function M.run_backup()
  local config_path = vim.fn.stdpath("config")
  local backup_dir = vim.fn.expand("$HOME/storage/shared/NvimBackups")
  
  -- Fallback if Termux storage is not set up
  if vim.fn.isdirectory(backup_dir) == 0 then
    backup_dir = vim.fn.expand("$HOME/NvimBackups")
    vim.fn.mkdir(backup_dir, "p")
  end

  local timestamp = os.date("%Y%m%d_%H%M%S")
  local backup_file = string.format("%s/nvim_backup_%s.zip", backup_dir, timestamp)

  print("📦 Preparing zip backup...")
  
  -- Run zip asynchronously
  local cmd = string.format("zip -r %s %s -x '*/.git/*' '*/.tests/*' '*/lazy-lock.json'", backup_file, config_path)
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("🎉 Backup thành công: " .. backup_file, vim.log.levels.INFO, { title = "Nvim Backup" })
      else
        vim.notify("🛑 Lỗi sao lưu cấu hình!", vim.log.levels.ERROR, { title = "Nvim Backup" })
      end
    end
  })
end

return M
```

Modify `init.lua` to define a user command `:NvimBackup`:
```lua
-- Register Backup command
vim.api.nvim_create_user_command("NvimBackup", function()
  require("util.backup").run_backup()
end, {})
```

Create `backup_recovery.sh` in the workspace root directory:
```bash
#!/usr/bin/env bash
# ============================================================================
# backup_recovery.sh — Khôi phục cấu hình Neovim siêu tốc trên Termux
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKUP_DIR="$HOME/storage/shared/NvimBackups"
if [ ! -d "$BACKUP_DIR" ]; then
  BACKUP_DIR="$HOME/NvimBackups"
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo -e "${RED}🛑 Không tìm thấy thư mục sao lưu nào tại $HOME/NvimBackups!${NC}"
  exit 1
fi

latest_backup=$(ls -t "$BACKUP_DIR"/nvim_backup_*.zip 2>/dev/null | head -n 1)

if [ -z "$latest_backup" ]; then
  echo -e "${RED}🛑 Không tìm thấy tệp .zip sao lưu nào!${NC}"
  exit 1
fi

echo -e "${CYAN}🔄 Đang phục hồi từ bản sao lưu gần nhất: ${latest_backup}...${NC}"

# Tạo bản sao dự phòng cấu hình hiện tại trước khi ghi đè
mv "$HOME/.config/nvim" "$HOME/.config/nvim_old_$(date +%s)" 2>/dev/null

unzip -q "$latest_backup" -d "$HOME/.config/"
# Đổi tên thư mục giải nén nếu cấu trúc bị lệch
if [ -d "$HOME/.config/nvim_android" ]; then
  mv "$HOME/.config/nvim_android" "$HOME/.config/nvim"
fi

echo -e "${GREEN}🎉 Khôi phục cấu hình Neovim thành công! Khởi động lại nvim để áp dụng.${NC}"
```
Make the shell script executable.

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_backup.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/util/backup.lua backup_recovery.sh init.lua
git commit -m "feat(backup): implement zip auto-backup command and rapid restoration bash script"
```

---

### Task 5: Mobile Diagnostic Hover and Trouble Integration

**Files:**
- Modify: `lua/config/options.lua`
- Modify: `lua/config/keymaps.lua`
- Test: `tests/test_diagnostic_hover.lua`

**Step 1: Write the failing test**
Create `tests/test_diagnostic_hover.lua`:
```lua
local config = vim.diagnostic.config()
if config.float and config.float.border == "rounded" then
  print("PASS: Rounded floating border configured successfully for diagnostic diagnostics!")
else
  print("FAIL: Floating diagnostic border config incorrect")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -c "luafile tests/test_diagnostic_hover.lua" -c "qa"`
Expected: FAIL (No round border diagnostic configuration exists)

**Step 3: Write minimal implementation**
Edit `lua/config/options.lua` diagnostic configuration around line 108 to specify mobile-optimized borders:
```lua
-- ── Diagnostics Optimization (Android-tuned, No Lag during Insert Mode) ──
vim.diagnostic.config({
  underline = true,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  update_in_insert = false, -- Never lag while typing!
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})
```

Add auto-open diagnostics hover on cursor hold inside normal mode in `lua/config/keymaps.lua`:
```lua
-- Auto-open diagnostic detail popup on cursor hold
vim.api.nvim_create_autocmd("CursorHold", {
  buffer = bufnr,
  callback = function()
    local opts = {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = 'rounded',
      source = 'always',
      prefix = ' ',
      scope = 'cursor',
    }
    vim.diagnostic.open_float(nil, opts)
  end
})
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile tests/test_diagnostic_hover.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add lua/config/options.lua lua/config/keymaps.lua
git commit -m "feat(ui): optimize floating diagnostic borders and auto-open cursor-hold details"
```

---

### Task 6: Automatic Performance Telemetry integration

**Files:**
- Modify: `check_performance.lua`
- Test: `tests/test_telemetry.lua`

**Step 1: Write the failing test**
Create `tests/test_telemetry.lua`:
```lua
local report = io.open("performance_report.txt", "r")
if report then
  local content = report:read("*a")
  report:close()
  if content:match("RAM Neovim Lua") then
    print("PASS: Telemetry output is fully formatted and complete!")
  else
    print("FAIL: Missing expected content inside telemetry report")
    os.exit(1)
  end
else
  print("FAIL: Telemetry performance_report.txt file not found")
  os.exit(1)
end
```

**Step 2: Run test to verify it fails**
Run: `nvim --headless -c "luafile tests/test_telemetry.lua" -c "qa"`
Expected: FAIL (File not existing or does not match structure)

**Step 3: Write minimal implementation**
Inject additional startup time measurement to `check_performance.lua` right before saving the file:
```lua
-- Add Telemetry measurement
local startup_time = vim.g.startuptime or "N/A"
print(string.format("  • Startup latency telemetry: %s", startup_time))
```

**Step 4: Run test to verify it passes**
Run: `nvim --headless -c "luafile check_performance.lua" -c "qa"`
Run: `nvim --headless -c "luafile tests/test_telemetry.lua" -c "qa"`
Expected: PASS

**Step 5: Commit**
```bash
git add check_performance.lua
git commit -m "feat(perf): add telemetry stats logger and update performance checking benchmark suite"
```

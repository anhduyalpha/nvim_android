local M = {}

local function safe_call(fn)
  local ok, err = pcall(fn)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Mobile actions" })
  end
end

local function is_explorer_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local ft = vim.bo[buf].filetype
  return ft == "snacks_picker_list" or ft:match("^snacks_explorer") ~= nil or ft:match("^snacks_layout") ~= nil
end

local function explorer_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and is_explorer_buffer(vim.api.nvim_win_get_buf(win)) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative == "" then
        return win
      end
    end
  end
end

local function close_explorer(win)
  local ok = pcall(function()
    Snacks.explorer.close()
  end)
  if not ok and win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

local function listed_normal_buffers()
  local buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" or vim.bo[bufnr].modified then
        table.insert(buffers, bufnr)
      end
    end
  end
  return buffers
end

local function delete_current_buffer()
  if _G.Snacks and Snacks.bufdelete then
    local ok = pcall(Snacks.bufdelete)
    if ok then
      return
    end
  end
  vim.cmd("confirm bdelete")
end

function M.smart_close()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local config = vim.api.nvim_win_get_config(win)

  if config.relative ~= "" then
    vim.api.nvim_win_close(win, true)
    return
  end

  if is_explorer_buffer(buf) then
    close_explorer(win)
    return
  end

  if vim.bo[buf].buftype ~= "" then
    local ok = pcall(vim.cmd, "close")
    if not ok then
      vim.cmd("confirm quit")
    end
    return
  end

  local normal_buffers = listed_normal_buffers()
  local explorer = explorer_window()

  if #normal_buffers > 1 then
    delete_current_buffer()
    return
  end

  if #normal_buffers == 1 and explorer then
    delete_current_buffer()
    return
  end

  if #normal_buffers == 0 and explorer then
    close_explorer(explorer)
    return
  end

  vim.cmd("confirm quit")
end

local function has_lsp_client()
  if vim.lsp.get_clients then
    return #vim.lsp.get_clients({ bufnr = 0 }) > 0
  end
  return #vim.lsp.get_active_clients({ bufnr = 0 }) > 0
end

local function run_repo_script(script, args)
  local path = vim.fn.stdpath("config") .. "/" .. script
  if vim.fn.executable(path) ~= 1 then
    vim.notify("Không tìm thấy script: " .. path, vim.log.levels.WARN)
    return
  end

  local command = { path }
  for _, arg in ipairs(args or {}) do
    table.insert(command, arg)
  end

  local on_exit = function(code)
    vim.schedule(function()
      local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
      vim.notify(script .. (code == 0 and " hoàn tất" or " thất bại"), level, { title = "Neovim Android" })
    end)
  end

  if vim.system then
    vim.system(command, { cwd = vim.fn.stdpath("config"), text = true }, function(result)
      on_exit(result.code)
    end)
  else
    vim.fn.jobstart(command, {
      cwd = vim.fn.stdpath("config"),
      on_exit = function(_, code)
        on_exit(code)
      end,
    })
  end
end

function M.action_menu()
  local items = {
    {
      label = "Format file",
      action = function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
    },
    {
      label = "Save all now",
      action = function()
        vim.cmd("AutoSaveNow")
      end,
    },
    {
      label = "Toggle auto save",
      action = function()
        vim.cmd("AutoSaveToggle")
      end,
    },
    {
      label = "Find files",
      action = function()
        Snacks.picker.files()
      end,
    },
    {
      label = "Open buffers",
      action = function()
        Snacks.picker.buffers()
      end,
    },
    {
      label = "Toggle explorer",
      action = function()
        Snacks.explorer()
      end,
    },
  }

  if has_lsp_client() then
    vim.list_extend(items, {
      { label = "Go to definition", action = vim.lsp.buf.definition },
      { label = "Find references", action = vim.lsp.buf.references },
      { label = "Code action", action = vim.lsp.buf.code_action },
      { label = "Rename symbol", action = vim.lsp.buf.rename },
    })
  end

  if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
    if vim.fn.exists(":ClangdSwitchSourceHeader") == 2 then
      table.insert(items, {
        label = "Switch header/source",
        action = function()
          vim.cmd("ClangdSwitchSourceHeader")
        end,
      })
    end
  end

  local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
  if ok_gitsigns then
    vim.list_extend(items, {
      { label = "Git preview hunk", action = gitsigns.preview_hunk },
      { label = "Git stage hunk", action = gitsigns.stage_hunk },
      { label = "Git reset hunk", action = gitsigns.reset_hunk },
    })
  end

  if vim.fn.exists(":NvimBackup") == 2 then
    table.insert(items, {
      label = "Backup config",
      action = function()
        vim.cmd("NvimBackup")
      end,
    })
  end

  table.insert(items, {
    label = "Apply no-ESC Termux layout",
    action = function()
      run_repo_script("scripts/disable-esc.sh", { "--apply" })
    end,
  })

  table.insert(items, {
    label = "Run performance check",
    action = function()
      run_repo_script("check_performance.sh")
    end,
  })

  table.insert(items, { label = "Open mobile help", action = M.show_help })

  vim.ui.select(items, {
    prompt = "Mobile actions",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      safe_call(item.action)
    end
  end)
end

function M.show_help()
  local lines = {
    " NEOVIM ANDROID QUICK GUIDE ",
    "",
    "Fast custom keys",
    "  q             Smart close / quit",
    "  d / D         Delete line / to line end",
    "  t / U         Toggle / focus Explorer",
    "  Ctrl-a        Select all",
    "  Tab / S-Tab   Indent / outdent",
    "  Ctrl-g        Start macro recording",
    "",
    "Input without ESC",
    "  Esc           Disabled in every Neovim mode",
    "  jk or jj      Leave Insert mode",
    "  q             Close popup, buffer, Explorer",
    "  Ctrl-c        Cancel command / close run terminal",
    "",
    "Auto save",
    "  idle 1.8s     Save after the last edit",
    "  :AutoSaveNow  Save all modified files",
    "  :AutoSaveToggle Enable or disable auto save",
    "",
    "Navigation",
    "  Alt-Left/Right Previous/next buffer",
    "  gd / gr / K   Definition / references / hover",
    "  ]d / [d / gl  Diagnostics",
    "",
    "Editing",
    "  Alt-Up/Down   Move line or selection",
    "  <leader>cf    Format file manually",
    "",
    "Mobile",
    "  <leader>z     Action menu",
    "  <leader>Q     Smart close alias",
    "  <leader>h     This guide",
    "",
    "C/C++",
    "  ct / cs / cv  Compile-run / timed / UBSan",
    "  cm / cx       Toggle mode / rerun",
    "  bits/stdc++.h Termux compatibility enabled",
  }

  local width = math.min(62, math.max(30, vim.o.columns - 4))
  local height = math.min(#lines, math.max(10, vim.o.lines - 4))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "mobile-help"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
  })
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
end

return M

local group = vim.api.nvim_create_augroup("AndroidSmoothUX", { clear = true })

-- Temporary windows keep a buffer-local q so the global Smart Quit remains predictable.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = {
    "help",
    "man",
    "qf",
    "checkhealth",
    "lazy",
    "mason",
    "notify",
    "snacks_notif",
    "startuptime",
    "trouble",
  },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true, nowait = true })
    vim.keymap.set("n", "<Esc>", "<Nop>", { buffer = args.buf, silent = true, nowait = true })
  end,
})

-- Cursorline is useful for navigation but unnecessary work while typing.
vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function()
    vim.opt_local.cursorline = false
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  callback = function()
    if not vim.b.large_file then
      vim.opt_local.cursorline = true
    end
  end,
})

-- Avoid Treesitter, diagnostics and persistent undo stalls on unusually large files.
vim.api.nvim_create_autocmd("BufReadPre", {
  group = group,
  callback = function(args)
    local stat = (vim.uv or vim.loop).fs_stat(args.file)
    if stat and stat.size > 1572864 then
      vim.b[args.buf].large_file = true
      vim.b[args.buf].autoformat = false
    end
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(args)
    if not vim.b[args.buf].large_file then
      return
    end

    vim.bo[args.buf].syntax = "off"
    vim.bo[args.buf].undofile = false
    vim.bo[args.buf].swapfile = false
    vim.wo.foldmethod = "manual"
    vim.wo.cursorline = false
    pcall(vim.treesitter.stop, args.buf)

    if vim.diagnostic.enable then
      pcall(vim.diagnostic.enable, false, { bufnr = args.buf })
    elseif vim.diagnostic.disable then
      pcall(vim.diagnostic.disable, args.buf)
    end

    vim.notify("Large-file mode enabled", vim.log.levels.INFO, { title = "Neovim Android" })
  end,
})

-- Restore the last cursor position without jumping inside commit messages.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count and not vim.bo[args.buf].filetype:match("commit") then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 120 })
  end,
})

vim.g.android_autosave_enabled = vim.g.android_autosave_enabled ~= false
vim.g.android_autosave_delay = vim.g.android_autosave_delay or 1800

local autosave_timers = {}

local function can_save(buf)
  if not vim.g.android_autosave_enabled then
    return false
  end
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end
  if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.bo[buf].readonly then
    return false
  end
  if not vim.bo[buf].modified or vim.api.nvim_buf_get_name(buf) == "" then
    return false
  end
  if vim.b[buf].large_file then
    return false
  end
  return true
end

local function save_buffer(buf)
  if not can_save(buf) then
    return false
  end

  local previous_autoformat = vim.b[buf].autoformat
  vim.b[buf].autoformat = false
  local ok = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("silent! update")
  end)
  vim.b[buf].autoformat = previous_autoformat
  return ok
end

local function close_timer(buf)
  local timer = autosave_timers[buf]
  if not timer then
    return
  end
  timer:stop()
  if not timer:is_closing() then
    timer:close()
  end
  autosave_timers[buf] = nil
end

local function schedule_save(buf)
  if not can_save(buf) then
    return
  end

  local uv = vim.uv or vim.loop
  local timer = autosave_timers[buf]
  if not timer or timer:is_closing() then
    timer = uv.new_timer()
    autosave_timers[buf] = timer
  end

  timer:stop()
  timer:start(vim.g.android_autosave_delay, 0, vim.schedule_wrap(function()
    if vim.api.nvim_buf_is_valid(buf) then
      save_buffer(buf)
    else
      close_timer(buf)
    end
  end))
end

local function save_all_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    save_buffer(buf)
  end
end

local function setup_autosave()
  -- Remove the older save-on-every-InsertLeave implementation from cpp.lua.
  pcall(vim.api.nvim_del_augroup_by_name, "InsertLeaveAutoSave")
  local save_group = vim.api.nvim_create_augroup("AndroidAutoSave", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = save_group,
    callback = function(args)
      schedule_save(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = save_group,
    callback = function(args)
      close_timer(args.buf)
      save_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("FocusLost", {
    group = save_group,
    callback = save_all_buffers,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = save_group,
    callback = function(args)
      close_timer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = save_group,
    callback = function()
      save_all_buffers()
      for buf in pairs(autosave_timers) do
        close_timer(buf)
      end
    end,
  })
end

pcall(vim.api.nvim_del_user_command, "AutoSaveToggle")
vim.api.nvim_create_user_command("AutoSaveToggle", function()
  vim.g.android_autosave_enabled = not vim.g.android_autosave_enabled
  vim.notify(
    "Auto save " .. (vim.g.android_autosave_enabled and "enabled" or "disabled"),
    vim.log.levels.INFO,
    { title = "Neovim Android" }
  )
end, {})

pcall(vim.api.nvim_del_user_command, "AutoSaveNow")
vim.api.nvim_create_user_command("AutoSaveNow", save_all_buffers, {})

setup_autosave()
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.defer_fn(setup_autosave, 200)
  end,
})

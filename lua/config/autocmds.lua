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

local function save_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or not vim.bo[buf].modified then
    return
  end
  local ft = vim.bo[buf].filetype
  if ft ~= "c" and ft ~= "cpp" then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! update")
  end)
end

local function setup_cpp_smart_save()
  -- cpp.lua previously wrote on every InsertLeave, causing repeated clangd reparses and storage I/O.
  pcall(vim.api.nvim_del_augroup_by_name, "InsertLeaveAutoSave")
  local save_group = vim.api.nvim_create_augroup("CppSmartSave", { clear = true })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = save_group,
    pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
    callback = function(args)
      save_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("FocusLost", {
    group = save_group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        save_buffer(buf)
      end
    end,
  })
end

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.defer_fn(setup_cpp_smart_save, 200)
  end,
})

-- Fallback for minimal/headless starts where VeryLazy is not emitted.
vim.defer_fn(setup_cpp_smart_save, 1500)

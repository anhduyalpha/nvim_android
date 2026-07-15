local group = vim.api.nvim_create_augroup("AndroidSmoothUX", { clear = true })

-- Preserve q for macro recording in normal files, but keep it convenient in temporary windows.
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

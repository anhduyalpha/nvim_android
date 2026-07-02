-- bootstrap lazy.nvim, LazyVim and your plugins

require("config.lazy")

-- Tự động kích hoạt tối ưu hóa hiệu năng & giám sát bộ nhớ
pcall(function()
  require("util.performance").setup_monitor()
end)

-- Register Backup command
vim.api.nvim_create_user_command("NvimBackup", function()
  require("util.backup").run_backup()
end, {})


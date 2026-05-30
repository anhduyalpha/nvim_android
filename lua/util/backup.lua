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

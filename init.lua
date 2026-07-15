-- Enable Neovim's Lua module cache before loading the plugin graph.
if vim.loader and vim.loader.enable then
  vim.loader.enable()
end

require("config.lazy")

-- Start the Android memory guard only after the UI and plugins have settled.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local ok, performance = pcall(require, "util.performance")
    if ok then
      performance.setup_monitor()
    end
  end,
})

vim.api.nvim_create_user_command("NvimOptimize", function()
  require("util.performance").prevent_oom(true)
end, { desc = "Run a safe Neovim memory cleanup" })

vim.api.nvim_create_user_command("NvimBackup", function()
  require("util.backup").run_backup()
end, { desc = "Back up this Neovim configuration" })

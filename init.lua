-- bootstrap lazy.nvim, LazyVim and your plugins

-- Cấu hình clangd tối ưu cho Termux/Android
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--background-index-priority=low",
    "--pch-storage=memory",
    "--completion-style=bundled",
    "--function-arg-placeholders=true",
    "--header-insertion=never",
    "--limit-results=20",
    "--clang-tidy=false",
    "--fallback-style=llvm",
    "-j=2",
    "--log=error",
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
})

require("config.lazy")

-- Tự động kích hoạt tối ưu hóa hiệu năng & giám sát bộ nhớ
pcall(function()
  require("util.performance").setup_monitor()
end)

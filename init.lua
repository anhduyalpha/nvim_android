-- bootstrap lazy.nvim, LazyVim and your plugins

-- Cấu hình clangd tối ưu cho Termux/Android
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--pch-storage=memory",
    "--completion-style=detailed",
    "--function-arg-placeholders=true",
    "--header-insertion=iwyu",
    "--limit-results=50",
    "--clang-tidy",
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

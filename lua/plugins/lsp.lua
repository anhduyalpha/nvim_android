-- ~/.config/nvim/lua/plugins/lsp.lua
-- LSP config cho Termux/Android

return {
  -- Disable mason-lspconfig (dùng clangd/pyright từ Termux pkg)
  { "mason-org/mason-lspconfig.nvim", enabled = false },

  -- pyright + lua_ls config
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.pyright = {
        mason = false,
        flags = { debounce_text_changes = 500 },
      }
      opts.servers.lua_ls = {
        mason = false,
        flags = { debounce_text_changes = 500 },
      }
      return opts
    end,
  },
}

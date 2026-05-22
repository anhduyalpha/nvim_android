-- ╭────────────────────────────────────────────────────────────────╮
-- │  clangd-extensions.lua — Cải thiện code navigation cho C++    │
-- │  Lightweight, phù hợp cho Termux/Android                       │
-- ╰────────────────────────────────────────────────────────────────╯

return {
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    ft = { "c", "cpp", "objc", "objcpp", "cuda" },
    opts = {
      -- Inlay hints (hiện kiểu biến, tham số inline)
      inlay_hints = {
        inline = true,
        -- Chỉ hiện cho parameter names, không hiện cho types (ít clutter)
        only_current_line = false,
        only_current_line_autocmd = "CursorHold",
        show_parameter_hints = true,
        parameter_hints_prefix = "<- ",
        other_hints_prefix = "=> ",
        max_len_align = false,
        max_len_align_padding = 1,
        right_align = false,
        right_align_padding = 7,
        highlight = "Comment",
        priority = 100,
      },
      -- AST viewer
      ast = {
        role_icons = {
          type = "",
          declaration = "",
          expression = "",
          specifier = "",
          statement = "",
          ["template argument"] = "",
        },
        kind_icons = {
          Compound = "",
          Recovery = "",
          TranslationUnit = "",
          PackExpansion = "",
          TemplateTypeParm = "",
          TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    },
    config = function(_, opts)
      require("clangd_extensions").setup(opts)

      -- Thêm keybindings cho clangd extensions
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("ClangdExtensions", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "clangd" then return end

          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = args.buf, desc = "Clangd: " .. desc, silent = true })
          end

          -- Switch header/source (cải tiến)
          map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Header/Source")

          -- Symbol info
          map("<leader>ci", "<cmd>ClangdSymbolInfo<cr>", "Symbol Info")

          -- Type hierarchy (xem class inheritance)
          map("<leader>cT", "<cmd>ClangdTypeHierarchy<cr>", "Type Hierarchy")

          -- Toggle inlay hints
          map("<leader>cH", function()
            local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
            vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = 0 })
          end, "Toggle Inlay Hints")

          -- AST viewer
          map("<leader>ca", "<cmd>ClangdAST<cr>", "AST Viewer")

          -- Rename (cải tiến)
          map("<leader>cr", function()
            vim.lsp.buf.rename()
          end, "Rename Symbol")
        end,
      })
    end,
  },
}

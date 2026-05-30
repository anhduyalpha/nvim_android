-- ~/.config/nvim/lua/plugins/ui.lua
-- Căn chỉnh lại toàn bộ UI cho đẹp trên Termux

return {

  -- ═══════════════════════════════════════════════
  --  1. SNACKS - Explorer + Dashboard + UI
  -- ═══════════════════════════════════════════════
  {
    "folke/snacks.nvim",
    opts = {
      -- 1. Cấu hình hành vi của Explorer
      explorer = {
        replace_netrw = true,
      },

      -- 2. Cấu hình GIAO DIỆN (độ rộng) cho Explorer phải nằm trong picker
      picker = {
        sources = {
          explorer = {
            layout = {
              layout = {
                width = 25,
                min_width = 25, -- Đảm bảo không bị bóp nhỏ hơn 25
              },
            },
          },
        },
      },

      -- Dashboard căn giữa
      dashboard = {
        width = 60,
        row = nil,
        col = nil,
        preset = {
          header = table.concat({
            "",
            "  █████╗ ██╗     ██████╗ ██╗  ██╗ █████╗ ██████╗ ",
            " ██╔══██╗██║     ██╔══██╗██║  ██║██╔══██╗██╔══██╗",
            " ███████║██║     ███████║███████║███████║██║  ██║",
            " ██╔══██║██║     ██╔═══╝ ██╔══██║██╔══██║██║  ██║",
            " ██║  ██║███████╗██║     ██║  ██║██║  ██║██████╔╝",
            " ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝",
            "",
            "         📱 PREMIUM MOBILE DEV ENVIRONMENT",
            "       ⚡ Powered by Antigravity (DeepMind)",
            "",
          }, "\n"),
          keys = {
            { icon = "📱 ", key = "z", desc = "Quick Action Menu", action = ":normal \\z" },
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('recent')" },
            { icon = "🛡️ ", key = "b", desc = "Create Config Backup", action = ":NvimBackup" },
            { icon = "📊 ", key = "p", desc = "Run Performance Check", action = ":!./check_performance.sh" },
            { icon = " ", key = "x", desc = "Lazy Plugin Manager", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit Neovim", action = ":qa" },
          },
        },
      },

      -- Notification vị trí gọn
      notifier = {
        top_down = false,
      },
    },

    config = function(_, opts)
      require("snacks").setup(opts)
    end,
  },

  -- ═══════════════════════════════════════════════
  --  2. LUALINE - Statusline gruvbox
  -- ═══════════════════════════════════════════════
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        theme = "catppuccin",
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "snacks_dashboard" },
        },
      })

      -- RAM Telemetry Component
      local function ram_indicator()
        local lua_mem = collectgarbage("count") / 1024
        if lua_mem > 30 then
          return string.format("⚠️ RAM: %.1fMB", lua_mem)
        else
          return string.format("📱 RAM: %.1fMB", lua_mem)
        end
      end

      -- Rút gọn mode cho mobile + add RAM indicator
      opts.sections = vim.tbl_deep_extend("force", opts.sections or {}, {
        lualine_a = {
          {
            "mode",
            fmt = function(m)
              local short = {
                ["NORMAL"] = "N",
                ["INSERT"] = "I",
                ["VISUAL"] = "V",
                ["V-LINE"] = "VL",
                ["V-BLOCK"] = "VB",
                ["COMMAND"] = "C",
                ["REPLACE"] = "R",
                ["TERMINAL"] = "T",
              }
              return short[m] or m:sub(1, 1)
            end,
            padding = { left = 1, right = 1 },
          },
        },
        lualine_z = {
          { ram_indicator },
        },
      })
    end,
  },

  -- ═══════════════════════════════════════════════
  --  3. BUFFER TABS - Tabline gọn hơn
  -- ═══════════════════════════════════════════════
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        mode = "buffers",
        themable = true,
        max_name_length = 18,
        max_prefix_length = 15,
        tab_size = 18,
        separator_style = { "", "" },
        indicator = {
          style = "underline",
        },
        show_close_icon = false,
        show_buffer_close_icons = true,
        always_show_bufferline = true,
        -- Ẩn bufferline khi chỉ có 1 buffer
        hide = { extensions = true, inactive = false },
      },
    },
  },

  -- ═══════════════════════════════════════════════
  --  4. NOICE - UI popups đẹp hơn
  -- ═══════════════════════════════════════════════
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          position = {
            row = "40%",
            col = "50%",
          },
          size = {
            width = math.max(40, math.floor(vim.o.columns * 0.6)),
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = "45%",
            col = "50%",
          },
          size = {
            width = math.max(40, math.floor(vim.o.columns * 0.6)),
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
        },
        mini = {
          position = {
            row = -2,
            col = "100%",
          },
        },
      },
    },
  },

  -- ═══════════════════════════════════════════════
  --  6. COLORSCHEME — load từ colorscheme.lua
  -- ═══════════════════════════════════════════════

  -- ═══════════════════════════════════════════════
  --  7. WINBAR - Hiển thị path file trên cùng
  -- ═══════════════════════════════════════════════
  {
    "b0o/incline.nvim",
    enabled = not require("util.android").is_android(),
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local helpers = require("incline.helpers")
      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0, vertical = 0 },
        },
        hide = {
          focused_win = false,
          only_win = true,
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
          local modified = vim.bo[props.buf].modified

          -- Catppuccin mocha palette
          local bg = "#313244"
          local fg = modified and "#f9e2af" or "#89b4fa"

          return {
            { " ", ft_icon, " ", guifg = ft_color, guibg = bg },
            { filename .. (modified and " ●" or ""), guifg = fg, guibg = bg, gui = modified and "bold" or "" },
            " ",
          }
        end,
      })
    end,
  },
}

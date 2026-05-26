-- ~/.config/nvim/lua/plugins/ui.lua
-- Căn chỉnh lại toàn bộ UI cho đẹp trên Termux

return {

  -- ═══════════════════════════════════════════════
  --  1. SNACKS - Explorer + Dashboard + UI
  -- ═══════════════════════════════════════════════
  {
    "folke/snacks.nvim",
    opts = {
      -- Explorer tự động căn chỉnh độ rộng
      explorer = {
        replace_netrw = true,
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
            "          Neovim on Android / Termux",
            "",
          }, "\n"),
        },
      },

      -- Notification vị trí gọn
      notifier = {
        top_down = false,
      },
    },

    config = function(_, opts)
      require("snacks").setup(opts)

      -- ── Auto-adjust Explorer width ─────────────────────
      local function adjust_explorer_width()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local ok, win_cfg = pcall(vim.api.nvim_win_get_config, win)
            if ok and win_cfg and win_cfg.relative == "" then
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[buf].filetype
              if ft:match("snacks_explorer") or ft:match("snacks") or ft == "neo-tree" then
                -- Lấy độ rộng nội dung dài nhất
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                local max_len = 25
                for _, line in ipairs(lines) do
                  local len = vim.fn.strdisplaywidth(line)
                  if len > max_len then
                    max_len = len
                  end
                end
                
                -- Clamp: min 30, max 60 (hoặc tối đa 40% màn hình)
                local screen_w = vim.o.columns
                local max_allowed = math.floor(screen_w * 0.40)
                max_allowed = math.max(max_allowed, 30)
                max_allowed = math.min(max_allowed, 60)
                
                local new_w = math.min(max_len + 4, max_allowed)
                new_w = math.max(new_w, 30)

                local cur_w = vim.api.nvim_win_get_width(win)
                if cur_w ~= new_w then
                  pcall(vim.api.nvim_win_set_width, win, new_w)
                end
              end
            end
          end
        end
      end

      -- Chạy auto-adjust khi mở/buffer thay đổi hoặc đổi window focus
      local resize_group = vim.api.nvim_create_augroup("SnacksExplorerResize", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWinEnter", "BufWritePost", "TextChanged", "WinEnter" }, {
        group = resize_group,
        callback = function()
          vim.defer_fn(adjust_explorer_width, 20)
        end,
      })

      -- CursorMoved đặc biệt cho snacks_explorer để bắt kịp việc đóng mở thư mục tức thì
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = resize_group,
        pattern = { "*" },
        callback = function()
          local ft = vim.bo.filetype
          if ft:match("snacks_explorer") or ft:match("snacks") then
            adjust_explorer_width()
          end
        end,
      })
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

      -- Rút gọn mode cho mobile
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

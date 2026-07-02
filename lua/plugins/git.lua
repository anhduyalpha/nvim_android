-- ╭────────────────────────────────────────────────────────────────╮
-- │  git.lua — Gitsigns keymaps + Lazygit (floating terminal)     │
-- ╰────────────────────────────────────────────────────────────────╯

return {

  -- ═══════════════════════════════════════════════
  --  1. GITSIGNS — Hiển thị thay đổi git + thao tác hunk
  -- ═══════════════════════════════════════════════
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      -- Tối ưu cho Android — không cập nhật quá nhanh
      update_debounce = 200,
      -- Keymaps cấu hình trong on_attach để đảm bảo buffer đã sẵn sàng
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Di chuyển giữa các hunk
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Hunk tiếp theo")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Hunk trước đó")

        -- Stage / Reset hunk (hỗ trợ cả normal + visual)
        map({ "n", "v" }, "<leader>gs", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "v" or mode == "V" then
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          else
            gs.stage_hunk()
          end
        end, "Stage hunk")

        map("n", "<leader>gS", gs.stage_buffer, "Stage toàn bộ buffer")

        map({ "n", "v" }, "<leader>gr", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "v" or mode == "V" then
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          else
            gs.reset_hunk()
          end
        end, "Reset hunk")

        map("n", "<leader>gR", gs.reset_buffer, "Reset toàn bộ buffer")

        -- Xem trước / Blame / Diff
        map("n", "<leader>gp", gs.preview_hunk_inline, "Xem trước hunk (inline)")
        map("n", "<leader>gb", gs.toggle_current_line_blame, "Blame dòng hiện tại (toggle)")
        map("n", "<leader>gd", gs.diffthis, "Diff file hiện tại")
      end,
    },
  },

  -- ═══════════════════════════════════════════════
  --  2. LAZYGIT — Mở lazygit trong floating terminal
  --     Sử dụng ToggleTerm (đã cài sẵn trong terminal.lua)
  -- ═══════════════════════════════════════════════
  {
    "akinsho/toggleterm.nvim",
    -- Chỉ thêm keymap lazygit, không ghi đè cấu hình gốc
    keys = {
      {
        "<leader>gg",
        function()
          -- Kiểm tra lazygit có sẵn trên hệ thống không
          if vim.fn.executable("lazygit") ~= 1 then
            vim.notify("lazygit chưa được cài đặt. Chạy: pkg install lazygit", vim.log.levels.WARN)
            return
          end

          local ok, Terminal = pcall(require, "toggleterm.terminal")
          if not ok then
            vim.notify("toggleterm chưa sẵn sàng", vim.log.levels.ERROR)
            return
          end

          local lazygit = Terminal.Terminal:new({
            cmd = "lazygit",
            direction = "float",
            float_opts = {
              border = "rounded",
              width = function() return math.floor(vim.o.columns * 0.9) end,
              height = function() return math.floor(vim.o.lines * 0.9) end,
            },
            on_open = function(_term)
              vim.cmd("startinsert!")
            end,
          })
          lazygit:toggle()
        end,
        desc = "Open Lazygit",
      },
    },
  },
}

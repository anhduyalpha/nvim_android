return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    local android = require("util.android")
    if android.is_android() then
      opts.highlight = {
        enable = true,
        -- Tối ưu tốc độ: Vô hiệu hóa Treesitter highlight trên các file lớn (>100KB) để tránh lag
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
        additional_vim_regex_highlighting = false,
      }
      -- Cắt giảm các tính năng phụ của Treesitter tốn nhiều CPU trên điện thoại
      opts.indent = { enable = false }
      opts.incremental_selection = { enable = false }
    end

    -- Cấu hình textobjects: chỉ kích hoạt khi bấm phím nên không ảnh hưởng hiệu suất
    opts.textobjects = {
      select = {
        enable = true,
        -- Tự động nhảy tới textobject gần nhất nếu con trỏ chưa nằm trong đó
        lookahead = true,
        keymaps = {
          ["af"] = { query = "@function.outer", desc = "Chọn quanh hàm" },
          ["if"] = { query = "@function.inner", desc = "Chọn trong hàm" },
          ["ac"] = { query = "@class.outer", desc = "Chọn quanh class" },
          ["ic"] = { query = "@class.inner", desc = "Chọn trong class" },
          ["aa"] = { query = "@parameter.outer", desc = "Chọn quanh tham số" },
          ["ia"] = { query = "@parameter.inner", desc = "Chọn trong tham số" },
          ["al"] = { query = "@loop.outer", desc = "Chọn quanh vòng lặp" },
          ["il"] = { query = "@loop.inner", desc = "Chọn trong vòng lặp" },
        },
      },
      move = {
        enable = true,
        -- Đặt vị trí nhảy vào jumplist để có thể quay lại bằng Ctrl-O
        set_jumps = true,
        goto_next_start = {
          ["]f"] = { query = "@function.outer", desc = "Hàm tiếp theo" },
          ["]c"] = { query = "@class.outer", desc = "Class tiếp theo" },
        },
        goto_next_end = {
          ["]F"] = { query = "@function.outer", desc = "Cuối hàm tiếp theo" },
        },
        goto_previous_start = {
          ["[f"] = { query = "@function.outer", desc = "Hàm trước đó" },
          ["[c"] = { query = "@class.outer", desc = "Class trước đó" },
        },
        goto_previous_end = {
          ["[F"] = { query = "@function.outer", desc = "Cuối hàm trước đó" },
        },
      },
    }
  end,
}

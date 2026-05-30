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
  end,
}

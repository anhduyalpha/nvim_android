-- ============================================================================
-- lua/plugins/formatting.lua — Auto-format cho LazyVim trên Android (Termux)
-- ============================================================================
-- Cài đặt trên Termux:
--   pkg install clang        (bao gồm clang-format)
--   cargo install stylua     (hoặc pkg install stylua nếu có)
-- ============================================================================
-- Sử dụng:
--   - Tự động format khi save (timeout 500ms cho Android)
--   - <leader>cf để format thủ công
--   - :ConformInfo để xem trạng thái formatter
-- ============================================================================

return {
  {
    "stevearc/conform.nvim",
    -- Lazy-load: chỉ load khi cần format (BufWritePre) hoặc gọi lệnh
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format Document",
      },
    },
    opts = {
      -- Formatter theo filetype
      -- C/C++: clang-format (đi kèm gói clang trên Termux)
      -- Lua: stylua (dùng stylua.toml ở project root)
      formatters_by_ft = {
        cpp = { "clang_format" },
        c = { "clang_format" },
        lua = { "stylua" },
      },
      -- Format on save — tối ưu cho Android
      -- async = false để đảm bảo format xong trước khi ghi file
      -- timeout 500ms hợp lý cho hiệu năng điện thoại
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}

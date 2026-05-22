-- ╭────────────────────────────────────────────────────────────────╮
-- │  terminal.lua — ToggleTerm + Flash (navigation)                │
-- ╰────────────────────────────────────────────────────────────────╯

return {
  -- ToggleTerm — Floating terminal, send code to terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      autochdir = false,
      highlights = {
        Normal = { link = "Normal" },
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
      },
      shade_terminals = true,
      shading_factor = -30,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float",       -- float, horizontal, vertical, tab
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "rounded",
        width = function() return math.floor(vim.o.columns * 0.85) end,
        height = function() return math.floor(vim.o.lines * 0.8) end,
        winblend = 10,
      },
      winbar = {
        enabled = false,
      },
    },
    keys = {
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (float)" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (horizontal)" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=40<cr>", desc = "Terminal (vertical)" },
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    },
  },

  -- Flash — Jump anywhere (faster than search)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm",
      search = {
        multi_window = true,
        forward = true,
        wrap = true,
        mode = "exact",
        incremental = false,
      },
      jump = {
        jumplist = true,
        pos = "start",
        history = false,
        register = false,
        nohlsearch = true,
        autojump = false,
      },
      label = {
        uppercase = true,
        exclude = "",
        current = true,
        after = true,
        before = false,
        style = "overlay",
        reuse = "lowercase",
        distance = true,
        min_pattern_length = 0,
        rainbow = {
          enabled = false,
          shade = 5,
        },
      },
      highlight = {
        backdrop = true,
        matches = true,
        priority = 5000,
        groups = {
          match = "FlashMatch",
          current = "FlashCurrent",
          backdrop = "FlashBackdrop",
          label = "FlashLabel",
        },
      },
      modes = {
        search = { enabled = false },
        char = {
          enabled = true,
          jump_labels = true,
          highlight = { backdrop = true },
        },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    },
  },
}

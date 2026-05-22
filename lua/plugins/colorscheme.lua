return {
  -- ═══════════════════════════════════════════════
  --  1. CATPPUCCIN — default theme (mocha)
  -- ═══════════════════════════════════════════════
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",        -- latte, frappe, macchiato, mocha
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = { "bold" },
        keywords = { "italic" },
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {},
      custom_highlights = {},
      default_integrations = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = { enabled = true },
        snacks = { enabled = true },
        telescope = { enabled = true },
        which_key = true,
        noice = true,
        indent_blankline = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd("colorscheme catppuccin")
    end,
  },

  -- ═══════════════════════════════════════════════
  --  2. KANAGAWA — cam nhẹ/nâu ấm/tím nhạt, tinh tế
  -- ═══════════════════════════════════════════════
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = { bold = true },
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = false,
      dimInactive = false,
      terminalColors = true,
      colors = {
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors)
        local theme = colors.theme
        return {
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          FloatTitle = { bg = "none", bold = true },
        }
      end,
      theme = "wave",   -- wave = dark, lotus = light
      background = { dark = "wave", light = "lotus" },
    },
  },

  -- ═══════════════════════════════════════════════
  --  3. SONOKAI — cam sáng/đỏ/hồng, vibrant, nổi bật
  -- ═══════════════════════════════════════════════
  {
    "sainnhe/sonokai",
    lazy = true,
    init = function()
      vim.g.sonokai_style = "default"       -- default, atlantis, andromeda, shusia, maia, espresso
      vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_disable_italic_comment = 0
      vim.g.sonokai_transparent_background = 0
      vim.g.sonokai_dim_inactive_windows = 0
      vim.g.sonokai_diagnostic_text_highlight = 1
      vim.g.sonokai_diagnostic_line_highlight = 0
      vim.g.sonokai_diagnostic_virtual_text = "colored"
      vim.g.sonokai_current_word = "grey background"
      vim.g.sonokai_better_performance = 1
    end,
  },

  -- ═══════════════════════════════════════════════
  --  4. EVERFOREST — xanh lá + nâu + cam, tự nhiên
  -- ═══════════════════════════════════════════════
  {
    "sainnhe/everforest",
    lazy = true,
    init = function()
      vim.g.everforest_style = "hard"       -- hard, medium, soft
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_disable_italic_comment = 0
      vim.g.everforest_transparent_background = 0
      vim.g.everforest_dim_inactive_windows = 0
      vim.g.everforest_diagnostic_text_highlight = 1
      vim.g.everforest_diagnostic_line_highlight = 0
      vim.g.everforest_diagnostic_virtual_text = "colored"
      vim.g.everforest_current_word = "grey background"
      vim.g.everforest_better_performance = 1
    end,
  },

  -- ═══════════════════════════════════════════════
  --  5. ROSE PINE — hồng nhạt + cam + nâu, cozy
  -- ═══════════════════════════════════════════════
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      variant = "main",         -- main (dark), moon (medium dark), dawn (light)
      dark_variant = "main",
      bold_vert_split = false,
      dim_nc_background = false,
      disable_background = false,
      disable_float_background = false,
      disable_italics = false,
      groups = {
        background = "base",
        panel = "surface",
        border = "muted",
        comment = "muted",
        link = "iris",
        punctuation = "subtle",
        error = "love",
        hint = "iris",
        info = "foam",
        warn = "gold",
        git_add = "foam",
        git_change = "rose",
        git_delete = "love",
        git_dirty = "rose",
        git_ignore = "muted",
        git_merge = "iris",
        git_rename = "pine",
        git_stage = "iris",
        git_text = "rose",
      },
    },
  },

  -- ═══════════════════════════════════════════════
  --  6. TOKYONIGHT — giữ lại để switch
  -- ═══════════════════════════════════════════════
  {
    "folke/tokyonight.nvim",
    lazy = true,
  },

  -- ═══════════════════════════════════════════════
  --  7. CATPPUCCIN — đã cài, giữ lại
  -- ═══════════════════════════════════════════════
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
  },
}

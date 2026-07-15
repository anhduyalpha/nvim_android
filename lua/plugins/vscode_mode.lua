return {
  {
    "mg979/vim-visual-multi",
    name = "vim-visual-multi",
    lazy = true,
    init = function()
      -- VSCode mode loads the plugin only when Ctrl+D is first used.
      -- Default global mappings stay disabled so mobile mode is unaffected.
      vim.g.VM_default_mappings = 0
      vim.g.VM_mouse_mappings = 0
      vim.g.VM_silent_exit = 1
      vim.g.VM_show_warnings = 0
      vim.g.VM_maps = vim.tbl_extend("force", vim.g.VM_maps or {}, {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
      })
    end,
  },
}

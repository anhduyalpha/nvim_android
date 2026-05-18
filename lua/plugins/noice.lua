-- ~/.config/nvim/lua/plugins/noice.lua

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    presets = {
      bottom_search = false,
      command_palette = true,
      long_message_to_split = false,
      lsp_doc_border = true,
    },
    views = {
      cmdline_popup = {
        position = { row = "35%", col = "50%" },
        size = { width = 40, height = "auto" },
        border = { style = "rounded", padding = { 0, 1 } },
      },
      popupmenu = {
        relative = "editor",
        anchor = "NW",
        position = { row = "40%", col = "50%" },
        size = { width = 40, height = 8 },
        border = { style = "rounded", padding = { 0, 1 } },
      },
      popup = {
        position = { row = "20%", col = "50%" },
        size = { width = 50, height = "auto", max_height = 15 },
        border = { style = "rounded", padding = { 1, 1 } },
      },
      confirm = {
        position = { row = "35%", col = "50%" },
        size = "auto",
        border = { style = "rounded", padding = { 0, 1 } },
      },
      hover = {
        position = { row = "10%", col = "50%" },
        size = { width = 50, height = "auto", max_height = 15 },
        border = { style = "rounded", padding = { 1, 1 } },
      },
      signature = {
        position = { row = "70%", col = "50%" },
        size = { width = 40, height = "auto" },
        border = { style = "rounded", padding = { 0, 1 } },
      },
      mini = {
        position = { row = -2, col = "100%" },
        size = { width = "auto", height = "auto", max_width = 35 },
        border = { style = "rounded" },
      },
    },
    routes = {
      { filter = { event = "msg_show", kind = "", find = "written" }, view = "mini" },
      { filter = { event = "msg_show", kind = "search_count" }, view = "mini" },
      { filter = { event = "msg_show", min_height = 3 }, view = "popup" },
      { filter = { event = "msg_show", kind = "emsg" }, view = "popup" },
      { filter = { event = "msg_show", kind = "wmsg" }, view = "popup" },
    },
  },
}

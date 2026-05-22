-- ╭────────────────────────────────────────────────────────────────╮
-- │  neotest.lua — Test runner cho C++ (Google Test, Catch2)       │
-- ╰────────────────────────────────────────────────────────────────╯

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "alfaix/neotest-gtest",
    },
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
      { "<leader>tT", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File Tests" },
      { "<leader>ta", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Run All Tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Test Summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show Test Output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop Test" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch" },
    },
    opts = {
      adapters = {
        ["neotest-gtest"] = {
          discovery = { enabled = true },
          args = { "--gtest_color=yes" },
        },
      },
      status = { virtual_text = true },
      output = { open_on_run = true },
      quickfix = { open = false },
    },
  },
}

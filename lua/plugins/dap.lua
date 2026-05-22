-- ╭────────────────────────────────────────────────────────────────╮
-- │  dap.lua — Debug Adapter Protocol cho C++ trên Termux          │
-- │  Dùng GDB để debug trực tiếp trong nvim                       │
-- ╰────────────────────────────────────────────────────────────────╯

return {
  -- Core DAP
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
      { "<leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, desc = "Log Point" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dp", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval Expression", mode = { "n", "v" } },
    },
    dependencies = {
      -- UI đẹp cho debugger
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        keys = {
          { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
          { "<leader>de", function() require("dapui").eval() end, desc = "Eval Expression", mode = { "n", "v" } },
        },
        opts = {
          layouts = {
            {
              elements = {
                { id = "scopes", size = 0.35 },
                { id = "breakpoints", size = 0.15 },
                { id = "stacks", size = 0.25 },
                { id = "watches", size = 0.25 },
              },
              position = "right",
              size = 40,
            },
            {
              elements = {
                { id = "repl", size = 0.5 },
                { id = "console", size = 0.5 },
              },
              position = "bottom",
              size = 10,
            },
          },
          controls = {
            enabled = true,
            element = "repl",
          },
        },
        config = function(_, opts)
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup(opts)
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
        end,
      },
      -- Hiển thị giá trị biến inline
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          enabled = true,
          enabled_commands = true,
          highlight_changed_variables = true,
          highlight_new_as_changed = true,
          show_stop_reason = true,
          commented = false,
          virt_text_pos = "eol",
        },
      },
    },
    config = function()
      local dap = require("dap")

      -- GDB Adapter cho C/C++ (Termux)
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }

      -- C++ Configuration
      dap.configurations.cpp = {
        {
          name = "Launch (single file)",
          type = "gdb",
          request = "launch",
          program = function()
            local file = vim.fn.expand("%:p")
            local out = vim.fn.expand("%:p:r")
            local compiler = vim.fn.executable("clang++") == 1 and "clang++" or "g++"
            local cmd = string.format("%s -std=c++20 -g -O0 -Wall '%s' -o '%s'", compiler, file, out)
            vim.notify("Compiling for debug...", vim.log.levels.INFO)
            os.execute(cmd)
            return out
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
          runInTerminal = false,
        },
        {
          name = "Launch (OOP project)",
          type = "gdb",
          request = "launch",
          program = function()
            local root = vim.fn.getcwd()
            local build = root .. "/build/main"
            if vim.fn.filereadable(build) == 1 then return build end
            os.execute(string.format("cd '%s' && mkdir -p build && bear -- make -j2 2>/dev/null || clang++ -std=c++20 -g -O0 -Iheader source/*.cpp -o build/main", root))
            return build
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
          runInTerminal = false,
        },
        {
          name = "Attach to process",
          type = "gdb",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      }

      dap.configurations.c = dap.configurations.cpp

      -- DAP Signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticSignWarn" })
      vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticSignInfo" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticSignOk" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "✗", texthl = "DiagnosticSignError" })
    end,
  },
}

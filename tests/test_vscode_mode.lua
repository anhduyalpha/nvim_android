vim.g.mapleader = " "
vim.g.vscode_mode_enabled = false

package.loaded["util.mobile"] = {
  smart_close = function() end,
}

_G.Snacks = {
  explorer = function() end,
  picker = {
    files = function() end,
    lines = function() end,
    commands = function() end,
  },
  terminal = {
    toggle = function() end,
  },
}

local function assert_true(value, message)
  if not value then
    error(message)
  end
end

local function mapping(mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true)
end

vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select All" })
vim.keymap.set("n", "<M-Left>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })

package.loaded["util.vscode_mode"] = nil
local vscode = require("util.vscode_mode")
vscode.setup()

assert_true(vim.fn.exists(":Vscode") == 2, ":Vscode command is missing")
assert_true(vscode.status() == false, "VSCode mode should start disabled")

vscode.enable({ quiet = true })
assert_true(vim.g.vscode_mode_enabled == true, "VSCode mode did not enable")
assert_true(mapping("n", "<C-a>").desc == "VSCode: Select All", "Ctrl+A was not replaced")
assert_true(mapping("n", "<C-v>").desc == "VSCode: Paste", "Ctrl+V mapping is missing")
assert_true(mapping("n", "<C-x>").desc == "VSCode: Cut Line", "Ctrl+X mapping is missing")
assert_true(mapping("n", "<C-d>").desc == "VSCode: Select Next Occurrence", "Ctrl+D mapping is missing")
assert_true(mapping("n", "<M-Left>").desc == "VSCode: Navigate Back", "Alt+Left mapping is missing")
assert_true(mapping("n", "<M-S-Down>").desc == "VSCode: Duplicate Down", "Alt+Shift+Down mapping is missing")
assert_true(mapping("n", "<F2>").desc == "VSCode: Rename Symbol", "F2 mapping is missing")

vscode.disable({ quiet = true })
assert_true(vim.g.vscode_mode_enabled == false, "VSCode mode did not disable")
assert_true(mapping("n", "<C-a>").desc == "Select All", "Ctrl+A mobile mapping was not restored")
assert_true(mapping("n", "<M-Left>").desc == "Previous Buffer", "Alt+Left mobile mapping was not restored")
assert_true(vim.fn.maparg("<C-v>", "n") == "", "VSCode-only Ctrl+V mapping was not removed")
assert_true(vim.fn.maparg("<C-d>", "n") == "", "VSCode-only Ctrl+D mapping was not removed")

vscode.command("on")
assert_true(vim.g.vscode_mode_enabled == true, ":vscode on behavior failed")
vscode.command("off")
assert_true(vim.g.vscode_mode_enabled == false, ":vscode off behavior failed")

print("PASS: VSCode mode toggles mappings and restores mobile mode")

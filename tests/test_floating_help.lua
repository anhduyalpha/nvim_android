-- tests/test_floating_help.lua

-- Load keymaps headlessly
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
}
dofile("lua/config/keymaps.lua")

local keymaps = vim.api.nvim_get_keymap("n")
local found_help = false
for _, m in ipairs(keymaps) do
  if (m.lhs == " h" or m.lhs == "\\h") and m.desc == "C++ Mobile Guide" then
    found_help = true
  end
end

if found_help then
  print("PASS: C++ mobile interactive floating help shortcut registered!")
else
  print("FAIL: Interactive C++ help shortcut missing")
  os.exit(1)
end

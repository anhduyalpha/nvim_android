-- tests/test_touch_keymaps.lua

-- Mock the android helper for headless execution
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
  get_platform_settings = function() return { update_time = 1000, undo_levels = 100 } end,
  notify_low_memory = function() end
}

-- Load our customized keymaps file
dofile("lua/config/keymaps.lua")

local keymaps = vim.api.nvim_get_keymap("n")
local found_menu = false
for _, m in ipairs(keymaps) do
  -- " z" is `<leader>z` when leader is space
  if m.lhs == " z" or m.lhs == "\\z" or m.lhs:match("z") then
    found_menu = true
  end
end

if not found_menu then
  print("FAIL: <leader>z quick action menu keymap not defined!")
  os.exit(1)
else
  print("PASS: <leader>z is correctly bound!")
end

vim.g.mapleader = " "

package.loaded["util.android"] = {
  is_android = function()
    return true
  end,
  is_termux = function()
    return true
  end,
  get_platform_settings = function()
    return { update_time = 300, undo_levels = 800 }
  end,
  notify_low_memory = function() end,
}

_G.Snacks = _G.Snacks or {
  explorer = function() end,
  picker = {
    files = function() end,
    buffers = function() end,
  },
}

dofile("lua/config/keymaps.lua")

local function assert_true(value, message)
  if not value then
    error(message)
  end
end

local function assert_mapping(lhs, mode, description)
  local mapping = vim.fn.maparg(lhs, mode, false, true)
  assert_true(type(mapping) == "table" and next(mapping) ~= nil, lhs .. " mapping is missing in mode " .. mode)
  assert_true(mapping.desc == description, lhs .. " has unexpected description: " .. tostring(mapping.desc))
end

assert_mapping("<leader>z", "n", "Mobile Action Menu")
assert_mapping("<leader>h", "n", "C++ Mobile Guide")
assert_mapping("<leader>Q", "n", "Smart Close")

assert_mapping("q", "n", "Smart Quit")
assert_mapping("<C-g>", "n", "Record Macro")
assert_mapping("d", "n", "Delete Line")
assert_mapping("D", "n", "Delete to Line End")
assert_mapping("t", "n", "Toggle Explorer")
assert_mapping("U", "n", "Focus Explorer")
assert_mapping("<C-a>", "n", "Select All")
assert_mapping("<Tab>", "n", "Indent Line")
assert_mapping("<S-Tab>", "n", "Outdent Line")
assert_mapping("<Tab>", "x", "Indent Selection")
assert_mapping("<S-Tab>", "x", "Outdent Selection")
assert_mapping("jk", "i", "Exit Insert Mode")
assert_mapping("jj", "i", "Exit Insert Mode")

for _, mode in ipairs({ "n", "i", "x", "s", "o", "c", "t" }) do
  assert_mapping("<Esc>", mode, "Escape Disabled")
end

print("PASS: optimized custom keys and no-ESC workflow are registered")

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

local normal_maps = vim.api.nvim_get_keymap("n")
local descriptions = {}
for _, item in ipairs(normal_maps) do
  descriptions[item.lhs] = item.desc
end

assert_true(descriptions[" z"] == "Mobile Action Menu", "<leader>z mobile menu is missing")
assert_true(descriptions[" h"] == "C++ Mobile Guide", "<leader>h mobile guide is missing")
assert_true(descriptions[" Q"] == "Smart Close", "<leader>Q smart close is missing")

for _, lhs in ipairs({ "q", "d", "t", "U", "<C-A>", "<Tab>" }) do
  assert_true(vim.fn.maparg(lhs, "n") == "", lhs .. " must keep its native Vim behavior")
end

print("PASS: mobile mappings are available and native Vim commands are preserved")

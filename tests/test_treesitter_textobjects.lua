-- tests/test_treesitter_textobjects.lua

local ts_plugin = dofile("lua/plugins/treesitter.lua")
if not ts_plugin then
  print("FAIL: treesitter.lua configuration not found!")
  os.exit(1)
end

local opts = ts_plugin.opts
if type(opts) ~= "function" then
  print("FAIL: treesitter opts is not a config function")
  os.exit(1)
end

-- Mock android config to verify textobjects are set up
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
}

local mock_opts = {}
opts(nil, mock_opts)

local to = mock_opts.textobjects
if not to or not to.select or not to.move then
  print("FAIL: Treesitter textobjects configuration missing from mock_opts")
  os.exit(1)
end

-- Check select queries
local keymaps = to.select.keymaps
if not keymaps or keymaps["af"].query ~= "@function.outer" or keymaps["ic"].query ~= "@class.inner" then
  print("FAIL: Treesitter textobject select keymaps incorrect or missing")
  os.exit(1)
end

-- Check move queries
local move = to.move
if not move or move.set_jumps ~= true or move.goto_next_start["]f"].query ~= "@function.outer" then
  print("FAIL: Treesitter textobject move query or set_jumps setting incorrect")
  os.exit(1)
end

print("PASS: Treesitter C++ textobjects configured and verified!")

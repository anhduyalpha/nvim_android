-- tests/test_treesitter_opt.lua

local ts_plugin = dofile("lua/plugins/treesitter.lua")
if not ts_plugin then
  print("FAIL: nvim-treesitter custom optimization module not found!")
  os.exit(1)
end

-- Validate the option configurations
local opts = ts_plugin.opts
if type(opts) == "function" then
  local mock_opts = { highlight = {}, indent = {}, incremental_selection = {} }
  -- Mock util.android to return is_android = true
  package.loaded["util.android"] = {
    is_android = function() return true end,
    is_termux = function() return true end,
  }
  
  opts(nil, mock_opts)
  
  if mock_opts.highlight.enable == true and mock_opts.indent.enable == false then
    print("PASS: Treesitter highlights enabled with optimal Android configs!")
  else
    print("FAIL: Treesitter highlight or indent configurations are not optimal.")
    os.exit(1)
  end
else
  print("FAIL: Treesitter options is not a configure function")
  os.exit(1)
end

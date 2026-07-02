-- tests/test_lualine_ram.lua

-- Mock the android helper for headless execution
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
}

local ui = dofile("lua/plugins/ui.lua")
local found_lualine = false
for _, spec in ipairs(ui) do
  if spec[1] == "nvim-lualine/lualine.nvim" then
    found_lualine = true
    local mock_opts = { sections = {} }
    spec.opts(nil, mock_opts)
    local z_sec = mock_opts.sections.lualine_z
    if z_sec and type(z_sec[1]) == "table" and type(z_sec[1][1]) == "function" then
      print("PASS: Statusline live RAM telemetry indicator registered!")
    else
      print("FAIL: RAM telemetry indicator missing or configured incorrectly in lualine")
      os.exit(1)
    end
  end
end

if not found_lualine then
  print("FAIL: lualine.nvim specification not found")
  os.exit(1)
end

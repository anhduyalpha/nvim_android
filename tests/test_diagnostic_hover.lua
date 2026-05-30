-- tests/test_diagnostic_hover.lua

-- Mock the android helper for headless execution
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
  get_platform_settings = function() return { update_time = 1000, undo_levels = 100 } end,
  notify_low_memory = function() end
}

-- Load our options file
dofile("lua/config/options.lua")

local config = vim.diagnostic.config()
if config and config.float and config.float.border == "rounded" then
  print("PASS: Rounded floating border configured successfully for diagnostics!")
else
  print("FAIL: Floating diagnostic border config incorrect or not rounded")
  os.exit(1)
end

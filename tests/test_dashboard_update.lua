-- tests/test_dashboard_update.lua

local ui = dofile("lua/plugins/ui.lua")
local found_snacks = false
for _, spec in ipairs(ui) do
  if spec[1] == "folke/snacks.nvim" then
    found_snacks = true
    local db = spec.opts and spec.opts.dashboard
    if db and db.preset and db.preset.keys then
      -- Verify new custom touch action keys are present
      local found_backup = false
      for _, k in ipairs(db.preset.keys) do
        if k.desc:match("Backup") then
          found_backup = true
        end
      end
      if found_backup then
        print("PASS: Premium dashboard touch keys configured!")
      else
        print("FAIL: Custom touch action keys missing from dashboard preset")
        os.exit(1)
      end
    else
      print("FAIL: Dashboard presets or keys missing completely")
      os.exit(1)
    end
  end
end

if not found_snacks then
  print("FAIL: snacks.nvim specification not found")
  os.exit(1)
end

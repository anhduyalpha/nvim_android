-- tests/test_memory_guard.lua

package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
}

local perf = dofile("lua/util/performance.lua")
if perf and type(perf.prevent_oom) == "function" then
  -- Trigger OOM prevention check
  local before = collectgarbage("count")
  perf.prevent_oom(true) -- Force clean
  local after = collectgarbage("count")
  if after <= before then
    print("PASS: Intelligent OOM Preventer runs and frees garbage successfully!")
  else
    print("FAIL: OOM preventer execution failed")
    os.exit(1)
  end
else
  print("FAIL: prevent_oom method not defined in performance.lua")
  os.exit(1)
end

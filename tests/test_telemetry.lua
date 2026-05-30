-- tests/test_telemetry.lua

local report = io.open("performance_report.txt", "r")
if report then
  local content = report:read("*a")
  report:close()
  if content:match("Startup latency telemetry") then
    print("PASS: Telemetry output is fully formatted and complete!")
  else
    print("FAIL: Missing expected startup latency content inside telemetry report")
    os.exit(1)
  end
else
  print("FAIL: Telemetry performance_report.txt file not found")
  os.exit(1)
end

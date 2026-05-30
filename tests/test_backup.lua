-- tests/test_backup.lua

local ok, backup = pcall(dofile, "lua/util/backup.lua")
if ok and backup and type(backup.run_backup) == "function" then
  print("PASS: Backup module initialized successfully!")
else
  print("FAIL: Backup module missing or broken")
  os.exit(1)
end

local M = {}
local android = require("util.android")
local uv = vim.uv or vim.loop
local monitor_timer

-- A moderate GC profile avoids both unbounded growth and aggressive typing-time collections.
if android.is_android() then
  collectgarbage("setpause", 150)
  collectgarbage("setstepmul", 200)
end

function M.get_startup_time()
  return vim.g.startuptime
end

function M.get_memory_usage()
  local meminfo = io.open("/proc/meminfo", "r")
  if not meminfo then
    return 0
  end

  local content = meminfo:read("*a")
  meminfo:close()
  local total = content:match("MemTotal:%s*(%d+)")
  local available = content:match("MemAvailable:%s*(%d+)")
  if total and available then
    return (tonumber(total) - tonumber(available)) / 1024
  end
  return 0
end

function M.count_buffers()
  return #vim.fn.getbufinfo({ buflisted = 1 })
end

function M.count_windows()
  return #vim.api.nvim_tabpage_list_wins(0)
end

function M.cleanup_buffers()
  local cleaned = 0
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if buf.name == "" and buf.changed == 0 and #buf.windows == 0 then
      local ok = pcall(vim.api.nvim_buf_delete, buf.bufnr, { force = false })
      if ok then
        cleaned = cleaned + 1
      end
    end
  end
  return cleaned
end

function M.prevent_oom(force)
  local before = collectgarbage("count") / 1024
  if not force and before < 64 then
    return false
  end

  collectgarbage("collect")
  local after = collectgarbage("count") / 1024
  if after > 56 then
    M.cleanup_buffers()
  end

  if force then
    vim.notify(
      string.format("Lua memory %.1f MB → %.1f MB", before, after),
      vim.log.levels.INFO,
      { title = "Memory Guard" }
    )
  end
  return true
end

function M.auto_optimize()
  if not android.is_android() then
    return
  end

  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == "i" or mode == "R" or mode == "c" or mode == "t" then
    return
  end

  M.prevent_oom(false)
  if M.count_buffers() > 24 then
    M.cleanup_buffers()
  end
  android.notify_low_memory()
end

function M.stop_monitor()
  if not monitor_timer then
    return
  end
  monitor_timer:stop()
  if not monitor_timer:is_closing() then
    monitor_timer:close()
  end
  monitor_timer = nil
end

function M.setup_monitor()
  if not android.is_android() or monitor_timer then
    return
  end

  monitor_timer = uv.new_timer()
  if not monitor_timer then
    return
  end

  -- Do no monitoring work during startup. Check after three minutes, then every five minutes.
  monitor_timer:start(180000, 300000, vim.schedule_wrap(M.auto_optimize))
  if monitor_timer.unref then
    monitor_timer:unref()
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = M.stop_monitor,
  })
end

function M.get_report()
  return {
    memory_mb = M.get_memory_usage(),
    lua_memory_mb = collectgarbage("count") / 1024,
    buffers = M.count_buffers(),
    windows = M.count_windows(),
    is_android = android.is_android(),
    is_low_resource = android.is_low_resource(),
    platform_settings = android.get_platform_settings(),
  }
end

return M

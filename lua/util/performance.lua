-- performance.lua — Performance tuning utilities for Android/Low-resource environments
-- Provides functions to monitor and optimize Neovim performance

local M = {}

local android = require("util.android")

--- Get current Neovim startup time (requires --startuptime flag)
---@return number|nil startup_ms
function M.get_startup_time()
  local startuptime = vim.g.startuptime
  if startuptime then
    return startuptime
  end
  return nil
end

--- Get current memory usage estimate
---@return number memory_mb
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
    local used_mb = (tonumber(total) - tonumber(available)) / 1024
    return used_mb
  end

  return 0
end

--- Count loaded buffers
---@return number
function M.count_buffers()
  return #vim.fn.getbufinfo({ buflisted = 1 })
end

--- Count active windows
---@return number
function M.count_windows()
  return #vim.api.nvim_tabpage_list_wins(0)
end

--- Clean up unused buffers to free memory
function M.cleanup_buffers()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  local cleaned = 0

  for _, buf in ipairs(bufs) do
    if buf.name == "" and buf.changed == 0 and #buf.windows == 0 then
      vim.api.nvim_buf_delete(buf.bufnr, { force = false })
      cleaned = cleaned + 1
    end
  end

  if cleaned > 0 then
    vim.notify(string.format("🧹 Cleaned %d unused buffers", cleaned), vim.log.levels.INFO)
  end
end

--- Optimize settings based on current system state
function M.auto_optimize()
  if not android.is_android() then
    return
  end

  -- Check memory and warn if low
  android.notify_low_memory()

  -- Auto-cleanup if too many buffers
  if M.count_buffers() > 15 then
    M.cleanup_buffers()
  end
end

local monitor_timer = nil

--- Setup periodic performance monitoring
function M.setup_monitor()
  if not android.is_android() then
    return
  end

  if monitor_timer then
    monitor_timer:stop()
    if not monitor_timer:is_closing() then
      monitor_timer:close()
    end
  end

  -- Check performance every 5 minutes
  monitor_timer = (vim.uv or vim.loop).new_timer()
  if monitor_timer then
    monitor_timer:start(
      0,
      300000,
      vim.schedule_wrap(function()
        M.auto_optimize()
      end)
    )
  end
end

--- Get performance report
---@return table report
function M.get_report()
  return {
    memory_mb = M.get_memory_usage(),
    buffers = M.count_buffers(),
    windows = M.count_windows(),
    is_android = android.is_android(),
    is_low_resource = android.is_low_resource(),
    platform_settings = android.get_platform_settings(),
  }
end

return M

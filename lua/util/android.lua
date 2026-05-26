-- ~/.config/nvim/lua/util/android.lua

local M = {}

function M.is_android()
  return vim.fn.has("android") == 1 or os.getenv("ANDROID_ROOT") ~= nil
end

function M.is_termux()
  return vim.env.TERMUX_VERSION ~= nil
end

function M.get_platform_settings()
  if M.is_android() then
    return {
      update_time = 500,
      undo_levels = 500,
    }
  else
    return {
      update_time = 250,
      undo_levels = 1000,
    }
  end
end

function M.is_low_resource()
  return M.is_android()
end

function M.notify_low_memory()
  if not M.is_android() then
    return
  end
  local meminfo = io.open("/proc/meminfo", "r")
  if not meminfo then
    return
  end
  local content = meminfo:read("*a")
  meminfo:close()
  local total = content:match("MemTotal:%s*(%d+)")
  local available = content:match("MemAvailable:%s*(%d+)")
  if total and available then
    local available_mb = tonumber(available) / 1024
    if available_mb < 500 then
      vim.notify(
        string.format("⚠️ Cảnh báo: Bộ nhớ điện thoại khả dụng thấp (%dMB)!", available_mb),
        vim.log.levels.WARN,
        { title = "Neovim System" }
      )
    end
  end
end

return M

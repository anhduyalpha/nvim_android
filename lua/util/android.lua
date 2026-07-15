local M = {}
local cached_android
local cached_termux
local last_memory_warning = 0

function M.is_termux()
  if cached_termux == nil then
    cached_termux = vim.env.TERMUX_VERSION ~= nil or vim.fn.executable("termux-info") == 1
  end
  return cached_termux
end

function M.is_android()
  if cached_android == nil then
    cached_android = vim.fn.has("android") == 1 or os.getenv("ANDROID_ROOT") ~= nil or M.is_termux()
  end
  return cached_android
end

function M.get_platform_settings()
  if M.is_android() then
    return {
      update_time = 300,
      undo_levels = 800,
    }
  end
  return {
    update_time = 250,
    undo_levels = 1000,
  }
end

function M.is_low_resource()
  return M.is_android()
end

function M.notify_low_memory()
  if not M.is_android() or os.time() - last_memory_warning < 900 then
    return
  end

  local meminfo = io.open("/proc/meminfo", "r")
  if not meminfo then
    return
  end

  local content = meminfo:read("*a")
  meminfo:close()
  local available = content:match("MemAvailable:%s*(%d+)")
  if not available then
    return
  end

  local available_mb = tonumber(available) / 1024
  if available_mb < 400 then
    last_memory_warning = os.time()
    vim.notify(
      string.format("Bộ nhớ khả dụng thấp: %.0f MB", available_mb),
      vim.log.levels.WARN,
      { title = "Neovim Android" }
    )
  end
end

return M

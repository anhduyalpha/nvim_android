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

return M

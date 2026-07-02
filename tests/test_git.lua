-- tests/test_git.lua

-- Mock the android helper for headless execution
package.loaded["util.android"] = {
  is_android = function() return true end,
  is_termux = function() return true end,
}

local git_plugin = dofile("lua/plugins/git.lua")
if not git_plugin then
  print("FAIL: git.lua configuration not found!")
  os.exit(1)
end

-- Find the gitsigns spec
local gitsigns_spec = nil
local lazygit_spec = nil
for _, spec in ipairs(git_plugin) do
  if spec[1] == "lewis6991/gitsigns.nvim" then
    gitsigns_spec = spec
  elseif spec[1] == "akinsho/toggleterm.nvim" then
    lazygit_spec = spec
  end
end

if not gitsigns_spec then
  print("FAIL: gitsigns.nvim spec not found in git.lua")
  os.exit(1)
end

if not lazygit_spec then
  print("FAIL: toggleterm.nvim spec not found in git.lua")
  os.exit(1)
end

-- Check gitsigns mobile opts
local opts = gitsigns_spec.opts
if not opts or opts.update_debounce ~= 200 or type(opts.on_attach) ~= "function" then
  print("FAIL: gitsigns options or on_attach hook not defined properly")
  os.exit(1)
end

-- Check lazygit ToggleTerm keys
local keys = lazygit_spec.keys
local found_lazygit_key = false
for _, key in ipairs(keys or {}) do
  if key[1] == "<leader>gg" and type(key[2]) == "function" then
    found_lazygit_key = true
    break
  end
end

if not found_lazygit_key then
  print("FAIL: Lazygit floating terminal keymap '<leader>gg' not configured")
  os.exit(1)
end

print("PASS: Git and Lazygit configurations verified!")

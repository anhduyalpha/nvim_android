-- tests/test_formatting.lua

local formatting_plugin = dofile("lua/plugins/formatting.lua")
if not formatting_plugin then
  print("FAIL: formatting.lua configuration not found!")
  os.exit(1)
end

-- Find the conform.nvim spec
local conform_spec = nil
for _, spec in ipairs(formatting_plugin) do
  if spec[1] == "stevearc/conform.nvim" then
    conform_spec = spec
    break
  end
end

if not conform_spec then
  print("FAIL: stevearc/conform.nvim spec not found in formatting.lua")
  os.exit(1)
end

local opts = conform_spec.opts
if not opts then
  print("FAIL: Conform opts not defined")
  os.exit(1)
end

-- Verify formatters by filetype
local formatters = opts.formatters_by_ft
if not formatters or formatters.cpp[1] ~= "clang_format" or formatters.lua[1] ~= "stylua" then
  print("FAIL: Formatters by filetype are incorrect or missing")
  os.exit(1)
end

-- Verify format on save config
local fos = opts.format_on_save
if not fos or fos.timeout_ms ~= 500 or fos.lsp_fallback ~= true then
  print("FAIL: format_on_save options not optimal for Android")
  os.exit(1)
end

-- Verify keymap configuration
local keys = conform_spec.keys
local found_key = false
for _, key in ipairs(keys or {}) do
  if key[1] == "<leader>cf" then
    found_key = true
    break
  end
end

if not found_key then
  print("FAIL: <leader>cf manual format keymap not found")
  os.exit(1)
end

print("PASS: conform.nvim formatting configurations verified!")

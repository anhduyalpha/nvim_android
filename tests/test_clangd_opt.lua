-- tests/test_clangd_opt.lua

local cpp_plugin = dofile("lua/plugins/cpp.lua")
if not cpp_plugin then
  print("FAIL: cpp.lua configuration not found!")
  os.exit(1)
end

-- Find the nvim-lspconfig spec
local lsp_spec = nil
for _, spec in ipairs(cpp_plugin) do
  if spec[1] == "neovim/nvim-lspconfig" then
    lsp_spec = spec
    break
  end
end

if not lsp_spec then
  print("FAIL: neovim/nvim-lspconfig spec not found in cpp.lua")
  os.exit(1)
end

local opts = lsp_spec.opts
local servers = nil
if type(opts) == "function" then
  local mock_opts = { servers = {} }
  opts(nil, mock_opts)
  servers = mock_opts.servers
elseif type(opts) == "table" then
  servers = opts.servers
end

if not servers or not servers.clangd then
  print("FAIL: Clangd server settings not defined in cpp.lua")
  os.exit(1)
end

local cmd = servers.clangd.cmd
local found_limit = false
for _, arg in ipairs(cmd or {}) do
  if arg == "-j=2" or arg == "--background-index-priority=low" then
    found_limit = true
  end
end

if found_limit then
  print("PASS: Clangd low-RAM flags optimized!")
else
  print("FAIL: Clangd limits not set")
  os.exit(1)
end

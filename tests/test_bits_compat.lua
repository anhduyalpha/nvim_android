local root = vim.fn.getcwd()
local include_dir = root .. "/include"
local header = include_dir .. "/bits/stdc++.h"

local function fail(message)
  error(message)
end

local file = io.open(header, "r")
if not file then
  fail("compatibility header is missing: " .. header)
end
local content = file:read("*a")
file:close()

for _, expected in ipairs({ "#include <algorithm>", "#include <iostream>", "#include <vector>" }) do
  if not content:find(expected, 1, true) then
    fail("compatibility header is missing " .. expected)
  end
end

local plugin = io.open(root .. "/lua/plugins/zz_cpp_smooth.lua", "r")
if not plugin then
  fail("clangd compatibility plugin is missing")
end
local plugin_content = plugin:read("*a")
plugin:close()

for _, expected in ipairs({ "CPLUS_INCLUDE_PATH", "fallbackFlags", "query-driver" }) do
  if not plugin_content:find(expected, 1, true) then
    fail("clangd compatibility wiring is missing " .. expected)
  end
end

if vim.fn.executable("clang++") == 1 then
  local source = vim.fn.tempname() .. ".cpp"
  local source_file = assert(io.open(source, "w"))
  source_file:write([[
#include <bits/stdc++.h>
int main() {
  std::vector<int> values{3, 1, 2};
  std::sort(values.begin(), values.end());
  return values.front() == 1 ? 0 : 1;
}
]])
  source_file:close()

  local output = vim.fn.system({
    "clang++",
    "-std=c++20",
    "-I" .. include_dir,
    "-fsyntax-only",
    source,
  })
  local code = vim.v.shell_error
  os.remove(source)

  if code ~= 0 then
    fail("clang++ could not compile bits/stdc++.h compatibility probe:\n" .. output)
  end
end

print("PASS: bits/stdc++.h compatibility header and clangd wiring are valid")

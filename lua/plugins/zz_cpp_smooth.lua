local android = require("util.android")
local compat_include = vim.fn.stdpath("config") .. "/include"

local function prepend_env(name, value)
  local current = vim.env[name] or ""
  for item in current:gmatch("[^:]+") do
    if item == value then
      return
    end
  end
  vim.env[name] = current == "" and value or (value .. ":" .. current)
end

if android.is_termux() then
  -- Termux ships Clang with libc++, which does not provide GNU's bits/stdc++.h.
  -- The compatibility header in this repo is visible to every clang++ job started by Neovim.
  prepend_env("CPLUS_INCLUDE_PATH", compat_include)
end

local function append_unique(items, value)
  for _, item in ipairs(items) do
    if item == value then
      return
    end
  end
  table.insert(items, value)
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      local clangd = opts.servers.clangd or {}

      clangd.flags = vim.tbl_deep_extend("force", clangd.flags or {}, {
        debounce_text_changes = android.is_android() and 650 or 300,
      })

      clangd.init_options = clangd.init_options or {}
      local fallback_flags = clangd.init_options.fallbackFlags or {}
      append_unique(fallback_flags, "-I" .. compat_include)
      clangd.init_options.fallbackFlags = fallback_flags

      if android.is_termux() then
        local prefix = vim.env.PREFIX or "/data/data/com.termux/files/usr"
        local cmd = vim.deepcopy(clangd.cmd or { "clangd" })
        local filtered = {}
        for _, arg in ipairs(cmd) do
          if not arg:match("^%-%-query%-driver=") then
            table.insert(filtered, arg)
          end
        end
        table.insert(filtered, "--query-driver=" .. prefix .. "/bin/clang*")
        clangd.cmd = filtered
      end

      opts.servers.clangd = clangd
      return opts
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      if not android.is_android() then
        return opts
      end

      opts.completion = opts.completion or {}
      opts.completion.list = opts.completion.list or {}
      opts.completion.list.max_items = 12
      opts.completion.documentation = vim.tbl_deep_extend("force", opts.completion.documentation or {}, {
        auto_show = false,
      })

      opts.signature = vim.tbl_deep_extend("force", opts.signature or {}, {
        enabled = false,
      })

      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.buffer = vim.tbl_deep_extend("force", opts.sources.providers.buffer or {}, {
        min_keyword_length = 5,
        max_items = 5,
      })

      return opts
    end,
  },
}

-- theme-switch.lua — Quick theme switching
-- Usage: :Theme <name>  or  :ThemeCycle

local themes = {
  { name = "gruvbox",     label = "Gruvbox     — cam/vàng/nâu, classic" },
  { name = "kanagawa",    label = "Kanagawa    — cam nhẹ/nâu ấm, tinh tế" },
  { name = "sonokai",     label = "Sonokai     — cam sáng/đỏ, vibrant" },
  { name = "everforest",  label = "Everforest  — xanh lá + nâu + cam" },
  { name = "rose-pine",   label = "Rose Pine   — hồng + cam + nâu, cozy" },
  { name = "tokyonight",  label = "Tokyonight  — xanh dương/tím, mát" },
  { name = "catppuccin",  label = "Catppuccin  — hồng nhạt, dịu" },
}

local idx = 1  -- catppuccin is default

local function apply_theme(name)
  local ok, _ = pcall(vim.cmd, "colorscheme " .. name)
  if not ok then
    vim.notify("Theme '" .. name .. "' not found", vim.log.levels.ERROR, { title = "Theme" })
    return false
  end
  local lualine_t = (name == "gruvbox") and "gruvbox" or "auto"
  pcall(function() require("lualine").setup({ options = { theme = lualine_t } }) end)
  vim.notify("Theme: " .. name, vim.log.levels.INFO, { title = "Theme" })
  return true
end

-- :Theme <name>
vim.api.nvim_create_user_command("Theme", function(opts)
  local name = opts.args
  if name == "" then
    -- List available themes
    local lines = { "Available themes:" }
    for i, t in ipairs(themes) do
      table.insert(lines, string.format("  %d. %s", i, t.label))
    end
    table.insert(lines, "")
    table.insert(lines, "Usage: :Theme <name>  or  :ThemeCycle")
    print(table.concat(lines, "\n"))
    return
  end
  -- Find theme by partial match
  for i, t in ipairs(themes) do
    if t.name:find(name, 1, true) then
      idx = i
      apply_theme(t.name)
      return
    end
  end
  vim.notify("Theme '" .. name .. "' not found. Use :Theme to list.", vim.log.levels.WARN, { title = "Theme" })
end, {
  nargs = "?",
  complete = function()
    return vim.tbl_map(function(t) return t.name end, themes)
  end,
})

-- :ThemeCycle
vim.api.nvim_create_user_command("ThemeCycle", function()
  idx = idx % #themes + 1
  apply_theme(themes[idx].name)
end, { desc = "Cycle themes" })

-- :ThemeList
vim.api.nvim_create_user_command("ThemeList", function()
  local lines = { "Themes:" }
  for i, t in ipairs(themes) do
    local marker = (i == idx) and " *" or ""
    table.insert(lines, string.format("  %d. %s%s", i, t.label, marker))
  end
  print(table.concat(lines, "\n"))
end, { desc = "List themes" })

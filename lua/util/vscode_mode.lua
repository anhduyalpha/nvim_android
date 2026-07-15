local M = {}

local saved_mappings = {}
local active_mappings = {}
local setup_complete = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "VSCode Mode" })
end

local function termcode(keys)
  return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

local function feed(keys, mode)
  vim.api.nvim_feedkeys(termcode(keys), mode or "n", false)
end

local function stop_insert()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == "i" or mode:sub(1, 1) == "R" then
    vim.cmd("stopinsert")
  end
end

local function same_lhs(left, right)
  return termcode(left) == termcode(right)
end

local function find_global_mapping(mode, lhs)
  for _, item in ipairs(vim.api.nvim_get_keymap(mode)) do
    if same_lhs(item.lhs, lhs) then
      return vim.deepcopy(item)
    end
  end
end

local function mapping_id(mode, lhs)
  return mode .. "\0" .. termcode(lhs)
end

local function remember_mapping(mode, lhs)
  local id = mapping_id(mode, lhs)
  if saved_mappings[id] == nil then
    saved_mappings[id] = {
      lhs = lhs,
      mode = mode,
      mapping = find_global_mapping(mode, lhs) or false,
    }
  end
end

local function restore_mapping(entry)
  pcall(vim.keymap.del, entry.mode, entry.lhs)
  local mapping = entry.mapping
  if mapping == false then
    return
  end

  local rhs = mapping.callback or mapping.rhs
  if rhs == nil or rhs == "" then
    return
  end

  vim.keymap.set(entry.mode, entry.lhs, rhs, {
    desc = mapping.desc,
    silent = mapping.silent == 1,
    expr = mapping.expr == 1,
    nowait = mapping.nowait == 1,
    remap = mapping.noremap == 0,
    replace_keycodes = mapping.replace_keycodes == 1,
  })
end

local function define(modes, lhs, rhs, description, options)
  if type(modes) == "string" then
    modes = { modes }
  end

  options = vim.tbl_extend("force", {
    silent = true,
    nowait = true,
    desc = "VSCode: " .. description,
  }, options or {})

  for _, mode in ipairs(modes) do
    remember_mapping(mode, lhs)
    vim.keymap.set(mode, lhs, rhs, options)
    active_mappings[mapping_id(mode, lhs)] = true
  end
end

local function clipboard_register()
  if vim.fn.has("clipboard") == 1 or type(vim.g.clipboard) == "table" then
    return "+"
  end
  return '"'
end

local function register_prefix()
  local register = clipboard_register()
  return register == '"' and "" or ('"' .. register)
end

local function save_current()
  if vim.bo.buftype == "" and vim.bo.modifiable and vim.api.nvim_buf_get_name(0) ~= "" then
    vim.cmd("silent! update")
  end
end

local function select_all()
  stop_insert()
  vim.cmd("normal! ggVG")
end

local function copy_visual()
  vim.cmd("normal! " .. register_prefix() .. "ygv")
end

local function cut_visual()
  vim.cmd("normal! " .. register_prefix() .. "d")
end

local function paste_normal()
  vim.cmd("normal! " .. register_prefix() .. "p")
end

local function paste_visual()
  vim.cmd("normal! \"_d" .. register_prefix() .. "P")
end

local function select_line()
  stop_insert()
  vim.cmd("normal! V")
end

local function duplicate_lines(direction)
  stop_insert()
  local mode = vim.fn.mode()
  local start_line
  local end_line

  if mode == "v" or mode == "V" or mode == "\22" then
    start_line = math.min(vim.fn.line("v"), vim.fn.line("."))
    end_line = math.max(vim.fn.line("v"), vim.fn.line("."))
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return
  end

  if direction == "up" then
    vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, lines)
    vim.api.nvim_win_set_cursor(0, { start_line, 0 })
  else
    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, lines)
    vim.api.nvim_win_set_cursor(0, { end_line + 1, 0 })
  end
end

local function insert_blank_line(direction)
  stop_insert()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local index = direction == "above" and row - 1 or row
  vim.api.nvim_buf_set_lines(0, index, index, false, { "" })
  vim.api.nvim_win_set_cursor(0, { index + 1, 0 })
  vim.cmd("startinsert")
end

local function toggle_wrap()
  vim.wo.wrap = not vim.wo.wrap
  notify("Word wrap " .. (vim.wo.wrap and "enabled" or "disabled"))
end

local function open_picker(name, fallback)
  if _G.Snacks and Snacks.picker and type(Snacks.picker[name]) == "function" then
    Snacks.picker[name]()
    return
  end
  fallback()
end

local function find_in_file()
  stop_insert()
  open_picker("lines", function()
    feed("/", "n")
  end)
end

local function replace_in_file()
  stop_insert()
  feed(":%s/", "n")
end

local function quick_open()
  stop_insert()
  open_picker("files", function()
    vim.cmd("edit ")
  end)
end

local function command_palette()
  stop_insert()
  open_picker("commands", function()
    feed(":", "n")
  end)
end

local function toggle_explorer()
  if _G.Snacks and type(Snacks.explorer) == "function" then
    Snacks.explorer()
  else
    notify("Snacks Explorer is unavailable", vim.log.levels.WARN)
  end
end

local function toggle_terminal()
  if _G.Snacks and Snacks.terminal and type(Snacks.terminal.toggle) == "function" then
    Snacks.terminal.toggle()
  else
    vim.cmd("belowright split | resize 12 | terminal")
  end
end

local function goto_line()
  vim.ui.input({ prompt = "Go to line: " }, function(value)
    local line = tonumber(value)
    if not line then
      return
    end
    local maximum = vim.api.nvim_buf_line_count(0)
    line = math.max(1, math.min(line, maximum))
    vim.api.nvim_win_set_cursor(0, { line, 0 })
  end)
end

local function lsp_action(action, label)
  return function()
    local fn = vim.lsp.buf[action]
    if type(fn) == "function" then
      fn()
    else
      notify(label .. " is unavailable", vim.log.levels.WARN)
    end
  end
end

local function fallback_select_occurrence()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("normal! n")
    vim.cmd("normal! gn")
    return
  end

  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  vim.fn.setreg("/", "\\<" .. vim.fn.escape(word, "\\.^$~[]") .. "\\>")
  vim.cmd("normal! viw")
end

local function select_next_occurrence()
  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    pcall(lazy.load, { plugins = { "vim-visual-multi" } })
  end

  local mode = vim.fn.mode()
  local plug = (mode == "v" or mode == "V" or mode == "\22")
      and "<Plug>(VM-Find-Subword-Under)"
    or "<Plug>(VM-Find-Under)"
  local plug_mode = (mode == "v" or mode == "V" or mode == "\22") and "x" or "n"

  if vim.fn.maparg(plug, plug_mode) ~= "" then
    feed(plug, "m")
  else
    fallback_select_occurrence()
  end
end

local function build_mappings()
  local register = clipboard_register()
  local prefix = register == '"' and "" or ('"' .. register)

  define({ "n", "i", "x" }, "<C-a>", select_all, "Select All")

  define("n", "<C-c>", prefix .. "yy", "Copy Line")
  define("i", "<C-c>", "<C-o>" .. prefix .. "yy", "Copy Line")
  define("x", "<C-c>", copy_visual, "Copy Selection")

  define("n", "<C-x>", prefix .. "dd", "Cut Line")
  define("i", "<C-x>", "<C-o>" .. prefix .. "dd", "Cut Line")
  define("x", "<C-x>", cut_visual, "Cut Selection")

  define("n", "<C-v>", paste_normal, "Paste")
  define("i", "<C-v>", "<C-r>" .. register, "Paste")
  define("x", "<C-v>", paste_visual, "Paste Over Selection")
  define("c", "<C-v>", "<C-r>" .. register, "Paste Into Command Line")

  define({ "n", "x" }, "<C-z>", "<cmd>undo<cr>", "Undo")
  define("i", "<C-z>", "<C-o>u", "Undo")
  define({ "n", "x" }, "<C-y>", "<cmd>redo<cr>", "Redo")
  define("i", "<C-y>", "<C-o><C-r>", "Redo")

  define({ "n", "i", "x" }, "<C-s>", save_current, "Save File")
  define({ "n", "x" }, "<C-d>", select_next_occurrence, "Select Next Occurrence")
  define({ "n", "i", "x" }, "<C-l>", select_line, "Select Line")

  define("n", "<C-_>", "gcc", "Toggle Line Comment", { remap = true })
  define("x", "<C-_>", "gc", "Toggle Selection Comment", { remap = true })
  define("i", "<C-BS>", "<C-w>", "Delete Previous Word")
  define("i", "<C-Del>", "<C-o>dw", "Delete Next Word")

  define({ "n", "i", "x" }, "<C-f>", find_in_file, "Find In File")
  define({ "n", "i", "x" }, "<C-h>", replace_in_file, "Replace In File")
  define({ "n", "i", "x" }, "<C-p>", quick_open, "Quick Open File")
  define({ "n", "i", "x" }, "<M-p>", command_palette, "Command Palette")
  define({ "n", "i" }, "<C-n>", "<cmd>enew<cr>", "New File")
  define({ "n", "i", "x" }, "<C-w>", function()
    require("util.mobile").smart_close()
  end, "Close Editor")
  define({ "n", "i" }, "<C-g>", goto_line, "Go To Line")
  define({ "n", "i", "x" }, "<C-b>", toggle_explorer, "Toggle Explorer")
  define({ "n", "i", "x" }, "<C-j>", toggle_terminal, "Toggle Terminal")

  define("n", "<M-Left>", "<C-o>", "Navigate Back")
  define("i", "<M-Left>", "<C-o><C-o>", "Navigate Back")
  define("n", "<M-Right>", "<C-i>", "Navigate Forward")
  define("i", "<M-Right>", "<C-o><C-i>", "Navigate Forward")

  define("n", "<M-Up>", "<cmd>move .-2<cr>==", "Move Line Up")
  define("n", "<M-Down>", "<cmd>move .+1<cr>==", "Move Line Down")
  define("i", "<M-Up>", "<Esc><cmd>move .-2<cr>==gi", "Move Line Up")
  define("i", "<M-Down>", "<Esc><cmd>move .+1<cr>==gi", "Move Line Down")
  define("x", "<M-Up>", ":move '<-2<cr>gv=gv", "Move Selection Up")
  define("x", "<M-Down>", ":move '>+1<cr>gv=gv", "Move Selection Down")

  define({ "n", "i", "x" }, "<M-S-Up>", function()
    duplicate_lines("up")
  end, "Duplicate Up")
  define({ "n", "i", "x" }, "<M-S-Down>", function()
    duplicate_lines("down")
  end, "Duplicate Down")

  define("n", "<C-Left>", "b", "Previous Word")
  define("n", "<C-Right>", "w", "Next Word")
  define("i", "<C-Left>", "<C-o>b", "Previous Word")
  define("i", "<C-Right>", "<C-o>w", "Next Word")
  define({ "n", "x" }, "<C-Home>", "gg", "Start Of File")
  define({ "n", "x" }, "<C-End>", "G", "End Of File")
  define("i", "<C-Home>", "<C-o>gg", "Start Of File")
  define("i", "<C-End>", "<C-o>G", "End Of File")

  define("n", "<S-Left>", "v<Left>", "Select Left")
  define("n", "<S-Right>", "v<Right>", "Select Right")
  define("n", "<S-Up>", "v<Up>", "Select Up")
  define("n", "<S-Down>", "v<Down>", "Select Down")
  define("x", "<S-Left>", "<Left>", "Extend Selection Left")
  define("x", "<S-Right>", "<Right>", "Extend Selection Right")
  define("x", "<S-Up>", "<Up>", "Extend Selection Up")
  define("x", "<S-Down>", "<Down>", "Extend Selection Down")

  define({ "n", "i" }, "<C-CR>", function()
    insert_blank_line("below")
  end, "Insert Line Below")
  define({ "n", "i" }, "<C-S-CR>", function()
    insert_blank_line("above")
  end, "Insert Line Above")
  define({ "n", "i", "x" }, "<M-z>", toggle_wrap, "Toggle Word Wrap")

  define("n", "<F2>", lsp_action("rename", "Rename"), "Rename Symbol")
  define("n", "<F12>", lsp_action("definition", "Definition"), "Go To Definition")
  define("n", "<S-F12>", lsp_action("references", "References"), "Find References")
  define({ "n", "x" }, "<C-.>", lsp_action("code_action", "Code action"), "Code Action")
end

local function fire_changed_event(enabled)
  pcall(vim.api.nvim_exec_autocmds, "User", {
    pattern = "VscodeModeChanged",
    data = { enabled = enabled },
  })
end

function M.enable(options)
  if vim.g.vscode_mode_enabled then
    if not (options and options.quiet) then
      notify("Already enabled")
    end
    return
  end

  saved_mappings = {}
  active_mappings = {}
  build_mappings()
  vim.g.vscode_mode_enabled = true
  fire_changed_event(true)

  if not (options and options.quiet) then
    notify("Enabled — type :vscode again to return to mobile mode")
  end
end

function M.disable(options)
  if not vim.g.vscode_mode_enabled then
    if not (options and options.quiet) then
      notify("Already disabled")
    end
    return
  end

  for id in pairs(active_mappings) do
    local entry = saved_mappings[id]
    if entry then
      restore_mapping(entry)
    end
  end

  active_mappings = {}
  saved_mappings = {}
  vim.g.vscode_mode_enabled = false
  fire_changed_event(false)

  if not (options and options.quiet) then
    notify("Disabled — touch-first mobile mappings restored")
  end
end

function M.toggle()
  if vim.g.vscode_mode_enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.status()
  local enabled = vim.g.vscode_mode_enabled == true
  notify("Status: " .. (enabled and "enabled" or "disabled"))
  return enabled
end

function M.command(argument)
  argument = (argument or ""):lower()
  if argument == "" or argument == "toggle" then
    M.toggle()
  elseif argument == "on" or argument == "enable" then
    M.enable()
  elseif argument == "off" or argument == "disable" then
    M.disable()
  elseif argument == "status" then
    M.status()
  else
    notify("Use :vscode [on|off|toggle|status]", vim.log.levels.WARN)
  end
end

function M.setup()
  if setup_complete then
    return
  end
  setup_complete = true
  vim.g.vscode_mode_enabled = vim.g.vscode_mode_enabled == true

  pcall(vim.api.nvim_del_user_command, "Vscode")
  vim.api.nvim_create_user_command("Vscode", function(options)
    M.command(options.args)
  end, {
    nargs = "?",
    complete = function()
      return { "on", "off", "toggle", "status" }
    end,
    desc = "Toggle VSCode-style keyboard mode",
  })

  vim.cmd([[
    cnoreabbrev <expr> vscode
          \ getcmdtype() ==# ':' && getcmdline() ==# 'vscode'
          \ ? 'Vscode' : 'vscode'
  ]])

  if vim.g.vscode_mode_default then
    vim.schedule(function()
      M.enable({ quiet = true })
    end)
  end
end

return M

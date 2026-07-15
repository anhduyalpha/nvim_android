vim.g.android_autosave_delay = 50
vim.g.android_autosave_enabled = true

dofile("lua/config/autocmds.lua")

local function assert_true(value, message)
  if not value then
    error(message)
  end
end

assert_true(vim.fn.exists(":AutoSaveToggle") == 2, ":AutoSaveToggle is missing")
assert_true(vim.fn.exists(":AutoSaveNow") == 2, ":AutoSaveNow is missing")

local events = {}
for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "AndroidAutoSave" })) do
  events[autocmd.event] = true
end

for _, event in ipairs({ "TextChanged", "TextChangedI", "BufLeave", "FocusLost", "BufWipeout", "VimLeavePre" }) do
  assert_true(events[event], "autosave event is missing: " .. event)
end

local path = vim.fn.tempname() .. ".cpp"
vim.cmd("edit " .. vim.fn.fnameescape(path))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "int main() { return 0; }" })
vim.api.nvim_exec_autocmds("TextChangedI", { buffer = 0 })

local saved = vim.wait(1000, function()
  if vim.fn.filereadable(path) ~= 1 then
    return false
  end
  local lines = vim.fn.readfile(path)
  return lines[1] == "int main() { return 0; }"
end, 20)

assert_true(saved, "debounced autosave did not write the modified buffer")
assert_true(not vim.bo.modified, "buffer remains modified after autosave")

vim.fn.delete(path)
print("PASS: debounced autosave commands, events, and write behavior work")

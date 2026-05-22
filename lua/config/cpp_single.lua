local M = {}

-- Biến cấu hình Global
vim.g.cpp_compiler = vim.g.cpp_compiler or "clang++"
vim.g.cpp_std = vim.g.cpp_std or "c++20"
vim.g.cpp_flags = vim.g.cpp_flags or "-O2 -Wall -Wextra -Wpedantic -pipe"

local function notify(msg, level)
  level = level or "info"
  local lvl = level == "error" and vim.log.levels.ERROR
    or level == "warn" and vim.log.levels.WARN
    or vim.log.levels.INFO
  vim.notify(msg, lvl, { title = "C++ Single File" })
end

local function run_background(cmd, callback)
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        callback(exit_code == 0, output)
      end)
    end,
  })
  if job_id <= 0 then
    notify("Không thể chạy lệnh: " .. cmd, "error")
  end
end

local function find_project_root()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return vim.fn.getcwd()
  end
  local dir = vim.fn.fnamemodify(file, ":h")
  while dir ~= vim.fn.fnamemodify(dir, ":h") do
    if vim.fn.isdirectory(dir .. "/header") == 1 and vim.fn.isdirectory(dir .. "/source") == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return vim.fn.getcwd()
end

local function get_build_binary()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return nil
  end
  local project_root = find_project_root()
  return project_root .. "/build/" .. vim.fn.fnamemodify(file, ":t:r")
end

local function compile_current(extra_flags, callback)
  local file = vim.fn.expand("%:p")
  if file == "" then
    notify("Không có file nào đang mở!", "warn")
    return
  end

  local project_root = find_project_root()
  local build_dir = project_root .. "/build"
  vim.fn.mkdir(build_dir, "p")

  local binary = get_build_binary()
  local compiler, std, flags = vim.g.cpp_compiler, vim.g.cpp_std, vim.g.cpp_flags
  local extra_sources, include_flag = "", ""

  if vim.fn.isdirectory(project_root .. "/header") == 1 and vim.fn.isdirectory(project_root .. "/source") == 1 then
    local srcs = vim.fn.glob(project_root .. "/source/*.cpp", false, true)
    local filtered = {}
    for _, s in ipairs(srcs) do
      if s ~= file then
        table.insert(filtered, s)
      end
    end
    if #filtered > 0 then
      extra_sources = " " .. table.concat(filtered, " ")
    end
    include_flag = "-I" .. project_root .. "/header/ "
  end

  local cmd =
    string.format("%s -std=%s %s %s%s%s -o %s 2>&1", compiler, std, flags, include_flag, file, extra_sources, binary)

  notify("⏳ Đang compile...")
  run_background(cmd, function(success, output)
    if success then
      notify("✅ Compile thành công!")
    else
      notify("❌ Compile thất bại! Xem quickfix.", "error")
      vim.fn.setqflist({}, "r", { title = "Compile Errors", lines = output })
      vim.cmd("copen")
    end
    callback(success, output, binary)
  end)
end

local function run_in_terminal(binary, show_time)
  if vim.fn.filereadable(binary) ~= 1 then
    notify("Binary chưa tồn tại, hãy compile trước!", "warn")
    return
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      break
    end
  end
  vim.cmd("belowright split | resize 15")
  if show_time then
    vim.cmd("terminal time " .. vim.fn.shellescape(binary))
  else
    vim.cmd("terminal " .. vim.fn.shellescape(binary))
  end
  vim.cmd("startinsert")
end

function M.setup()
  local cpp_group = vim.api.nvim_create_augroup("CppLeaderKey", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = cpp_group,
    pattern = { "c", "cpp" },
    callback = function()
      vim.defer_fn(function()
        local wk = require("which-key")
        wk.add({ { "c", group = "⚡ C++ Dev", buffer = 0 } })

        vim.keymap.set("n", "c", function()
          wk.show("c", { mode = "n" })
        end, { buffer = 0, desc = "C++ Dev Leader", silent = true })
        vim.keymap.set("n", "ct", function()
          compile_current("", function(success, _, binary)
            if success then
              run_in_terminal(binary, false)
            end
          end)
        end, { buffer = 0, desc = "Compile & Run", silent = true })
        vim.keymap.set("n", "cs", function()
          compile_current("", function(success, _, binary)
            if success then
              run_in_terminal(binary, true)
            end
          end)
        end, { buffer = 0, desc = "Compile & Run + Time", silent = true })
        vim.keymap.set("n", "cv", function()
          compile_current("-fsanitize=undefined -fno-sanitize-recover=all", function(success, _, binary)
            if success then
              run_in_terminal(binary, false)
            end
          end)
        end, { buffer = 0, desc = "Compile + UBSan", silent = true })
        vim.keymap.set("n", "cr", function()
          local binary = get_build_binary()
          if binary then
            run_in_terminal(binary, false)
          end
        end, { buffer = 0, desc = "Re-run binary", silent = true })
        vim.keymap.set("n", "ce", function()
          if #vim.fn.getqflist() == 0 then
            notify("Không có lỗi trong quickfix", "info")
          else
            vim.cmd("copen")
          end
        end, { buffer = 0, desc = "Show errors", silent = true })
      end, 100)
    end,
  })
end

return M

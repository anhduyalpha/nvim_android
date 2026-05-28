local M = {}

local function notify(msg, level)
  local lvl = level == "error" and vim.log.levels.ERROR
    or level == "warn" and vim.log.levels.WARN
    or vim.log.levels.INFO
  vim.notify(msg, lvl, { title = "C++ OOP Mode" })
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

local function is_oop_dir()
  -- 1. Kiểm tra thư mục làm việc hiện tại (cwd)
  local cwd = vim.fn.getcwd()
  local folder_name = vim.fn.fnamemodify(cwd, ":t")
  if folder_name == "OOP" or (vim.fn.isdirectory(cwd .. "/header") == 1 and vim.fn.isdirectory(cwd .. "/source") == 1) then
    return true
  end

  -- 2. Kiểm tra thư mục dự án chứa file của buffer đang mở
  local file = vim.fn.expand("%:p")
  if file ~= "" then
    local project_root = find_project_root()
    if vim.fn.isdirectory(project_root .. "/header") == 1 and vim.fn.isdirectory(project_root .. "/source") == 1 then
      return true
    end
  end

  return false
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

local function scaffold_project(project_path)
  vim.fn.mkdir(project_path .. "/header", "p")
  vim.fn.mkdir(project_path .. "/source", "p")

  local files = {
    ["/source/source.cpp"] = '#include <iostream>\n\nusing namespace std;\n\nint main() {\n    cout << "Hello OOP!" << endl;\n    return 0;\n}\n',
  }

  for rel_path, content in pairs(files) do
    local f = io.open(project_path .. rel_path, "w")
    if f then
      f:write(content)
      f:close()
    end
  end

  vim.defer_fn(function()
    vim.cmd("edit " .. project_path .. "/source/source.cpp")
  end, 100)
end

-- ==================== AUTO INCLUDE KHI LƯU ====================
local symbol_to_header = {
  ["cout"] = "iostream",
  ["cin"] = "iostream",
  ["cerr"] = "iostream",
  ["endl"] = "iostream",
  ["vector"] = "vector",
  ["string"] = "string",
  ["to_string"] = "string",
  ["map"] = "map",
  ["multimap"] = "map",
  ["unordered_map"] = "unordered_map",
  ["set"] = "set",
  ["multiset"] = "set",
  ["unordered_set"] = "unordered_set",
  ["sort"] = "algorithm",
  ["reverse"] = "algorithm",
  ["find"] = "algorithm",
  ["min"] = "algorithm",
  ["max"] = "algorithm",
  ["swap"] = "algorithm",
  ["lower_bound"] = "algorithm",
  ["upper_bound"] = "algorithm",
  ["next_permutation"] = "algorithm",
  ["setw"] = "iomanip",
  ["setprecision"] = "iomanip",
  ["fixed"] = "iomanip",
  ["sqrt"] = "cmath",
  ["pow"] = "cmath",
  ["abs"] = "cmath",
  ["ceil"] = "cmath",
  ["floor"] = "cmath",
  ["log"] = "cmath",
  ["sin"] = "cmath",
  ["cos"] = "cmath",
  ["rand"] = "cstdlib",
  ["srand"] = "cstdlib",
  ["atoi"] = "cstdlib",
  ["printf"] = "cstdio",
  ["scanf"] = "cstdio",
  ["sprintf"] = "cstdio",
  ["sscanf"] = "cstdio",
  ["ifstream"] = "fstream",
  ["ofstream"] = "fstream",
  ["fstream"] = "fstream",
  ["unique_ptr"] = "memory",
  ["shared_ptr"] = "memory",
  ["make_unique"] = "memory",
  ["make_shared"] = "memory",
  ["pair"] = "utility",
  ["make_pair"] = "utility",
  ["move"] = "utility",
  ["forward"] = "utility",
  ["function"] = "functional",
  ["bind"] = "functional",
  ["array"] = "array",
  ["list"] = "list",
  ["deque"] = "deque",
  ["queue"] = "queue",
  ["priority_queue"] = "queue",
  ["stack"] = "stack",
  ["accumulate"] = "numeric",
  ["iota"] = "numeric",
  ["strlen"] = "cstring",
  ["strcpy"] = "cstring",
  ["strcmp"] = "cstring",
  ["memset"] = "cstring",
  ["memcpy"] = "cstring",
  ["stringstream"] = "sstream",
  ["istringstream"] = "sstream",
  ["ostringstream"] = "sstream",
  ["time"] = "ctime",
  ["clock"] = "ctime",
  ["chrono"] = "chrono",
  ["thread"] = "thread",
  ["mutex"] = "mutex",
  ["malloc"] = "cstdlib",
  ["calloc"] = "cstdlib",
  ["realloc"] = "cstdlib",
  ["free"] = "cstdlib",
  ["exit"] = "cstdlib",
  ["bool"] = "cstdbool",
  ["true"] = "cstdbool",
  ["false"] = "cstdbool",
  ["assert"] = "cassert",
}

local function has_include(content, header)
  local pattern = '#include[%s]*[<"]' .. header:gsub("%.", "%%.") .. '[>"]'
  return content:match(pattern) ~= nil
end

local function setup_auto_include()
  local auto_group = vim.api.nvim_create_augroup("CppAutoInclude", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = auto_group,
    pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content = table.concat(lines, "\n")
      
      -- Một pass trích xuất từ (O(N)) thay vì nhiều regex scans
      local words = {}
      for word in content:gmatch("[a-zA-Z_][a-zA-Z0-9_]*") do
        words[word] = true
      end

      -- Tự động phát hiện file C hay C++
      local file = vim.fn.expand("%:p")
      local ext = vim.fn.fnamemodify(file, ":e")
      local is_c = (ext == "c" or ext == "h" or vim.bo.filetype == "c")

      local needed = {}
      for symbol, header in pairs(symbol_to_header) do
        local mapped_header = header
        if is_c then
          if header == "cstdio" then mapped_header = "stdio.h"
          elseif header == "cstdlib" then mapped_header = "stdlib.h"
          elseif header == "cstring" then mapped_header = "string.h"
          elseif header == "cmath" then mapped_header = "math.h"
          elseif header == "ctime" then mapped_header = "time.h"
          elseif header == "cassert" then mapped_header = "assert.h"
          elseif header == "cstdbool" then mapped_header = "stdbool.h"
          else
            mapped_header = nil
          end
        else
          -- Trong C++, cstdbool không cần thiết vì bool/true/false là built-in
          if header == "cstdbool" then
            mapped_header = nil
          elseif header == "cassert" then
            mapped_header = "cassert"
          end
        end

        if mapped_header and words[symbol] and not has_include(content, mapped_header) then
          needed[mapped_header] = true
        end
      end
      
      if not next(needed) then
        return
      end
      
      local sorted = {}
      for h in pairs(needed) do
        table.insert(sorted, h)
      end
      table.sort(sorted)
      
      local insert_line = 1
      for i, line in ipairs(lines) do
        if line:match("^#include") or ((line:match("^#ifndef") or line:match("^#pragma once")) and i <= 5) then
          insert_line = i + 1
        end
      end
      
      local insert_lines = {}
      for _, h in ipairs(sorted) do
        table.insert(insert_lines, "#include <" .. h .. ">")
      end
      vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, insert_lines)
      notify("📝 Auto-include: " .. table.concat(sorted, ", "))
    end,
  })
end

-- ==================== SETUP PHÍM TẮT OOP ====================
function M.setup()
  setup_auto_include()

  local function setup_oop_keymaps()
    if not is_oop_dir() then
      return
    end
    local map = vim.keymap.set
    -- Khởi tạo biến mode nếu chưa có
    vim.g.cpp_compile_mode = vim.g.cpp_compile_mode or "debug"

    map("n", "<leader>om", function()
      if vim.g.cpp_compile_mode == "release" then
        vim.g.cpp_compile_mode = "debug"
        vim.g.cpp_flags = "-O0 -Wall -Wextra -Wpedantic -pipe"
        notify("🛡️ Mode: DEBUG (-O0, Compile siêu nhanh, an toàn)")
      else
        vim.g.cpp_compile_mode = "release"
        vim.g.cpp_flags = "-O3 -Wall -Wextra -Wpedantic -DNDEBUG -pipe"
        notify("⚡ Mode: RELEASE (-O3, Tối ưu tối đa, không debug)")
      end
    end, { desc = "Toggle Debug/Release Compile Mode", silent = true })

    map("n", "<leader>oqq", "<esc>", { desc = "Thoát WhichKey", silent = true })

    map("n", "<leader>os", function()
      vim.ui.input({ prompt = "Tên Solution: " }, function(name)
        if not name or name == "" then
          return
        end
        local solution_path = vim.fn.getcwd() .. "/" .. name
        vim.fn.mkdir(solution_path, "p")
        vim.cmd("cd " .. solution_path)
        notify("✅ Đã tạo Solution: " .. name)
        vim.ui.input({ prompt = "Tạo Project đầu tiên? (tên/bỏ trống): " }, function(proj)
          if proj and proj ~= "" then
            scaffold_project(solution_path .. "/" .. proj)
            notify("✅ Đã tạo Project: " .. proj)
          end
        end)
      end)
    end, { desc = "Tạo Solution mới", silent = true })

    map("n", "<leader>op", function()
      vim.ui.input({ prompt = "Tên Project: " }, function(name)
        if not name or name == "" then
          return
        end
        scaffold_project(vim.fn.getcwd() .. "/" .. name)
        notify("✅ Đã tạo Project: " .. name)
      end)
    end, { desc = "Tạo Project mới", silent = true })

    map("n", "<leader>oc", function()
      vim.ui.input({ prompt = "Tên Class: " }, function(name)
        if not name or name == "" then
          return
        end
        local root = vim.fn.getcwd()
        local display = name:sub(1, 1):upper() .. name:sub(2)

        local h_path = root .. "/header/" .. display .. ".h"
        local f = io.open(h_path, "w")
        if f then
          f:write(
            string.format(
              "#pragma once\n\nclass %s\n{\n};\n",
              display
            )
          )
          f:close()
        end

        local cpp_path = root .. "/source/" .. display .. ".cpp"
        f = io.open(cpp_path, "w")
        if f then
          f:write(
            string.format(
              '#include "%s.h"\n',
              display
            )
          )
          f:close()
        end

        notify("✅ Đã tạo Class: " .. display)
        vim.cmd("edit " .. h_path)
        vim.cmd("vsplit " .. cpp_path)
      end)
    end, { desc = "Tạo Class mới", silent = true })

    -- Tìm tất cả thư mục chứa file header (.h, .hpp) đệ quy để tự động detect thay vì nhập full đường dẫn
    local function get_oop_include_flags(project_root)
      project_root = project_root:gsub("\\", "/")
      local dirs = {}
      -- Mặc định thêm header/ và source/ của dự án
      local default_header = project_root .. "/header"
      local default_source = project_root .. "/source"
      if vim.fn.isdirectory(default_header) == 1 then
        dirs[default_header] = true
      end
      if vim.fn.isdirectory(default_source) == 1 then
        dirs[default_source] = true
      end

      -- Tìm đệ quy các thư mục chứa .h hoặc .hpp
      local h_files = vim.fn.globpath(project_root, "/**/*.h", false, true)
      local hpp_files = vim.fn.globpath(project_root, "/**/*.hpp", false, true)
      for _, files in ipairs({ h_files, hpp_files }) do
        for _, f in ipairs(files) do
          local dir = vim.fn.fnamemodify(f, ":h"):gsub("\\", "/")
          dirs[dir] = true
        end
      end

      local flags = {}
      for d, _ in pairs(dirs) do
        table.insert(flags, "-I" .. vim.fn.shellescape(d))
      end
      return table.concat(flags, " ") .. " "
    end

    -- Tự động sinh file compile_flags.txt để cấu hình cho LSP clangd nhận diện đầy đủ header
    local function write_compile_flags_txt(project_root)
      project_root = project_root:gsub("\\", "/")
      local root_name = vim.fn.fnamemodify(project_root, ":t"):lower()
      if root_name == "oop" then
        return
      end
      local dirs = {}
      -- Mặc định thêm header/ và source/
      local default_header = project_root .. "/header"
      local default_source = project_root .. "/source"
      if vim.fn.isdirectory(default_header) == 1 then
        dirs[default_header] = true
      end
      if vim.fn.isdirectory(default_source) == 1 then
        dirs[default_source] = true
      end

      -- Tìm đệ quy các thư mục chứa .h hoặc .hpp
      local h_files = vim.fn.globpath(project_root, "/**/*.h", false, true)
      local hpp_files = vim.fn.globpath(project_root, "/**/*.hpp", false, true)
      for _, files in ipairs({ h_files, hpp_files }) do
        for _, f in ipairs(files) do
          local dir = vim.fn.fnamemodify(f, ":h"):gsub("\\", "/")
          dirs[dir] = true
        end
      end

      -- Sinh nội dung compile_flags.txt
      local lines = {
        "-xc++",
        "-std=c++20",
      }
      for d, _ in pairs(dirs) do
        table.insert(lines, "-I" .. d)
      end

      local filepath = project_root .. "/compile_flags.txt"
      local f = io.open(filepath, "w")
      if f then
        f:write(table.concat(lines, "\n") .. "\n")
        f:close()
      end
    end

    map("n", "<leader>ob", function()
      local root = find_project_root()
      local file = vim.fn.expand("%:p")
      local ext = file ~= "" and vim.fn.fnamemodify(file, ":e") or ""
      local is_c = (ext == "c" or ext == "h" or vim.bo.filetype == "c")

      local compiler = is_c and "clang" or vim.g.cpp_compiler
      local std = is_c and "c17" or vim.g.cpp_std
      local flags = vim.g.cpp_flags

      local pattern = is_c and "/**/*.c" or "/**/*.cpp"
      local srcs = vim.fn.globpath(root .. "/source", pattern, false, true)
      if #srcs == 0 then
        notify("Không tìm thấy file nguồn trong source/!", "warn")
        return
      end

      local build_dir = root .. "/build"
      local binary = build_dir .. "/main"
      vim.fn.mkdir(build_dir, "p")
      write_compile_flags_txt(root)

      local include_flag = get_oop_include_flags(root)
      local escaped_srcs = {}
      for _, s in ipairs(srcs) do
        table.insert(escaped_srcs, vim.fn.shellescape(s))
      end

      local cmd = string.format(
        "%s -std=%s %s %s%s -o %s 2>&1",
        compiler,
        std,
        flags,
        include_flag,
        table.concat(escaped_srcs, " "),
        vim.fn.shellescape(binary)
      )
      notify("⏳ Đang build...")
      run_background(cmd, function(success, output)
        if success then
          notify("✅ Build thành công!")
          run_in_terminal(binary, false)
        else
          notify("❌ Build thất bại!", "error")
          vim.fn.setqflist({}, "r", { title = "Build Errors", lines = output })
          vim.cmd("copen")
        end
      end)
    end, { desc = "Build & Run All", silent = true })

    map("n", "<leader>or", function()
      run_in_terminal(find_project_root() .. "/build/main", false)
    end, { desc = "Run (no rebuild)", silent = true })

    -- Tự động sinh compile_flags.txt cho clangd hoạt động tức thì
    local root = find_project_root()
    write_compile_flags_txt(root)

    local ft = vim.bo.filetype
    local bt = vim.bo.buftype
    local is_special = (ft == "snacks_explorer" or ft == "snacks_explorer_tree" or ft == "lazy" or ft == "mason" or bt == "nofile" or bt == "terminal" or bt == "prompt")

    if not is_special and vim.g.oop_mode_last_notified_root ~= root then
      notify("🏗️ OOP Mode đã kích hoạt trong: " .. root)
      vim.g.oop_mode_last_notified_root = root
    end
  end

  local oop_group = vim.api.nvim_create_augroup("OopMode", { clear = true })
  vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "BufEnter" }, {
    group = oop_group,
    callback = function()
      vim.defer_fn(setup_oop_keymaps, 200)
    end,
  })
end

return M

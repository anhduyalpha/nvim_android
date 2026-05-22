-- ============================================================================
-- lua/plugins/cpp.lua — C/C++ Dev Config cho LazyVim trên Điện thoại (Termux)
-- ============================================================================
-- Đặt file này vào: ~/.config/nvim/lua/plugins/cpp.lua
-- Tự động load bởi LazyVim (không cần require trong init.lua)
-- ============================================================================
-- Cài đặt trên Termux:
--   pkg install clang lld
-- ============================================================================

return {
  -- ========================================================================
  -- 1. CÀI ĐẶT PLUGIN CẦN THIẾT
  -- ========================================================================

  -- LSP cho C/C++ — tối ưu cho Termux/Android
  -- Chỉ set mason=false, config clangd sẽ dùng vim.lsp.config ở init.lua
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.clangd = { mason = false }
      return opts
    end,
  },

  -- Completion: blink.cmp (đã cài, không dùng nvim-cmp)
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-e>"] = { "hide", "fallback" },
      },
      completion = {
        list = {
          selection = { preselect = true, auto_insert = true },
          max_items = 50,
        },
        menu = {
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
        },
        ghost_text = { enabled = true },
      },
      sources = {
        default = { "lsp", "snippets", "path", "buffer" },
        per_filetype = {
          cpp = { "lsp", "snippets", "path", "buffer" },
          c = { "lsp", "snippets", "path", "buffer" },
        },
        providers = {
          lsp = { min_keyword_length = 2, score_offset = 100 },
          snippets = { min_keyword_length = 2, score_offset = 80 },
          buffer = { min_keyword_length = 4, max_items = 10, score_offset = -100 },
        },
      },
      signature = { enabled = true },
    },
  },

  -- ========================================================================
  -- 2. CONFIG CHÍNH — TÍNH NĂNG C++ DEV
  -- ========================================================================

  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- Thêm OOP mode vào which-key registrations (API mới)
      vim.list_extend(opts.defaults or {}, {
        { "<leader>o", group = "OOP Mode" },
        { "<leader>os", desc = "Tạo Solution" },
        { "<leader>op", desc = "Tạo Project" },
        { "<leader>oc", desc = "Tạo Class" },
        { "<leader>ob", desc = "Build & Run All" },
        { "<leader>or", desc = "Run (no rebuild)" },
      })
      return opts
    end,
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)

      -- ==================================================================
      -- BIẾN CẤU HÌNH
      -- ==================================================================
      vim.g.cpp_compiler = vim.g.cpp_compiler or "clang++"
      vim.g.cpp_std = vim.g.cpp_std or "c++20"
      vim.g.cpp_flags = vim.g.cpp_flags or "-O2 -Wall -Wextra -Wpedantic -pipe"

      -- ==================================================================
      -- HÀM TIỆN ÍCH
      -- ==================================================================

      --- Hiển thị notification (không dùng floating window lớn)
      local function notify(msg, level)
        level = level or "info"
        local lvl = ({
          info = vim.log.levels.INFO,
          warn = vim.log.levels.WARN,
          error = vim.log.levels.ERROR,
        })[level] or vim.log.levels.INFO
        vim.notify(msg, lvl, { title = "C++ Dev" })
      end

      --- Chạy lệnh nền bằng jobstart (không mở terminal split)
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

      --- Tìm project root (có header/ và source/)
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

      --- Lấy đường dẫn binary trong build/ (trong project root)
      local function get_build_binary()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return nil
        end
        local project_root = find_project_root()
        local name = vim.fn.fnamemodify(file, ":t:r")
        return project_root .. "/build/" .. name
      end

      --- Compile file C/C++ hiện tại → output vào build/ (trong project root)
      --- Nếu trong project OOP → compile tất cả source/*.cpp
      local function compile_current(extra_flags, callback)
        local file = vim.fn.expand("%:p")
        if file == "" then
          notify("Không có file nào đang mở!", "warn")
          return
        end

        local binary = get_build_binary()
        local project_root = find_project_root()
        local build_dir = project_root .. "/build"
        vim.fn.mkdir(build_dir, "p")

        local compiler = vim.g.cpp_compiler
        local std = vim.g.cpp_std
        local flags = vim.g.cpp_flags

        -- Nếu trong project OOP (có header/ + source/), compile tất cả source/*.cpp
        local extra_sources = ""
        local include_flag = ""
        if
          vim.fn.isdirectory(project_root .. "/header") == 1 and vim.fn.isdirectory(project_root .. "/source") == 1
        then
          local srcs = vim.fn.glob(project_root .. "/source/*.cpp", false, true)
          -- Loại trừ file hiện tại nếu nó nằm trong source/
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

        local cmd = string.format(
          "%s -std=%s %s %s%s%s -o %s 2>&1",
          compiler,
          std,
          flags,
          include_flag,
          file,
          extra_sources,
          binary
        )

        notify("⏳ Đang compile...")
        run_background(cmd, function(success, output)
          if success then
            notify("✅ Compile thành công!")
          else
            notify("❌ Compile thất bại! Xem quickfix.", "error")
            vim.fn.setqflist({}, "r", {
              title = "Compile Errors",
              lines = output,
            })
            vim.cmd("copen")
          end
          callback(success, output, binary)
        end)
      end

      --- Mở popup terminal để chạy binary (tương tác được)
      local function run_in_terminal(binary, show_time)
        if vim.fn.filereadable(binary) ~= 1 then
          notify("Binary chưa tồn tại, hãy compile trước!", "warn")
          return
        end

        -- Đóng terminal cũ nếu đang mở
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buftype == "terminal" then
            local ok = pcall(vim.api.nvim_buf_delete, buf, { force = true })
            if ok then
              break
            end
          end
        end

        -- Mở split terminal ở dưới
        vim.cmd("belowright split | resize 15")
        if show_time then
          vim.cmd("terminal time " .. vim.fn.shellescape(binary))
        else
          vim.cmd("terminal " .. vim.fn.shellescape(binary))
        end

        -- Focus vào terminal để tương tác ngay
        vim.cmd("startinsert")
      end

      --- Kiểm tra cwd có phải OOP không
      local function is_oop_dir()
        local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        return cwd == "OOP"
      end

      -- ==================================================================
      -- TẠO CẤU TRÚC PROJECT (OOP MODE)
      -- ==================================================================

      --- Scaffold project mẫu
      local function scaffold_project(project_path)
        vim.fn.mkdir(project_path .. "/header", "p")
        vim.fn.mkdir(project_path .. "/source", "p")

        local files = {
          ["/source/source.cpp"] = [[#include <iostream>
#include "example.h"

int main() {
    Example obj;
    obj.hello();
    return 0;
}
]],
          ["/header/example.h"] = [[#ifndef EXAMPLE_H
#define EXAMPLE_H

class Example {
public:
    Example();
    ~Example();
    void hello();
};

#endif // EXAMPLE_H
]],
          ["/source/example.cpp"] = [[#include "example.h"
#include <iostream>

Example::Example() {}
Example::~Example() {}

void Example::hello() {
    std::cout << "Hello from Example!" << std::endl;
}
]],
        }

        for rel_path, content in pairs(files) do
          local f = io.open(project_path .. rel_path, "w")
          if f then
            f:write(content)
            f:close()
          end
        end

        -- Auto mở source.cpp + header/example.h dạng split
        vim.defer_fn(function()
          local source_file = project_path .. "/source/source.cpp"
          local header_file = project_path .. "/header/example.h"
          vim.cmd("edit " .. source_file)
          vim.cmd("vsplit " .. header_file)
          vim.cmd("wincmd h") -- focus vào source.cpp
        end, 100)
      end

      -- ==================================================================
      -- LEADER PHỤ `c` — CHỈ CHO C/C++ BUFFER
      -- ==================================================================

      local function setup_cpp_leader()
        local ft = vim.bo.filetype
        if ft ~= "c" and ft ~= "cpp" then
          return
        end

        -- Đăng ký which-key cho buffer hiện tại (dùng wk.add API mới)
        wk.add({
          { "<leader>c", group = "C++ Dev", buffer = 0 },
          { "<leader>ct", desc = "Compile & Run", buffer = 0 },
          { "<leader>cs", desc = "Compile & Run + Time", buffer = 0 },
          { "<leader>cv", desc = "Compile + UBSan", buffer = 0 },
          { "<leader>cr", desc = "Re-run binary", buffer = 0 },
          { "<leader>ce", desc = "Show errors (quickfix)", buffer = 0 },
          { "<leader>cR", desc = "Restart clangd", buffer = 0 },
        })

        -- `c` mở which-key
        vim.keymap.set("n", "c", function()
          wk.show("c", { mode = "n" })
        end, { buffer = 0, desc = "C++ Dev Leader", silent = true })

        -- ct: Compile & Run
        vim.keymap.set("n", "ct", function()
          compile_current("", function(success, _, binary)
            if success then
              run_in_terminal(binary, false)
            end
          end)
        end, { buffer = 0, desc = "Compile & Run", silent = true })

        -- cs: Compile & Run + Đo thời gian
        vim.keymap.set("n", "cs", function()
          compile_current("", function(success, _, binary)
            if success then
              run_in_terminal(binary, true)
            end
          end)
        end, { buffer = 0, desc = "Compile & Run + Time", silent = true })

        -- cv: Compile + UBSan
        vim.keymap.set("n", "cv", function()
          compile_current("-fsanitize=undefined -fno-sanitize-recover=all", function(success, _, binary)
            if success then
              run_in_terminal(binary, false)
            end
          end)
        end, { buffer = 0, desc = "Compile + UBSan", silent = true })

        -- cr: Re-run
        vim.keymap.set("n", "cr", function()
          local binary = get_build_binary()
          if binary then
            run_in_terminal(binary, false)
          end
        end, { buffer = 0, desc = "Re-run binary", silent = true })

        -- ce: Show errors
        vim.keymap.set("n", "ce", function()
          local qf = vim.fn.getqflist()
          if #qf == 0 then
            notify("Không có lỗi trong quickfix list", "info")
          else
            vim.cmd("copen")
          end
        end, { buffer = 0, desc = "Show errors", silent = true })

        -- cR: Restart clangd (khi completion bị stuck)
        vim.keymap.set("n", "cR", function()
          vim.cmd("LspRestart clangd")
          notify("clangd restarted")
        end, { buffer = 0, desc = "Restart clangd", silent = true })
      end

      -- ==================================================================
      -- OOP MODE — `<leader>o`
      -- ==================================================================

      local function setup_oop_mode()
        if not is_oop_dir() then
          return
        end

        -- <leader>os: Tạo Solution (auto vào solution, không vào project)
        vim.keymap.set("n", "<leader>os", function()
          vim.ui.input({ prompt = "Tên Solution: " }, function(name)
            if not name or name == "" then
              return
            end

            local cwd = vim.fn.getcwd()
            local solution_path = cwd .. "/" .. name

            if vim.fn.isdirectory(solution_path) == 1 then
              notify("Solution '" .. name .. "' đã tồn tại!", "warn")
              return
            end

            vim.fn.mkdir(solution_path, "p")
            vim.cmd("cd " .. solution_path)
            notify("✅ Đã tạo Solution: " .. name .. " (đang ở trong solution)")

            vim.ui.input({ prompt = "Tạo Project đầu tiên? (tên / bỏ trống): " }, function(proj_name)
              if proj_name and proj_name ~= "" then
                local project_path = solution_path .. "/" .. proj_name
                scaffold_project(project_path)
                notify("✅ Đã tạo Project: " .. proj_name .. " (ở trong solution, cd vào project nếu cần)")
              end
            end)
          end)
        end, { desc = "Tạo Solution mới", silent = true })

        -- <leader>op: Tạo Project (không cd vào project, chỉ tạo)
        vim.keymap.set("n", "<leader>op", function()
          vim.ui.input({ prompt = "Tên Project: " }, function(name)
            if not name or name == "" then
              return
            end

            local cwd = vim.fn.getcwd()
            local project_path = cwd .. "/" .. name

            if vim.fn.isdirectory(project_path) == 1 then
              notify("Project '" .. name .. "' đã tồn tại!", "warn")
              return
            end

            scaffold_project(project_path)
            notify("✅ Đã tạo Project: " .. name)
          end)
        end, { desc = "Tạo Project mới", silent = true })

        -- <leader>oc: Tạo Class
        vim.keymap.set("n", "<leader>oc", function()
          vim.ui.input({ prompt = "Tên Class: " }, function(class_name)
            if not class_name or class_name == "" then
              return
            end

            local cwd = vim.fn.getcwd()
            local header_dir = cwd .. "/header"
            local source_dir = cwd .. "/source"

            if vim.fn.isdirectory(header_dir) == 0 then
              notify("Không tìm thấy header/!", "warn")
              return
            end

            local display_name = class_name:sub(1, 1):upper() .. class_name:sub(2)
            local guard = display_name:upper() .. "_H"

            -- Header
            local header_path = header_dir .. "/" .. display_name .. ".h"
            if vim.fn.filereadable(header_path) == 1 then
              notify("File " .. display_name .. ".h đã tồn tại!", "warn")
              return
            end

            local header_content = string.format(
              "#ifndef %s\n#define %s\n\nclass %s {\npublic:\n    %s();\n    ~%s();\n\nprivate:\n\n};\n\n#endif // %s\n",
              guard,
              guard,
              display_name,
              display_name,
              display_name,
              guard
            )
            local f = io.open(header_path, "w")
            if f then
              f:write(header_content)
              f:close()
            end

            -- Source (cùng tên, nằm trong source/)
            local source_path = source_dir .. "/" .. display_name .. ".cpp"
            local source_content = string.format(
              '#include "%s.h"\n\n%s::%s() {\n}\n\n%s::~%s() {\n}\n',
              display_name,
              display_name,
              display_name,
              display_name,
              display_name
            )
            f = io.open(source_path, "w")
            if f then
              f:write(source_content)
              f:close()
            end

            notify("✅ Đã tạo Class: " .. display_name)

            -- Auto mở .h + .cpp dạng split
            vim.defer_fn(function()
              vim.cmd("edit " .. header_path)
              vim.cmd("vsplit " .. source_path)
              vim.cmd("wincmd h") -- focus vào header
            end, 100)
          end)
        end, { desc = "Tạo Class mới", silent = true })

        -- <leader>ob: Build & Run All
        -- Nếu có source/ → compile tất cả source/*.cpp
        -- Nếu không → compile file hiện tại
        vim.keymap.set("n", "<leader>ob", function()
          local cwd = vim.fn.getcwd()
          local project_root = find_project_root()
          local source_dir = project_root .. "/source"
          local header_dir = project_root .. "/header"

          local compiler = vim.g.cpp_compiler
          local std = vim.g.cpp_std
          local flags = vim.g.cpp_flags
          local build_dir = project_root .. "/build"
          vim.fn.mkdir(build_dir, "p")

          local cmd, binary

          if vim.fn.isdirectory(source_dir) == 1 then
            -- OOP project: compile tất cả source/*.cpp
            local srcs = vim.fn.glob(source_dir .. "/*.cpp", false, true)
            if #srcs == 0 then
              notify("Không tìm thấy .cpp trong source/!", "warn")
              return
            end
            binary = build_dir .. "/main"
            local include_flag = vim.fn.isdirectory(header_dir) == 1 and "-I" .. header_dir .. "/ " or ""
            cmd = string.format(
              "%s -std=%s %s %s%s -o %s 2>&1",
              compiler,
              std,
              flags,
              include_flag,
              table.concat(srcs, " "),
              binary
            )
          else
            -- Single file: compile file hiện tại
            local file = vim.fn.expand("%:p")
            if file == "" then
              notify("Không có file nào đang mở!", "warn")
              return
            end
            local name = vim.fn.fnamemodify(file, ":t:r")
            binary = build_dir .. "/" .. name
            cmd = string.format("%s -std=%s %s %s -o %s 2>&1", compiler, std, flags, file, binary)
          end

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

        -- <leader>or: Run (no rebuild)
        vim.keymap.set("n", "<leader>or", function()
          local project_root = find_project_root()
          local source_dir = project_root .. "/source"
          local build_dir = project_root .. "/build"
          local binary

          if vim.fn.isdirectory(source_dir) == 1 then
            binary = build_dir .. "/main"
          else
            local file = vim.fn.expand("%:p")
            local name = vim.fn.fnamemodify(file, ":t:r")
            binary = build_dir .. "/" .. name
          end

          run_in_terminal(binary, false)
        end, { desc = "Run (no rebuild)", silent = true })

        notify("🏗️ OOP Mode đã kích hoạt trong: " .. vim.fn.getcwd())
      end

      -- ==================================================================
      -- AUTO-INSERT #INCLUDE KHI SAVE
      -- ==================================================================

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
      }

      local function has_include(content, header)
        local pattern = '#include[%s]*[<"]' .. header:gsub("%.", "%%.") .. '[>"]'
        return content:match(pattern) ~= nil
      end

      local function find_insert_line(lines)
        local last_include = 0
        local after_guard = 0
        for i, line in ipairs(lines) do
          if line:match("^#include") then
            last_include = i
          end
          if line:match("^#ifndef") and i <= 5 then
            after_guard = i + 1
          end
        end
        if last_include > 0 then
          return last_include + 1
        elseif after_guard > 0 then
          return after_guard + 1
        else
          return 1
        end
      end

      local auto_group = vim.api.nvim_create_augroup("CppAutoInclude", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = auto_group,
        pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
        callback = function()
          local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
          local needed = {}

          for symbol, header in pairs(symbol_to_header) do
            local pattern = "[^a-zA-Z_]" .. symbol .. "[^a-zA-Z_]"
            if content:match(pattern) and not has_include(content, header) then
              needed[header] = true
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

          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local insert_line = find_insert_line(lines)
          local insert_lines = {}
          for _, h in ipairs(sorted) do
            table.insert(insert_lines, "#include <" .. h .. ">")
          end

          vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, insert_lines)
          notify("📝 Auto-include: " .. table.concat(sorted, ", "))
        end,
      })

      -- ==================================================================
      -- AUTOCMD: KÍCH HOẠT LEADER `c` KHI MỞ C/C++ BUFFER & INDENT
      -- ==================================================================

      local cpp_group = vim.api.nvim_create_augroup("CppLeaderKey", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = cpp_group,
        pattern = { "c", "cpp" },
        callback = function()
          -- === THÊM VÀO ĐÂY: Cấu hình 4 spaces chuẩn Visual Studio ===
          vim.opt_local.shiftwidth = 4
          vim.opt_local.tabstop = 4
          vim.opt_local.softtabstop = 4
          vim.opt_local.expandtab = true
          -- ===========================================================

          vim.defer_fn(setup_cpp_leader, 100)
        end,
      })

      -- ==================================================================
      -- AUTOCMD: KÍCH HOẠT OOP MODE KHI CD VÀO THƯ MỤC OOP
      -- ==================================================================

      local oop_group = vim.api.nvim_create_augroup("OopMode", { clear = true })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = oop_group,
        callback = function()
          vim.defer_fn(setup_oop_mode, 200)
        end,
      })

      vim.api.nvim_create_autocmd("DirChanged", {
        group = oop_group,
        callback = function()
          vim.defer_fn(setup_oop_mode, 200)
        end,
      })
    end,
  },
}

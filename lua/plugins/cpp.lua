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
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.clangd = {
        mason = false,
        cmd = {
          "clangd",
          "--background-index",
          "--background-index-priority=low",
          "--pch-storage=memory",
          "--completion-style=bundled",
          "--function-arg-placeholders=true",
          "--header-insertion=never",
          "--limit-results=20",
          "--clang-tidy=false",
          "--fallback-style=llvm",
          "-j=2",
          "--log=error",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
      }
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
          selection = { preselect = true, auto_insert = false },
          max_items = 20,
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
          auto_show_delay_ms = 500,
        },
        ghost_text = { enabled = false },
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
        { "<leader>om", desc = "Toggle Debug/Release Mode" },
        { "<leader>oq", group = "Thoát Menu" },
        { "<leader>oqq", desc = "Thoát WhichKey" },
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
      vim.g.cpp_flags = vim.g.cpp_flags or "-O0 -Wall -Wextra -Wpedantic -pipe"

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

      --- Tìm project root (có header/ và source/) - tự động chuẩn hóa dấu gạch chéo xuôi cho đa nền tảng
      local function find_project_root()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return vim.fn.getcwd():gsub("\\", "/")
        end
        local dir = vim.fn.fnamemodify(file, ":h")
        while dir ~= vim.fn.fnamemodify(dir, ":h") do
          if vim.fn.isdirectory(dir .. "/header") == 1 and vim.fn.isdirectory(dir .. "/source") == 1 then
            return dir:gsub("\\", "/")
          end
          dir = vim.fn.fnamemodify(dir, ":h")
        end
        return vim.fn.getcwd():gsub("\\", "/")
      end

      --- Lấy đường dẫn binary trong build/ (nếu là OOP project thì nằm ở thư mục project root)
      local function get_build_binary()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return nil
        end
        local project_root = find_project_root()
        if vim.fn.isdirectory(project_root .. "/header") == 1 and vim.fn.isdirectory(project_root .. "/source") == 1 then
          return project_root .. "/build/main"
        else
          local parent_dir = vim.fn.fnamemodify(file, ":h")
          local name = vim.fn.fnamemodify(file, ":t:r")
          return parent_dir .. "/build/" .. name
        end
      end

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

      --- Compile file C/C++ hiện tại → output vào build/
      --- Nếu trong project OOP → compile tất cả source/**/*.cpp và output vào thư mục project_root/build/
      local function compile_current(extra_flags, callback)
        local file = vim.fn.expand("%:p")
        if file == "" then
          notify("Không có file nào đang mở!", "warn")
          return
        end

        local binary = get_build_binary()
        local project_root = find_project_root()
        local is_oop = vim.fn.isdirectory(project_root .. "/header") == 1 and vim.fn.isdirectory(project_root .. "/source") == 1
        
        local build_dir
        if is_oop then
          build_dir = project_root .. "/build"
          -- Tạo compile_flags.txt cho clangd khi biên dịch
          write_compile_flags_txt(project_root)
        else
          local parent_dir = vim.fn.fnamemodify(file, ":h")
          build_dir = parent_dir .. "/build"
        end
        vim.fn.mkdir(build_dir, "p")

        -- Tự động phát hiện file C hay C++ để chọn compiler & standard phù hợp
        local ext = vim.fn.fnamemodify(file, ":e")
        local is_c = (ext == "c" or ext == "h" or vim.bo.filetype == "c")

        local compiler = is_c and "clang" or vim.g.cpp_compiler
        local std = is_c and "c17" or vim.g.cpp_std
        local flags = vim.g.cpp_flags

        -- Nếu trong project OOP (có header/ + source/), compile tất cả source/**/*.cpp (hoặc *.c) đệ quy
        local extra_sources = ""
        local include_flag = ""
        if is_oop then
          local pattern = is_c and "/**/*.c" or "/**/*.cpp"
          local srcs = vim.fn.globpath(project_root .. "/source", pattern, false, true)
          -- Loại trừ file hiện tại nếu nó nằm trong source/
          local filtered = {}
          for _, s in ipairs(srcs) do
            if s ~= file then
              table.insert(filtered, s)
            end
          end
          if #filtered > 0 then
            local escaped_srcs = {}
            for _, s in ipairs(filtered) do
              table.insert(escaped_srcs, vim.fn.shellescape(s))
            end
            extra_sources = " " .. table.concat(escaped_srcs, " ")
          end
          include_flag = get_oop_include_flags(project_root)
        end

        local cmd = string.format(
          "%s -std=%s %s %s%s%s -o %s %s 2>&1",
          compiler,
          std,
          flags,
          include_flag,
          vim.fn.shellescape(file),
          extra_sources,
          vim.fn.shellescape(binary),
          extra_flags or ""
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
          if callback then
            callback(success, output, binary)
          end
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

      --- Kiểm tra cwd hoặc buffer hiện tại có phải OOP không (tự động hoặc theo tên thư mục)
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

      -- ==================================================================
      -- TẠO CẤU TRÚC PROJECT (OOP MODE)
      -- ==================================================================

      --- Scaffold project mẫu
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

        -- Auto mở source.cpp
        vim.defer_fn(function()
          local source_file = project_path .. "/source/source.cpp"
          vim.cmd("edit " .. source_file)
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
          { "c", group = "C++ Dev", buffer = 0 },
          { "ct", desc = "Compile & Run", buffer = 0 },
          { "cs", desc = "Compile & Run + Time", buffer = 0 },
          { "cv", desc = "Compile + UBSan", buffer = 0 },
          { "cm", desc = "Toggle Debug/Release Mode", buffer = 0 },
          { "cx", desc = "Re-run binary", buffer = 0 },
          { "ce", desc = "Show errors (quickfix)", buffer = 0 },
          { "cR", desc = "Restart clangd", buffer = 0 },
          { "cq", group = "Thoát Menu", buffer = 0 },
          { "cqq", "<esc>", desc = "Thoát WhichKey", buffer = 0 },
        })

        -- Khởi tạo biến mode nếu chưa có
        vim.g.cpp_compile_mode = vim.g.cpp_compile_mode or "debug"

        -- `c` mở which-key trong normal mode
        vim.keymap.set("n", "c", function()
          wk.show("c", { mode = "n" })
        end, { buffer = 0, desc = "C++ Dev Leader", silent = true })

        -- cm: Toggle Compile Mode (Debug / Release)
        vim.keymap.set("n", "cm", function()
          if vim.g.cpp_compile_mode == "release" then
            vim.g.cpp_compile_mode = "debug"
            vim.g.cpp_flags = "-O0 -Wall -Wextra -Wpedantic -pipe"
            notify("🛡️ Mode: DEBUG (-O0, Compile siêu nhanh, an toàn)")
          else
            vim.g.cpp_compile_mode = "release"
            vim.g.cpp_flags = "-O3 -Wall -Wextra -Wpedantic -DNDEBUG -pipe"
            notify("⚡ Mode: RELEASE (-O3, Tối ưu tối đa, không debug)")
          end
        end, { buffer = 0, desc = "Toggle Debug/Release Compile Mode", silent = true })

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

        -- cx: Re-run
        vim.keymap.set("n", "cx", function()
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
        local ft = vim.bo.filetype
        if ft ~= "cpp" and ft ~= "c" and ft ~= "h" and ft ~= "hpp" then
          return
        end

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

            local project_root = find_project_root()
            local header_dir = project_root .. "/header"
            local source_dir = project_root .. "/source"

            if vim.fn.isdirectory(header_dir) == 0 then
              notify("Không tìm thấy header/!", "warn")
              return
            end

            -- Hỗ trợ tạo thư mục con (ví dụ: utils/Helper)
            class_name = class_name:gsub("\\", "/")
            local class_dir = vim.fn.fnamemodify(class_name, ":h")
            local bare_name = vim.fn.fnamemodify(class_name, ":t")
            if class_dir == "." then
              class_dir = ""
            end

            local display_name = bare_name:sub(1, 1):upper() .. bare_name:sub(2)

            -- Tạo thư mục con tương ứng nếu có
            local target_header_dir = header_dir .. (class_dir ~= "" and ("/" .. class_dir) or "")
            local target_source_dir = source_dir .. (class_dir ~= "" and ("/" .. class_dir) or "")
            vim.fn.mkdir(target_header_dir, "p")
            vim.fn.mkdir(target_source_dir, "p")

            local header_path = target_header_dir .. "/" .. display_name .. ".h"
            local source_path = target_source_dir .. "/" .. display_name .. ".cpp"

            if vim.fn.filereadable(header_path) == 1 then
              notify("File " .. display_name .. ".h đã tồn tại!", "warn")
              return
            end

            local header_content = string.format(
              "#pragma once\n\nclass %s\n{\n};\n",
              display_name
            )
            local f = io.open(header_path, "w")
            if f then
              f:write(header_content)
              f:close()
            end

            -- Source
            local source_content = string.format(
              '#include "%s.h"\n',
              display_name
            )
            f = io.open(source_path, "w")
            if f then
              f:write(source_content)
              f:close()
            end

            notify("✅ Đã tạo Class: " .. (class_dir ~= "" and (class_dir .. "/") or "") .. display_name)

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

          local file = vim.fn.expand("%:p")
          local ext = file ~= "" and vim.fn.fnamemodify(file, ":e") or ""
          local is_c = (ext == "c" or ext == "h" or vim.bo.filetype == "c")

          local compiler = is_c and "clang" or vim.g.cpp_compiler
          local std = is_c and "c17" or vim.g.cpp_std
          local flags = vim.g.cpp_flags
          
          local cmd, binary, build_dir

          if vim.fn.isdirectory(source_dir) == 1 then
            -- OOP project: compile tất cả source/**/*.cpp hoặc source/**/*.c đệ quy
            local pattern = is_c and "/**/*.c" or "/**/*.cpp"
            local srcs = vim.fn.globpath(source_dir, pattern, false, true)
            if #srcs == 0 then
              notify("Không tìm thấy file nguồn trong source/!", "warn")
              return
            end
            build_dir = project_root .. "/build"
            vim.fn.mkdir(build_dir, "p")
            binary = build_dir .. "/main"
            write_compile_flags_txt(project_root)
            local include_flag = get_oop_include_flags(project_root)
            local escaped_srcs = {}
            for _, s in ipairs(srcs) do
              table.insert(escaped_srcs, vim.fn.shellescape(s))
            end
            cmd = string.format(
              "%s -std=%s %s %s%s -o %s 2>&1",
              compiler,
              std,
              flags,
              include_flag,
              table.concat(escaped_srcs, " "),
              vim.fn.shellescape(binary)
            )
          else
            -- Single file: compile file hiện tại
            if file == "" then
              notify("Không có file nào đang mở!", "warn")
              return
            end
            local parent_dir = vim.fn.fnamemodify(file, ":h")
            build_dir = parent_dir .. "/build"
            vim.fn.mkdir(build_dir, "p")
            local name = vim.fn.fnamemodify(file, ":t:r")
            binary = build_dir .. "/" .. name
            cmd = string.format(
              "%s -std=%s %s %s -o %s 2>&1",
              compiler,
              std,
              flags,
              vim.fn.shellescape(file),
              vim.fn.shellescape(binary)
            )
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
          local binary

          if vim.fn.isdirectory(source_dir) == 1 then
            binary = project_root .. "/build/main"
          else
            local file = vim.fn.expand("%:p")
            local parent_dir = vim.fn.fnamemodify(file, ":h")
            local name = vim.fn.fnamemodify(file, ":t:r")
            binary = parent_dir .. "/build/" .. name
          end

          run_in_terminal(binary, false)
        end, { desc = "Run (no rebuild)", silent = true })

        -- <leader>oqq: Thoát WhichKey
        vim.keymap.set("n", "<leader>oqq", "<esc>", { desc = "Thoát WhichKey", silent = true })

        -- Tự động cập nhật compile_flags.txt cho clangd hoạt động tức thì
        local root = find_project_root()
        write_compile_flags_txt(root)

        if vim.g.oop_mode_last_notified_root ~= root then
          notify("🏗️ OOP Mode đã kích hoạt trong: " .. root)
          vim.g.oop_mode_last_notified_root = root
        end
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

      local function find_insert_line(lines)
        local last_include = 0
        local after_guard = 0
        for i, line in ipairs(lines) do
          if line:match("^#include") then
            last_include = i
          end
          if (line:match("^#ifndef") or line:match("^#pragma once")) and i <= 5 then
            after_guard = i
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
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local content = table.concat(lines, "\n")
          
          -- Một pass trích xuất từ (O(N)) thay vì 70+ regex scans
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

      vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "BufEnter" }, {
        group = oop_group,
        callback = function()
          vim.defer_fn(setup_oop_mode, 200)
        end,
      })

      -- ==================================================================
      -- AUTOCMD: TỰ ĐỘNG LƯU FILE KHI THOÁT INSERT MODE (INSERTLEAVE)
      -- ==================================================================
      local autosave_group = vim.api.nvim_create_augroup("InsertLeaveAutoSave", { clear = true })
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = autosave_group,
        pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
        callback = function()
          if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! write")
          end
        end,
      })
    end,
  },
}

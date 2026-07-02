-- tests/test_snippets.lua

local file = io.open("snippets/cpp.json", "r")
if not file then
  print("FAIL: cpp.json snippets file not found!")
  os.exit(1)
end

local content = file:read("*a")
file:close()

-- Decode JSON
local ok, snippets = pcall(vim.json.decode, content)
if not ok then
  print("FAIL: cpp.json is not a valid JSON document: " .. tostring(snippets))
  os.exit(1)
end

-- Verify original snippets
if not snippets["Khung Competitive Programming (C++)"] or not snippets["Hàm Main tiêu chuẩn (Basic)"] then
  print("FAIL: Original competitive programming snippets are missing")
  os.exit(1)
end

-- Verify new OOP snippets
local required_new_snippets = {
  "Khai báo lớp đầy đủ",
  "Constructor với danh sách khởi tạo",
  "Destructor ảo",
  "Getter và Setter",
  "Kế thừa lớp",
  "Toán tử xuất <<",
  "Khối try-catch",
  "Vòng lặp for theo phạm vi",
  "Biểu thức Lambda",
  "Khai báo Vector",
  "Xuất nhanh cout",
  "Nhập nhanh cin"
}

for _, name in ipairs(required_new_snippets) do
  local s = snippets[name]
  if not s or type(s.prefix) ~= "string" or type(s.body) ~= "table" then
    print("FAIL: OOP snippet '" .. name .. "' is missing or incorrectly formatted")
    os.exit(1)
  end
end

print("PASS: 12 C++ OOP snippets validated and functional!")

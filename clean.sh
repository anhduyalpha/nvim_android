#!/usr/bin/env bash

# ============================================================================
# clean.sh — Script dọn dẹp các tệp .lua cũ, tệp nháp và tệp tạm trên Android
# ============================================================================
# Cách chạy trên Termux:
#   1. Cấp quyền thực thi:  chmod +x clean.sh
#   2. Chạy script:         ./clean.sh
# ============================================================================

# Định nghĩa màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}      🧹 TIẾN TRÌNH DỌN DẸP TỆP TIN TẠM & .LUA CŨ TRÊN TERMUX        ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# Danh sách các tệp tin kiểm thử/nháp cần quét và dọn dẹp
temp_files=(
  "test_performance.lua"
  "test_ctrl_q.lua"
  "test_tab.lua"
  "test_lsp_gd.lua"
  "test_silent_move.lua"
  "test_alt_keymaps.lua"
  "test_buffers.lua"
  "test_c.lua"
  "test_cpp.lua"
  "test_oop_refinements.lua"
  "test_ui.lua"
)

deleted_count=0

echo -e "\n${BLUE}1. Quét và dọn dẹp các tệp thử nghiệm test_*.lua cục bộ:${NC}"
for file in "${temp_files[@]}"; do
  if [ -f "$file" ]; then
    echo -e "  ${YELLOW}• Đang xóa tệp tạm:${NC} $file"
    rm -f "$file"
    deleted_count=$((deleted_count + 1))
  fi
done

# Tìm và xóa thêm các tệp test_*.lua khác trong các thư mục con nếu có (loại trừ các thư mục hệ thống như .git)
other_tests=$(find . -maxdepth 3 -name "test_*.lua" -not -path '*/.*' 2>/dev/null)
if [ -n "$other_tests" ]; then
  for file in $other_tests; do
    echo -e "  ${YELLOW}• Phát hiện tệp test phụ:${NC} $file"
    rm -f "$file"
    deleted_count=$((deleted_count + 1))
  done
fi

# Dọn dẹp tệp tin swap của Vim/Neovim (*.swp, *.swo) nếu có
echo -e "\n${BLUE}2. Quét dọn dẹp tệp tin đệm swap/backup (*.swp, *.swo):${NC}"
swap_files=$(find . -name "*.swp" -o -name "*.swo" -not -path '*/.*' 2>/dev/null)
if [ -n "$swap_files" ]; then
  for file in $swap_files; do
    echo -e "  ${YELLOW}• Đang xóa tệp swap/tạm:${NC} $file"
    rm -f "$file"
    deleted_count=$((deleted_count + 1))
  done
else
  echo -e "  ${GREEN}[✓] Không phát hiện tệp swap hoặc tệp tạm nào dư thừa.${NC}"
fi

echo -e "\n${CYAN}======================================================================${NC}"
if [ $deleted_count -gt 0 ]; then
  echo -e "${GREEN}🎉 HOÀN TẤT! Đã giải phóng thành công $deleted_count tệp tin rác/cũ khỏi thư mục.${NC}"
else
  echo -e "${GREEN}🎉 HOÀN TẤT! Thư mục làm việc của bạn đã sạch sẽ hoàn toàn, không có tệp dư thừa.${NC}"
fi
echo -e "${CYAN}======================================================================${NC}\n"

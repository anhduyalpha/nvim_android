#!/usr/bin/env bash

# ============================================================================
# check_performance.sh — Script chạy chẩn đoán hiệu năng nhanh trên Android
# ============================================================================
# Cách chạy trên Termux:
#   1. Cấp quyền thực thi:  chmod +x check_performance.sh
#   2. Chạy script:         ./check_performance.sh
# ============================================================================

# Mã màu ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # Không màu

# 1. Kiểm tra sự tồn tại của trình biên tập Neovim
if ! command -v nvim &> /dev/null; then
  echo -e "${RED}🛑 LỖI: Không tìm thấy lệnh 'nvim' cài đặt trên hệ thống Android Termux!${NC}"
  echo -e "Vui lòng cài đặt Neovim trước bằng cách chạy lệnh: ${CYAN}pkg install neovim${NC}"
  exit 1
fi

# 2. Kiểm tra sự tồn tại của tệp lua check_performance.lua
if [ ! -f "check_performance.lua" ]; then
  echo -e "${RED}🛑 LỖI: Không tìm thấy tệp chẩn đoán nguồn 'check_performance.lua' trong thư mục hiện tại!${NC}"
  echo -e "Vui lòng đảm bảo bạn đang đứng ở thư mục gốc của dự án cấu hình Neovim."
  exit 1
fi

# 3. Thực thi chẩn đoán hiệu năng headless
echo -e "${CYAN}🚀 Đang kích hoạt chế độ chẩn đoán hiệu năng Neovim Termux...${NC}\n"
nvim --headless -c "luafile check_performance.lua" -c "qa"

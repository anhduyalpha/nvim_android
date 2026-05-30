#!/usr/bin/env bash
# ============================================================================
# backup_recovery.sh — Khôi phục cấu hình Neovim siêu tốc trên Termux
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKUP_DIR="$HOME/storage/shared/NvimBackups"
if [ ! -d "$BACKUP_DIR" ]; then
  BACKUP_DIR="$HOME/NvimBackups"
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo -e "${RED}🛑 Không tìm thấy thư mục sao lưu nào tại $HOME/NvimBackups!${NC}"
  exit 1
fi

latest_backup=$(ls -t "$BACKUP_DIR"/nvim_backup_*.zip 2>/dev/null | head -n 1)

if [ -z "$latest_backup" ]; then
  echo -e "${RED}🛑 Không tìm thấy tệp .zip sao lưu nào!${NC}"
  exit 1
fi

echo -e "${CYAN}🔄 Đang phục hồi từ bản sao lưu gần nhất: ${latest_backup}...${NC}"

# Tạo bản sao dự phòng cấu hình hiện tại trước khi ghi đè
mv "$HOME/.config/nvim" "$HOME/.config/nvim_old_$(date +%s)" 2>/dev/null

unzip -q "$latest_backup" -d "$HOME/.config/"
# Đổi tên thư mục giải nén nếu cấu trúc bị lệch
if [ -d "$HOME/.config/nvim_android" ]; then
  mv "$HOME/.config/nvim_android" "$HOME/.config/nvim"
fi

echo -e "${GREEN}🎉 Khôi phục cấu hình Neovim thành công! Khởi động lại nvim để áp dụng.${NC}"

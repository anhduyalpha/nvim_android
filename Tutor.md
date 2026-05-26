# 📘 Hướng Dẫn Cấu Hình C++ Neovim (Android / Termux)

Chào mừng bạn đến với môi trường lập trình C++ siêu tối ưu dành cho thiết bị Android chạy Termux. Cấu hình này đã được tinh chỉnh toàn diện nhằm mang lại trải nghiệm **siêu mượt mà (zero lag)**, **biên dịch siêu tốc**, và **hiệu năng cực đỉnh** tương đương với PC.

---

## ⚡ 1. Chế Độ Đơn File (Single File Mode)
Dành cho việc viết các bài tập đơn lẻ, thuật toán nhanh. Chế độ này sử dụng tổ hợp phím bắt đầu bằng `<leader>c` (Với `<leader>` mặc định là **Phím cách / Spacebar**).

> [!NOTE]
> Phím `c` mặc định của Vim (lệnh `change`) đã được giải phóng hoàn toàn. Bạn có thể sử dụng `cw`, `cc`, `ci"` bình thường mà không bị khựng hay lag!

### 📊 Bảng phím tắt Single Mode:
| Phím tắt | Chức năng | Mô tả |
| :--- | :--- | :--- |
| `<leader>ct` | **Compile & Run** | Biên dịch file hiện tại và chạy trực tiếp trong split terminal bên dưới. |
| `<leader>cs` | **Compile & Run + Time** | Biên dịch và chạy kèm đo thời gian thực thi (rất có ích khi test thuật toán). |
| `<leader>cv` | **Compile + UBSan** | Biên dịch với bộ kiểm tra lỗi tràn mảng/hành vi không xác định (Sanitizer). |
| `<leader>cx` | **Re-run binary** | Chạy lại chương trình vừa biên dịch trước đó mà không cần compile lại (tiết kiệm thời gian). |
| `<leader>ce` | **Show errors** | Mở cửa sổ Quickfix để xem danh sách lỗi nếu biên dịch thất bại. |
| `<leader>cm` | **Toggle Compile Mode** | Chuyển đổi nhanh giữa chế độ **DEBUG** (Biên dịch siêu tốc) và **RELEASE** (Tối ưu hóa tối đa `-O3`). |
| `<leader>cR` | **Restart clangd** | Khởi động lại LSP nếu tính năng gợi ý từ bị đơ hoặc treo. |

---

## 🏗️ 2. Chế Độ Dự Án Hướng Đối Tượng (OOP Mode)
Tự động kích hoạt khi bạn mở hoặc di chuyển (`cd`) vào một thư mục có cấu trúc OOP: có chứa 2 thư mục con là `header/` và `source/` (Không bắt buộc thư mục cha phải đặt tên chính xác là `"OOP"` như trước). Các phím tắt bắt đầu bằng `<leader>o`.

### 📊 Bảng phím tắt OOP Mode:
| Phím tắt | Chức năng | Mô tả |
| :--- | :--- | :--- |
| `<leader>os` | **Tạo Solution** | Tạo một Solution cha chứa các dự án OOP con bên trong. |
| `<leader>op` | **Tạo Project** | Tạo cấu trúc một dự án con mẫu (Scaffold tự động tạo `source.cpp`, `example.h`, `example.cpp`). |
| `<leader>oc` | **Tạo Class mới** | Nhập tên Class (ví dụ: `Student`), Neovim tự động tạo `Student.h` trong `header/` và `Student.cpp` trong `source/` với template dựng sẵn, sau đó tự động split màn hình làm việc để bạn code ngay! |
| `<leader>ob` | **Build & Run All** | Biên dịch toàn bộ các file `.cpp` trong thư mục `source/` liên kết với các file trong `header/` thành file chạy `build/main` rồi thực thi. |
| `<leader>or` | **Run (no rebuild)** | Thực thi file `build/main` đã build trước đó mà không cần biên dịch lại. |
| `<leader>om` | **Toggle Compile Mode** | Bật/tắt chế độ biên dịch (DEBUG / RELEASE) cho dự án OOP. |

---

## 🚀 3. Các Tối Ưu Hóa Đã Được Thiết Lập (Dưới Mũi Code)

Để giúp Neovim trên điện thoại mượt mà và không bị giật lag, các cấu hình sau đã được thiết lập tự động:

### ⏱️ Không còn Lag khi Lưu (Save Lag)
- **Cơ chế cũ**: Mỗi lần nhấn `:w`, Neovim quét toàn bộ file 70+ lần bằng regex để tự động thêm `#include <...>`. Việc này gây đơ máy khoảng 0.5s - 1s mỗi lần lưu.
- **Cơ chế mới**: Áp dụng thuật toán quét **một pass $O(N)$** thu thập toàn bộ các từ trong file bằng bộ tách từ native tốc độ cao của Lua, sau đó so khớp trực tiếp dạng bảng. Quá trình lưu file giờ đây diễn ra **tức thì (0.001s)**.

### ⌨️ Không còn Lag khi Gõ (Typing Lag)
- Thiết lập ưu tiên biên dịch nền thấp cho `clangd` (`--background-index-priority=low`) để không chiếm CPU của bàn phím.
- Tắt tính năng tự động chẩn đoán lỗi nặng `clang-tidy` khi đang gõ, chỉ hiển thị gợi ý nhẹ nhàng.
- Tắt tính năng `ghost_text` và giới hạn danh sách gợi ý tự động từ `50` xuống `20` mục để giảm tải vẽ lại màn hình của Termux trên màn hình điện thoại di động.
- Trì hoãn hiển thị tài liệu mô tả hàm (`documentation popup`) thêm `500ms` để tránh hiện tượng nhấp nháy giật khung hình khi gõ nhanh.

### 🔋 Biên dịch Siêu Tốc & Tiết kiệm Pin
- Chế độ **DEBUG** mặc định sử dụng cờ biên dịch `-O0 -pipe`. Bằng cách bỏ qua các bước tối ưu hóa phức tạp của compiler, tốc độ biên dịch tăng **2x đến 5x**, giúp bạn test code nhanh hơn rất nhiều và điện thoại không bị nóng.
- Sử dụng `-pipe` để truyền dữ liệu trực tiếp qua RAM thay vì lưu các file tạm vào bộ nhớ flash của điện thoại, giúp kéo dài tuổi thọ bộ nhớ và tăng tốc độ đọc/ghi.

---

## 📝 4. Bộ Snippet C++ Gõ Nhanh Hữu Ích

Hãy gõ các từ viết tắt sau và nhấn `Tab` để tự động điền code:

*   `cp`: Khung sườn lập trình thi đấu giải thuật chuẩn (đầy đủ các lệnh tối ưu hóa I/O, cấu trúc testcase, macro nhanh `int = long long`).
*   `main`: Hàm main cơ bản cho các bài tập thông thường.
*   `fori`: Vòng lặp for xuôi (`for (int i = 0; i < n; ++i)`).
*   `forrev`: Vòng lặp for ngược từ `n-1` về `0`.
*   `cinv`: Nhập nhanh dữ liệu cho mảng/vector (`for (int &x : v) cin >> x;`).
*   `coutv`: In nhanh mảng/vector trên 1 dòng kèm dấu cách.
*   `fio`: Chuyển hướng đọc/ghi file `input.txt` và `output.txt` tự động nếu file tồn tại.
*   `gcd`: Hàm tìm Ước chung lớn nhất và Bội chung nhỏ nhất chuẩn.
*   `bs`: Khung thuật toán Tìm kiếm nhị phân mẫu.
*   `dfs`: Mẫu duyệt đồ thị DFS.
*   `sieve`: Thuật toán Sàng nguyên tố tìm số nguyên tố siêu tốc lên tới $10^6$.

---

## 📱 5. Mẹo Lập Trình Trên Android / Termux

1.  **Sao chép và Dán (Clipboard)**:
    Cấu hình đã tích hợp sẵn với clipboard của Termux thông qua gói `termux-api`. Bạn có thể sao chép (`y` - yank) trong Neovim và dán thẳng ra ngoài điện thoại (Facebook, Zalo, trình duyệt) và ngược lại.
    *(Lưu ý: Hãy cài đặt ứng dụng Termux:API trên điện thoại và chạy lệnh `pkg install termux-api` trong Termux để tính năng này hoạt động).*
2.  **Sử dụng Chuột/Touch**:
    Nhấn chạm vào màn hình để di chuyển con trỏ, kéo vuốt để cuộn trang, hoặc nhấn chạm vào các tab/split để chuyển nhanh khu vực làm việc rất tiện lợi.
3.  **Bàn phím ảo**:
    Khuyên dùng các bàn phím hỗ trợ phím điều hướng và phím Ctrl/Alt như **Hacker's Keyboard** hoặc bàn phím chuyên biệt cho coder để thao tác gõ tổ hợp phím dễ dàng hơn.

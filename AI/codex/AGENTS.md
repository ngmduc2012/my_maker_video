# Codex Agent Rules

Context và quy tắc dùng chung nằm trong `AI/shared`.

- Đọc `AI/shared/project-context.md` và `pubspec.yaml` trước khi sửa.
- Dùng `rg` để tìm source; không đọc hoặc sửa `.dart_tool/`, `build/`, Pods hay file sinh tự động.
- Phân biệt package thuần Dart, Flutter package và Flutter plugin trước khi chọn lệnh kiểm tra.
- Giữ tương thích giữa Dart API và implementation Android, iOS, macOS, web, Linux hoặc Windows đang được khai báo.
- Không tự tăng version, publish lên pub.dev, push hoặc tạo release nếu người dùng chưa yêu cầu rõ.
- Chạy format, analyze và test phù hợp trước khi bàn giao; ghi rõ platform chưa thể kiểm tra trên máy hiện tại.

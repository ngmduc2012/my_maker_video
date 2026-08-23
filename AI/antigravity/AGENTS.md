# Antigravity Agent Rules

Context và quy tắc dùng chung nằm trong `AI/shared`.

- Đọc `AI/shared/project-context.md`, `pubspec.yaml` và source liên quan trước khi sửa.
- Ưu tiên công cụ đọc/tìm kiếm tĩnh; chỉ chạy command trong đúng repository khi cần xác minh.
- Không sửa `.dart_tool/`, `build/`, Pods hoặc file sinh tự động.
- Dùng `dart` cho package thuần Dart và `flutter` cho Flutter package/plugin.
- Với platform channel, đối chiếu đồng thời Dart API, tên channel, method, argument và kết quả trên từng nền tảng.
- Luôn chạy format, analyze và test phù hợp trước khi bàn giao; không tự publish hoặc tạo release.

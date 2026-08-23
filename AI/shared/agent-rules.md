# Agent Rules

## Trước khi sửa

1. Đọc `AI/shared/project-context.md` và `pubspec.yaml`.
2. Kiểm tra worktree để giữ nguyên thay đổi ngoài task.
3. Đọc public API, implementation, test, example và tài liệu trực tiếp liên quan.
4. Xác định package thuần Dart, Flutter package hay Flutter plugin.

## Phạm vi và an toàn

- Mỗi patch phục vụ một mục tiêu rõ; không nâng dependency hoặc format file ngoài phạm vi một cách ngẫu nhiên.
- Không sửa `.dart_tool/`, `build/`, `coverage/`, Pods, generated registrant hoặc IDE cache.
- Không xóa thay đổi của người dùng và không chạy lệnh Git phá hủy lịch sử/worktree.
- Không tự publish pub.dev, push, tag, tạo release hoặc đổi credential.
- Quyết định cần dùng lại phải được ghi trong source hoặc tài liệu repository, không chỉ ở hội thoại.

## Code Dart/Flutter

- Ưu tiên code rõ, null-safe, dễ kiểm thử và theo convention hiện tại.
- Giữ public API nhỏ; implementation nội bộ đặt trong `lib/src`.
- Dùng type cụ thể; tránh `dynamic`, ép kiểu không kiểm tra và catch lỗi rỗng.
- Không thêm abstraction khi mới có một consumer hoặc chưa có contract dùng chung.
- Không import `dart:io` vào đường code cần chạy trên web; dùng conditional import/export.
- Tách logic khỏi widget khi logic có thể kiểm thử độc lập; không lạm dụng state toàn cục.

## Plugin và platform channel

- Task sửa native/web phải dùng `AI/shared/skills/platform-channel/SKILL.md`.
- Dart API là một nửa contract; luôn đối chiếu implementation từng platform được khai báo.
- Mọi callback/result phải hoàn tất đúng một lần và resource phải được giải phóng theo lifecycle.
- Không trả dữ liệu định danh nhạy cảm hoặc xin permission vượt quá nhu cầu đã tài liệu hóa.

## Nâng Flutter

- Task nâng SDK/dependency phải dùng `AI/shared/skills/flutter-upgrade/SKILL.md`.
- Theo `AI/shared/flutter-upgrade-order.md` khi làm việc trên toàn workspace.
- Không đặt constraint theo phiên bản chưa kiểm tra; không cập nhật version package chỉ để làm dependency solver xanh.
- Thay đổi có ảnh hưởng người dùng phải cập nhật CHANGELOG và migration note trước phát hành.

## Trước khi bàn giao

1. Chạy `dart format` cho file Dart đã sửa.
2. Chạy `dart analyze`/`flutter analyze` và test phù hợp.
3. Với native change, chạy build hoặc test platform hẹp nếu môi trường hỗ trợ.
4. Đối chiếu `AI/shared/code-review-checklist.md`.
5. Báo rõ test đã chạy, test chưa chạy và giới hạn còn lại.

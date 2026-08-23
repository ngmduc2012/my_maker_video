---
project_name: read_from_pubspec
project_type: dart_or_flutter_package
updated_at: 2026-08-22
---

# Project Context

Thư mục `AI` là template dùng chung cho nhiều repository. Không giả định tên package hoặc platform hỗ trợ; lấy thông tin thật từ `pubspec.yaml`, `.metadata`, source và CI của repository hiện tại.

## Nhận diện package

- Package thuần Dart: không phụ thuộc Flutter SDK; dùng `dart analyze` và `dart test`.
- Flutter package: phụ thuộc Flutter SDK nhưng không khai báo `flutter.plugin`.
- Flutter plugin: `pubspec.yaml` khai báo `flutter.plugin.platforms`; phải kiểm tra Dart API và từng implementation native/web.
- Federated plugin: có platform interface hoặc implementation package riêng; giữ đúng token xác minh và quan hệ dependency.

## Cấu trúc thường gặp

```text
lib/<package>.dart       # public API
lib/src                  # implementation nội bộ
test                     # unit/widget tests
integration_test         # kiểm thử tích hợp
example                  # ứng dụng mẫu và platform projects
android, ios, macos      # implementation native phổ biến
web, linux, windows      # implementation platform nếu được khai báo
pubspec.yaml             # SDK, dependency, plugin metadata
CHANGELOG.md              # thay đổi phát hành
```

Chỉ dựa vào các thư mục thật đang tồn tại. Không tạo platform hoặc tầng kiến trúc mới nếu task không yêu cầu.

## Định tuyến context

| Task | Đọc trước |
| --- | --- |
| Nâng Flutter/Dart/dependency | `pubspec.yaml`, `.metadata`, CI, example và `AI/shared/skills/flutter-upgrade/SKILL.md` |
| Sửa public API | file export trong `lib/`, implementation `lib/src`, test và CHANGELOG |
| Sửa native/web plugin | khai báo platforms, Dart channel và `AI/shared/skills/platform-channel/SKILL.md` |
| Sửa command-line executable | `executables`, `bin/`, test CLI và README |
| Refactor/code health | source, test liên quan và `AI/shared/skills/code-health/SKILL.md` |

## Nguyên tắc

- `lib/<package>.dart` chỉ export API có chủ đích; chi tiết nội bộ nằm trong `lib/src`.
- Không làm vỡ public API nếu chưa có migration path và yêu cầu major version.
- Tên channel, method, argument, error code và kiểu trả về là contract xuyên nền tảng.
- Không khai báo platform chưa có implementation hoạt động.
- Tránh import `dart:io` trong code dùng chung cho web; dùng conditional import/export khi cần.
- Không chỉnh lockfile, generated registrant hoặc platform project chỉ vì tool tự sinh nếu thay đổi đó không thuộc task.
- Thứ tự nâng toàn workspace được ghi tại `AI/shared/flutter-upgrade-order.md`.

---
name: flutter-upgrade
description: Nâng package hoặc plugin lên Flutter/Dart stable mới theo từng bước có baseline, migration và kiểm thử đa nền tảng.
---

# Flutter Upgrade

## Quy trình

1. Đọc `AI/shared/flutter-upgrade-order.md`; chỉ làm repository đang đến lượt.
2. Ghi nhận baseline: Git status, Flutter/Dart hiện tại, SDK constraints, dependency outdated, analyze và test hiện có.
3. Xác minh Flutter stable mục tiêu và migration guide từ nguồn chính thức; không dựa vào trí nhớ cho phiên bản mới nhất.
4. Nâng SDK constraints và dependency từng nhóm nhỏ. Đọc changelog/migration guide của dependency có major change hoặc native code.
5. Chạy `dart fix --dry-run` trước; chỉ áp dụng fix đã review và thuộc phạm vi.
6. Với Flutter plugin, cập nhật example/platform projects và registration API theo template hiện hành nhưng giữ identifier công khai nếu đổi sẽ làm hỏng consumer.
7. Chạy format, analyze, unit/widget tests và build/test platform bị ảnh hưởng.
8. Kiểm tra `flutter pub publish --dry-run` khi package chuẩn bị phát hành; rà archive để loại build/cache/secret.
9. Cập nhật CHANGELOG, README hoặc migration note; không tự publish, tag hoặc push.

## Gate tối thiểu

```bash
flutter --version
flutter pub outdated
flutter analyze
flutter test
```

Package thuần Dart dùng các lệnh `dart pub outdated`, `dart analyze` và `dart test`. Chỉ báo tương thích với platform đã được kiểm tra hoặc có CI chứng minh.

## Dừng và báo cáo

Dừng thay vì ép nâng khi dependency đã ngừng duy trì, license thay đổi, API mới đòi quyền truy cập nhạy cảm, hoặc migration làm thay đổi public contract mà chưa có quyết định version/migration.

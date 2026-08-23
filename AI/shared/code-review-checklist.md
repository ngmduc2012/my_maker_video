# Code Review Checklist

## Public API và null safety

- Export trong `lib/<package>.dart` là có chủ đích; không lộ implementation nội bộ ngoài ý muốn.
- Kiểu nullable, generic và async thể hiện đúng contract; không dùng `dynamic` để che lỗi type.
- Thay đổi breaking có migration path, changelog và version phù hợp.
- Exception hoặc `PlatformException` có mã lỗi, thông điệp và dữ liệu nhất quán.

## Dart và Flutter

- Code đã được `dart format`.
- `dart analyze` hoặc `flutter analyze` không phát sinh lỗi mới.
- Không dùng API deprecated khi có lựa chọn ổn định phù hợp.
- Không giữ import thừa, dead code, debug log hoặc generated artifact trong diff.
- Code dùng chung không import API chỉ tồn tại trên một platform.

## Plugin đa nền tảng

- Platform khai báo trong `pubspec.yaml` có implementation thật và đúng registration API hiện hành.
- Tên channel, method, argument và kiểu kết quả khớp giữa Dart và native/web.
- Mọi đường đi async đều hoàn tất result đúng một lần; lifecycle và listener được giải phóng.
- Permission, dữ liệu định danh, quyền riêng tư và fallback lỗi được xử lý rõ ràng.
- Example vẫn build/chạy trên platform bị ảnh hưởng, nếu môi trường cho phép.

## Hoàn tất

- Test mới hoặc test hiện có bao phủ hành vi thay đổi và đã chạy thành công.
- SDK/dependency constraints không rộng hơn mức đã thực sự kiểm tra.
- README, CHANGELOG và example được cập nhật khi contract hoặc cách dùng thay đổi.
- `dart pub publish --dry-run` hoặc `flutter pub publish --dry-run` chỉ chạy khi chuẩn bị phát hành.
- Không có secret, credential, file build, IDE cache hoặc dữ liệu máy cá nhân trong gói phát hành.

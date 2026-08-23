---
name: platform-channel
description: Sửa hoặc review Flutter plugin có MethodChannel, EventChannel, FFI hoặc implementation web/native.
---

# Platform Channel

## Quy trình

1. Đọc `pubspec.yaml` để liệt kê đúng platform đã khai báo và entry point tương ứng.
2. Lập bảng contract từ Dart: channel, method, argument, kiểu trả về và mã lỗi.
3. Đối chiếu từng implementation; tìm tên lệch, method thiếu, kiểu dữ liệu không tương thích và nhánh không hoàn tất result.
4. Kiểm tra registration API, lifecycle, listener/receiver/delegate, threading và cleanup.
5. Kiểm tra permission, privacy manifest/usage description và hành vi khi capability không có.
6. Thêm unit test cho Dart contract; thêm native/web test hoặc example smoke test cho platform bị ảnh hưởng.
7. Chạy analyze, test và build platform hẹp trước khi mở rộng matrix.

## Contract cần giữ

- Method/result hoàn tất đúng một lần, kể cả nhánh empty, denied, unsupported và exception.
- Stream được cancel và resource được giải phóng khi detach/dispose.
- Dữ liệu qua channel chỉ dùng kiểu codec hỗ trợ hoặc có serialization rõ ràng.
- Không gắn nhãn IMEI/MAC cho identifier khác và không trả identifier nhạy cảm khi platform cấm hoặc hạn chế.
- Web implementation không import `dart:io`; native implementation không bị kéo vào web bundle.

Không khai báo hỗ trợ platform chỉ vì project template có thư mục tương ứng.

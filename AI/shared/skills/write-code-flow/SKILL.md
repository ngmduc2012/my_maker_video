---
name: write-code-flow
description: Ghi lại luồng public API, state hoặc platform channel của package Dart/Flutter sau khi implementation tồn tại.
---

# Write Code Flow

Tạo hoặc cập nhật tài liệu kiến trúc gần nhất trong `doc/` hoặc `docs/`. Không tạo cả hai thư mục chỉ để tuân theo template.

Tài liệu cần có:

1. Điểm gọi từ public Dart API hoặc widget.
2. Luồng qua `lib/src` và state/service liên quan.
3. Với plugin: channel, method, argument và implementation từng platform.
4. Kiểu kết quả, lỗi và lifecycle.
5. Link tới file và test thật trong repository.

Không viết luồng cho API chưa tồn tại và không sao chép toàn bộ source vào tài liệu.

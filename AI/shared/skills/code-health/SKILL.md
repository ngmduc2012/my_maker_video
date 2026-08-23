---
name: code-health
description: Kiểm tra và cải thiện code Dart/Flutter trong phạm vi thay đổi mà không làm đổi public contract ngoài ý muốn.
---

# Code Health

## Chế độ diff

1. Đọc `AI/shared/project-context.md`, source và test liên quan.
2. Giữ nguyên thay đổi ngoài task; chỉ dọn code trong phạm vi đang sửa.
3. Chạy script với danh sách file khi worktree có thay đổi khác:

```bash
dart run AI/shared/skills/code-health/scripts/run_code_health.dart diff --files <file-1> <file-2>
```

Nếu toàn bộ thay đổi cùng thuộc task, có thể bỏ `--files`; script lấy file tracked/untracked đang đổi.

4. Kiểm tra thủ công public exports, null safety, async lifecycle, import platform-specific, dead code và debug log.
5. Chạy test hành vi liên quan. Với plugin native/web, bổ sung gate trong `platform-channel`; script Dart không chứng minh native implementation hoạt động.

## Chế độ audit

```bash
dart run AI/shared/skills/code-health/scripts/run_code_health.dart audit
```

Audit chạy format check, analyze và test cho package. Phân loại phát hiện thành `confirmed`, `candidate` hoặc `false-positive` trước khi sửa. Không tự xóa public API, file platform, code gọi qua reflection/registration hoặc thêm ignore rộng chỉ để báo cáo xanh.

## Giữ nguyên hành vi

- Package: public API, kiểu trả về, exception và side effect.
- Flutter UI: widget tree quan sát được, tương tác, state, loading/empty/error.
- Plugin: channel contract, permission, lifecycle, threading và cleanup.

Nếu test chưa chứng minh hành vi rủi ro, thêm characterization test trước khi refactor.

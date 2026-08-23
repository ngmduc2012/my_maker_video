# Flutter Upgrade Order

Nâng và kiểm định từng repository theo đúng thứ tự sau; chỉ chuyển bước khi repository hiện tại đã có kết quả kiểm tra rõ ràng:

1. `my_lang`
2. `my_log`
3. `my_timezone`
4. `my_device_info`
5. `my_bluetooth`
6. `my_maker_video`
7. `my_salt`
8. Đánh giá hợp nhất hoặc lưu trữ `DeviceInformationPlugin`

`my_filter_camera` chưa có source để nâng cấp. Chỉ thêm vào quy trình khi repository đã có code hoặc nguồn upstream được xác định.

Không hiểu thứ tự này là quyền tự động publish. Mỗi repository vẫn phải được review, test và xác nhận điều kiện phát hành riêng.

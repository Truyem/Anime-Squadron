# Anime Squadron Free HUB

**Ngôn ngữ:** [English](./README.md) | **Tiếng Việt**

[![Price](https://img.shields.io/badge/price-free-22c55e)](#miễn-phí--mã-nguồn-mở)
[![Source](https://img.shields.io/badge/source-open-3b82f6)](#miễn-phí--mã-nguồn-mở)
[![Language](https://img.shields.io/badge/language-Luau-00a2ff)](https://luau.org/)
[![License](https://img.shields.io/badge/license-MIT-f59e0b)](./LICENSE)

**Anime Squadron Free HUB** là script Luau automation miễn phí và mã nguồn mở, tích hợp sẵn giao diện tiếng Anh và tiếng Việt. Script kết hợp auto farm ở lobby, tiện ích trong trận, công cụ nâng cấp, party nhiều tài khoản và thống kê phiên local trong một giao diện duy nhất.

Dự án không có key system, không có paywall và không thu phí người dùng.

> Đây là dự án cộng đồng, không liên kết hoặc được chứng thực bởi Roblox hay nhà phát triển Anime Squadron. Hãy tự chịu trách nhiệm khi sử dụng phần mềm bên thứ ba và tuân thủ điều khoản của nền tảng.

## Tính năng

- Master Auto Farm với thứ tự ưu tiên tác vụ tùy chỉnh.
- Auto Join Map theo world, mode, độ khó và act.
- Auto Farm Gear với hàng đợi mục tiêu, số lượng và tiến độ được lưu lại.
- Auto Farm Unit với khả năng tự xác định map rơi unit.
- Farm Trait Map theo priority và độ khó đã chọn.
- Săn Daily Challenge và Regular Challenge theo phần thưởng mục tiêu.
- Auto Quest, quà đăng nhập, free bundle, battlepass, milestone và discovery index.
- Auto Evo và hàng đợi Auto Craft nhiều vật phẩm.
- Auto Stat Reroll với lựa chọn unit và khóa chỉ số cần giữ.
- Auto mua Merchant, Raid Shop, Event Shop và nâng cấp Perk.
- Trong trận có Auto Play, replay, replay theo wave, speed, ultimate và các cơ chế auto leave an toàn.
- Đồng bộ thời gian săn Challenge tại các mốc `XX:00` và `XX:30`.
- Party Mode Host/Member cho nhiều tài khoản và đồng bộ rời trận.
- Thống kê phiên farm hàng ngày gồm số trận và tài nguyên nhận được.
- Tự reconnect và đổi server khi bị kẹt.
- Tự nhập code và quét code mới từ Update Log.
- Lưu Fluent config, queue và thiết lập giao diện.
- Hỗ trợ lựa chọn tiếng Anh hoặc tiếng Việt.
- Công cụ visual độc lập giả lập Trait Reroll và Summon, chỉ hiển thị local.
- Hỗ trợ Anti-AFK.

## Cài đặt

Chạy loader sau trong môi trường Luau tương thích khi đã vào game:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Truyem/Anime-Squadron/refs/heads/main/astt.lua"))()
```

Lần chạy đầu tiên sẽ hiển thị màn hình chọn ngôn ngữ. Lựa chọn được lưu trong `as_free/Language.txt` và cũng có thể thay đổi tại Settings. Hãy chạy lại script sau khi đổi ngôn ngữ.

## Yêu cầu

- Môi trường thực thi Luau hỗ trợ `loadstring` và `game:HttpGet`.
- File APIs như `readfile`, `writefile`, `isfile`, `isfolder` và `makefolder` để lưu settings và queue.
- Kết nối mạng để tải Fluent UI, SaveManager, InterfaceManager và tài nguyên script.

Khả năng tương thích phụ thuộc vào môi trường thực thi. Nếu thiếu API, một số tính năng có thể không hoạt động dù giao diện vẫn tải thành công.

## Sử dụng cơ bản

1. Chạy loader tại lobby ít nhất một lần để cache dữ liệu map và inventory.
2. Chọn tiếng Anh hoặc tiếng Việt trong lần chạy đầu tiên.
3. Cấu hình map, mục tiêu farm, queue và thứ tự ưu tiên tác vụ.
4. Bật các tính năng cần dùng, sau đó bật `MASTER AUTO FARM`.
5. Kiểm tra kỹ username Party Mode trước khi AFK.
6. Nhấn `LeftControl` để thu nhỏ hoặc mở lại giao diện.

Settings và dữ liệu runtime được lưu trong `as_free/as_<UserId>` thuộc workspace của executor.

## File trong repository

- [`astt.lua`](./astt.lua): hub automation chính với hai ngôn ngữ.
- [`Fake.lua`](./Fake.lua): công cụ visual giả lập Trait Reroll và Summon, chỉ hoạt động local.
- [`README.md`](./README.md): tài liệu tiếng Anh mặc định.
- [`LICENSE`](./LICENSE): MIT License.

`Fake.lua` chỉ thay đổi hình ảnh hiển thị phía client, không thực hiện Trait reroll hoặc Summon thật. Script chính không tự động tải file này.

## Mạng & Quyền riêng tư

Script chính không gửi inventory, unit, số dư tài nguyên, username hoặc thống kê phiên tới webhook hay máy chủ bên ngoài. Thống kê phiên chỉ được lưu trong workspace local của executor.

Script chính chỉ thực hiện kết nối mạng để:

- Tải Fluent UI, SaveManager và InterfaceManager từ nguồn GitHub chính thức.
- Đọc danh sách server công khai của Roblox khi cơ chế đổi server chống kẹt hoạt động.

Party Mode phân giải username bằng API tích hợp `Players:GetUserIdFromNameAsync()` của Roblox. File `Fake.lua` là công cụ độc lập và không bao giờ được script chính tự thực thi.

## Miễn phí & Mã nguồn mở

Mã nguồn được công khai miễn phí để cộng đồng đọc, kiểm tra, cải tiến và đóng góp.

- Không mua bán hoặc trả phí để nhận script này.
- Không tin các bản reupload yêu cầu key hoặc thanh toán.
- Nên lấy phiên bản mới nhất trực tiếp từ repository GitHub chính thức.
- Khi chia sẻ hoặc fork, vui lòng giữ copyright notice và license notice.

Dự án được phát hành theo [MIT License](./LICENSE).

Nếu dự án hữu ích, hãy tặng repository một Star:

https://github.com/Truyem/Anime-Squadron

## Đóng góp

Pull request và báo lỗi đều được hoan nghênh.

1. Fork repository.
2. Tạo branch cho thay đổi của bạn.
3. Giữ thay đổi nhỏ, rõ ràng và không thêm code bị obfuscate.
4. Kiểm tra cú pháp Luau trước khi gửi pull request.
5. Mô tả hành vi đã thay đổi và cách bạn kiểm tra nó.

Khi báo lỗi, hãy cung cấp mode/map, thao tác gây lỗi, log console liên quan và tên môi trường thực thi. Không đăng webhook URL, token tài khoản hoặc dữ liệu cá nhân.

## Credits

- **Truyem789**: tác giả và người duy trì dự án.
- [Fluent](https://github.com/dawid-scripts/Fluent): thư viện UI, SaveManager và InterfaceManager.
- Cộng đồng Anime Squadron: kiểm thử và đóng góp phản hồi.

## Disclaimer

Phần mềm được cung cấp nguyên trạng và có thể ngừng hoạt động sau khi game cập nhật. Tác giả không chịu trách nhiệm cho mất dữ liệu, gián đoạn tài khoản hoặc hậu quả khác phát sinh từ việc sử dụng script.

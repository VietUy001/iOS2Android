# Phụ lục giải thích các số hiệu quy tắc

Tài liệu này chỉ giải thích các chuỗi `rule #NN`, `#NN` và `bất biến #NN` xuất hiện trong repo để người đọc bên ngoài hiểu ngữ cảnh. Đây không phải điều khoản ràng buộc người dùng ngoài, không bổ sung nghĩa vụ mới, và không thay thế các quy định canonical trong `SKILL.md`, `enforcement.md`, `measurement.md` hoặc checklist.

## Cách lập bảng

- Danh mục được lấy bằng cách grep toàn repo với mẫu `#[0-9]+`, sau đó loại mã màu, số thứ tự stage, ID checklist và các số không được dùng như quy tắc.
- Tên gọi dưới đây là nhãn mô tả ngắn suy trực tiếp từ ngữ cảnh công khai trong repo, không phải tên chính thức nếu repo không nêu tên.
- Repo đang dùng xen kẽ ít nhất hai hệ đánh số: `rule #NN` của bộ house rules và `bất biến #NN` của riêng skill. Vì vậy cùng một số không nên được suy rộng ra ngoài đúng ngữ cảnh được liệt kê.

## Danh mục

| Số hiệu | Tên gọi | Tóm tắt suy từ ngữ cảnh trong repo | File trích dẫn |
|---|---|---|---|
| `#3` | Không tự ý diễn giải lại iOS | Trong hệ bất biến của skill, Android không được tự thêm, bỏ hoặc đổi hành vi so với iOS. Mọi khác biệt phải vào Deviation Register và có sign-off phù hợp. | `telegram-grade.md` |
| `#5` | Không để Material mặc định lọt vào UI | Spacing và thành phần mặc định của Material/Compose không được thay cho số đo iOS. Token và component phải được override theo Parity Spec. | `telegram-grade.md`, `mapping-kb.md`, `enforcement.md` |
| `#13` | Test-env isolation | Cấm chạy parity test trên backend production. Cả hai nền tảng phải dùng staging, mock hoặc fixture đã khai trong manifest. | `SKILL.md`, `enforcement.md`, `measurement.md`, `scripts/preflight.sh`, `parity-spec.template.md`, `manifest.template.md` |
| `#14` | Source pin | Parity Spec và ledger phải gắn với một revision iOS cố định. Khi source đổi, phải re-sync các màn và flow bị ảnh hưởng trước khi tiếp tục port. | `SKILL.md`, `orchestration.md`, `scripts/preflight.sh`, `manifest.template.md` |
| `#15` | REUSE-FIRST | Trước khi tạo component, util, adapter hoặc style mới, phải tìm và tái dùng hoặc mở rộng bản tương đương đã có. Trùng chức năng từ hai bản trở lên là lỗi cần hợp nhất. | `SKILL.md`, `enforcement.md`, `roles.md`, `telegram-grade.md` |
| `#16` | Tiếng Việt là locale mặc định | `values/strings.xml` dùng tiếng Việt làm fallback; tiếng Anh đặt ở `values-en/`. Repo không mô tả công khai thêm về nguồn gốc số hiệu này. | `mapping-kb.md` |
| `#17` | Device pair cùng logical size | Chỉ đo parity khi kích thước logical của thiết bị tham chiếu iOS theo pt bằng kích thước Android theo dp. Nếu lệch, `%diff` và IoU không hợp lệ. | `SKILL.md`, `manifest.template.md` |
| `#24` | Giới hạn kích thước file | File Kotlin/KTS trên 500 LOC phải được đánh giá; trên 800 LOC là trần cứng trừ khi người dùng duyệt và có marker. Chỉ tách theo nhóm chức năng, không tách cơ học để hạ số dòng. | `enforcement.md`, `roles.md`, `checklists/standards.md`, `scripts/verify.sh` |
| `#24.2` | Đánh giá file trên 500 LOC | Một nhóm chức năng thì giữ và báo số LOC cho user; từ hai nhóm chức năng trở lên thì tách theo nhóm. | `SKILL.md`, `scripts/verify.sh` |
| `#24.4` | Miễn trừ code sinh tự động | Code được sinh tự động được loại khỏi phép kiểm giới hạn LOC. Repo chưa mô tả công khai thêm về tiêu chí ngoài các pattern loại trừ trong script. | `scripts/verify.sh` |
| `#27` | ATT chỉ áp dụng cho iOS | Android không dùng ATT. Nếu có quảng cáo, Android dùng UMP consent và khai `AD_ID` cùng Data Safety phù hợp. | `mapping-kb.md`, `checklists/standards.md` |
| `#30` | Attestation một lần thành device token | App Attest/DeviceCheck được map sang Play Integrity. Không ký lại từng request, không gate read công khai, và client vẫn gửi request khi token chưa sẵn theo cơ chế fail-open-send. | `mapping-kb.md`, `checklists/capability.md` |
| `#31` | In-App Review đúng thời điểm | Không để nút “Đánh giá” gọi thẳng Review API. Review tự động chỉ kích hoạt ở mốc tích cực và được throttle một lần mỗi phiên bản; nút chủ động mở trang store. | `mapping-kb.md`, `checklists/capability.md`, `checklists/standards.md` |
| `#32` | Đồng bộ version gate backend | Khi bump phiên bản app, phải cập nhật cấu hình version gate phía backend và các header/version tương ứng; nếu không, bản mới có thể bị chặn 403. | `mapping-kb.md`, `checklists/standards.md` |
| `#34` | Release gate | Debug pass chưa đủ. Phải build `assembleRelease`, xử lý R8/minify/keep rules, cài bản release thật và smoke-test các flow trước khi DONE. | `SKILL.md`, `enforcement.md`, `scripts/verify.sh`, `checklists/standards.md`, `manifest.template.md` |
| `#37` | Log là một phần của Definition of Done | Log phải được đặt cùng lúc với code cho màn, vùng, scroll, nhánh quyết định và lỗi; đi qua kênh chung, được gác cho debug, dùng message lambda và không chứa PII. Thiếu log hoặc dùng `Log.d`/`println` rời rạc thì chưa xong. | `SKILL.md`, `enforcement.md`, `mapping-kb.md`, `roles.md`, `checklists/capability.md`, `checklists/standards.md`, `checklists/ui-parity.md`, `scripts/verify.sh`, `parity-spec.template.md`, `manifest.template.md`, `benchmark/README.md`, `benchmark/fixtures/sample-spec-good.md` |

## Ghi chú về phạm vi

Các tham chiếu như `§20`, `§21`, stage `-1` đến `6`, ID `C20` hoặc `F01`, và mã màu dạng `#22D3EE` không phải house rule nên không có trong bảng. Nếu một số hiệu chỉ có mô tả cục bộ, bảng giữ nguyên giới hạn đó thay vì suy đoán nội dung của bộ quy tắc riêng chưa được công bố.

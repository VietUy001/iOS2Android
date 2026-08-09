<div align="center">

<img src="assets/banner.png" alt="iOS2Android" width="100%">

**Tiếng Việt** · [English](README.en.md) · [中文](README.zh-CN.md) · [한국어](README.ko.md) · [日本語](README.ja.md)

![version](https://img.shields.io/badge/version-1.0.0-8FA8C4?style=flat-square)
![license](https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-22D3EE?style=flat-square)
![platform](https://img.shields.io/badge/platform-macOS-0B0F1A?style=flat-square)
![claude code](https://img.shields.io/badge/Claude%20Code-skill-38BDF8?style=flat-square)
![selftest](https://img.shields.io/badge/selftest-39%20checks-3DDC84?style=flat-square)

</div>

## iOS2Android là gì

Một **skill cho Claude Code**: quy trình port app iOS (Swift/SwiftUI) sang Android (Kotlin/Compose) với mục tiêu **parity đo được**, không phải "làm lại cho giống giống".

Vấn đề của việc nhờ AI port app: nó dựng ra một bản Android *trông na ná*, thiếu vài section, lệch nhịp dọc, mất hiệu ứng, rồi tuyên bố "cơ bản đã xong". Skill này biến "xong" thành một điều kiện **nhị phân do script quyết định**, không do agent tự phán.

```
Chưa có số đo  →  chưa VERIFIED
Chưa VERIFIED  →  chưa DONE
Chưa DONE      →  agent không được phép dừng
```

## Ba trụ parity và sai số cho phép

| Hạng mục | Sai số tối đa |
|---|---|
| Vị trí / kích thước / spacing | ≤ 2 dp |
| Màu sắc | 0 (đúng hex/alpha) |
| Thời lượng animation | ≤ 16 ms (1 frame @60fps) |
| Visual diff pixel mỗi state | ≤ 1.0% sau khi loại chrome hệ thống |
| Nội dung chữ | 0 (giống tuyệt đối, qua i18n key) |

- **Trụ 1 Visual**: layout, màu, typography, icon, theme, mọi state.
- **Trụ 2 Behavioral**: chức năng, state machine, validation, edge case, persistence, navigation.
- **Trụ 3 Perceptual**: animation, transition, gesture, haptic, scroll physics.

Chỗ nào không thể giống 100% (font hệ thống, back gesture, ripple, dịch vụ độc quyền Apple) thì phải ghi vào `DEVIATIONS.md` và chờ người dùng duyệt, không được im lặng làm khác.

## Pipeline

<img src="assets/pipeline.png" alt="Pipeline stage -1 đến 6" width="100%">

## Chuỗi cổng kiểm tra

Không có ảnh và số đo thì không có parity. Mỗi cổng đều được script kiểm, trượt cổng nào thì dừng ngay ở đó.

<img src="assets/gates.png" alt="Verify gate chain" width="100%">

## Trong repo có gì

| File | Vai trò |
|---|---|
| `SKILL.md` | La bàn: formula card, pipeline, 18 quy tắc bất biến, bảng load-on-demand |
| `enforcement.md` | Ép form chống bỏ ngang: ledger, Definition of Done, no-stop, anti-stub, element gate, section gate, release gate, log gate |
| `measurement.md` | Cách đo thật: visual diff, onion-skin, IoU, cặp thiết bị, đo animation, perf, regression baseline |
| `mapping-kb.md` | Kho ánh xạ Swift ↔ Kotlin: motion, layout, state, concurrency, navigation, API, typography, i18n, log |
| `orchestration.md` | Chia việc có giới hạn, resume qua nhiều phiên, chống phình context |
| `roles.md` | 8 vai: MANAGER, UI-AUDITOR, SOURCE-ANALYST, FLOW-CHECKER, DEV-FE, DEV-FUNC, QA-RECONCILER, PERF-OPTIMIZER |
| `telegram-grade.md` | Kỹ thuật animation/render rút từ source Telegram, kèm cổng chống làm quá tay |
| `parity-spec.template.md` | Mẫu tài liệu vàng: Structure Map, Flow Inventory, ledger, spec từng màn |
| `manifest.template.md` | Khai báo đầu vào: path, source pin, test-env, cặp thiết bị, mode |
| `checklists/` | 3 checklist ký tay: ui-parity, capability, standards |
| `scripts/` | 7 script: preflight, inventory, extract-assets, parity-diff, verify, parity-status, selftest |
| `benchmark/` | App iOS mini + máy chấm process compliance |

## Cài đặt

```bash
git clone https://github.com/VietUy001/iOS2Android.git
mkdir -p ~/.claude/skills
cp -R iOS2Android ~/.claude/skills/ios2android
chmod +x ~/.claude/skills/ios2android/scripts/*.sh
```

Trong Claude Code, gõ:

```
/ios2android
```

Skill sẽ hỏi 2 đường dẫn tuyệt đối (source iOS và thư mục Android đích), xin duyệt vị trí đặt tài liệu, rồi chạy preflight.

## Yêu cầu môi trường

- macOS, Xcode + iOS Simulator (làm oracle: không chạy được app iOS thì không có gì để so).
- Android SDK, JDK, emulator hoặc máy thật.
- `adb`, `ffmpeg`, ImageMagick (`compare`, `convert`, `composite`, `identify`), `git`.
- Quan trọng: emulator Android phải có **cùng logical size** với thiết bị iOS tham chiếu (ví dụ cả hai đều 393x852). Lệch dp thì mọi con số %diff và IoU đều vô nghĩa.

## Tự kiểm

```bash
scripts/selftest.sh      # 39 assertion cho các cổng: ledger, bằng chứng, deviation, preflight, IoU, texts-diff
benchmark/selftest.sh    # kiểm máy chấm benchmark
```

Chạy benchmark trên app mẫu:

```bash
T=$(mktemp -d); cp -R benchmark/fixture-ios "$T/ios"; mkdir "$T/android"
# chạy /ios2android trỏ vào $T/ios và $T/android, tới hết stage 1
benchmark/score.sh "$T/parity-spec.md" "$T/android"
```

## Giới hạn đã biết

- Chỉ chạy trên macOS, vì oracle bắt buộc là iOS Simulator.
- Benchmark chấm **quy trình**, không chấm pixel parity: đo pixel cần cả simulator lẫn emulator nên không tự động hoá được.
- App iOS không build được thì phải bật ORACLE-LIMITED và chịu mất Trụ 1, cần người dùng ký chấp nhận.
- Tài liệu doctrine viết bằng tiếng Việt. Bản tóm tắt tiếng Anh ở [docs/overview.en.md](docs/overview.en.md).

## Tác giả

**Nguyễn Việt Uy** · [@VietUy001](https://github.com/VietUy001)

- Facebook: https://www.facebook.com/1206463405
- Telegram: https://t.me/QTUNUy

Góp ý, báo lỗi hoặc hỏi cách dùng: nhắn Telegram hoặc mở Issue trên repo.

## Giấy phép

[CC BY-NC-ND 4.0](LICENSE): dùng miễn phí cho mục đích cá nhân, học tập, nghiên cứu và công việc nội bộ phi thương mại. **Cấm dùng cho mục đích thương mại. Cấm phát hành bản chỉnh sửa.** Khi dùng thì ghi nguồn và dẫn link về repo gốc.

Tác giả mong bạn **không mirror hay đăng lại** repo này ở nơi khác. Hãy dẫn link về bản gốc để mọi người luôn nhận được bản mới nhất.

<div align="center">
<sub>iOS2Android · parity là số đo, không phải cảm nhận</sub>
</div>

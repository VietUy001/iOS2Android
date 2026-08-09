# ios2android manifest — <APP NAME>

> Copy thành `s2a-manifest.md` trong folder dự án Android (sau khi user duyệt
> vị trí — không tự tạo folder). Khai báo đầu vào & quyết định cho 1 lần port.

## Paths (CHỈ đọc/ghi 2 path này — project isolation)
- iOS source (read-only): `<abs path>`
- Android target (read/write): `<abs path>`
- Parity Spec: `./parity-spec.md`
- Deviations: `./DEVIATIONS.md`
- Ledger: trong `parity-spec.md` §4

## Source pin (bất biến #14 SOURCE PIN — bắt buộc, preflight kiểm)
- ios_rev: `<git rev/tag iOS>`  (mọi spec gắn rev này; lệch → re-sync)

## Test-env isolation (bất biến #13 TEST-ENV — CẤM prod)
- test_backend: `<https://staging… hoặc mock://…>`  (KHÔNG chứa prod)
- fixture dir: `./fixtures/`

## Cặp thiết bị đo parity (bất biến #17 — measurement §1.2, preflight kiểm)
> pt của iOS PHẢI BẰNG dp của Android, nếu không mọi %diff/IoU đều vô nghĩa.
- ios_ref_pt: `393x852`        (vd iPhone 15 = 393×852 pt)
- android_device_dp: `393x852` (ép bằng `adb shell wm size/density`, hoặc AVD
  có cùng logical size; kiểm: `parity-diff.sh devcheck 393x852`)
- Giữ NGUYÊN cặp này suốt dự án (đổi giữa chừng = baseline cũ hết hiệu lực).

## Tham chiếu chụp ảnh iOS
- Device class: `<iPhone 15 / @3x>`
- iOS version: `<17.x>`
- Có chạy được iOS để record animation? `<yes/no>`
- oracle_mode: `full`   (`limited` = iOS KHÔNG build/chạy được — SKILL.md
  §ORACLE-LIMITED; chỉ được đặt khi user duyệt)
- oracle_limited_approved: `<no/yes — ai duyệt, ngày>`

## Performance targets (measurement.md §7)
- Cold start iOS: `<ms>` → Android trần: `<iOS+20%>`
- fps target màn động: `<60/120>` | jank frame trần: `<%>`

## Stack Android (dùng cái đã có / user duyệt — KHÔNG tự cài dependency)
- UI: Jetpack Compose + Material3 (token override toàn bộ)
- DI: `<Hilt/Koin/—>`  | Net: `<Ktor/OkHttp/—>` | DB: `<Room/—>`
- minSdk/targetSdk: `<theo yêu cầu Play hiện hành>`
- Tooling đề xuất chờ user duyệt (orchestration §E): `<điền khi research>`

## Font
- iOS font: `<SF Pro>` → Android: `<bundle SF Pro / metric-equivalent / Deviation>`

## Asset
- iOS catalog: `<Assets.xcassets path>`
- Pipeline: `scripts/extract-assets.sh` (dùng chung asset iOS, KHÔNG vẽ lại)
- Map nguồn từng resource: ghi `from: <catalog/name>` (traceable cho app sau)

## i18n
- Default locale: `vi` (i18n không hardcode). Locale khác: `<en/ja/ko/—>`

## Log (rule #37 — bắt buộc, enforcement §21)
- Kênh log chung: `<vd AppLog.kt — AppLog.auth/AppLog.home/…>`
- Gác: `BuildConfig.DEBUG` + message lambda | CẤM `Log.d`/`println` rời rạc
- CẤM PII: chỉ id rút gọn 6 ký tự, mã trạng thái, số lượng, nhánh, thời gian

## Release gate (rule #34 — enforcement §20)
- `assembleRelease` pass: `<yes/no>` | smoke-test bản release: `<ngày, flow>`
- Keep-rule R8 cho reflection/serialization: `<đã có/không dùng>`

## Version — KHÔNG auto-bump mobile khi user chưa yêu cầu rõ
- Source-of-truth: `<build.gradle versionName/versionCode>`
- Hiển thị UI: `<Settings row>`

## Quyết định đã chốt với user
| # | vấn đề | quyết định | ngày |
|---|---|---|---|
| | vị trí spec/manifest | | |
| | font strategy | | |
| | tooling thêm | | |

## Trạng thái port (tóm tắt — chi tiết ở ledger)
- Tổng flow: `<n>` | VERIFIED: `<n>` | DONE? chạy `scripts/parity-status.sh`

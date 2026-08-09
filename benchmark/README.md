# Benchmark — process compliance cho skill /ios2android

Benchmark end-to-end chấm **quy trình** (spec coverage + gate compliance) khi Claude
chạy skill trên 1 app iOS mini biết trước cấu trúc (`fixture-ios/`). KHÔNG đo
pixel-parity outcome — việc đó cần simulator iOS + emulator Android (quá nặng cho
benchmark tự động); dùng `scripts/parity-diff.sh` thủ công khi cần.

## Thành phần

| File | Vai trò |
|---|---|
| `fixture-ios/` | App SwiftUI mini (2 screen, tab nav, flow add-item nhiều bước, animation scale, i18n vi+en, persist UserDefaults, 1 hidden key `secret.easterEgg`, 1 color trong code) — chỉ là INPUT port, không cần build |
| `expected.json` | Ground truth: entry ledger bắt buộc (patterns nhiều alias), section bắt buộc (gồm **LOG-INVENTORY** rule #37 và **DEVICE-PAIR** measurement §1.2), min ledger rows, min screens |
| `score.sh` | Scorer máy-chấm: coverage / sections / gate integrity / anti-stub |
| `fixtures/sample-spec-{good,poor}.md` + `selftest.sh` | Tự kiểm scorer (good→PASS, poor→FAIL đúng entry) |

## Protocol eval

1. **Setup**: copy `fixture-ios/` ra thư mục tạm + tạo folder Android đích rỗng:
   ```bash
   T=$(mktemp -d); cp -R benchmark/fixture-ios "$T/ios"; mkdir "$T/android"
   ```
2. **Chạy skill**: phiên Claude mới, gọi `/ios2android` trỏ iOS source `$T/ios`,
   Android đích `$T/android` (app nhỏ → LITE MODE phù hợp). Duyệt vị trí spec khi
   skill hỏi (vd `$T/parity-spec.md`).
3. **Chấm sau stage 1** (spec vừa sinh xong, trước khi port):
   ```bash
   benchmark/score.sh "$T/parity-spec.md" "$T/android"
   ```
   → đo chất lượng inventory/spec: skill có bắt đủ 2 screen, flow, animation,
   hidden key, i18n 2 lang, persist, color, TextField/bàn phím, log inventory,
   cặp thiết bị đo... không.
4. **Chấm sau khi port xong** (skill tuyên bố DONE): chạy lại `score.sh` +
   `scripts/parity-status.sh "$T/parity-spec.md" "$T/android"` — gate phải in
   `DONE` thật (ledger VERIFIED hết, verify.sh GREEN).
5. **Metrics** (dòng `BENCHMARK:` của score.sh):
   - `coverage=X%` — % entry ground-truth có mặt trong spec (PASS cần ≥90%).
   - `sections=Y/Z` — section bắt buộc + ledger ≥ 8 dòng hợp lệ + ≥ 2 screen.
   - `gate=CONSISTENT|INCONSISTENT` — parity-status.sh chạy được và lý do
     DONE/NOT DONE khớp trạng thái ledger thật (không đòi DONE ở bước 3).
   - `stub=N` — marker TODO/FIXME/notImplemented trong Android (thông tin).
   - Nếu chạy trọn: parity-status.sh = `DONE` là metric outcome cuối.

## Selftest scorer

```bash
benchmark/selftest.sh   # → BENCH SELFTEST PASS
```

## Giới hạn

- Không đo pixel-parity / hành vi runtime (cần emulator + simulator).
- Coverage match bằng regex alias → có thể false-positive nếu spec nhắc từ khoá
  mà không thật sự spec hoá; đọc chéo spec khi điểm sát ngưỡng.
- Gate ở bước 3 chỉ kiểm "script chạy + lý do nhất quán", không kiểm build Android.

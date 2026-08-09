# MEASUREMENT — đo parity thật, không cảm quan

> Biến "giống 100%" thành số đo được. Dùng ở Stage 5 lớp B + Detail Diff
> Table. Mọi kết luận parity phải kèm con số + đường dẫn bằng chứng.

## 1. Visual diff (ảnh tĩnh, từng state)

### 1.0 DETERMINISTIC CAPTURE (bắt buộc — diff nhiễu = gate vô dụng)
Trước khi chụp, ÉP môi trường tất định ở CẢ 2 nền tảng (parity-diff.sh tự
áp): freeze status-bar/clock (iOS `simctl status_bar override`, Android demo
mode), TẮT animation khi chụp tĩnh (Android `settings put global
*_animation_scale 0`; iOS reduce-motion/đợi anim kết thúc), seed data cố
định + cùng fixture (§4) + cùng entitlement state, khoá device-class/scale/
locale/font-scale/appearance, ẩn chrome động (giờ/pin/sóng). Khác môi trường
= diff giả → CẤM kết luận PASS/FAIL trên ảnh chưa tất định.

Quy trình (script `scripts/parity-diff.sh`):
1. **Chụp iOS** (simulator): `xcrun simctl io booted screenshot ios.png`.
   Cùng màn, cùng state, cùng data fixture (xem §4).
2. **Chụp Android** (emulator/thiết bị): `adb exec-out screencap -p > and.png`.
   Cùng màn/state/fixture, cùng appearance (light/dark), cùng dynamic-type.
3. **Cắt chrome** không thuộc app (status bar, nav/gesture bar) theo vùng đã
   ghi `DEVIATIONS.md` — chỉ so phần app vẽ.
4. **Chuẩn hoá**: scale cả 2 về cùng logical width (point/dp), KHÔNG méo tỉ
   lệ. iOS @3x → chia 3; Android theo density → chia về dp.
5. **Diff**: ImageMagick `compare -metric AE` (đếm pixel khác) + perceptual
   `-metric DSSIM`/`-fuzz`. Tính `%diff = AE / tổng pixel`.
6. **Đạt**: `%diff ≤ 1.0%` (tolerance §0 SKILL.md) sau khi loại chrome.
   Sinh ảnh heatmap khác biệt để QA soi vùng lệch.
7. Lưu `ios.png/and.png/diff.png + %` làm bằng chứng dòng ledger.

Lưu ý: khác font hệ thống/anti-alias gây diff nền → đó là lý do chọn font
metric-tương-đương + tắt `includeFontPadding` (mapping-kb §Typography); nếu vẫn lệch do
render glyph → Deviation, KHÔNG hạ tolerance ngầm.

### 1.2 CẶP THIẾT BỊ CÙNG LOGICAL SIZE (bắt buộc — nếu không, mọi số đều sai)
iOS đo bằng **pt**, Android bằng **dp**, quy đổi 1:1 — NHƯNG kích thước màn
khác nhau: iPhone 15 = 393×852 pt, Pixel 7 = 412×915 dp. Nếu chụp 2 máy này
rồi scale ảnh Android về width iOS, mọi element bị thu 4.6%: một bản Android
ĐÚNG (card 100dp = 100pt) sẽ hiện thành sai 4.6%, còn một bản SAI 4.6% lại
"qua". ⇒ %diff và IoU **không có ý nghĩa** khi 2 nền khác logical size.
- Khai trong manifest: `ios_ref_pt: 393x852` và `android_device_dp: 393x852`
  (phải BẰNG nhau). `preflight.sh … verify` chặn nếu lệch.
- Ép thiết bị Android về đúng dp: `adb shell wm size <W>x<H>` (px) +
  `adb shell wm density <dpi>` sao cho `px*160/dpi == pt`. Reset: `wm size reset`.
  Kiểm nhanh: `parity-diff.sh devcheck 393x852` → phải `DEVCHECK: GREEN`.
- Đặt `S2A_IOS_PT_W=393` khi chạy `diff`/`onion` để script tự cảnh báo đo chéo.
- Chọn cặp thiết bị 1 lần ở Stage -1 và **giữ nguyên suốt dự án** (đổi giữa
  chừng = mọi baseline cũ hết hiệu lực, §8).

### 1.1 ONION-SKIN OVERLAY + COLOR-SPACE (bắt buộc — %pixel KHÔNG đủ)
`%diff = AE/tổng` là chỉ số TOÀN CỤC: một lệch ĐỀU 2dp khắp màn có thể vẫn
"≤1%" mà mắt thấy sai rõ. Phải bổ sung 2 phép:
- **Onion-skin / blink**: chồng `ios.png` lên `and.png` ở alpha 50% (ImageMagick
  `composite -blend 50 ios.png and.png onion.png`) + ảnh blink (flicker 2 frame).
  QA soi: mép element/baseline text/cạnh card có "double-vision" = lệch vị trí
  → mở FAIL kèm `onion.png`, kể cả khi %diff qua. Đây là kiểm bố cục mạnh nhất.
- **Color-space normalization TRƯỚC khi so màu**: iOS thường render/chụp
  **Display-P3**, Android sRGB → so hex thô báo lệch GIẢ. Convert cả 2 về cùng
  profile (`convert in.png -profile sRGB.icc out.png` hoặc `-colorspace sRGB`)
  rồi mới đo màu/diff. Token màu lấy từ **source iOS** (giá trị thật), KHÔNG
  pick từ screenshot đã lệch profile.
- **Màu phải kiểm RIÊNG**: `compare` chạy với `-fuzz 2%` (chống nhiễu
  anti-alias) ⇒ %diff KHÔNG chứng minh được parity màu (tolerance màu = 0).
  Dùng `parity-diff.sh color <img> <x> <y>` lấy hex tại điểm đại diện của mỗi
  vùng màu, đối chiếu **token lấy từ source iOS** (không pick từ ảnh).
- **Text content phải kiểm RIÊNG**: `parity-diff.sh texts-and and.txt` (trích
  text hiển thị từ `uiautomator`) + tập text iOS (MCP describe-ui hoặc §8 i18n
  spec) → `parity-diff.sh texts-diff ios.txt and.txt`. Bắt được "mất nguyên
  một section chữ" mà %diff nuốt gọn (đúng defect enforcement §11 mô tả).
- Kết hợp: %diff (nền) + onion-skin (bố cục) + element-IoU §3.1 (vị trí từng
  element) + texts-diff (nội dung) + color (màu) — đủ 5 mới kết luận Trụ 1.

## 2. Đo animation / transition (Trụ 3)

**Nguồn chuẩn = SOURCE, không phải mắt thường:**
1. Đọc Swift: lấy literal `.spring(response:R, dampingFraction:D)`,
   `.easeInOut(duration:t)`, `.delay(d)`, `withAnimation(...)`,
   `.repeatForever(autoreverses:)`, keyframes. → quy đổi Compose theo
   `mapping-kb.md §Motion` (công thức chính xác).
2. **Xác nhận bằng record** (không phải để đoán):
   - Quay iOS: `xcrun simctl io booted recordVideo ios.mov` trong khi trigger.
   - Tách frame: `ffmpeg -i ios.mov -vf fps=120 f_%04d.png` (hoặc 60).
   - Đếm số frame từ frame bắt đầu đổi → frame ổn định cuối.
   - `duration_ms = (frames-1) * 1000 / fps`.
   - Làm tương tự Android (`adb shell screenrecord` / `recordVideo`).
3. **Đạt**: `|duration_iOS - duration_Android| ≤ 16ms` và đường cong khớp
   (kiểm tra vài frame mốc: 25%/50%/75% tiến trình lệch ≤ 1 frame).
4. Spring khó đo bằng frame → tin công thức từ source là chính; record chỉ
   bắt sai lệch thô (overshoot/bounce sai rõ).

## 3. Đo số đo tĩnh (Detail Diff Table)

- Lấy từ **source iOS trước** (constant, token, `.frame/.padding/.font`),
  điền cột iOS. Đây là chân lý.
- Đối chiếu Android bằng layout inspector / `onGloballyPositioned` log /
  screenshot đo pixel.
- Ô = `iOS | Android | PASS|Δ=...`. Δ > tolerance §0 = FAIL.

### 3.1 LAYOUT ANCHOR & SAFE-AREA (bắt buộc — chống "cao/thấp/lệch")
Lỗi điển hình: content đẩy sát status bar (thiếu top inset), nhịp dọc sai.
- **Safe-area/system inset**: đo inset top/bottom/leading/trailing iOS
  (`view.safeAreaInsets`, dưới status bar/notch/home-indicator) ↔ Android
  (`WindowInsets`/`Scaffold` padding, edge-to-edge). Content KHÔNG được chạm
  status bar nếu iOS có khoảng cách. Thiếu inset = FAIL.
- **Anchor dọc**: đo Y (theo dp, từ mép safe-area top) của MỖI khối top-level
  — hero/icon center, title, card top, primary button, tab bar — trên ảnh
  iOS vs Android. |ΔY| ≤ tolerance §0 (≤2dp) từng khối.
- **Box model từng element**: padding trong, margin ngoài, spacing giữa các
  item, alignment (left/center), kích thước. Lấy từ source iOS, KHÔNG ước.
- Điền các dòng này vào Detail Diff Table (loại `layout`): inset_top,
  anchor_Y(<khối>), pad, margin, gap, align. Δ vượt = FAIL.
- **Element-box IoU** (mạnh hơn %pixel toàn màn): lập CSV
  `name,ix,iy,iw,ih,ax,ay,aw,ah` (dp) cho từng element rồi
  `parity-diff.sh iou bbox.csv [thr=0.90]`. IoU < ngưỡng = element lệch
  vị trí/kích thước = FAIL (kể cả khi %pixel toàn màn "qua").
- **Bán tự động (bớt gõ tay)**: `parity-diff.sh boxes-and bbox.csv` tự trích
  bbox Android (px→dp) từ `uiautomator dump` → điền sẵn cột `ax,ay,aw,ah`.
  Cột iOS (`ix,iy,iw,ih`) lấy từ accessibility/view-hierarchy iOS qua MCP
  `xcodebuild`/`ios-simulator` describe-ui (frame mỗi element), hoặc đo từ
  source. Có CSV → `parity-diff.sh iou`. Lý do dùng a11y/semantics tree thay
  vì dò pixel: tọa độ chính xác từ hệ thống, không nhiễu anti-alias.

## 4. Contract & Fixture parity (cùng input → cùng output)

"Behavior parity" vô nghĩa nếu iOS và Android nhận dữ liệu khác.
- Trích **hợp đồng API** từ source iOS: endpoint, method, request shape,
  response shape, mã lỗi, header. Ghi vào `parity-spec.md §Network Contracts`.
- Tạo **fixture cố định** (JSON response mẫu cho mọi nhánh: ok/empty/error/
  timeout/phân trang). Dùng CHUNG:
  - Oracle iOS: chạy iOS trỏ mock/staging trả fixture, ghi hành vi quan sát.
  - Test Android: cùng fixture → assert cùng output.
- Không có fixture chung → KHÔNG được đánh VERIFIED behavior.
- **Entitlement/VIP trong ma trận fixture**: thêm 2 trạng thái `locked` &
  `unlocked` (mock receipt/entitlement, KHÔNG mua thật, KHÔNG prod — bất biến
  #13 TEST-ENV). Dùng
  debug-override entitlement để render & diff UI mở khoá ở CẢ iOS lẫn Android
  mà không cần tài khoản VIP demo. iOS không ép được → đối chiếu code-flow
  tương đương + asset, ghi DEVIATION (parity-spec §10.1).

## 5. Test-env isolation (an toàn)

- CẤM tuyệt đối chạy parity test (iOS oracle hoặc Android) trên backend
  **prod** — có thể tạo/sửa/xoá dữ liệu thật.
- Manifest khai báo `test_backend` = staging URL hoặc mock server. Mọi run
  trỏ vào đó.
- App chỉ có prod → dựng mock layer trả fixture §4 (đề xuất tool, KHÔNG tự
  cài dependency). Báo user nếu buộc phải.

## 6. Source pin & re-sync (chống drift)

- Preflight ghi `ios_rev` (git rev/tag) vào manifest. Mọi dòng ledger gắn
  rev này.
- Trước mỗi phiên: `git -C <ios> rev-parse HEAD` so với manifest.
  - Khớp → tiếp tục.
  - Lệch → DỪNG port. Chạy re-sync: diff iOS giữa 2 rev → liệt kê màn/flow
    bị đổi → các dòng ledger liên quan về `FAIL/NOT_STARTED` → cập nhật spec
    → mới port tiếp. Báo user phạm vi ảnh hưởng.
- KHÔNG port mù trên spec đã lệch source.

## 7. Performance parity (đo, không cảm tính)

- Cold start: iOS (Instruments/`os_signpost` hoặc thời điểm first-frame) vs
  Android (`adb shell am start -W` TotalTime). Mục tiêu: Android ≤ iOS + 20%.
- Scroll/animation jank: iOS 60/120fps mượt → Android `dumpsys gfxinfo` /
  Macrobenchmark, jank frame ≤ ngưỡng, cùng fps target màn đó.
- Ghi số vào Detail Diff Table dòng `perf`. Lệch lớn = FAIL (UX không parity).

### 7.1 Profiling toolkit (PERF-OPTIMIZER §8) — số trước→sau
- Cold start: `adb shell am start -W -n <pkg>/<activity>` (TotalTime/WaitTime),
  lặp ≥5 lần lấy trung vị; iOS đo first-frame tương ứng.
- Jank: `adb shell dumpsys gfxinfo <pkg> framestats` hoặc Macrobenchmark
  `FrameTimingMetric`; đếm % frame > 16.6ms (60fps) / 8.3ms (120fps) khớp
  target màn iOS.
- Recomposition (Compose): bật composition tracing / Layout Inspector đếm
  recomposition; storm (1 thay đổi → recompose cả cây) = anti-pattern.
- Main-thread block: StrictMode + Perfetto/systrace; I/O/JSON/network trên
  main = FAIL (quy tắc chống block main thread).
- Memory/leak: Android Studio Memory Profiler / LeakCanary nếu repo có
  (KHÔNG tự cài dep — đề xuất chờ user duyệt).
- **Phân biệt nhiễu**: build chậm/lỗi treo do Gradle Kotlin daemon quá tải
  ≠ lag runtime app — re-verify `--rerun-tasks --no-build-cache
  --no-configuration-cache` trước khi kết luận perf
  (Kotlin/Gradle daemon quá tải sinh lỗi GIẢ kiểu "Unresolved reference"). Không đổ oan code/agent.
- Mỗi dòng `perf:` ledger PHẢI có cặp số **trước→sau** + ngưỡng đạt; QA
  tái kiểm không lệch parity mới đóng (enforcement §18).

## 8. Screenshot regression baseline + REGRESSION SWEEP (giữ parity, chống drift)

Đạt 1000% 1 lần CHƯA đủ — sửa token/shared-component/flow sau đó dễ phá thầm
màn đã VERIFIED. Cơ chế giữ:
- **Baseline ảnh Android**: mỗi state đã VERIFIED → lưu ảnh chuẩn (`baseline/
  <screen>_<state>.png`, dev-tool root local, KHÔNG commit). Đề xuất (không
  tự cài dependency) Roborazzi/Paparazzi để chụp tất định trong test → so byte với
  baseline mỗi lần build. Khác baseline = test đỏ = bắt regression tức thì.
- **REGRESSION SWEEP bắt buộc khi đụng nền dùng chung**: sửa 1 design token,
  1 Shared Component (§3.1), 1 adapter, hoặc 1 string dùng nhiều nơi → **mọi
  màn/flow CONSUMER (theo cột `dep` ledger) bị hạ về `RECHECK`** và phải chạy
  lại parity-diff + onion-skin TRƯỚC khi đóng. KHÔNG sửa nền rồi chỉ verify 1
  màn vừa sửa. `parity-status.sh` coi dòng `RECHECK` như chưa VERIFIED.
- **Re-baseline có chủ đích**: baseline chỉ được cập nhật khi thay đổi là CỐ Ý
  + đã đối chiếu lại iOS (oracle). CẤM "cập nhật baseline cho test xanh" mà
  chưa so iOS — đó là che regression.
- Khi `ios_rev` đổi (§6 re-sync): baseline của màn bị ảnh hưởng hết hiệu lực →
  chụp lại oracle iOS trước, rồi mới re-baseline Android.

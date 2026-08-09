# TELEGRAM-GRADE (port-applied) — UI mượt khi port iOS→Android

> File này CHỈ giữ phần **áp dụng khi PORT để đạt parity**: cổng chống
> over-engineering + playbook animation/effect + hằng số đã rút. Hằng số tái
> dùng: §5 dưới đây (canonical).
> Nguồn tham chiếu: source công khai của Telegram iOS và Telegram Android
> (github.com/TelegramMessenger/Telegram-iOS, github.com/DrKLO/Telegram).
> Mọi hằng số dưới đây chỉ áp khi app iOS gốc THỰC SỰ có effect tương ứng.

## 0. CỔNG CHỐNG OVER-ENGINEERING (đọc trước, bắt buộc)

Kỹ thuật Telegram rất mạnh → dễ cám dỗ xây dựng quá tay. Quy tắc bất biến:
- **Parity-driven, KHÔNG aspirational.** Chỉ áp một kỹ thuật khi app iOS gốc
  THỰC SỰ có effect/độ phức tạp đó. iOS không có confetti → KHÔNG dựng particle
  engine. iOS dùng fade 0.2s đơn giản → KHÔNG thay bằng spring vật lý.
- Khớp với Simplicity First + Surgical Changes (CLAUDE.md) + bất biến #3 skill
  (cấm sáng tạo/thêm so với iOS).
- Bậc thang lựa chọn (chọn bậc THẤP nhất đủ đạt parity):
  1. API Compose chuẩn (`animate*AsState`, `tween`, `AnimatedVisibility`).
  2. `Animatable`/`updateTransition` (khi cần interrupt/đo chính xác).
  3. `Canvas`/`graphicsLayer` custom draw (khi stock không khớp pixel iOS).
  4. Off-main render / RenderEffect / AGSL (khi iOS có blur/gradient nặng).
  5. Particle/physics/GL (CHỈ khi iOS có effect tương ứng thật).
- Mỗi lần lên bậc ≥3 phải ghi lý do parity vào Parity Spec (truy về file iOS).
  Không justify được = over-engineering = hạ bậc.
- Cấm "thêm cho đẹp hơn iOS". Đẹp = GIỐNG iOS, không phải hơn.

## 1. KIẾN TRÚC PARITY (bài học lớn nhất từ Telegram)

1. **Custom-render thứ cần pixel-perfect.** Telegram CỐ TÌNH không dùng stock
   control 2 nền tảng → tự vẽ → pixel khớp nhau. Áp dụng: phần UI quan trọng
   parity → custom Compose/Canvas, KHÔNG để Material default lọt ra (đã là bất
   biến #5 skill). Nhưng theo cổng §0: chỉ custom khi stock lệch iOS thật.
2. **Khoá tầng data/contract trước.** iOS↔Android Telegram parity hành vi nhờ
   chung wire format (MTProto/TL). Áp dụng: chốt Network Contract + fixture
   chung TRƯỚC khi port UI (đã có parity-spec §9 + measurement.md §4).
3. **Design token externalized, 1 nguồn.** Telegram theme = file `.attheme`
   chung 2 nền tảng. Áp dụng: token màu/spacing/timing đọc từ 1 nơi, KHÔNG
   hardcode trong view (đã là Parity Spec §2 + bất biến #15 reuse).
4. **Asset wire-format > raster.** Telegram tải Lottie/`.tgs` JSON render
   on-device, không ảnh raster per-platform. Áp dụng: ưu tiên vector/Lottie
   dùng chung (extract-assets.sh), raster chỉ khi iOS cũng raster.

## 2. PLAYBOOK ANIMATION/EFFECT (đạt mượt như Telegram)

Áp theo cổng §0. Chi tiết hằng số: §5 dưới đây.
1. **Animate từ giá trị đang chạy, không từ target** → interrupt/resume mượt
   (Telegram luôn đọc `presentation()`). Compose: `Animatable`, KHÔNG snap.
2. **1 frame-driver chung, FPS thích ứng** (Telegram SharedDisplayLink: 60
   thường, 120 nội dung high-refresh, 30 idle). Compose: `withFrameNanos`/1
   infinite-transition; KHÔNG mỗi view một vòng lặp.
3. **Frame-locked, on-demand invalidation** (AnimatedFloat đọc clock mỗi frame,
   chỉ invalidate khi đang chạy). Tránh busy-loop; fade-to-0 khi kết thúc
   (quy tắc animation lặp không giật).
4. **Effect nặng off-main + double-buffer.** Blur/gradient/video: render thread
   khác, swap bitmap; blur downscale ~1/15 rồi upscale. CẤM pixel-math main.
5. **Hardware layer có chọn lọc** cho view vẽ nặng + animate nhiều; tắt khi
   nội dung đổi liên tục (tránh phí VRAM).
6. **Cubic-bezier hand-tuned, không preset Material bừa.** Dùng đúng control
   point khớp curve iOS (bảng KB). Đo xác nhận (measurement.md §2).
7. **Particle/physics = delta-time + pool + batch + decelerate fade**, không
   keyframe baked. Chỉ khi iOS có.
8. **Transition propagate xuống cây** (parent truyền context xuống child).
   Compose: `CompositionLocal` cho transition, KHÔNG hardcode timing ở leaf.

## 3. KỶ LUẬT KỸ THUẬT

Telegram (100+ wave refactor) validate các rule SẴN CÓ của skill: discovery-
first = bất biến #15 + enforcement §10; inventory-at-execution = Stage 1.0;
abandonment = enforcement §3–4 WIP-LOCK; atomic-wave+lesson = port 1 module/
commit + Stage 6 HARVEST. → GIỮ NGUYÊN, không nới. Không lặp lại ở đây.

## 4. ÁP DỤNG Ở STAGE NÀO

- Stage 1 (spec): nhận diện effect iOS → phân loại bậc §0; ghi vào Parity Spec
  (animation spec) + Detail Diff Table dùng hằng số §5.
- Stage 3 (map): mỗi effect chọn bậc thấp nhất đủ parity; bậc ≥3 ghi lý do.
- Stage 4 (port): build theo playbook §2, hằng số §5.
- Stage 5 (verify): đo curve/duration (measurement.md §2) + perf parity
  (standards §4.1). Mượt nhưng lệch curve iOS = FAIL.
- Stage 6 (harvest): effect/hằng số mới → ghi vào §5 file này (mapping động
  Swift↔Kotlin thường vẫn về `mapping-kb.md §Motion`).

## 5. HẰNG SỐ & KỸ THUẬT (canonical — gộp từ mapping-kb, rút từ Telegram-iOS/Android)

> Chỉ áp khi iOS gốc THỰC SỰ có effect tương ứng (cổng §0).

**Easing/spring chuẩn (dùng cho Detail Diff khi iOS dùng tương đương):**
| Vai trò | iOS (Telegram) | Compose tương đương |
|---|---|---|
| Spring hệ thống | damping 88, stiffness 750 | `spring(dampingRatio≈.62, stiffness 750f)` |
| Spring theo gesture | damping 124, initialVelocity=v | `spring` + initialVelocity từ drag |
| Slide/dismiss | cubicBezier(.33,.52,.25,.99) | `CubicBezierEasing(.33f,.52f,.25f,.99f)` |
| Quick state | 0.2s | `tween(200)` |
| Standard | 0.3s | `tween(300)` |
| Spring snappy | 0.4–0.45s | spring trên |
| Android emphasis | cubicBezier(.23,1,.32,1) EASE_OUT_QUINT | `CubicBezierEasing(.23f,1f,.32f,1f)` |
| Android easeOutBack | cubicBezier(.34,1.56,.64,1) | overshoot bounce |

**Kỹ thuật → Compose:**
- Animate từ giá trị ĐANG chạy (presentation()), không từ target → interrupt
  được: Compose dùng `Animatable`/`updateTransition`, KHÔNG snap về target.
- 1 frame-driver chung (Telegram SharedDisplayLink): Compose `withFrameNanos`
  / 1 `rememberInfiniteTransition`, KHÔNG mỗi view một loop.
- Effect nặng (blur/gradient/particle) off-main + double-buffer: Android
  `RenderEffect`(API31+)/`AGSL`/`RenderScript`, blur downscale ~1/15 rồi
  upscale; KHÔNG pixel-math trên main thread.
- Invalidate thưa: chỉ recompose/redraw khi đang animate (fade-to-0 khi xong),
  hợp rule quy tắc animation lặp không giật.
- Particle/confetti: delta-time integration + object pool + batch draw +
  decelerate fade — KHÔNG keyframe baked. Damping/frame ~0.93.
- View vẽ nặng + animate nhiều → hardware layer (`graphicsLayer`/rasterize),
  tắt khi nội dung đổi liên tục.

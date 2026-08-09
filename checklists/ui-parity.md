# UI-Parity walkthrough checklist (stage 5 lớp C)

> Chạy cho MỖI page/flow. Mỗi mục: PASS / FAIL / DEVIATION(đã duyệt #id).
> FAIL = quay lại stage 4, KHÔNG ghi VERIFIED. Phải có bằng chứng (ảnh/record).
> Dùng kèm Detail Diff Table (parity-spec §5.x) — bảng = số đo, checklist =
> hành vi.

## A. Trước khi check (điều kiện cần)
- [ ] Đã FULL-SCROLL toàn page iOS, spec liệt kê đủ section (enforcement §5)
- [ ] Có ảnh tham chiếu iOS mọi state (light/dark/empty/loading/error/selected)
- [ ] Cùng device-class/scale khi chụp Android

## A2. SECTION COMPOSITION (GATE — làm TRƯỚC mọi mục dưới, enforcement §11)
- [ ] Screen Composition Manifest (parity-spec §5.x) đã liệt kê đủ khối
- [ ] `count(section iOS) == count(section Android)` (đếm tay 2 bên)
- [ ] Thứ tự khối Android khớp iOS 1:1 (không đảo)
- [ ] Mọi sub-system có mặt (achievements/streak/record/gamification…)
- [ ] Khối ẩn/không-test-được (parity-spec §10) đã port đủ
→ Sai bất kỳ ô nào = FAIL, DỪNG, trả DEV. KHÔNG check tiếp B–G.

## A3. ELEMENT INVENTORY + bằng chứng (GATE, enforcement §12)
- [ ] Element Inventory (parity-spec §5.x) liệt kê đủ TỪNG widget từ ảnh iOS
- [ ] Mỗi widget có ở Android: card-wrapper, hero, icon, helper text, nút
      phụ/hành động, toggle/eye, header đúng kiểu — không thiếu
- [ ] KHÔNG vùng trống lớn bất thường so ảnh iOS (mất card/khung = FAIL)
- [ ] **Cặp thiết bị**: `parity-diff.sh devcheck <WxH pt>` = GREEN (Android dp
      == iOS pt). Lệch → mọi %diff/IoU vô hiệu, DỪNG (measurement §1.2)
- [ ] Ledger màn có chuỗi `parity-diff %=… ≤ tol` cho MỌI state + ảnh diff
      (parity-status.sh chặn cứng dòng VERIFIED thiếu chuỗi này)
- [ ] `texts-diff` giữa tập text iOS và Android = GREEN (không thiếu/thừa chữ)
- [ ] Màu kiểm riêng bằng `parity-diff.sh color` + token source (%diff dùng
      fuzz 2% nên KHÔNG chứng minh được màu — tolerance màu = 0)
- [ ] **Onion-skin** (`parity-diff.sh onion`, measurement §1.1): chồng ảnh
      50% KHÔNG thấy "bóng đôi" ở cạnh card/baseline text/icon (lệch đều mà
      %diff giấu) — có bóng đôi = FAIL dù %diff qua

## A4. LAYOUT / CĂN LỀ / SAFE-AREA (GATE, enforcement §14, measurement §3.1)
- [ ] Safe-area: content KHÔNG chạm status bar/notch/home-indicator nếu iOS
      có spacing (vd hero/icon KHÔNG bị đẩy sát đỉnh)
- [ ] anchor_Y mỗi khối (hero/title/card/button/tab bar) khớp iOS ≤2dp
- [ ] padding/margin/gap/alignment/size lấy từ source iOS (Layout Map đã điền)
- [ ] KHÔNG dùng default spacing Material thay số đo iOS
→ Sai căn lề/anchor/safe-area = FAIL dù đủ element. DỪNG, trả DEV.

## A5. MOTION PER-LAYER (GATE, enforcement §16) — ảnh tĩnh không thấy effect
- [ ] Mỗi element đã đối chiếu SOURCE tìm motion (Motion Inventory đủ;
      element không motion ghi `none` — đã soi, không bỏ sót)
- [ ] Mỗi motion iOS có bản Android tương ứng (trigger/prop/curve/repeat)
- [ ] Đo trên record: Δduration ≤ tolerance §0, curve khớp
- [ ] Hidden/gated/VIP motion (không quan sát được) cũng soi source + spec
→ Thiếu Motion Inventory / bỏ sót effect = FAIL. DỪNG, trả DEV.

## B. Visual (Trụ 1) — từng state
- [ ] Layout: thứ tự/vị trí/size/spacing/align khớp (Δ ≤ 2dp mọi element)
- [ ] Màu: bg/text/border/shadow/gradient/overlay alpha đúng hex (Δ=0)
- [ ] Typography: family/size/weight/tracking/lineHeight/case/truncation/#dòng
- [ ] Icon/asset: đúng asset iOS (export, không vẽ lại), đúng tint/size
- [ ] Light + Dark + High-contrast + Dynamic-type S→XXL không vỡ
- [ ] Mọi state (default/pressed/focus/disabled/loading/empty/error/selected)
- [ ] Visual-diff % ≤ tolerance (loại trừ chrome đã ghi Deviation)

## B2. LIST / COLLECTION parity (LazyColumn/Row vs List/LazyVStack — dễ lệch thầm)
- [ ] Content padding đầu/cuối list (iOS `List` có inset mặc định; Compose
      `LazyColumn` KHÔNG) — set `contentPadding` khớp iOS, KHÔNG để 0 hoặc
      Material default
- [ ] Spacing giữa item = iOS (dùng `Arrangement.spacedBy`/padding theo spec,
      KHÔNG để dính sát hay giãn Material)
- [ ] Divider/separator: có/không, màu, độ dày, inset trái khớp iOS (Compose
      `HorizontalDivider` Material có inset/màu mặc định KHÁC iOS → override)
- [ ] Section header / sticky header: kiểu, nền, sticky behavior khớp iOS
- [ ] Item background/selection/pressed ripple: iOS highlight vs Android ripple
      (Deviation nếu giữ ripple; nếu parity tuyệt đối → custom indication)
- [ ] Swipe-action / pull-to-refresh / reorder (nếu iOS có) port đủ + cùng ngưỡng
- [ ] `key` ổn định cho mỗi item (chống nhảy/giật khi recompose, perf + tránh
      mất state); ảnh trong list có `key`/cache (chống re-fetch)
- [ ] Empty/loading/error state của list khớp iOS (không để list trắng trơn)

## B3. FORM / INPUT / BÀN PHÍM (Compose KHÔNG tự né bàn phím như SwiftUI)
- [ ] Bàn phím hiện KHÔNG che field đang nhập (`imePadding`/`WindowInsets.ime`)
      — cuộn tới field như iOS, không để nội dung bị kẹt dưới bàn phím
- [ ] TextField không dùng Material default nếu iOS trần: padding/indicator/
      label nổi/minHeight 56dp phải đo khớp hoặc dựng `BasicTextField`
- [ ] Placeholder: nội dung + màu + size + vị trí khớp iOS
- [ ] keyboardType từng field khớp (email/number/phone/password)
- [ ] imeAction (next/done) + thứ tự chuyển field khớp iOS
- [ ] SecureField: chấm tròn + nút hiện/ẩn (eye) có mặt & hoạt động
- [ ] Autofill/OTP hint hoạt động (không mất tiện ích so iOS)
- [ ] Validate hiện lỗi ĐÚNG thời điểm iOS (onChange vs onSubmit)
- [ ] Tap ra ngoài đóng bàn phím nếu iOS có; nút back đóng bàn phím trước màn
- [ ] Text dài / dán clipboard / emoji không vỡ layout

## C. Behavior (Trụ 2)
- [ ] Mọi chức năng iOS của page hiện diện, hành vi giống hệt
- [ ] State machine: cùng input → cùng transition → cùng output (theo oracle)
- [ ] Validation: cùng rule, cùng message, cùng thời điểm hiện lỗi
- [ ] Edge: rỗng / offline / lỗi mạng / timeout / token hết hạn / quyền bị
      từ chối / dữ liệu lớn / ký tự đặc biệt — xử lý y iOS
- [ ] Persistence: cold start / kill app / mất mạng → kết quả giống iOS
- [ ] **Config change**: xoay máy / đổi theme / đổi font-scale → state GIỮ
      nguyên như iOS (`rememberSaveable`, không phải `remember`)
- [ ] **Process death**: bật "Don't keep activities" → quay lại app khôi phục
      đúng màn + đúng state (iOS state-restoration tương đương)
- [ ] Multi-window / split-screen không vỡ (nếu app cho phép)
- [ ] Không stub/TODO/mock/màn rỗng (enforcement §6)
- [ ] **LOG (rule #37)**: màn/scroll/nhánh quyết định/lỗi đều có log qua kênh
      chung, gác `BuildConfig.DEBUG`, không PII, không `Log.d` rời rạc
- [ ] **RELEASE**: bản `assembleRelease` cài được, đi hết flow này không crash
      (logcat sạch) — enforcement §20

## D. Perceptual (Trụ 3) — đo trên record, không cảm quan
- [ ] Animation: duration đo được Δ ≤ 16ms; curve/spring params khớp KB
- [ ] Stagger/delay/thứ tự/thuộc-tính-animate khớp; lặp không giật
      (rule no_snap_repeat_animations)
- [ ] Transition màn: kiểu/hướng/thời lượng/interactive-dismiss khớp
- [ ] Gesture: tap/long-press/swipe/drag/pinch/pan — ngưỡng & vùng hit & phản
      hồi khớp
- [ ] Haptic: mỗi rung iOS có rung Android tương ứng (KB §Haptics)
- [ ] Scroll physics & focus order hợp lý so với iOS (over-scroll = Deviation
      nếu khác cảm giác)
- [ ] Âm thanh (nếu có) khớp

## E. Navigation
- [ ] Đến/đi đúng như iOS; back-stack giống; nút back/predictive-back đúng
- [ ] Deep link / universal link → đúng đích
- [ ] Không màn lạc / dead-end không có ở iOS

## F. Standards / a11y / perf (link checklists/standards.md)
- [ ] Mục mandatory Google/Play áp dụng (không phá parity một cách im lặng)
- [ ] Accessibility PARITY: focus order + label/trait khớp VoiceOver iOS
- [ ] Performance: cold start / fps / jank đo & đạt (measurement.md §7)

## F2. i18n & format parity
- [ ] Mọi text qua key (vi default — i18n), nội dung khớp iOS từng ký tự
- [ ] Interpolation đúng thứ tự biến; plural đúng quy tắc (không concat)
- [ ] Format số/ngày/tiền theo locale khớp iOS
- [ ] Đổi ngôn ngữ dài hơn (text-expansion) KHÔNG vỡ layout / cắt chữ

## G. Ký sign-off
- Page/Flow: `__________`  | Agent: `____` | ts: `____`
- Visual-diff bằng chứng: `____` (%, IoU, đường dẫn ảnh)
- Test bằng chứng: `____` (lệnh + kết quả)
- **Adversarial (enforcement §17)**: liệt kê ≥5 khác biệt đã soi + cách xử
  lý: `1)__ 2)__ 3)__ 4)__ 5)__` (CẤM "trông ổn")
- Kết luận: ☐ VERIFIED  ☐ FAIL(lý do)  ☐ blocked(user #)

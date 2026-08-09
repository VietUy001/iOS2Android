# Standards checklist — Apple HIG (đóng băng từ iOS) + Google/Play

> **Thứ tự ưu tiên khi xung đột (canonical — SKILL.md §0 trỏ về đây):**
> 1. **Mandatory kỹ thuật/policy (không thương lượng)** — luôn thắng, kể cả
>    khác iOS (không tuân = Play từ chối hoặc crash). Khác iOS → ghi
>    `DEVIATIONS.md` loại `MANDATORY` (không cần xin phép, nhưng minh bạch).
> 2. **Parity với iOS** — thắng mọi "khuyến nghị thẩm mỹ" Material/Android.
>    App phải nhìn & hành xử như bản iOS, KHÔNG bị Material hoá.
> 3. **Khuyến nghị nền tảng (HIG/Material)** — CHỈ áp khi không phá parity
>    (accessibility tối thiểu, dark theme, RTL, reduce motion — mục 4 dưới).
>
> Chuẩn Apple phía iOS coi là **đã đạt** (app gốc đã trên App Store) → mọi
> hành vi HIG iOS "đóng băng" vào Parity Spec, tái hiện nguyên trạng.

## 1. Apple HIG — đã đạt sẵn, ĐÓNG BĂNG
App iOS đã trên App Store ⇒ hành vi HIG của nó là spec. KHÔNG diễn giải lại.
- [ ] Mọi hành vi HIG iOS được capture vào Parity Spec và tái hiện nguyên trạng
- [ ] KHÔNG "Material hoá" / KHÔNG đổi theo HIG khác bản gốc

## 2. Google Play — MANDATORY (không thương lượng, thắng cả parity)
- [ ] targetSdk đạt mức Play yêu cầu hiện hành; compileSdk tương ứng
- [ ] Runtime permission: chỉ xin quyền thực dùng, có rationale UI, không thừa
- [ ] Photo Picker thay quyền ảnh rộng; scoped storage (không quyền storage cũ)
- [ ] Data Safety form khớp dữ liệu thực thu thập
- [ ] Foreground service khai báo đúng `foregroundServiceType`
- [ ] Billing: dùng Google Play Billing nếu bán digital goods (không cổng
      ngoài nếu vi phạm policy)
- [ ] Account deletion path nếu app có tài khoản (Play yêu cầu)
- [ ] Quảng cáo: tuân Families/UMP consent nếu áp dụng; AdMob ID hợp lệ
- [ ] **AD_ID**: khai `com.google.android.gms.permission.AD_ID` + Data Safety
      khớp nếu dùng quảng cáo (Android không có ATT — rule #27 chỉ áp iOS)
- [ ] **Notification**: có `NotificationChannel` (API 26+) + xin
      `POST_NOTIFICATIONS` runtime (API 33+) — thiếu = thông báo câm
- [ ] **App Links**: `assetlinks.json` đã host trên domain (không có thì link
      mở trình duyệt thay vì app — khác hành vi iOS)
- [ ] **IAP**: dùng Play Billing **và** verify entitlement phía server
      — CẤM mở khoá chỉ bằng flag local
- [ ] **In-App Review** đúng chuẩn (rule #31): tự động ở mốc tích cực + throttle
      1 lần/phiên bản; KHÔNG nút "Đánh giá" gọi thẳng API
- [ ] Version gate backend đã cập nhật cho bản Android (rule #32) nếu backend
      có kiểm version — nếu không, app mới bị chặn 403 toàn bộ
- [ ] Không API ẩn/non-SDK; không quyền nguy hiểm không khai báo

## 3. Kỹ thuật chất lượng — MANDATORY
- [ ] 0 crash / 0 ANR ở mọi flow đã port
- [ ] Xử lý đúng configuration change + process death (state restore)
- [ ] Back & predictive-back hoạt động mọi màn (không kẹt/không thoát app sai)
- [ ] Edge-to-edge + WindowInsets đúng (không bị che bởi system bar)
- [ ] 16 KB page size ready (native libs nếu có)
- [ ] Không block main thread (I/O/network ở coroutine)
- [ ] Không memory leak (Combine→Flow lifecycle-aware, Timer→invalidate,
      animation→dispose) — quy tắc memory-leak CLAUDE.md
- [ ] Secret không hardcode (không commit secrets); TLS; Keystore cho dữ liệu nhạy cảm
- [ ] File > 500 LOC đã đánh giá theo rule #24 (1 nhóm chức năng → giữ + báo
      user; ≥2 nhóm → tách theo nhóm); **0 file > 800 LOC** chưa được duyệt
- [ ] **Bản RELEASE build được + cài + smoke-test hết flow, logcat sạch**
      (R8/minify/keep-rule reflection) — enforcement §20, rule #34
- [ ] **LOG đầy đủ theo rule #37**: kênh chung, gác `BuildConfig.DEBUG`,
      không PII, không `Log.d`/`println` rời rạc

## 4. Accessibility PARITY (không chỉ "tối thiểu" — khớp iOS)
Nếu iOS hỗ trợ VoiceOver thì Android phải parity TalkBack, vì đó là một flow:
- [ ] Thứ tự đọc (focus order) khớp thứ tự VoiceOver iOS
- [ ] Label/value/hint/trait từng phần tử khớp ngữ nghĩa nhãn iOS
- [ ] Hành động accessibility tuỳ biến (custom action) có tương đương
- [ ] Group/heading/landmark khớp cấu trúc iOS
- [ ] Contrast: bằng iOS (iOS thấp hơn → giữ parity + Deviation, KHÔNG tự
      "sửa đẹp")
- [ ] Touch target ≥48dp nếu iOS ≥44pt; iOS nhỏ hơn → parity + Deviation
- [ ] Font scale hệ thống: không vỡ layout (text-expansion test)
- [ ] "Reduce motion" KHỚP cách iOS xử lý (quy tắc animation lifecycle)
- [ ] RTL nếu app có ngôn ngữ RTL

## 4.1 Performance PARITY (đo — measurement.md §7)
- [ ] Cold start Android ≤ iOS + 20% (`am start -W` vs iOS first-frame)
- [ ] Scroll/animation fps khớp target màn (60/120), jank frame ≤ ngưỡng
- [ ] Không tụt frame ở animation đã port (Macrobenchmark/gfxinfo)
- [ ] Bộ nhớ/đỉnh không bất thường so với iOS (không leak)
- [ ] Số liệu ghi Detail Diff Table dòng `perf`; lệch lớn = FAIL (UX≠parity)

## 5. Deviation loại MANDATORY (khác iOS vì bắt buộc nền tảng)
Liệt kê ở `DEVIATIONS.md` loại `MANDATORY` (minh bạch, KHÔNG cần xin phép vì
bắt buộc, nhưng PHẢI ghi): adaptive icon, system back/predictive-back, status
bar, scroll over-scroll, share sheet, permission model, billing flow…

Mỗi mục trên = 1 dòng verify ở stage 5 lớp A/C. Chưa tick hết → không DONE.

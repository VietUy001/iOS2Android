# Capability checklist — API platform-specific iOS → Android

> Mỗi capability iOS app dùng = 1 dòng. KHÔNG "convert" — viết adapter tay,
> ghi mapping vào `../mapping-kb.md` §API. Khác mạnh hành vi → `DEVIATIONS.md`.
> Dòng chưa giải quyết = ledger không thể DONE.

| # | iOS API / framework | dùng ở (file:line) | Android adapter | trạng thái | deviation | parity note |
|---|---|---|---|---|---|---|
| C01 | Keychain | | EncryptedSharedPreferences/Keystore | NOT_STARTED | | giữ key/vòng đời, SiwA local-only (CLAUDE.md) |
| C02 | UserDefaults / @AppStorage | | DataStore Preferences | | | |
| C03 | CoreData / SwiftData | | Room | | | schema+migration tương đương |
| C04 | CoreNFC | | NfcAdapter/Ndef/HCE | | | tech khác nhiều → check Deviation |
| C05 | StoreKit / IAP | | Google Play Billing | | | giá/flow theo Play policy |
| C06 | Sign in with Apple | | Credential Manager + Apple REST / local-only | | | local-only mode bắt buộc |
| C07 | AdMob | | AdMob Android SDK | | | frequency caps khớp chuẩn AdMob (CLAUDE.md) |
| C08 | Push (APNs/PushKit) | | FCM | | | payload mapping |
| C09 | LocalAuthentication (Face/Touch) | | BiometricPrompt | | | |
| C10 | CLLocation | | FusedLocationProvider | | | runtime permission + rationale (Play policy) |
| C11 | AVFoundation (audio/video) | | MediaPlayer/ExoPlayer | | | |
| C12 | Camera / PhotosUI | | CameraX / Photo Picker | | | Photo Picker thay quyền rộng (Play policy) |
| C13 | UIPasteboard | | ClipboardManager | | | |
| C14 | Haptics (UIFeedbackGenerator) | | Vibrator/VibrationEffect | | | mapping ../mapping-kb.md §Haptics |
| C15 | WidgetKit / Live Activity | | Glance / RemoteViews / ongoing notif | | | version sync app+widget |
| C16 | Universal Links / deep link | | App Links + intent-filter | | | giữ đúng route |
| C17 | Background tasks | | WorkManager / foreground service (type khai báo) | | | Play policy |
| C18 | HealthKit/HomeKit/CarPlay… | | Health Connect / tương ứng | | | có thể yêu cầu video demo (store review) |
| C19 | IAP verify (StoreKit + server) | | Play Billing + verify server-side | | | entitlement từ server, KHÔNG flag local |
| C20 | App Attest / DeviceCheck | | Play Integrity (attest→token) | | | rule #30: KHÔNG ký từng request; read công khai không gate |
| C21 | SKStoreReviewController | | Play In-App Review | | | rule #31: tự động ở mốc tích cực, không nút gọi thẳng |
| C22 | Notification hiển thị | | NotificationChannel + POST_NOTIFICATIONS | | | thiếu channel = notif câm; quyền runtime API 33+ |
| C23 | Logging (`os_log`/DLog) | | kênh log chung + BuildConfig.DEBUG | | | rule #37: chưa có log = chưa xong; cấm PII |

Quy tắc:
- Mọi dòng phải kết thúc ở `VERIFIED` (adapter có test parity) hoặc
  `DEVIATION đã user duyệt`.
- Adapter mới → ghi `../mapping-kb.md §API` + `## Adapters đã viết` để app sau
  tái dùng (cơ chế tái sử dụng).
- Permission Android: chỉ xin quyền iOS thực sự dùng, có rationale, không thừa
  (Play policy).

# Mapping Knowledge Base — Swift/SwiftUI → Kotlin/Compose

> Lõi tái sử dụng. Mỗi app port xong → stage 6 ghi mapping/adapter mới vào đây.
> Quy tắc: ví dụ phải có cặp Swift ↔ Kotlin thật. KHÔNG ghi rule mơ hồ.
> Mục tiêu mọi entry: phục vụ PARITY (giống hệt), không phải "tương đương đại khái".

## §Language

| Swift | Kotlin | Ghi chú parity |
|---|---|---|
| `struct` (value) | `data class` | copy-on-write → Kotlin immutable + `copy()` |
| `enum` w/ associated | `sealed class`/`sealed interface` | giữ đúng case + payload |
| `protocol` | `interface` | default impl → interface default method |
| `extension` | extension function/property | giữ cùng scope ngữ nghĩa |
| `guard let` | `?: return`/`requireNotNull` | giữ đúng early-exit |
| `if let`/`if case` | `?.let`/`is`/`when` | |
| `Optional<T>` | `T?` | đừng đổi nil-semantics |
| `lazy var` | `by lazy` | |
| `defer` | `try/finally` | |
| `Result<T,E>` | `Result<T>`/sealed | giữ đúng đường lỗi |
| `Codable` | `kotlinx.serialization @Serializable` | giữ key JSON đúng (`@SerialName`) |
| `Date` | `kotlinx-datetime Instant`/`java.time` | format tách khỏi lang file (i18n) |
| `Decimal`/tiền | `BigDecimal` | KHÔNG dùng Double cho tiền |

## §Motion (quan trọng nhất cho Trụ 3 — phải chính xác, KHÔNG ước lượng)

> Nguồn chuẩn = literal trong source Swift (đọc trước, quy đổi theo công thức
> dưới); record chỉ để XÁC NHẬN (measurement.md §2). KHÔNG đoán bằng mắt.

SwiftUI spring → Compose spring (cùng mô hình bậc 2, quy đổi tham số):

- `withAnimation(.spring(response: R, dampingFraction: D))` (response giây):
  - Compose `spring(dampingRatio = D, stiffness = (2π / R)^2)`
  - vd `response:0.5, dampingFraction:0.8` → `stiffness ≈ 157.9`, `dampingRatio = 0.8`
- `.spring(duration:bounce:)` (iOS 17): bounce→dampingRatio `= 1 - bounce`
  (bounce 0 → critically damped 1.0; bounce 0.3 → 0.7).
- `.interpolatingSpring(stiffness:K, damping:C, mass:M)`:
  `dampingRatio = C / (2·√(K·M))`, `stiffness = K/M` (Compose mặc định mass=1).
- `.easeInOut(duration: t)` → `tween(durationMillis = t*1000, easing = FastOutSlowInEasing)`
  - `.easeIn` → `LinearOutSlowInEasing` đảo? Dùng `CubicBezierEasing(0.42,0,1,1)`
  - `.easeOut` → `CubicBezierEasing(0,0,0.58,1)`
  - `.linear` → `LinearEasing`
  - SwiftUI default `.easeInOut(0.35)` → `tween(350, FastOutSlowInEasing)`
- `.repeatForever(autoreverses:)` → `infiniteRepeatable(animation, repeatMode =
  if autoreverses Reverse else Restart)`. Áp rule `no_snap_repeat_animations`
  CLAUDE.md (TimelineView staggered + fade-to-0, tránh giật).
- `.delay(d)` → `startDelay = d*1000` trong tween/keyframes.
- matchedGeometryEffect → Compose `LookaheadScope` + `Modifier.animateBounds`/
  shared element (navigation animation API).
- `.transition(.move/.opacity/.scale)` → `AnimatedVisibility(enter/exit)` với
  `slideIn/fadeIn/scaleIn` cùng spec.

Đo chéo: luôn đối chiếu duration đo trên record iOS với output Compose,
sai số ≤ 16ms (§0 tolerance).

## §Layout

| SwiftUI | Compose | Parity note |
|---|---|---|
| `VStack(spacing:s)` | `Column(verticalArrangement=Arrangement.spacedBy(s.dp))` | spacing chỉ GIỮA item, giống iOS |
| `HStack` | `Row` | alignment vertical ↔ |
| `ZStack(alignment:)` | `Box(contentAlignment=)` | z-order theo thứ tự khai báo |
| `Spacer()` | `Spacer(Modifier.weight(1f))` | trong scroll cần xử lý khác |
| `.frame(width,height,alignment)` | `Modifier.size().wrapContentX(align)` | |
| `.frame(maxWidth:.infinity)` | `Modifier.fillMaxWidth()` | |
| `.padding(.horizontal, x)` | `Modifier.padding(horizontal=x.dp)` | |
| `GeometryReader` | `BoxWithConstraints`/`onGloballyPositioned` | tránh lạm dụng |
| `.offset/.position` | `Modifier.offset/absoluteOffset` | offset KHÔNG đổi layout, giống iOS |
| `LazyVStack`/`List` | `LazyColumn` | item key giữ ổn định (chống re-fetch ảnh trong list) |
| `.cornerRadius/clipShape` | `Modifier.clip(RoundedCornerShape)` | |
| `.shadow(color,radius,x,y)` | custom `Modifier.shadow` / drawBehind | Material elevation KHÁC iOS shadow → dựng custom để khớp |
| `safeAreaInset`/`view.safeAreaInsets` | `WindowInsets.systemBars`/`Scaffold` innerPadding | PHẢI áp; thiếu = content sát status bar = FAIL (enforcement §14) |
| `.padding/.frame` anchor dọc | đo anchor_Y từ safe-top, khớp ≤2dp | measurement §3.1, KHÔNG dùng default spacing |
| `ScrollView` | `Modifier.verticalScroll(rememberScrollState())` | KHÔNG dùng `LazyColumn` nếu iOS là ScrollView (khác lifecycle item/animation) |
| thứ tự modifier | `padding` TRƯỚC `background` ≠ SAU | Compose modifier có THỨ TỰ: `.background().padding()` = nền tràn ra ngoài padding; SwiftUI `.padding().background()` là mặc định ngược lại → lệch nền/vùng bấm rất dễ lọt |
| vùng bấm | `.clickable` đặt sau `padding` để hit-area khớp iOS | iOS `contentShape` ↔ Compose `Modifier.clickable`+`clip`; hit-area lệch = FAIL Trụ 3 |

## §Forms, TextField & bàn phím (nhóm lỗi bị bỏ sót nhiều nhất khi port)

> SwiftUI tự né bàn phím và `TextField` gần như trần; Compose thì KHÔNG —
> đây là chỗ Material default lọt ra UI nhiều nhất (bất biến #5).

| SwiftUI | Compose | Parity note |
|---|---|---|
| Tự đẩy nội dung khi bàn phím hiện | `Modifier.imePadding()` + `WindowInsets.ime` + `adjustResize` | KHÔNG có = bàn phím CHE input (iOS không bao giờ bị) = FAIL |
| `TextField` (không viền, không label nổi) | `BasicTextField` + `decorationBox` | `OutlinedTextField`/`TextField` Material có padding 16dp + indicator + label nổi + minHeight 56dp → KHÁC iOS. Dùng Material chỉ khi đo khớp |
| `.textFieldStyle(.plain)` + placeholder | `decorationBox` tự vẽ placeholder | màu/size placeholder lấy từ token iOS |
| `.keyboardType(.emailAddress/.numberPad)` | `KeyboardOptions(keyboardType=…)` | giữ đúng loại bàn phím từng field |
| `.submitLabel(.next/.done)` | `KeyboardOptions(imeAction=…)` + `KeyboardActions` | thứ tự next/done khớp iOS |
| `.focused($f)` chuyển field | `FocusRequester` + `focusManager.moveFocus` | focus order khớp (cũng là a11y parity) |
| `SecureField` | `visualTransformation = PasswordVisualTransformation()` | nút hiện/ẩn mật khẩu (eye) là 1 element trong Element Inventory |
| `.textContentType(.oneTimeCode/.password)` | autofill hints (`Modifier.semantics { contentType = … }`) | mất autofill = lệch flow đăng nhập |
| `.onChange` validate realtime | `snapshotFlow`/`derivedStateOf` | cùng thời điểm hiện lỗi như iOS (Trụ 2) |
| `.disabled` / readOnly | `enabled=false` / `readOnly=true` | 2 cái KHÁC nhau: readOnly vẫn focus/copy được |
| dismiss bàn phím khi tap nền | `focusManager.clearFocus()` trong `pointerInput` | iOS thường có → port đủ, đừng bỏ |

## §i18n — bẫy khi chuyển `Localizable.strings` → `strings.xml`

| Bẫy | Hậu quả | Xử lý |
|---|---|---|
| Dấu `'` chưa escape (`Don't`, `Hôm nay's`) | build đỏ hoặc **mất phần chuỗi im lặng** | `\'` hoặc bọc `"…"`; `verify.sh` §3b cảnh báo |
| `%@`, `%d` của iOS | Android không hiểu `%@`; nhiều tham số bị đảo | `%1$s`, `%2$d` — LUÔN đánh số thứ tự (đổi ngôn ngữ hay đảo thứ tự) |
| `&`, `<` trong chuỗi | XML parse lỗi | `&amp;`, `&lt;` |
| `.stringsdict` (plural) | mất quy tắc số nhiều | `<plurals>` + `quantityString`; **tiếng Việt chỉ có `other`**, đừng bịa `one` |
| Xuống dòng `\n` | Android XML nuốt newline thật | dùng `\n` escape, không xuống dòng thật |
| Chuỗi không dịch (key kỹ thuật) | dịch nhầm | `translatable="false"` |
| Format số/ngày/tiền | lệch locale so iOS | `NumberFormat`/`DateTimeFormatter` theo locale, tách khỏi lang file |
| vi là default (rule #16) | thiếu fallback | `values/strings.xml` = vi; `values-en/` cho en |

## §Log & observability (rule #37 — bắt buộc)

| iOS | Android | Parity note |
|---|---|---|
| `os_log`/`Logger`/`DLog.<module>` | `AppLog.<module>` (object bọc `Log`) | 1 kênh chung cho cả app; CẤM `Log.d`/`println` rời rạc (verify.sh §3a) |
| `#if DEBUG` bọc log | `if (BuildConfig.DEBUG)` + message lambda | release không dựng chuỗi (`msg: () -> String`) |
| log vòng đời màn | `LaunchedEffect(Unit){ log("enter") }` + `DisposableEffect` onDispose | mọi màn có enter/exit; scroll/section có log riêng |
| log lỗi nuốt (`try?`) | `runCatching{}.onFailure{ log }` | CẤM `catch {}` rỗng (enforcement §6) |
| — | CẤM log PII | chỉ id 6 ký tự, mã trạng thái, số lượng, nhánh, thời gian |

## §State & Lifecycle

| SwiftUI | Compose | Parity note |
|---|---|---|
| `@State` | `remember { mutableStateOf() }` | scope = composable |
| `@StateObject` | `viewModel()` (owned) | tạo 1 lần |
| `@ObservedObject` | hoisted `StateFlow` collect | |
| `@EnvironmentObject` | `CompositionLocal`/Hilt scoped | |
| `@Published` | `MutableStateFlow` + `asStateFlow()` | update từ bg → đúng dispatcher |
| `objectWillChange` | `StateFlow` emission | giữ đúng thời điểm recompose |
| `onAppear/onDisappear` | `LaunchedEffect`/`DisposableEffect` | khớp side-effect timing |
| `@AppStorage` | DataStore + Flow | key giữ nguyên |
| `@FocusState` | `FocusRequester`/`focusable` | giữ focus order |
| `@State` sống qua xoay máy | **`rememberSaveable`** (không phải `remember`) | Android **tạo lại Activity** khi xoay/đổi theme/đổi font-scale → `remember` MẤT state. iOS không có bệnh này ⇒ dùng `remember` = lệch hành vi |
| `@StateObject` sống qua xoay | `viewModel()` (giữ qua config change) | ViewModel sống, nhưng state trong `remember` của composable thì không |
| state-restoration iOS | `SavedStateHandle` + `rememberSaveable` | **process death** (OS kill nền) phải khôi phục y iOS; test: Developer options → "Don't keep activities" |
| kiểu phức tạp cần lưu | `rememberSaveable(stateSaver = …)`/`@Parcelize` | tránh lưu object lớn (TransactionTooLarge) |

## §Concurrency

| Swift | Kotlin | Parity note |
|---|---|---|
| `async/await` | `suspend` | |
| `Task {}` | `viewModelScope.launch` | scope đúng vòng đời |
| `Task.detached` | `CoroutineScope(Dispatchers...)` | cẩn thận leak (quy tắc memory-leak) |
| `actor` | class + `Mutex`/single dispatcher | giữ serialization |
| `@MainActor` | `Dispatchers.Main`/`withContext(Main)` | UI update đúng thread |
| Combine `Publisher` | `Flow` | operator map sát: `map/filter/combineLatest/debounce` |
| `@Published` sink | `flow.collect` | hủy đúng (lifecycle-aware) |
| `URLSession` | `OkHttp`/`Ktor` (dùng dep đã có repo) | KHÔNG tự cài dep mới |

## §Navigation

| SwiftUI | Compose | Parity note |
|---|---|---|
| `NavigationStack`/`path` | Navigation-Compose `NavController` | back-stack KHỚP iOS |
| `.navigationDestination` | `composable(route)` | |
| `.sheet` | `ModalBottomSheet`/custom | KHỚP kiểu present iOS (height, drag, dim) |
| `.fullScreenCover` | full-screen `Dialog`/destination | transition khớp |
| `.popover` | custom popup | iOS popover ≠ Android default → dựng custom |
| `NavigationLink` | `navController.navigate` | |
| toolbar/nav bar | `TopAppBar` override token | KHÔNG để Material bar lệch iOS |
| swipe-back | predictive back / custom edge | Deviation nếu khác cảm giác iOS |

## §API platform-specific (KHÔNG convert — viết adapter, ghi vào đây)

| iOS | Android adapter | Parity risk |
|---|---|---|
| Keychain | EncryptedSharedPreferences / Keystore | giữ đúng key, vòng đời (rule SiwA CLAUDE.md) |
| `UserDefaults` | DataStore Preferences | didSet batch ↔ Flow |
| CoreData | Room | schema + migration tương đương |
| CoreNFC `NFCNDEFReaderSession` | `android.nfc` NfcAdapter/Ndef | capability checklist; khác mạnh → Deviation |
| StoreKit | Google Play Billing | Play policy (checklists/standards.md); giá/flow theo Play |
| Sign in with Apple `ASAuthorization` | Credential Manager + Apple JS/REST hoặc local-only (quy tắc SiwA local-only) | local-only mode bắt buộc |
| AdMob iOS SDK | AdMob Android SDK | frequency caps khớp chuẩn AdMob (CLAUDE.md) |
| `AVAudioPlayer`/`AVPlayer` | `MediaPlayer`/`ExoPlayer` | |
| `CLLocationManager` | `FusedLocationProvider` | permission rationale (Play policy) |
| `UIPasteboard` | `ClipboardManager` | |
| `UIImpactFeedbackGenerator` | xem §Haptics | |
| `LocalAuthentication` (FaceID) | `BiometricPrompt` | |
| `WidgetKit` | Glance / RemoteViews | version sync app+widget |
| `PushKit`/APNs | FCM | payload mapping |
| Local/remote notification hiển thị | `NotificationChannel` (bắt buộc API 26+) + `POST_NOTIFICATIONS` (API 33+, runtime) | iOS xin quyền 1 lần; Android cần **channel** (thiếu = notif câm) + **xin quyền runtime**. Tên/độ ưu tiên channel = 1 dòng Deviation `MANDATORY` |
| `SKStoreReviewController` / `requestReview` | **Play In-App Review** (`ReviewManager.requestReviewFlow`) | rule #31: CẤM nút "Đánh giá" gọi thẳng; chỉ bắn tự động ở mốc tích cực, throttle 1 lần/phiên bản. Nút chủ động → `market://details?id=` |
| StoreKit IAP | Play Billing + **verify receipt phía server** (SDK verify của bạn) | CẤM mở khoá chỉ bằng flag local/SharedPreferences; nguồn sự thật entitlement = server + Play Billing; acknowledge purchase SAU khi server xác nhận |
| App Attest / DeviceCheck | **Play Integrity** (`integrityTokenProvider`) | rule #30: attest 1 lần → device-token, KHÔNG ký từng request; read công khai KHÔNG gate; client fail-open-send |
| Universal Links | App Links + `intent-filter` + **`assetlinks.json`** hosted | thiếu file trên domain = link mở trình duyệt thay vì app (khác iOS) |
| IDFA / ATT prompt | KHÔNG có ATT trên Android — dùng **UMP consent** + khai `com.google.android.gms.permission.AD_ID` | rule #27 chỉ áp iOS; Android khai sai AD_ID/Data Safety = Play từ chối |
| version gate backend | header `x-app-version/x-app-build` + `ANDROID_LATEST_*` ở backend | rule #32: bump app PHẢI cập nhật cấu hình gate backend, nếu không 403 toàn bộ |

## §Platform-Equivalent — service Apple-ecosystem → Android-ecosystem

> Nguyên tắc: một số chức năng iOS dựa vào **dịch vụ độc quyền Apple** KHÔNG tồn
> tại trên Android (đăng nhập iCloud, đồng bộ CloudKit, APNs, Apple Pay…). Với
> các chức năng này, parity KHÔNG phải "tái hiện đúng provider Apple" (bất khả
> thi + vi phạm Play) mà là **giữ NGUYÊN VAI TRÒ/HÀNH VI, đổi sang dịch vụ
> Android-native tương đương gần nhất**. Ví dụ user yêu cầu: iOS login iCloud →
> Android login Google/Gmail.
>
> Mỗi swap kiểu này là **DEVIATION loại `MANDATORY`** (ghi `DEVIATIONS.md`): bắt
> buộc về kỹ thuật/chính sách nên KHÔNG cần xin phép từng cái, NHƯNG phải minh
> bạch (liệt kê đủ) + giữ behavioral parity (cùng input người dùng → cùng kết
> quả: đăng nhập được, đồng bộ được, thanh toán được). UI nút/branding theo
> guideline provider Android (Google brand) — đây cũng là yêu cầu Play.

| Vai trò / chức năng iOS | Dịch vụ Apple | → Android-equivalent | Parity giữ gì | Ghi chú |
|---|---|---|---|---|
| **Đăng nhập tài khoản** | Sign in with Apple / iCloud account | **Google Sign-In** (Credential Manager + GoogleIdTokenCredential) | cùng flow: tap → chọn account → đăng nhập 1 chạm, lưu session, cold-start auto-login | nút theo Google brand guideline (bắt buộc); quy tắc SiwA local-only vẫn áp |
| **Đồng bộ dữ liệu user (key-value)** | `NSUbiquitousKeyValueStore` (iCloud KVS) | Firebase / DataStore + backend, hoặc Drive AppData | cùng key, cùng dữ liệu đồng bộ qua thiết bị, cùng vòng đời | nếu app iOS chỉ KVS nhỏ → cân nhắc backend đang có |
| **Đồng bộ tài liệu/CloudKit** | CloudKit / iCloud Drive | **Google Drive API** (Drive AppData folder) hoặc Firebase Firestore/Storage | cùng nội dung sync, cùng resolve conflict semantics | chọn theo loại dữ liệu (doc → Drive, structured → Firestore) |
| **Push notification** | APNs / `PushKit` | **FCM** | cùng payload → cùng UI thông báo + cùng side-effect | mapping payload, §API |
| **Thanh toán trong app** | StoreKit IAP / App Store | **Google Play Billing** | cùng sản phẩm, cùng giá-theo-store, cùng entitlement sau mua | Play policy — bắt buộc Play Billing |
| **Thanh toán contactless** | Apple Pay (`PKPaymentRequest`) | **Google Pay** (Wallet API) | cùng flow checkout, cùng token hoá | nút theo Google Pay brand |
| **Bản đồ** | MapKit / Apple Maps | **Google Maps SDK** (hoặc Mapbox nếu app cần) | cùng marker/overlay/camera behavior | API key Maps; đề xuất dep chờ user duyệt |
| **Trợ lý / shortcut** | SiriKit / App Intents / Shortcuts | **App Actions / Assistant** (hoặc App Shortcuts widget) | cùng intent người dùng kích hoạt được | khác mạnh → Deviation chi tiết |
| **Sức khoẻ** | HealthKit | **Health Connect** | cùng loại dữ liệu đọc/ghi, cùng permission scope | runtime permission rationale (Play policy) |
| **Mật khẩu/credential đồng bộ** | iCloud Keychain | **Credential Manager + Block Store** | cùng credential khôi phục được sau cài lại | §API Keychain cho phần local |
| **Continuity / Handoff** | Handoff, Universal Clipboard | (không có tương đương trực tiếp) Nearby / clipboard cục bộ | ghi rõ giới hạn | Deviation `MANDATORY`, user duyệt nếu là tính năng cốt lõi |

Quy trình áp dụng (SOURCE-ANALYST + DEV-FUNC):
1. SOURCE-ANALYST phát hiện chức năng dùng dịch vụ Apple-độc-quyền → ghi 1 dòng
   ledger + 1 dòng `DEVIATIONS.md` loại `MANDATORY` nêu rõ Apple service →
   Android-equivalent đã chọn (theo bảng trên; ngoài bảng → đề xuất + ghi KB).
2. Behavioral oracle (FLOW-CHECKER) đo trên iOS = "đăng nhập thành công / đồng
   bộ xong / mua xong"; Android phải tái hiện **cùng kết quả** qua provider mới,
   KHÔNG cần giống pixel provider.
3. Mọi swap mới phát sinh → stage 6 ghi vào bảng này (tái dùng cho app sau).

## §Haptics (iOS → Android)

| iOS | Android |
|---|---|
| `UIImpactFeedbackGenerator(.light)` | `HapticFeedbackConstants.KEYBOARD_TAP` / VibrationEffect amplitude ~40 |
| `.medium` | `VibrationEffect.createOneShot(20, ~80)` |
| `.heavy`/`.rigid` | `createOneShot(30, 255)` |
| `.soft` | low amplitude ~30 |
| `UISelectionFeedbackGenerator` | `HapticFeedbackConstants.CLOCK_TICK` |
| `UINotificationFeedbackGenerator(.success)` | waveform [0,30,60,30] |
| `.error` | waveform [0,50,40,50,40,50] |
> Android API 30+ ưu tiên `VibrationEffect.Composition` (PRIMITIVE_TICK/CLICK)
> để gần cảm giác Taptic. Ghi mapping thực tế từng app vào đây.

## §Typography / Font (lỗ hổng parity số 1 — Stage 2.2)

> Sai font/metric = mọi text-box lệch cao-thấp-rộng → kéo lệch spacing &
> anchor TOÀN MÀN dù màu/đo đúng. Bắt buộc xử lý ở Stage 2 TRƯỚC khi port UI.

- **SF Pro KHÔNG được bundle vào app Android** (license Apple cấm — KHÔNG copy
  `.otf` SF Pro vào `res/font`). Chọn font thay thế **metric-tương-đương**
  (vd Inter / Roboto Flex) rồi **tinh chỉnh metric cho khớp**; ghi Deviation
  `MANDATORY` (font hệ thống khác là bất khả kháng) + nêu font đã chọn.
- **Tắt padding font mặc định Android** (thủ phạm lệch chiều cao text âm
  thầm) — đặt ở Theme typography cho MỌI text, không sót:
  ```kotlin
  Text(text, style = style.copy(
      platformStyle = PlatformTextStyle(includeFontPadding = false),
      lineHeightStyle = LineHeightStyle(
          alignment = LineHeightStyle.Alignment.Center,
          trim = LineHeightStyle.Trim.None)))
  ```
- **Khớp từng metric với iOS** (đọc từ source: `.font(.system(size:weight:))`,
  custom `UIFont`, `kerning`, `lineSpacing`): `fontSize` (pt→sp 1:1 giữ kích
  thước thị giác), `fontWeight`, `letterSpacing` (iOS `kern`/tracking →
  Compose `letterSpacing` theo `.sp`/`.em` đúng), `lineHeight` (iOS
  lineSpacing → Compose `lineHeight` + lineHeightStyle, cộng đúng base size).
- iOS dùng **tracking động theo size** (SF Pro optical) → tra bảng tracking
  Apple cho từng size, KHÔNG để letterSpacing=0.
- **Dynamic Type ↔ fontScale**: map bậc Dynamic Type iOS sang `fontScale`
  Android; verify layout ở bậc lớn nhất (text không tràn/cắt) như iOS.
- Verify: render cùng chuỗi text ở cả 2 nền → đo bề rộng & baseline
  (onion-skin, measurement §1.1). Lệch > tolerance = chỉnh metric tiếp,
  KHÔNG "nhìn na ná". Residual do glyph shape → ghi Deviation.

## §Asset — dùng chung asset iOS (single source of truth = Assets.xcassets)

> User cho phép dùng chung asset iOS. Asset catalog iOS là nguồn gốc duy
> nhất, KHÔNG vẽ lại/tái tạo. Pipeline: `scripts/extract-assets.sh` (Stage 2.1).

- **Bitmap imageset** (`@1x/@2x/@3x`) → density buckets theo bảng dưới; nội
  suy `hdpi(1.5x)`/`xxhdpi(3x)` từ ảnh @3x bằng downscale chất lượng cao.
  Giữ nguyên tên (snake_case theo ràng buộc resource Android), map tên ↔ tên
  trong KB.
- **Vector** (PDF/SVG single-scale) → Android Vector Drawable (giữ vector,
  KHÔNG rasterize) — sắc nét mọi mật độ.
- **App icon set** → `mipmap` + adaptive icon (foreground/background tách
  đúng layout iOS icon; không tách lớp được → Deviation `MANDATORY`, vì
  Android bắt buộc adaptive icon).
- **Color set** trong catalog → token `Color.kt` (light/dark/contrast variant
  khớp từng appearance trong catalog).
- **Asset có `template-rendering-intent`** (tint được) → giữ vector
  monochrome + tint runtime, KHÔNG bake màu.
- **Traceable**: mỗi resource Android ghi nguồn `from: Assets.xcassets/<name>`
  trong manifest (app sau tái dùng).
- KHÔNG đổi pixel, KHÔNG nén mất chất, KHÔNG đổi tỉ lệ/màu. Asset là dữ liệu
  parity — sai asset = fail Trụ 1.

| iOS scale | Android bucket | factor |
|---|---|---|
| @1x | mdpi | 1.0 |
| — | hdpi | 1.5 (downscale từ @3x) |
| @2x | xhdpi | 2.0 |
| — | xxhdpi | 3.0 (= @3x) |
| @3x | xxxhdpi | 4.0? thực tế @3x→xxxhdpi giữ pixel, hoặc upscale tránh — ưu tiên vector |
> Vector (PDF/SVG) → VectorDrawable: KHÔNG rasterize, sắc nét mọi dpi.
> App icon → adaptive (foreground/background). Color set → token Color.kt.

## §Telegram-grade reference → đã gộp về `telegram-grade.md §5`

Hằng số easing/spring chuẩn Telegram + kỹ thuật render (frame-driver chung,
off-main blur, particle pool, hardware layer…): đọc `telegram-grade.md §5`
(nguồn canonical duy nhất). Chỉ áp khi iOS gốc THỰC SỰ có effect tương ứng.

---
## Adapters đã viết (điền dần qua từng app)
<!-- [app] | iOS API | Android adapter file | note parity -->

| app | iOS API | Android adapter file | note parity |
|---|---|---|---|
| `<example>` QR tool | `AVCaptureSession` + `AVCaptureVideoPreviewLayer(.resizeAspectFill)` + `AVCaptureMetadataOutput(metadataObjectTypes=[.qr])`; QR-gen `CIFilter.qrCodeGenerator` correctionLevel "H" | CameraX `PreviewView` FILL_CENTER + `ImageAnalysis` → ML Kit `BarcodeScanning` FORMAT_QR_CODE; dừng ngay lần decode đầu (`provider.unbindAll()` rồi callback 1 lần); `DisposableEffect` onDispose unbind + shutdown executor | FILL_CENTER ≡ resizeAspectFill; lọc QR-only ≡ metadataObjectTypes[.qr]; stop-first-hit ≡ session.stopRunning. Camera live-scan KHÔNG chạy được trên emulator lẫn iOS simulator → parity hành vi verify qua source + oracle, pixel-diff phải để lại cho thiết bị thật |

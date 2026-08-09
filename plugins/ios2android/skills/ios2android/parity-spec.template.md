# Parity Spec — <APP NAME> iOS → Android

> Tài liệu VÀNG, language-neutral. Nguồn sự thật duy nhất cho port + verify.
> Copy file này thành `parity-spec.md` trong folder dự án Android (sau khi
> user duyệt vị trí — không tự tạo folder). Điền đủ, KHÔNG để "TBD" ở mục
> bắt buộc. Mọi giá trị phải lấy TỪ source/quan sát iOS, KHÔNG tự đặt.

## Cách khai thác spec (Stage 1 — trái tim của parity)

**FULL SOURCE TRAVERSAL (bắt buộc, không sampling)** — đọc TOÀN BỘ source iOS,
TỪNG file, TỪNG folder, không đoán nội dung file chưa mở:
- Liệt kê 100% file (`scripts/inventory.sh`) → mỗi file 1 dòng disposition ở
  §1 Structure Map. KHÔNG file nào ở trạng thái "chưa rõ".
- Đọc thực sự nội dung mọi `.swift`, `.strings`, `.plist`, `.entitlements`,
  `project.yml`/`.pbxproj`, asset catalog `Contents.json`, `.storyboard`/
  `.xib` (nếu có), script build, `Package.swift`/Podfile.
- "Xây chuẩn từng chi tiết": mọi chi tiết Android phải truy ngược được về
  dòng/file iOS cụ thể (ghi `Files: path:line` trong spec).

**Khai thác từ 3 nguồn, không thiếu nguồn nào:**
1. **Source iOS**: từng `.swift` (View, ViewModel, Service, Model, Modifier,
   animation, navigation), Localizable.strings, asset catalog, Info.plist
   (capability, entitlement), project.yml.
2. **Quan sát runtime nếu chạy được**: screenshot mọi màn × mọi state (light/
   dark/dynamic-type), quay video animation/transition để đo duration & curve.
   DETERMINIZE trước khi chụp (measurement §1.0).
3. **Tri thức tích lũy**: `mapping-kb.md` (đọc trước, áp rule đã biết).

**Mỗi màn hình phải đủ 10 mục** (điền vào các section §5.x bên dưới):
component tree · measurement table · design tokens (§2, rút TRỰC TIẾP từ iOS,
không tự đặt) · state inventory · animation/transition spec · interaction
spec (gesture + ngưỡng + haptic + sound) · behavior/flow spec (state machine,
validation, edge case, persistence) · navigation graph · capability map (§6) ·
i18n inventory (§8, mọi text user-visible → key, vi default).

**Tính năng ẩn / VIP / không test được trên simulator** → §10/§10.1 (vai
SOURCE-ANALYST, roles.md §7): truy TỪ code+plist+entitlements, không quan sát.
Thiếu = SPEC FAIL, KHÔNG port tiếp.

**Copy checklists**: cùng lúc tạo spec, copy folder `checklists/` của skill
vào cạnh file spec này — gate DONE grep bản copy đó (enforcement §2).

## 0. Meta
- iOS source path: `<abs>`
- Android target path: `<abs>`
- iOS version/build tham chiếu: `<x.y.z (n)>`
- Thiết bị tham chiếu chụp ảnh: `<vd iPhone 15, @3x, iOS 17>`
- Appearance phải bao phủ: light / dark / high-contrast / dynamic-type S–XXL
- Deviation register: `./DEVIATIONS.md`

## 1. STRUCTURE MAP (iOS → Android) — bắt buộc, từ FULL traversal

Bảng ánh xạ TỪNG folder & file iOS sang Android. Sinh khung bằng
`scripts/inventory.sh`. KHÔNG dòng nào "chưa rõ".

| iOS path | loại | disposition | Android path/package | note |
|---|---|---|---|---|
| `App/…` | app/scene | port | `app/…/MainActivity.kt` | |
| `Models/User.swift` | model | port | `…/data/model/User.kt` | |
| `Services/APIClient.swift` | service | port | `…/data/remote/ApiClient.kt` | |
| `Services/Keychain.swift` | platform | adapter | `…/data/secure/SecureStore.kt` | KB §API |
| `Resources/Assets.xcassets` | asset | asset | `res/drawable*,mipmap*` | extract-assets.sh |
| `Resources/*.strings` | i18n | port | `res/values*/strings.xml` | vi default (i18n) |
| `…/*.generated.swift` | generated | bỏ/regen | — | miễn trừ generated (không tính ngưỡng LOC), ghi lý do |

disposition ∈ {port, adapter, asset, config, i18n, generated, bỏ(lý do)}.
Cấu trúc Android **phản chiếu** phân tầng feature iOS (co-locate theo feature), KHÔNG tự nghĩ.

## 2. DESIGN TOKENS (rút trực tiếp từ iOS Theme/AppColor/Font…)

### 2.1 Color (mọi token, mọi appearance)
| token | light | dark | high-contrast | dùng ở |
|---|---|---|---|---|
| `primary` | `#RRGGBBAA` | … | … | nút chính… |

### 2.2 Typography scale
| token | font | size(pt→sp) | weight | tracking | lineHeight |
|---|---|---|---|---|---|

### 2.3 Spacing / radius / shadow / motion token
| token | giá trị iOS | ghi chú |
|---|---|---|
| `spacing.md` | `12pt` | |
| `radius.card` | `16pt` | |
| `shadow.card` | `x0 y4 blur12 #000 22%` | dựng custom, KHÔNG Material elevation |
| `motion.standard` | `spring(response0.4,damp0.85)` | → KB §Motion quy đổi |

## 3. FLOW INVENTORY — liệt kê 100% flow TRƯỚC khi port

Mọi luồng người dùng từ source iOS (entry point → mọi nhánh điều hướng → kết
thúc). Đây là master checklist; thiếu flow = inventory FAIL.

| Flow ID | tên | entry | page tham gia | phụ thuộc | iOS source | trạng thái |
|---|---|---|---|---|---|---|
| F01 | Đăng nhập Apple | Splash→Login | Login,Consent,Home | — | `Account/Login*.swift` | |
| F02 | … | | | F01 | | |

- **Thứ tự port theo phụ thuộc**: flow nền (auth/khởi tạo/networking) trước
  flow phụ thuộc. Manager xếp pipeline theo cột "phụ thuộc", KHÔNG port flow
  con khi flow cha chưa VERIFIED.
- Mỗi flow: state machine (input→state→output), mọi edge case (rỗng/offline/
  lỗi/timeout/deny quyền/dữ liệu lớn/ký tự đặc biệt), side effect,
  persistence — là **test oracle** (test iOS trước, Android tái hiện).

### 3.1 Shared Components (chống làm trùng)
Component dùng ở ≥2 flow → 1 dòng ledger RIÊNG, port 1 lần, các flow tái dùng.
| SC ID | tên | dùng ở flow | iOS source | ledger dòng |
|---|---|---|---|---|
| SC01 | PrimaryButton | F01,F03,F07 | `Components/PrimaryButton.swift` | L0xx |

## 4. COMPLETENESS LEDGER — DoD nhị phân (xem enforcement.md)

Mỗi đơn vị việc nhỏ độc lập (screen/component/function/flow/animation/adapter/
model/viewmodel/test/string-group) = 1 dòng.

| ID | loại | tên | iOS src (file:line) | dep | trạng thái | bằng chứng | agent | ts |
|---|---|---|---|---|---|---|---|---|
| L001 | token | Color/Type/Spacing | `Theme.swift:1` | | NOT_STARTED | | | |
| L002 | shared | PrimaryButton | `Components/Btn.swift:1` | L001 | NOT_STARTED | | | |
| L003 | adapter | login Google (≡ iCloud) | `Auth.swift:1` | | NOT_STARTED | | | |
| L004 | screen | LoginView | `Login.swift:40` | L001,L002,L003 | NOT_STARTED | | | |
| L005 | anim | logo pulse | `Splash.swift:88` | L001 | NOT_STARTED | | | |

**ĐỊNH DẠNG CỘT BẰNG CHỨNG (parity-status.sh gate cứng — enforcement §12):**
- Mọi dòng `VERIFIED` phải có bằng chứng, KHÔNG được rỗng.
- Dòng loại `screen`/`section`/`element` phải chứa chuỗi đo:
  `parity-diff %=0.42 ≤ tol | IoU=0.97 | diff: <path>` — thiếu `%=`/`IoU=` là
  `NOT DONE` dù trạng thái đã ghi VERIFIED ("trông ổn" không phải bằng chứng).
- ORACLE-LIMITED (SKILL.md): dòng không đo được ảnh ghi
  `source-derived: <file:line>` + ID deviation, và cần user ký.

- `dep` = ID việc phải VERIFIED trước (dep gate). Rỗng = việc nền
  (token/adapter/platform-equivalent) → làm trước. Việc UI phụ thuộc nền.
- Mỗi việc chạm 1 file ghi riêng (1-owner-1-file); việc độc lập có thể giao
  vài subagent song song (orchestration §B, KHÔNG swarm).
Trạng thái: NOT_STARTED→SPECD→IN_PROGRESS→PORTED→VERIFIED|FAIL.
Quy tắc trạng thái + bằng chứng + DONE + dep + WIP-LOCK per-worker:
`enforcement.md`.

## 5. PER-SCREEN SPEC (lặp khối này cho MỖI page)

### Screen: `<Tên>` — iOS `<file.swift>`
- [ ] **FULL-SCROLL DONE** — đã cuộn hết toàn page iOS, thấy mọi section dưới
  fold (enforcement §5). Số section đếm tay: `<n>`.
- Ảnh tham chiếu (mỗi state): `<paths>` (light/dark/empty/loading/error/…)

**5.x SCREEN COMPOSITION MANIFEST** (BẮT BUỘC — chống mất/đảo section)
Liệt kê 100% khối top→bottom; mỗi khối 1 dòng ledger; Android phải có ĐÚNG
bộ + ĐÚNG thứ tự. `iOS_count == Android_count` & thứ tự khớp mới qua
attribute-diff (enforcement §11).
| # | section | loại | sub-system? | iOS src | ledger | có ở Android? |
|---|---|---|---|---|---|---|
| 1 | `<header/nav>` | bar | — | `<file:line>` | L0.. | |
| 2 | `<section A>` | section | — | | | |
| 3 | `<section B — stat/summary…>` | section | — | | | |
| 4 | `<sub-system block, vd thành tựu/streak>` | section | `<tên>` | | | |
| n | `<tab/footer bar>` | bar | — | | | |
> Điền theo ảnh iOS THỰC TẾ của dự án (placeholder chỉ là ví dụ format).
> Sub-system (achievements/streak/record/gamification/…) = feature riêng,
> PHẢI có dòng ledger + port đủ. Bỏ 1 khối = SECTION FAIL, cấm VERIFIED.

**5.x ELEMENT INVENTORY** (BẮT BUỘC — liệt kê TỪNG widget từ ảnh iOS)
Sau Composition Manifest, đi vào TỪNG section: liệt kê 100% widget nhìn thấy
trên ảnh iOS — card wrapper, icon, label, helper text, input + placeholder,
nút phụ, toggle, eye-icon… Mỗi widget 1 dòng. DEV BỊ CẤM viết code màn khi
inventory chưa đủ (enforcement §12).
| El# | section | widget | text/placeholder | container | có ở Android? |
|---|---|---|---|---|---|
| E1 | `<section>` | `<card wrapper + icon + tiêu đề + subtitle>` | `<text>` | Card | |
| E2 | `<section>` | `<nút phụ / hành động>` | `<nhãn>` | trong Card | |
| E3 | `<section>` | `<field + toggle/eye>` | `<placeholder>` | Card | |
> Điền theo ảnh iOS THỰC TẾ (placeholder là ví dụ format, không phải nội dung
> bắt buộc). Thiếu 1 widget (kể cả card-wrapper/helper text/nút phụ) =
> ELEMENT FAIL. "Trống so iOS" (mất card/khung) = bằng chứng FAIL hiển nhiên.

**5.x Component tree**
```
Screen
 ├─ Header (…)
 ├─ ScrollView
 │   ├─ Section A …
 │   └─ Section B (dưới fold) …
 └─ FooterBar …
```

**5.x Measurement / token map** — mỗi node: token hoặc số đo tuyệt đối.

**5.x LAYOUT & SAFE-AREA MAP** (bắt buộc — measurement §3.1, enforcement §14)
| mục | iOS | Android | KQ |
|---|---|---|---|
| safe-area inset top/bottom | `<dp>` | | |
| anchor_Y `<hero/icon>` (từ safe top) | `<dp>` | | |
| anchor_Y `<title>` / `<card top>` / `<primary btn>` / `<tab bar>` | `<dp>` | | |
| padding trong / margin ngoài / gap item `<khối>` | `<dp>` | | |
| alignment (left/center) `<khối>` | `<…>` | | |
> Lấy số từ source iOS. Δ > tolerance §0 (≤2dp) = FAIL. Content chạm status
> bar khi iOS có spacing = FAIL.

**5.x State inventory** — default/pressed/focused/disabled/loading/empty/
error/selected: điều kiện + UI từng state.
+ **State sống sót** (Android-only risk): state nào phải giữ qua xoay máy /
đổi theme / đổi font-scale (`rememberSaveable`) và qua **process death**
(`SavedStateHandle`) để bằng iOS. Ghi rõ từng state, vì `remember` sẽ MẤT.

**5.x LOG INVENTORY** (rule #37, enforcement §21 — điền cùng lúc port)
| vùng/sự kiện | kênh | mức | dữ liệu ghi (KHÔNG PII) | iOS tương ứng |
|---|---|---|---|---|
| `<màn enter/exit>` | `AppLog.<module>` | debug | id6, thời gian | `<os_log …>` |
| `<nhánh quyết định / lỗi>` | `AppLog.<module>` | warn/error | mã lỗi, nhánh | `<file:line>` |
> Màn không có dòng log nào = chưa xong (verify.sh §3a cảnh báo).

**5.x MOTION INVENTORY (per-layer, từ SOURCE — ảnh tĩnh không thấy effect)**
Với MỖI element ở Element Inventory: soi source layer đó tìm motion (enforce
§16). Mỗi motion 1 dòng; element không có thì ghi `none` (đã soi).
| El# | element | có motion? | trigger | prop từ→đến | duration | curve/spring | delay/stagger/repeat | nguồn iOS |
|---|---|---|---|---|---|---|---|---|
| E1 | `<…>` | yes/none | appear/tap/state… | `<…>` | `<ms>` | `<KB §Motion>` | `<…>` | `<file:line>` |
> Đọc literal source (không nhìn ảnh). Mỗi motion → port Android + đo xác
> nhận record (measurement §2), Δduration ≤ §0. Thiếu Motion Inventory =
> chưa VERIFIED; bỏ sót effect = FAIL.

**5.x Interaction** — mỗi gesture: loại, ngưỡng, vùng hit, phản hồi, haptic,
sound.

**5.x Behavior/flow** — state machine, validation, edge case, side effect,
persistence, networking, offline. (= test oracle)

**5.x Navigation** — đến từ đâu, đi đâu, kiểu transition, back-stack, deep
link.

**5.x DETAIL DIFF TABLE** (điền khi verify — enforcement §7)
| element | thuộc tính | iOS | Android | KQ (PASS/Δ) |
|---|---|---|---|---|
| Title | fontSize | 28sp | | |
| Title | weight | Bold | | |
| Card | radius | 16dp | | |
| Card | shadow | x0y4b12 22% | | |
| CTA | press anim | scale .96 / 120ms easeOut | | |

**5.x Sign-off** (verify 3 lớp — SKILL.md stage 5)
- [ ] A Build+Test pass — bằng chứng: `<log>`
- [ ] B Visual diff ≤ tolerance mọi state — `<diff img paths + %>`
- [ ] C Behavior+perceptual walkthrough — `checklists/ui-parity.md` ký
- [ ] Deviation (nếu có) đã user duyệt: `DEVIATIONS.md#<id>`
→ chỉ khi đủ 4 ô: ledger dòng screen = VERIFIED.

## 6. CAPABILITY MAP
Tham chiếu `checklists/capability.md` — mọi API platform-specific + adapter +
trạng thái + deviation.

## 7. STANDARDS
Tham chiếu `checklists/standards.md` — Apple HIG (đóng băng từ iOS) + Google/
Play mandatory. Mỗi mục = 1 dòng verify ở stage 5.

## 8. i18n INVENTORY
| key (semantic EN) | vi (default) | en | nguồn iOS | format/plural |
|---|---|---|---|---|
| `auth.login.title` | … | … | `Login.swift:42` | — |
| `cart.items` | … | … | `Cart.swift:88` | plural {count} |

Ghi rõ: interpolation order, plural rule, format số/ngày/tiền theo locale,
chuỗi dài gây vỡ layout (test text-expansion).

## 9. NETWORK CONTRACTS & FIXTURES (measurement.md §4)
Trích từ source iOS — dùng CHUNG cho oracle iOS + test Android.
| API | method | request shape | response shape | mã lỗi | fixture file |
|---|---|---|---|---|---|
| `/auth/apple` | POST | `{idToken}` | `{user,token}` | 401/409 | `fixtures/auth_ok.json` … |

Fixture mọi nhánh: ok / empty / error / timeout / phân trang. Test-env:
`test_backend` (manifest) — CẤM prod (bất biến #13 TEST-ENV). Không fixture chung → behavior
KHÔNG được VERIFIED.

## 10. HIDDEN / SOURCE-ONLY / SIMULATOR-UNTESTABLE (vai SOURCE-ANALYST §7)
Truy TỪ CODE+plist+entitlements (không quan sát). Mỗi mục 1 dòng ledger.
| ID | tính năng | loại | nguồn iOS (file:line/plist key) | đặc tả (attr/flow/state) | verify ở đâu | ledger |
|---|---|---|---|---|---|---|
| H01 | `<feature flag/A-B>` | hidden | `<file:line>` | điều kiện bật, code path | unit/contract | |
| H02 | `<năng lực phần cứng>` | untestable | `<*.entitlements/plist key>` | session, lỗi | THIẾT BỊ THẬT | |
| H03 | `<deep link/URL scheme>` | hidden | Info.plist `CFBundleURLTypes` | route → màn | instrument test | |
| H04 | `<silent push/background>` | untestable | `UIBackgroundModes`, handler | payload→side effect | contract+device | |
| H05 | `<tính năng VIP/premium/gated>` | gated | `<entitlement/IAP/role check file:line>` | điều kiện gate + state khoá + state mở | mock-entitlement | |

Loại: hidden (không hiện UI) / untestable (simulator không chạy) / **gated**
(VIP/premium/subscription/role — KHÔNG có tài khoản VIP demo nên KHÔNG quan
sát được UI mở khoá).

### 10.1 GATED / VIP — tái dựng TỪ SOURCE (bắt buộc, mỗi feature 1 khối)
Vì không vào được UI VIP trên simulator: SOURCE-ANALYST đọc source GỐC, đặc
tả ĐỦ — KHÔNG đoán, KHÔNG bỏ:
- **Điều kiện gate**: cờ/entitlement/receipt/role nào quyết định mở (file:line).
- **State KHOÁ**: UI khi chưa VIP (paywall/CTA/blur/disable…) — cái này quan
  sát được, spec như màn thường.
- **State MỞ**: mọi màn/thành phần CHỈ hiện khi VIP — dựng spec đầy đủ
  (Composition/Element/Layout §5.x) TỪ source + asset, vì không screenshot
  được. Liệt kê từng màn VIP thành dòng ledger riêng.
- **Flow mua/khôi phục/đồng bộ entitlement**: bước, API, state machine, lỗi,
  offline, hết hạn, gia hạn, downgrade.
- **Server entitlement contract** + fixture 2 trạng thái (locked/unlocked) →
  measurement §4, để test cả 2 platform KHÔNG cần mua thật.
- **Verify**: ép trạng thái entitlement bằng mock/debug-override (KHÔNG mua
  thật, KHÔNG prod — bất biến #13 TEST-ENV) để render & diff được UI mở khoá ở cả iOS lẫn
  Android; nếu iOS hoàn toàn không ép được → đối chiếu tương đương code-flow
  + asset thiết kế, ghi DEVIATION lý do.

Thiếu 1 mục (kể cả màn VIP không quan sát được) = SPEC FAIL, KHÔNG port tiếp.

## 11. ANALYTICS / EVENTS (nếu iOS có) — parity đo được của sản phẩm
Event bắn sai/thiếu = báo cáo sản phẩm sai, không lộ ra qua ảnh hay UI test.
| event key | trigger (màn/hành động) | tham số | iOS source (file:line) | Android | ledger |
|---|---|---|---|---|---|
| `<screen_view_home>` | mở Home | `{tab}` | `<file:line>` | | |
> Giữ NGUYÊN tên key + tên tham số + thời điểm bắn. Đổi tên = vỡ dashboard.
> Verify bằng log/debug-view của SDK, không phải "chắc là có bắn".

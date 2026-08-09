# Parity Spec — FixtureApp iOS → Android (sample GOOD — selftest scorer)

## 0. Meta

- iOS source: benchmark/fixture-ios/ (pin rev: fixture-v1)
- Android đích: app/ (Kotlin/Compose)
- Cặp thiết bị đo (cùng logical size): ios_ref_pt 393x852 == android_device_dp 393x852
  (kiểm bằng `parity-diff.sh devcheck 393x852` trước mọi phép đo)

## 1. STRUCTURE MAP (iOS → Android)

| iOS path | loại | LOC | disposition | Android path |
|---|---|---|---|---|
| FixtureApp.swift | ui | 34 | port | app/src/main/java/fixture/MainActivity.kt |
| Views/HomeView.swift | ui | 63 | port | app/src/main/java/fixture/home/HomeScreen.kt |
| Views/SettingsView.swift | ui | 37 | port | app/src/main/java/fixture/settings/SettingsScreen.kt |
| Models/Item.swift | model | 13 | port | app/src/main/java/fixture/model/Item.kt |
| Services/ItemStore.swift | state | 31 | port | app/src/main/java/fixture/data/ItemStore.kt |
| Resources/vi.lproj/Localizable.strings | i18n | - | i18n | res/values/strings.xml |
| Resources/en.lproj/Localizable.strings | i18n | - | i18n | res/values-en/strings.xml |

## 2. DESIGN TOKENS

| token | iOS | Android |
|---|---|---|
| accent | Color.fixtureAccent #FF6B35 (định nghĩa trong code, không Assets.xcassets) | Color(0xFFFF6B35) |

## 3. FLOW INVENTORY — liệt kê 100% flow

| Flow ID | tên | entry | page | phụ thuộc | iOS source | trạng thái |
|---|---|---|---|---|---|---|
| F01 | ADD-ITEM: Add → sheet detail → nhập tên → Save → persist | Home toolbar | Home,SheetDetail | L005 | HomeView.swift:29 | VERIFIED |
| F02 | Toggle dark mode | Settings | Settings | — | SettingsView.swift:17 | VERIFIED |
| F03 | Đổi ngôn ngữ vi/en | Settings | Settings | — | SettingsView.swift:18 | VERIFIED |

### 3.1 Shared Components

- ItemRow (list cell) — dùng ở HomeScreen.

## 4. COMPLETENESS LEDGER — DoD nhị phân (xem enforcement.md)

| ID | loại | tên | iOS src | dep | trạng thái | bằng chứng | agent | ts |
|---|---|---|---|---|---|---|---|---|
| L001 | token | accent color fixtureAccent #FF6B35 | FixtureApp.swift:31 | | VERIFIED | diff 0.1% | M | t1 |
| L002 | nav | TAB-NAV: TabView 2 tab → bottom NavigationBar | FixtureApp.swift:11 | L001 | VERIFIED | diff 0.3% | M | t2 |
| L003 | screen | HomeView (list 5 item) | Views/HomeView.swift:3 | L002 | VERIFIED | diff 0.4% | W1 | t3 |
| L004 | screen | SettingsView (toggle/picker/version row) | Views/SettingsView.swift:3 | L002 | VERIFIED | diff 0.4% | W1 | t4 |
| L005 | flow | ADD-ITEM flow: Add → sheet → Save | Views/HomeView.swift:29 | L003 | VERIFIED | e2e ok | W2 | t5 |
| L006 | anim | ADD-BUTTON-SCALE: spring scaleEffect 1.0→1.3 nút Add | Views/HomeView.swift:31 | L003 | VERIFIED | video khớp | W2 | t6 |
| L007 | ui | sheet detail nhập item (ModalBottomSheet) | Views/HomeView.swift:45 | L005 | VERIFIED | diff 0.5% | W2 | t7 |
| L008 | state | ItemStore persist UserDefaults → DataStore | Services/ItemStore.swift:5 | | VERIFIED | unit test | W1 | t8 |
| L009 | i18n | i18n parity vi.lproj + en.lproj → values/ + values-en/ (13 key) | Resources/ | | VERIFIED | key parity 13/13 | M | t9 |
| L010 | hidden | EASTER-EGG: key secret.easterEgg KHÔNG dùng ở UI (unused key) — port nguyên trạng | vi.lproj/Localizable.strings:14 | L009 | VERIFIED | key có mặt 2 lang | M | t10 |

## 5. PER-SCREEN SPEC

### Screen: `Home` — iOS `Views/HomeView.swift`

- List 5 item seed, row: dot accent + tên + ngày.
- Nút Add (toolbar): animation spring scale bump rồi mở sheet.
- Sheet detail: TextField tên + nút Save (disabled khi rỗng) → ItemStore.add → đóng.

### Screen: `Settings` — iOS `Views/SettingsView.swift`

- Toggle dark mode (`settings.darkMode`), Picker ngôn ngữ vi/en, row Version đọc Bundle.

## 8. i18n INVENTORY

- 2 lang: vi (default) + en, 13 key/lang. Key ẩn: `secret.easterEgg` (không dùng ở UI — giữ parity).

## 10. HIDDEN / SOURCE-ONLY

- `secret.easterEgg` — unused key, chỉ thấy khi đọc source.

## LOG INVENTORY (rule #37)

| vùng/sự kiện | kênh | mức | dữ liệu (không PII) | iOS |
|---|---|---|---|---|
| Home enter/exit + scroll | AppLog.home | debug | id6, số item | HomeView.swift:12 |
| Add item: mở sheet → save → lỗi rỗng | AppLog.home | debug/warn | nhánh, độ dài tên | HomeView.swift:29 |
| Settings đổi dark mode / ngôn ngữ | AppLog.settings | debug | giá trị mới | SettingsView.swift:10 |

## DEVIATIONS

- Không deviation. (Log tại DEVIATIONS.md cạnh spec.)

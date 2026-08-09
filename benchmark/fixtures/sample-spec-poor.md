# Parity Spec — FixtureApp iOS → Android (sample POOR — selftest scorer)

<!-- Cố ý THIẾU 3 entry ground-truth (xem selftest.sh) + thiếu 1 section bắt buộc. -->

## 0. Meta

- iOS source: benchmark/fixture-ios/
- Android đích: app/ (Kotlin/Compose)

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

## 3. FLOW INVENTORY — liệt kê 100% flow

| Flow ID | tên | entry | page | phụ thuộc | iOS source | trạng thái |
|---|---|---|---|---|---|---|
| F01 | ADD-ITEM: Add → sheet detail → nhập tên → Save | Home toolbar | Home,SheetDetail | L005 | HomeView.swift:29 | VERIFIED |
| F02 | Toggle dark mode | Settings | Settings | — | SettingsView.swift:17 | VERIFIED |

## 4. COMPLETENESS LEDGER — DoD nhị phân (xem enforcement.md)

| ID | loại | tên | iOS src | dep | trạng thái | bằng chứng | agent | ts |
|---|---|---|---|---|---|---|---|---|
| L001 | nav | TAB-NAV: TabView 2 tab → bottom NavigationBar | FixtureApp.swift:11 | | VERIFIED | diff 0.3% | M | t1 |
| L002 | screen | HomeView (list 5 item) | Views/HomeView.swift:3 | L001 | VERIFIED | diff 0.4% | W1 | t2 |
| L003 | screen | SettingsView (toggle/picker/version row) | Views/SettingsView.swift:3 | L001 | VERIFIED | diff 0.4% | W1 | t3 |
| L004 | model | Item struct | Models/Item.swift:3 | | VERIFIED | unit test | W1 | t4 |
| L005 | flow | ADD-ITEM flow: Add → sheet → Save | Views/HomeView.swift:29 | L002 | VERIFIED | e2e ok | W2 | t5 |
| L006 | ui | sheet detail nhập item (ModalBottomSheet) | Views/HomeView.swift:45 | L005 | VERIFIED | diff 0.5% | W2 | t6 |
| L007 | state | ItemStore persist UserDefaults → DataStore | Services/ItemStore.swift:5 | | VERIFIED | unit test | W1 | t7 |
| L008 | i18n | i18n parity vi.lproj + en.lproj → values/ + values-en/ | Resources/ | | VERIFIED | key parity | M | t8 |

## 5. PER-SCREEN SPEC

### Screen: `Home` — iOS `Views/HomeView.swift`

- List 5 item seed. Nút Add mở sheet detail: TextField tên + Save → ItemStore.add.

### Screen: `Settings` — iOS `Views/SettingsView.swift`

- Toggle dark mode, Picker ngôn ngữ vi/en, row Version đọc Bundle.

## 8. i18n INVENTORY

- 2 lang: vi (default) + en.

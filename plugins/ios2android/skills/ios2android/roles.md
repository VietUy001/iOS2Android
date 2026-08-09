# ROLES — mô hình đa agent song song (năng suất + chất lượng)

> Bổ trợ `enforcement.md`. MỌI vai trò bị ràng buộc no-stop / WIP-LOCK /
> anti-stub / bằng chứng như enforcement.md — không vai nào được "nới".
> Hợp đồng chung = `parity-spec.md` (Ledger + Spec) + `DEVIATIONS.md`.

## Cách kích hoạt
Phiên chính = **MANAGER** và MANAGER **tự làm việc thật** (đọc/port/build/
verify). Các vai dưới đây là "mũ" công việc MANAGER tự đội lần lượt theo
vertical-slice; nhiều việc ĐỘC LẬP + nặng thật sự → giao một số ÍT subagent
đóng vai tương ứng, mỗi subagent làm TRỌN 1 việc rồi trả kết quả. Giới hạn
số lượng/no-swarm/1-writer/1-owner: orchestration §B (canonical); WIP-LOCK
per-worker: enforcement §4. subagent_type:
- UI-AUDITOR, FLOW-CHECKER, QA-RECONCILER → `general-purpose` (cần
  simulator/MCP, bash, read).
- DEV-FE, DEV-FUNC → `general-purpose`.
- SOURCE-ANALYST → `Explore` (đọc rộng source/plist/entitlements, read-only).
- PERF-OPTIMIZER → `general-purpose` (cần adb/profiler/bash + đọc code).
Mỗi spawn: prompt phải nhúng (a) trích vai trò dưới đây, (b) đường dẫn
parity-spec/ledger, (c) ID dòng ledger được giao, (d) trích `enforcement.md`.

---

## 1. MANAGER (phiên chính — owner Ledger, NGƯỜI LÀM CHÍNH)
Trách nhiệm:
- **Tự làm việc thật**: đọc source iOS, port Kotlin/Compose, chạy `gradle`,
  chạy verify/đo diff. KHÔNG chỉ sinh lệnh giao tiến trình khác.
- Sở hữu & ghi Ledger (CHỈ Manager đổi trạng thái dòng — 1-writer; vai/subagent
  khác đề nghị + nộp bằng chứng).
- Lập Flow Inventory + Structure Map; port theo **vertical-slice** từng flow
  (Stage 4). Nền dùng chung (token/Shared §3.1/adapter/platform-equivalent)
  VERIFIED TRƯỚC khi port UI phụ thuộc (dep gate).
- Theo dõi tiến độ; mỗi nhịp chạy `scripts/parity-status.sh`, dán output.
- **No-stop / không idle sau khi giao subagent / cấm task breadth nửa vời**:
  theo enforcement §3, §3.1, §3.2 (canonical — không lặp ở đây). Subagent
  treo/không bằng chứng → giao lại; 1 subagent = 1 flow/1 file/1 màn-spec,
  làm tới bằng chứng.
- Gate: chỉ chuyển flow sang DONE khi đủ bằng chứng QA 3 lớp.
- Báo user CHỈ tại 5 ngoại lệ chặn (enforcement §3); ngoài ra tiếp tục, không dừng.
- KHÔNG tự VERIFIED không có bằng chứng QA.
- **ORCHESTRATOR-GỌN + CHIA VIỆC CÓ GIỚI HẠN**: theo orchestration §A2/§B/§D3
  (canonical). MANAGER vẫn là người build + verify + ghi ledger; nghi ngờ
  xung đột → tách file hoặc làm tuần tự, KHÔNG hạ verify để nhanh.

## 2. UI-AUDITOR (Giao diện)
Trách nhiệm:
- Đọc source iOS màn được giao (đầy đủ, không lướt).
- **Chạy simulator** qua MCP `xcodebuild`/`ios-simulator`: build & boot app
  iOS, mở đúng màn.
- **Tự scroll HẾT** màn (đỉnh→đáy, mọi section dưới fold, expand/accordion,
  tab con) — enforcement §5. Chụp ảnh tham chiếu mọi state (light/dark/
  dynamic-type/empty/loading/error).
- Điền Parity Spec §2 (token), §5: **Screen Composition Manifest + ELEMENT
  INVENTORY (liệt kê TỪNG widget từ ảnh iOS — card/icon/helper/nút phụ/
  toggle)**, measurement, state, animation, interaction, navigation; đính ảnh.
- Đo animation từ record (duration/curve) → §5.x + KB.
- Output: spec màn `SPECD` + ảnh + “FULL-SCROLL DONE: n sections”. Read-only
  Android. KHÔNG sang màn khác khi màn hiện tại chưa SPECD đủ.

## 3. FLOW-CHECKER (Check flow)
Trách nhiệm:
- Với flow được giao: chạy trên **iOS simulator trước** (oracle) — tự bấm
  từng bước, từng chức năng nhỏ nhất, mọi nhánh, mọi edge (rỗng/offline/lỗi/
  deny quyền/dữ liệu lớn). Ghi lại chính xác input→state→output + record.
- Sau khi DEV build: chạy lại đúng kịch bản trên **Android** build.
- So từng bước. Báo PASS/FAIL từng dòng ledger kèm bằng chứng (record/log).
- FAIL → nộp Manager + mô tả lệch cụ thể (bước nào, khác gì). KHÔNG tự sửa
  code. KHÔNG bỏ qua chức năng nhỏ.

## 4. DEV-FE (build giao diện)
Trách nhiệm:
- Nhận dòng ledger UI từ Manager/QA. Build Compose **đúng Parity Spec §5 +
  số đo UI-Auditor** (token, không literal rời, file 500 = cảnh báo / 800 =
  trần cứng theo rule #24, i18n không hardcode).
- **ELEMENT GATE** (enforcement §12): CẤM code màn khi Element Inventory chưa
  đủ. Build = tô lại TỪNG widget trên ảnh iOS, KHÔNG tự nghĩ "màn nên có gì".
- Animation đúng số đo (KB §Motion), không "đại khái".
- **ĐẶT LOG cùng lúc với code** (rule #37, enforcement §21): kênh chung, gác
  `BuildConfig.DEBUG`, không PII. Nộp việc mà màn không có log = trả lại.
- **SEARCH-FIRST** (bất biến #15): tìm component/util đã có (Shared ledger §3.1,
  code đã port, mapping-kb) → tái dùng/mở rộng, CẤM copy-paste bản trùng.
- KHÔNG thêm/bớt/đổi so với spec; thiếu thông tin → hỏi UI-AUDITOR/Manager,
  KHÔNG đoán. KHÔNG nhảy dòng khác khi dòng hiện tại chưa PORTED.
- Cần tool/lib để đạt parity → đề xuất Manager (TECH RESEARCH — orchestration
  §E), không tự cài.

## 5. DEV-FUNC (build chức năng)
Trách nhiệm:
- Nhận dòng ledger logic/adapter. Build model/service/viewmodel/adapter đúng
  spec + **behavior oracle** từ FLOW-CHECKER (cùng input→cùng output).
- Viết/port test cho phần mình (XCTest→JUnit) — test-đến-đâu-build-đến-đó.
- Adapter platform-specific → ghi `mapping-kb.md §API`. File 500 cảnh báo /
  800 trần (rule #24).
- KHÔNG stub/mock để qua compile (enforcement §6). WIP-LOCK như DEV-FE.
- Log cho mọi nhánh quyết định/lỗi (rule #37); `runCatching{}.onFailure{log}`,
  CẤM `catch {}` rỗng nuốt lỗi.

## 6. QA-RECONCILER (Check & tổng kết & kiểm tra + INTAKE AUDIT)
Trách nhiệm:
- **INTAKE AUDIT (brownfield, enforcement §13)**: dự án có code Android cũ →
  agent rà soát chuyên trách: quét TOÀN BỘ màn/flow hiện có, đối chiếu iOS,
  lập danh sách lệch, trả DEV dựng lại. KHÔNG màn nào miễn vì "đã làm rồi".
- Sau khi DEV xong + FLOW-CHECKER pass sơ bộ: rà bug toàn diện.
- So **iOS ↔ Android side-by-side** (ảnh + Detail Diff Table parity-spec
  §5.x): từng thuộc tính (font size/màu/spacing/radius/shadow/duration/
  curve/gesture/haptic). Δ vượt tolerance §0 = FAIL.
- Chạy `checklists/ui-parity.md` + `standards.md` 3 lớp; kiểm **cặp thiết bị**
  (`parity-diff.sh devcheck`) TRƯỚC khi tin bất kỳ số %diff/IoU nào.
- Từ chối VERIFIED màn **không có log** (rule #37) hoặc chưa qua **release
  gate** (enforcement §20) — ngang hàng với thiếu Motion Inventory.
- **Adversarial (enforcement §17)**: bắt buộc nêu ≥5 khác biệt cụ thể/màn
  trước sign-off; cấm "trông ổn". Determinize trước khi đối chiếu.
- Quét code trùng lặp (enforcement §10): thấy ≥2 bản cùng chức năng → FAIL,
  trả DEV gộp về 1 nguồn.
- Tự đánh giá khác biệt, mở dòng FAIL kèm bằng chứng, **trả việc** DEV kèm
  chỉ dẫn sửa cho giống bản gốc iOS. Lặp tới hết lệch.
- CHỈ QA được đề nghị Manager đặt `VERIFIED` (kèm bằng chứng đủ A+B+C).
- KHÔNG nương tay ("gần giống là được" = FAIL).

## 7. SOURCE-ANALYST (Đọc source — tính năng ẩn & không test được)
Lý do: nhiều tính năng KHÔNG hiện trên UI / KHÔNG chạy được trên simulator
(NFC, camera/AR, Face/Touch ID, Secure Enclave, push/silent push, IAP/
StoreKit, HealthKit, Bluetooth, CallKit, background mode, location nền) →
UI-AUDITOR/FLOW-CHECKER quan sát không thấy. Vai này KHÔNG dựa quan sát.
Trách nhiệm:
- Đọc KỸ source iOS (read-only): mọi `.swift`, `Info.plist`, `*.entitlements`,
  `project.yml`, build config, scheme, `URL types`, `UIBackgroundModes`,
  Intents/AppShortcuts, App/Action/Share/Widget extension, push handler.
- Truy **tính năng ẩn**: feature flag, A/B gate, remote-config gate, debug/
  internal menu, code path theo điều kiện (build config, region, entitlement,
  iOS version), deep link/URL scheme, handoff, pasteboard, quick action,
  state-restoration, silent-push side effect, dead-but-shipped path.
- Truy **tính năng không test được trên máy ảo** → đặc tả từ CODE: thuộc tính,
  tham số, state machine, side effect, lưu trữ, lỗi/timeout, entitlement.
- **VIP/GATED** (không có tài khoản VIP demo → KHÔNG quan sát UI mở khoá):
  đọc source GỐC, dựng ĐỦ điều kiện gate + state khoá + MỌI màn VIP (spec
  Composition/Element/Layout từ source+asset) + flow mua/khôi phục + server
  entitlement contract → Parity Spec §10.1. KHÔNG đoán, KHÔNG bỏ màn VIP.
- Output: điền Parity Spec §10 (Hidden/untestable) + Behavior spec + đề nghị
  dòng ledger cho từng tính năng (kể cả không có trên UI). Đánh dấu mục cần
  verify trên **thiết bị thật** (không phải simulator) hoặc qua contract/
  fixture (measurement.md §4). Mơ hồ → hỏi MANAGER, KHÔNG đoán.
- **MOTION PER-LAYER** (enforcement §16): ảnh tĩnh không thấy effect → soi
  source TỪNG layer/element tìm animation/transition/implicit/CA*/repeat/
  gesture/appear → điền Motion Inventory (parity-spec §5.x); element không
  motion ghi `none`. UI-AUDITOR quay video xác nhận, KHÔNG thay source.
- KHÔNG sửa code. Phối hợp DEV-FUNC để dựng tương đương Android 100%.

## 8. PERF-OPTIMIZER (Đọc lại code đã build — chẩn đoán & phân việc tối ưu)
Lý do: app build ra bị đơ/giật/lag. Vai này KHÔNG dựa cảm tính — đo + đọc
code + chẩn đoán + phân việc, KHÔNG tự sửa (giữ tách vai như QA).
Trách nhiệm:
- **Profile build hiện tại** (số, không đoán): cold start `adb shell am
  start -W`; jank `dumpsys gfxinfo <pkg> framestats` / Macrobenchmark;
  recomposition (Layout Inspector / composition tracing); main-thread block
  & I/O (StrictMode, Perfetto/systrace); memory & leak (Memory Profiler,
  LeakCanary nếu có); overdraw. Ghi số trước-tối-ưu.
- **Đọc lại code đã build** tìm anti-pattern (đối chiếu telegram-grade +
  quy tắc memory-leak CLAUDE.md): recomposition thừa (param không stable, đọc state quá cao,
  thiếu `key`/`derivedStateOf`/`remember`), việc nặng/alloc trong
  measure/draw/`onDraw`, block main thread (I/O/network/JSON sync), `Lazy*`
  thiếu key, ảnh re-decode, animation không pause khi off-screen, leak
  (Flow/Timer/listener), off-main render thiếu cho blur/gradient/video.
- **So PERF PARITY với iOS** (measurement §7, standards §4.1): cold start
  ≤ iOS+20%, fps/jank khớp target màn. Lag hơn iOS quá ngưỡng = FAIL.
- **Phân biệt nhiễu hạ tầng**: lag do máy/Gradle Kotlin daemon quá tải
  (lỗi/treo GIẢ) ≠ lag runtime app — verify lại, đừng đổ oan code/agent
  (Kotlin/Gradle daemon quá tải sinh lỗi GIẢ kiểu "Unresolved reference").
- **Phân việc**: lập danh sách tối ưu xếp theo tác động (đo được), mở dòng
  ledger `perf:<mô tả>` kèm số liệu + đề xuất cách sửa → **MANAGER** giao
  DEV-FE/DEV-FUNC. KHÔNG tự sửa, KHÔNG đề nghị VERIFIED (việc của QA).
- **Bằng chứng bắt buộc**: mỗi dòng perf chỉ đóng khi có số **trước→sau**
  đạt ngưỡng + không gây lệch parity (QA tái kiểm). "Thấy mượt hơn" = không
  tính.
- Đọc-only, KHÔNG sửa code; ghi ledger qua MANAGER (1 writer duy nhất, không
  để nhiều agent ghi ledger song song).

---

## Pipeline mặc định tuần tự + chia việc có giới hạn (WIP-LOCK per-worker)
```
SPEC   : MANAGER tự spec, hoặc giao vài UI-AUDITOR/SOURCE-ANALYST — mỗi
         subagent 1 màn/cụm ẩn-VIP read-only → gom vào parity-spec
NỀN    : MANAGER (hoặc 1–2 DEV) build token + Shared Components + adapter +
         platform-equivalent (login Google/FCM/Billing…) → VERIFIED trước
PORT   : mặc định MANAGER port từng flow vertical-slice tới VERIFIED; nhiều
         flow độc lập + máy khoẻ → giao tối đa ~5–8 subagent (1 flow/file/
         subagent, 1-owner-1-file). MANAGER build + verify (serialize Gradle)
xuyên suốt : PERF-OPTIMIZER profile flow VERIFIED → mở `perf:` → MANAGER giao
             DEV; perf parity (vs iOS) là điều kiện đóng
```
- Mặc định TUẦN TỰ cho rõ ràng & không xung đột. Song song / giới hạn số
  lượng / 1-owner-1-file / 1-writer ledger / dep gate: orchestration §B;
  WIP-LOCK per-worker: enforcement §4 (đều canonical, không lặp).
- 1 việc chỉ VERIFIED khi đủ bằng chứng QA. MANAGER đẩy việc tới khi
  `parity-status.sh` = DONE — trước đó KHÔNG ai tuyên bố hoàn thành/bàn giao
  (enforcement §2–3).

## Chống xung đột
- Mỗi dòng ledger chỉ 1 DEV sở hữu tại 1 thời điểm (Manager phân, ghi cột
  agent). Không 2 agent sửa cùng file.
- Vai đọc-only (UI-AUDITOR/FLOW-CHECKER/QA) không sửa code Android.
- Mọi cập nhật Ledger đi qua Manager (nguồn sự thật đơn).
- Bất đồng iOS-behavior → UI-AUDITOR/FLOW-CHECKER dựa source+simulator phân
  xử; vẫn mơ hồ → Manager hỏi user (enforcement §3).

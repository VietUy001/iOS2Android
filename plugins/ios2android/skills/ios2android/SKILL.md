---
name: ios2android
description: >
  Port một app iOS Swift/SwiftUI sang Android (Kotlin/Compose) với mục tiêu PARITY
  100% — giao diện, chức năng, flow, hiệu ứng giống hệt bản iOS. AI-assisted thủ
  công, đa agent, có cổng kiểm tra & ép form chống bỏ ngang. Kích hoạt bằng
  `/ios2android`, hoặc khi user yêu cầu "port iOS sang Android", "build lại bản
  Android giống iOS", "convert Swift sang Android", hoặc trỏ vào source iOS +
  folder Android đích. KHÔNG kích hoạt khi user chỉ hỏi lý thuyết porting /
  so sánh nền tảng iOS-Android mà KHÔNG có source iOS + folder Android đích
  cụ thể — khi đó trả lời trực tiếp, không chạy pipeline.
---

# ios2android — Học thuyết Parity & Quy trình port

> Mục tiêu tối thượng: **bản Android là BẢN SAO của bản iOS, không phải bản
> diễn giải lại.** Mọi quyết định visual/behavioral phải truy được về một sự
> thật quan sát từ iOS. Không sáng tạo, không "cải tiến", không "best practice
> Android" nếu nó làm khác bản iOS — trừ khi user duyệt rõ trong Deviation
> Register (enforcement §0).

## ★ FORMULA CARD (la bàn — luôn theo thứ tự này)

```
-1 PREFLIGHT   `preflight.sh … pre`: iOS build/run + pin source + test-env ≠ prod
               + CẶP THIẾT BỊ cùng logical size (ios_ref_pt == android_device_dp)
               → GREEN. (gradlew chưa cần — greenfield scaffold ở stage 2)
 0 CONTRACT    3 trụ + tolerance; brownfield → code cũ KHÔNG tin (enforce §13)
 1 SPEC        full traversal → Structure Map + Flow Inventory + per-screen:
               Composition→Element→Layout/safe-area→Motion(soi source)→§10
               hidden/VIP. DETERMINIZE trước khi chụp. Spec duyệt mới port.
 2 SCAFFOLD    token từ iOS (KHÔNG Material default); asset dùng chung iOS
 3 MAP         mỗi mục chọn bậc THẤP nhất đủ parity (telegram-grade cổng)
 4 PORT        vertical-slice 1 flow: model→logic→UI; test-đến-đâu; LOG cùng lúc
               (#37); i18n; REUSE-FIRST; element gate; file 500 cảnh báo/800 trần
 5 VERIFY      `preflight.sh … verify` trước → Composition→Element(texts-diff)→
               Layout/IoU→Motion→parity-diff mọi state→Detail Diff→adversarial
               ≥5→perf parity→RELEASE/R8. Bằng chứng số mới VERIFIED
 6 HARVEST     mapping/effect mới → mapping-kb
```
Vòng lặp: build → đo → vùng lệch thành task → lặp tới `parity-status.sh`=DONE.
Phiên chính TỰ LÀM việc thật; việc độc lập + nặng → giao vài subagent (tối đa
~5–8); giữ context cha MỎNG, ghi ledger ngay; context đầy KHÔNG phải lý do
dừng (chi tiết + canonical: mục "Bất biến cốt lõi" dưới). Quên gì → đọc lại
card + bảng load-on-demand.

## ☼ LITE MODE (chống chính skill bị over-engineer)

App nhỏ/đơn giản (ít màn, không VIP/hardware/animation phức tạp, 1 người
dùng/phiên): VẪN giữ Parity Contract + Composition/Element/Layout gate +
bằng chứng diff, NHƯNG phiên chính tự làm tuần tự (không tách vai, không
subagent), spec gọn (manifest ngắn). KHÔNG hạ tolerance, KHÔNG bỏ verify.
MANAGER quyết lite/full ở Stage -1, ghi manifest, user duyệt. Nghi ngờ → full.

## 📖 LOAD-ON-DEMAND — đọc companion đúng lúc, KHÔNG nạp cả cụm

Kích hoạt skill = CHỈ nạp file này. Companion đọc khi đến lượt theo bảng
(cần thì đọc lại, KHÔNG đọc trước "cho chắc"):

| Khi nào | Đọc file |
|---|---|
| Stage -1 → 1 (preflight/contract/spec/RESUME/brownfield) | `enforcement.md` + `orchestration.md` + `parity-spec.template.md` + `manifest.template.md` |
| Khi chia việc cho subagent (mọi stage) | `roles.md` |
| Stage 2 (scaffold: font/asset/token) | `mapping-kb.md` §Typography + §Asset |
| Stage 3–4 (map/port) | `mapping-kb.md` toàn bộ; **chỉ khi gặp effect/animation** → `telegram-grade.md` |
| Stage 5 (verify/đo) | `measurement.md` |
| Checklists (`capability/ui-parity/standards`) | copy vào project ở stage 1 (enforcement §2), đọc + tick khi verify |

## 0. PARITY CONTRACT — "giống 100%" = 3 trụ + tolerance

Mọi màn hình phải đạt cả 3 trụ (danh mục chi tiết từng trụ: enforcement §0):
- **Trụ 1 — Visual** (nhìn giống): layout/màu/typography/icon-asset/theme/
  mọi state khớp spec từng số đo.
- **Trụ 2 — Behavioral** (làm giống): mọi chức năng + state machine +
  validation + edge case + persistence + navigation y hệt; dịch vụ Apple-độc-
  quyền → platform-equivalent (`mapping-kb.md §Platform-Equivalent`).
- **Trụ 3 — Perceptual** (cảm giác giống): animation/transition/gesture/
  haptics/âm thanh/scroll physics khớp số đo.

### Tolerance (sai số cho phép)
| Hạng mục | Sai số tối đa |
|---|---|
| Vị trí / kích thước / spacing | ≤ 2 dp |
| Màu sắc | 0 (đúng hex/alpha) |
| Animation duration | ≤ 16 ms (1 frame@60fps) |
| Visual diff pixel (per state) | ≤ 1.0% sau khi loại status bar/nav chrome |
| Text content | 0 (giống tuyệt đối, qua i18n key) |

**Deviation Register**: điểm KHÔNG thể giống 100% (OS-chrome, font hệ thống,
platform-equivalent…) → ghi `DEVIATIONS.md`, ưu tiên replicate custom, user
duyệt trước khi port. Quy tắc đầy đủ + loại `MANDATORY`: enforcement §0.

**Standards (Apple HIG + Google/Play)**: thứ tự ưu tiên khi xung đột =
Mandatory policy/kỹ thuật > Parity iOS > khuyến nghị nền tảng — canonical:
`checklists/standards.md`. Mỗi mục standards = 1 hàng verify stage 5.

---

## PIPELINE (stage -1 → 6)

### Stage -1 — PREFLIGHT (cổng chặn trước mọi thứ, 2 chế độ)
`scripts/preflight.sh <iOS> <ANDROID> <manifest> [pre|verify]`:
- **`pre`** (trước Stage 0): iOS build + chạy được trên simulator (không chạy
  được = KHÔNG có oracle → chỉ đi tiếp bằng ORACLE-LIMITED MODE dưới đây);
  xcrun/git/java sẵn sàng; **pin source iOS** (bất biến #14); **test-env
  isolation** (bất biến #13); **cặp thiết bị** khai đủ & khớp (bất biến #17).
  `gradlew` KHÔNG bắt buộc — greenfield chỉ có sau Stage 2 SCAFFOLD.
- **`verify`** (trước Stage 5): thêm adb + ffmpeg + ImageMagick + gradlew +
  device online + kiểm thiết bị THẬT đúng dp đã khai. Thiếu công cụ → đề xuất
  user cài, KHÔNG tự cài.
Gate: in `PREFLIGHT GREEN` + manifest đủ. Đỏ → DỪNG báo user.

**ORACLE-LIMITED MODE** (iOS KHÔNG build/chạy được — signing, pod, Xcode cũ):
KHÔNG tự ý chạy tiếp và KHÔNG hạ tolerance. Trình bày cho user, chỉ bật khi
user duyệt rõ; ghi manifest `oracle_mode: limited` + `oracle_limited_approved:
yes`. Khi bật: spec dựng 100% từ SOURCE (vai SOURCE-ANALYST), mọi dòng ledger
không đo được ảnh đánh bằng chứng `source-derived: <file:line>` + 1 dòng
`DEVIATIONS.md` loại `MANDATORY` nêu rõ "không có oracle runtime", và mục đó
CẦN user ký mới VERIFIED. Ưu tiên tuyệt đối: khôi phục oracle (nhờ user mở
Xcode/pod install) trước khi chấp nhận mode này.

### Stage 0 — CONTRACT
Chốt 3 trụ + tolerance (§0) với user; brownfield → code cũ KHÔNG tin
(enforcement §13). Quyết lite/full mode, ghi manifest.

### Stage 1 — SPEC EXTRACTION (trái tim của parity)
Trước khi viết 1 dòng Kotlin: reverse-engineer iOS thành **Parity Spec**
(nguồn sự thật duy nhất). Cách khai thác chi tiết (full traversal, 3 nguồn,
10 mục per-screen, hidden/VIP §10): `parity-spec.template.md §Cách khai thác`.
- FULL SOURCE TRAVERSAL — đọc TOÀN BỘ source, mỗi file 1 disposition, mọi chi
  tiết truy về `path:line`. Structure Map = artifact bắt buộc.
- Screen Composition Manifest + Element Inventory + Motion Inventory (soi
  source từng layer) + Layout/safe-area map cho TỪNG màn (enforcement
  §11/§12/§14/§16).
- Tính năng ẩn/VIP/simulator-untestable → SOURCE-ANALYST truy từ code+plist+
  entitlements (spec §10/§10.1). Thiếu = SPEC FAIL.
- **Copy `checklists/` của skill vào cạnh parity-spec trong project** — gate
  DONE grep bản copy đó, tick dần khi verify (enforcement §2).
Gate: spec không còn "TBD" mục bắt buộc, mọi màn có ảnh tham chiếu; user
duyệt spec TRƯỚC khi sang stage 2.

### Stage 2 — SCAFFOLD
Skeleton Android phản chiếu cấu trúc iOS, KHÔNG sáng tạo cấu trúc mới:
- Gradle Kotlin DSL + Compose + Material3 (chỉ làm nền — override toàn bộ
  token khớp iOS, KHÔNG để Material default lọt ra UI). Package-by-feature
  khớp cây iOS (co-locate theo feature).
- Design token layer từ spec §2 (`Color/Type/Spacing/Motion/Shape.kt`) — giá
  trị copy đúng từ iOS, mọi UI đọc token, KHÔNG hardcode literal.
- **Typography parity** (lỗ hổng số 1 — SF Pro cấm bundle, font metric-tương-
  đương, includeFontPadding=false, tracking động): `mapping-kb.md §Typography`.
- **Shared assets từ iOS** (catalog = nguồn duy nhất, KHÔNG vẽ lại; pipeline
  `scripts/extract-assets.sh`): `mapping-kb.md §Asset`.
- `strings.xml` vi default (i18n không hardcode); version source-of-truth +
  UI hiển thị, KHÔNG auto-bump mobile; `.gitignore` chặn secret; file dev/
  helper để root local, KHÔNG commit.
Gate: `./gradlew assembleDebug` pass trên skeleton; token khớp 100% spec.

### Stage 3 — MAP
Mỗi đơn vị trong spec → đích Android qua `mapping-kb.md` (Language/Motion/
Layout/State/Concurrency/Navigation/API/Platform-Equivalent/Haptics):
- Có rule KB → áp. Chưa có nhưng suy được → port + ghi KB (stage 6).
- API platform-specific → KHÔNG "convert", viết **adapter tay** (KB §API).
- Motion/effect: quy đổi chính xác từ literal source (KB §Motion), cổng
  chống over-engineering + hằng số chuẩn: `telegram-grade.md`.
- Điểm không đạt parity 100% → `DEVIATIONS.md`, chờ user duyệt.
Gate: mọi symbol/feature có đích rõ hoặc task adapter; deviation đã gửi user.

### Stage 4 — PORT (vertical slice, test-đến-đâu-build-đến-đó)
KHÔNG port theo chiều rộng (build hết UI rồi mới logic = "xong giả"). Từng
FLOW một, hoàn chỉnh end-to-end rồi mới flow sau:
```
Lấy 1 flow từ Flow Inventory → trích đủ spec của flow
  → port Models → Service → ViewModel → UI (500 cảnh báo / 800 trần)
  → ĐẶT LOG cùng lúc với code (rule #37) — chưa có log = việc CHƯA XONG
  → VIẾT/PORT TEST cho flow (oracle = hành vi đo từ iOS, ghi vào spec TRƯỚC)
  → CHẠY: gradle assemble + test + visual diff + walkthrough checklist
  → ledger dòng flow = VERIFIED (kèm bằng chứng) → mới sang flow kế
```
- **LOG bắt buộc (rule #37, enforcement §21)**: mỗi màn/vùng/scroll/nhánh quyết
  định có log qua **kênh log chung** (vd `AppLog.<module>`), gác
  `BuildConfig.DEBUG`, message dạng lambda (release không dựng chuỗi), CẤM
  `Log.d`/`println` rời rạc, CẤM log PII (chỉ id rút gọn 6 ký tự, mã trạng
  thái, số lượng, nhánh, thời gian).
- UI đúng spec + token; animation đúng số đo, KHÔNG "đại khái cho mượt".
- KHÔNG thêm/bỏ tính năng/animation/màn so với iOS. REUSE-FIRST (bất biến
  #15). Text vào strings.xml. Secret không hardcode.
- 1 module = 1 commit nhỏ (format bump-version CLAUDE.md) — **KHÔNG tự
  `git add`/commit/push**, chỉ edit local, báo user chờ duyệt.
Gate mỗi module: compile pass + đối chiếu sơ bộ spec trước khi sang module sau.

### Stage 5 — VERIFY (cổng 3 lớp, không skip — phương pháp đo: measurement.md)
Chạy `preflight.sh … verify` TRƯỚC (thiết bị cặp đôi + công cụ đo). Rồi:
- **Lớp A — Build & Test**: `scripts/verify.sh <app> --full` (assemble + test +
  anti-stub + log-gate + file-size + **RELEASE/R8**) xanh; test port từ iOS
  cùng input → cùng output. Bản **release phải cài & smoke-test thật** —
  "Debug chạy, Release không" là bệnh kinh điển (rule #34, enforcement §20).
- **Lớp B — Visual diff (Trụ 1)**: `scripts/parity-diff.sh` chụp 2 nền, cắt
  chrome, chuẩn hoá, đo %diff + onion-skin + IoU + `texts-diff` (tập text hiển
  thị, bắt mất chữ/section im lặng) + `color` (màu tolerance 0, %diff dùng
  fuzz 2% nên KHÔNG chứng minh màu); animation đọc source trước, record xác
  nhận (measurement §1–3). Đạt ≤ tolerance §0 mọi state.
- **Lớp C — Behavior & Perceptual walkthrough (Trụ 2+3)**: chạy
  `checklists/ui-parity.md` từng flow/gesture/edge/animation/haptic/back.
Gate: sign-off mỗi màn đủ A+B+C; FAIL đã đóng; DEVIATION đã user duyệt.

### Stage 6 — HARVEST
Mapping/adapter/quy đổi motion/giải pháp deviation mới → ghi ngược
`mapping-kb.md` (có ví dụ Swift↔Kotlin). KB lớn dần → app sau nhanh hơn.

---

## Bất biến cốt lõi (mỗi cái 1 nguồn canonical — đọc đúng file, không lặp)

- **Ledger = DoD nhị phân**: "xong" CHỈ khi `scripts/parity-status.sh` in
  `DONE`; agent cấm tuyên bố hoàn thành nếu chưa dán output → enforcement §1–2.
- **No-stop**: chưa DONE = không kết thúc lượt (5 ngoại lệ user-chặn duy
  nhất); dispatch async ≠ được dừng; context đầy → ghi ledger + CHẠY TIẾP
  cùng session → enforcement §3 (canonical) + orchestration §D3.
- **No-swarm, bounded subagents**: phiên chính tự đọc/port/build/verify; tối
  đa ~5–8 subagent việc độc lập; KHÔNG headless swarm/`claude -p`/fan-out
  40+; 1-writer ledger, 1-owner-1-file, serialize Gradle → orchestration §B
  (canonical).
- **WIP-LOCK per-worker**: mỗi worker chỉ 1 việc IN_PROGRESS, đóng rồi mới
  mở; cấm bỏ dở nhảy việc → enforcement §4 (canonical).
- **Anti-stub / anti-dup / element gate / section parity / adversarial ≥5 /
  perf parity / regression sweep / release gate / log gate** → enforcement
  §6/§10/§12/§11/§17/§18/§19/§20/§21.
- **8 vai** (MANAGER, UI-AUDITOR, SOURCE-ANALYST, FLOW-CHECKER, DEV-FE,
  DEV-FUNC, QA-RECONCILER, PERF-OPTIMIZER) → roles.md.
- **Token endurance + RESUME + brownfield intake** → orchestration §A/§D,
  enforcement §13. **Tech research chủ động** → orchestration §E.

## Quy tắc BẤT BIẾN (vi phạm = dừng, hỏi user)

1. KHÔNG port khi chưa có Parity Spec được user duyệt (stage 1).
2. KHÔNG đánh dấu done khi chưa qua cổng verify 3 lớp (stage 5).
3. KHÔNG sáng tạo/đổi/bỏ/thêm so với iOS. Lệch = Deviation có sign-off.
4. KHÔNG dùng giá trị "ước lượng" cho màu/đo/animation — lấy từ spec.
5. KHÔNG để Material3 default lọt ra UI — override token toàn bộ.
6. KHÔNG hardcode text (i18n) / secret. **File: 500 LOC = CẢNH BÁO** (dừng
   đánh giá theo rule #24.2: 1 nhóm chức năng → giữ + báo user; ≥2 nhóm → tách
   theo NHÓM CHỨC NĂNG), **800 LOC = trần cứng** (vượt phải user duyệt + ghi
   marker `s2a-loc-approved:` đầu file). CẤM tách chỉ để hạ con số.
7. KHÔNG tự commit/push/bump version mobile/tạo folder ngoài cấu trúc đã
   duyệt/cài dep mới khi user chưa yêu cầu rõ.
8. KHÔNG đọc ngoài 2 path user chỉ định (project isolation).
9. Nghi ngờ parity → DỪNG hỏi user, KHÔNG đoán.
10. NGHIÊM CẤM ngừng khi chưa hoàn thành (enforcement §3).
11. WIP-LOCK per-worker (enforcement §4).
12. FULL-SCROLL CAPTURE — cấm build page chưa cuộn hết trên iOS (enforce §5).
13. TEST-ENV ISOLATION — cấm parity test trên backend prod (measurement §5).
14. SOURCE PIN — spec gắn 1 git rev iOS; source đổi → re-sync (measurement §6).
15. REUSE-FIRST — cấm duplicate; tìm cái đã có trước khi viết mới
    (enforcement §10).
16. LOG BẮT BUỘC — mỗi vùng/màn/chức năng có log qua kênh chung, gác
    `BuildConfig.DEBUG`, không PII; chưa có log = chưa xong (enforcement §21).
17. DEVICE-PAIR — chỉ đo parity giữa iOS và Android CÙNG logical size
    (pt == dp). Lệch = mọi %diff/IoU vô hiệu (measurement §1.2).
18. RELEASE GATE — chưa build + smoke-test bản release/R8 thì chưa DONE
    (enforcement §20).

## Khởi động một lần port (khi `/ios2android` được gọi)

1. Đọc theo hàng đầu bảng LOAD-ON-DEMAND (`enforcement.md`,
   `orchestration.md`, 2 template) — KHÔNG nạp các file stage sau.
1b. **Dự án đã có sẵn?** Có `parity-spec.md` do skill tạo → RESUME
   (orchestration §A1). Có code Android KHÔNG do skill → BROWNFIELD INTAKE
   (enforcement §13): code cũ không tin, QA-RECONCILER rà toàn bộ đối chiếu
   iOS, lệch thì dựng lại.
2. Yêu cầu user dán **path tuyệt đối**: source iOS + folder Android đích
   (chỉ đọc/ghi 2 path này).
3. Xin user duyệt vị trí đặt `parity-spec.md` + `DEVIATIONS.md` +
   `s2a-manifest.md`; tạo từ template + **copy `checklists/` vào cạnh spec**
   (enforcement §2).
4. Stage -1 PREFLIGHT: `scripts/preflight.sh <iOS> <ANDROID> <manifest> pre`
   (khai `ios_ref_pt` + `android_device_dp` cùng logical size trong manifest
   trước khi chạy). RED → DỪNG báo user.
5. Chạy Stage 0→6 tuần tự; MANAGER tự làm theo vertical-slice, giao vài
   subagent (roles.md) cho việc độc lập + nặng; dừng ở từng verify gate báo
   user.
6. Vòng lặp tới khi `scripts/parity-status.sh` = `DONE`. Trước đó KHÔNG
   tuyên bố hoàn thành/bàn giao (enforcement §2–3).

## Benchmark (process compliance)

`benchmark/` chứa fixture app iOS mini + scorer máy-chấm để eval skill:
chạy `/ios2android` trên `benchmark/fixture-ios/` → `benchmark/score.sh <spec>
<android-root>` chấm coverage/sections/gate. Protocol + metrics xem
`benchmark/README.md`; tự kiểm scorer: `benchmark/selftest.sh`.
KHÔNG nạp folder benchmark/ khi port dự án thật.

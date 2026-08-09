# ENFORCEMENT — ép form cho agent, chống bỏ ngang & xong giả

> Lý do tồn tại: agent hay tự dừng khi chưa xong, nhảy việc, miss flow/chi
> tiết, tuyên bố "cơ bản đã xong". File này biến hoàn thành thành điều kiện
> NHỊ PHÂN kiểm tra được bằng máy, không do agent tự phán.

## 0. PARITY CONTRACT — chi tiết 3 trụ (chuẩn để spec + verify)

> SKILL.md §0 giữ định nghĩa + bảng tolerance. Dưới đây là danh mục chi tiết
> từng trụ — spec/verify soi theo đây để không bỏ sót hạng mục.

### Trụ 1 — Visual parity (nhìn giống) — mọi state của mọi màn
- **Layout**: thứ tự, vị trí, kích thước, spacing, alignment, padding/margin,
  safe-area, z-order — sai số ≤ 2dp so với spec.
- **Color**: mọi màu (background, text, border, shadow, gradient stop, overlay
  alpha) khớp đúng hex/alpha. Sai số 0.
- **Typography**: font family, size, weight, letter-spacing, line-height,
  text-case, truncation, số dòng. iOS dùng SF Pro → font metric-tương-đương
  (`mapping-kb.md §Typography`) hoặc ghi Deviation.
- **Iconography & asset**: cùng icon, kích thước, tint, asset ảnh (export lại
  từ asset catalog iOS, KHÔNG vẽ lại — `mapping-kb.md §Asset`).
- **Theme**: light + dark + high-contrast + dynamic type khớp từng biến thể.
- **State**: default / pressed / focused / disabled / loading / empty / error /
  selected — mỗi state có ảnh tham chiếu iOS và phải khớp.

### Trụ 2 — Behavioral parity (làm giống)
- **Mọi chức năng** trong iOS phải tồn tại trong Android, hành vi giống hệt.
- **State machine** mỗi màn: cùng input → cùng transition → cùng output.
- **Validation**: cùng quy tắc, cùng thông báo lỗi, cùng thời điểm hiện lỗi.
- **Edge cases**: rỗng / offline / lỗi mạng / token hết hạn / quyền bị từ
  chối / dữ liệu lớn / ký tự đặc biệt — xử lý y hệt iOS.
- **Persistence**: cùng dữ liệu lưu, cùng key, cùng vòng đời, cùng kết quả khi
  cold start / kill app / mất mạng.
- **Navigation graph**: cùng số màn, thứ tự, back-stack, deep link, kết quả
  nút back.
- **Platform-equivalent service**: chức năng dựa dịch vụ độc quyền Apple
  (Sign in with Apple/iCloud, CloudKit, APNs, Apple Pay, StoreKit, MapKit,
  HealthKit…) → KHÔNG tái hiện provider Apple (bất khả thi + vi phạm Play) mà
  map sang dịch vụ Android-native tương đương, giữ NGUYÊN vai trò/hành vi
  (cùng input → cùng KẾT QUẢ: đăng nhập được/đồng bộ được/mua được, KHÔNG cần
  giống pixel provider). Mỗi swap = Deviation `MANDATORY`. Bảng + quy trình
  canonical: `mapping-kb.md §Platform-Equivalent`.

### Trụ 3 — Perceptual parity (cảm giác giống)
- **Animation**: cùng duration (ms), easing curve / spring (mass, stiffness,
  damping), delay, thứ tự stagger, thuộc tính được animate.
- **Transition màn**: cùng kiểu (push/modal/fade/sheet), hướng, thời lượng,
  interactive-dismiss nếu có.
- **Gesture**: tap / long-press / swipe / drag / pinch / pan — cùng ngưỡng,
  phản hồi, vùng hit-test.
- **Haptics**: mỗi rung iOS map sang Android tương đương gần nhất
  (`mapping-kb.md §Haptics`), ghi vào KB.
- **Âm thanh / scroll physics / focus order**: khớp.

### Deviation Register — sự thật về giới hạn nền tảng
"100%" tuyệt đối KHÔNG khả thi cho phần OS-chrome (SF Pro vs Roboto, system
back gesture, status bar, scroll rubber-band vs stretch glow, ripple, share
sheet, picker wheel, switch look, alert dialog…). KHÔNG được im lặng để nó khác:
1. Mọi điểm không thể giống 100% → ghi vào `DEVIATIONS.md` của dự án:
   `[ID] | hạng mục | iOS behavior | Android constraint | phương án (replicate
   custom / accept platform norm) | trạng thái duyệt`.
2. Mặc định **ưu tiên replicate** bằng custom Compose component (dựng lại
   iOS-style switch, segmented control, alert, picker, bounce scroll) khi user
   muốn parity tuyệt đối.
3. Item chọn "accept platform norm" → PHẢI có user sign-off trước khi port.
4. KHÔNG Deviation nào được tự ý quyết — Claude đề xuất, user duyệt.
5. **Platform-equivalent swap** = loại `MANDATORY`: bắt buộc kỹ thuật/chính
   sách nên KHÔNG cần xin phép TỪNG cái, NHƯNG phải liệt kê ĐỦ trong
   `DEVIATIONS.md` + giữ behavioral parity. Provider ngoài bảng KB → đề xuất,
   ghi KB; tính năng cốt lõi không có tương đương (Handoff…) → hỏi user.

## 1. Completeness Ledger — nguồn sự thật của "xong"

Mỗi đơn vị công việc = 1 dòng trong `ledger` (phần trong `parity-spec.md`):
mọi screen, mọi component tái sử dụng, mọi function, mọi flow, mọi animation,
mọi gesture, mọi adapter API, mọi nhóm string.

Cột bắt buộc mỗi dòng (1 dòng = 1 đơn vị việc nhỏ độc lập):
```
ID | loại | tên | iOS source (file:line) | dep | trạng thái | bằng chứng | agent | ts
```
- `dep` = danh sách ID việc phải VERIFIED trước (dep gate). Rỗng = việc nền
  (token/adapter/platform-equivalent). Việc con CẤM port khi dep chưa VERIFIED.
- `agent` = ai đang giữ việc (MANAGER hoặc 1 subagent); 1 việc = 1 owner.
Trạng thái hợp lệ (chỉ tiến, không lùi trừ khi FAIL/RECHECK):
`NOT_STARTED → SPECD → IN_PROGRESS → PORTED → VERIFIED` (hoặc `FAIL`).
`RECHECK` = đã VERIFIED nhưng một nền dùng chung (token/shared/adapter) bị
sửa → phải verify lại (regression sweep §19); `parity-status.sh` coi RECHECK
như chưa VERIFIED.

- `VERIFIED` CHỈ được đặt khi cột **bằng chứng** có: đường dẫn ảnh visual-diff
  đạt tolerance + kết quả test pass + dòng checklist tương ứng đã tick. Không
  bằng chứng = không được VERIFIED (dù code trông xong).
- `FAIL` phải kèm lý do; quay lại `IN_PROGRESS`, KHÔNG bỏ qua.

## 2. Definition of Done — nhị phân, do script quyết

`scripts/parity-status.sh <spec> <android> [--fast]` đọc ledger + chạy
`verify.sh --full` + soi checklist/deviation, in đúng 1 trong 2:
- `DONE` ⇔ (0 dòng ledger ≠ VERIFIED, RECHECK tính là chưa) ∧ (0 dòng VERIFIED
  thiếu **bằng chứng**; dòng loại screen/section phải có chuỗi đo `%=`/`IoU=`)
  ∧ (assembleDebug + test + **assembleRelease/R8** pass) ∧ (mọi checklist đã
  ký) ∧ (0 file > 800 LOC không có `s2a-loc-approved`) ∧ (0 TODO/stub) ∧ (0
  log rời rạc) ∧ (`DEVIATIONS.md` tồn tại, 0 dòng chờ duyệt).
- `NOT DONE: <đếm> dòng chưa VERIFIED | <chi tiết>`.
- `--fast` bỏ qua build để soi ledger nhanh giữa các nhịp — **KHÔNG BAO GIỜ**
  in `DONE`; chốt DONE phải chạy bản đầy đủ.

**File-size (đồng bộ rule #24)**: 500 LOC = **cảnh báo bắt buộc đánh giá** (1
nhóm chức năng → GIỮ + báo user số LOC; ≥2 nhóm → tách theo NHÓM CHỨC NĂNG),
800 LOC = **trần cứng** (vượt cần user duyệt, ghi `s2a-loc-approved: <lý do>`
trong 5 dòng đầu file). CẤM tách chỉ để hạ con số — tách sai phá đóng gói.

**Cơ chế "mọi checklist đã ký"**: Stage 1 PHẢI **copy folder `checklists/` của
skill vào cạnh `parity-spec.md` trong project Android** (thành
`<dirname spec>/checklists/`), rồi tick dần `- [ ]` → `- [x]` khi verify từng
mục. `parity-status.sh` gate trên bản COPY đó (KHÔNG grep template của skill —
template luôn đầy ô trống). Thiếu folder copy = `NOT DONE: chưa copy
checklists`; còn ô `- [ ]` = `NOT DONE: còn ô checklist chưa ký`.

Agent **CẤM** tuyên bố hoàn thành/bàn giao nếu chưa dán output `DONE` của
script này trong lượt trả lời. "Tôi nghĩ đã xong" không có giá trị.

## 3. No-stop protocol — cấm dừng khi chưa DONE

Khi `parity-status.sh` ≠ `DONE`, agent **KHÔNG được kết thúc lượt**. Phải tiếp
tục lấy dòng ledger chưa xong kế tiếp và làm.

Ngoại lệ DUY NHẤT được dừng (đều là "bị user chặn"):
1. Cần quyết định Deviation/sign-off của user.
2. Phát hiện secret cần user xử lý (quy tắc không-commit-secrets).
3. Thao tác destructive / commit/push / cài dependency / tạo folder — đều
   cần user duyệt trước (quy tắc không tự commit-push, không tự tạo folder,
   không tự cài dep, không destructive shell).
4. Thiếu input bắt buộc (path source, ảnh tham chiếu iOS).
5. Mơ hồ parity thật sự không tự giải được (nguyên tắc hỏi-trước-khi-đoán).

Mọi lý do khác để dừng đều BỊ CẤM, đặc biệt:
- "Cơ bản đã hoàn thiện" / "phần còn lại tương tự" / "có thể bổ sung sau"
- "Đã làm rất nhiều" / "tổng kết bàn giao" khi ledger còn dòng chưa VERIFIED
- Hết ý tưởng → phải nghiên cứu (TECH RESEARCH — orchestration.md §E), KHÔNG dừng
- Sắp hết context → cập nhật ledger (lưới an toàn) và **TIẾP TỤC ngay trong
  CÙNG session**, KHÔNG "bàn giao" nửa vời, KHÔNG bắt user mở session mới / gõ
  lại `/ios2android`. Harness tự nén context để chạy tiếp (orchestration §D3).
  Ledger là lưới đỡ NẾU session chết thật; KHÔNG phải cái cớ để tự thay phiên.

### 3.1 Dispatch async ≠ được dừng (BỊT KẼ HỞ "Đang chờ — tự đánh thức")

Giao việc cho background/sub-agent rồi **idle/ngủ/đợi đánh thức/bàn giao** =
DỪNG TRÁ HÌNH = BỊ CẤM khi `parity-status.sh` ≠ DONE.
Khi đã spawn background/QA agent, orchestrator PHẢI làm 1 trong 2, KHÔNG idle:
1. **Tiếp tục dòng ledger ĐỘC LẬP khác** ngay (song song — không chờ); HOẶC
2. Nếu thật sự MỌI dòng còn lại đều phụ thuộc agent đang chạy: **active
   monitor loop** (poll trạng thái bằng Monitor/until-loop, đọc kết quả NGAY
   khi xong rồi tiếp), KHÔNG phát thông điệp "Đang chờ / tự đánh thức / tổng
   kết / bàn giao" rồi kết thúc lượt.
Cụm từ CẤM khi chưa DONE: "Đang chờ", "tự đánh thức", "chờ — tự đánh thức",
"tổng kết bàn giao", "Đã làm nhiều". Hết việc song song + agent vẫn chạy →
monitor, KHÔNG nghỉ. Chỉ thật sự dừng ở 5 ngoại lệ §3 (user chặn).

### 3.2 CẤM breadth-trong-1-agent — chia việc trọn vẹn, có giới hạn

Phân biệt 2 thứ KHÁC nhau:
- **CẤM (breadth nửa vời trong 1 agent)**: 1 agent ôm task "Breadth port
  F07–F49", quét rộng nhiều thứ mỗi thứ làm dở dang rồi "quay lại sau" = sinh
  "xong giả". Mỗi agent CHỈ ôm 1 việc, làm trọn (đến VERIFIED) rồi mới việc kế.
- **ĐÚNG**: mặc định MANAGER tự làm từng flow vertical-slice. Khi đủ việc ĐỘC
  LẬP thật sự → giao **tối đa ~5–8 subagent** (orchestration §B), **mỗi subagent
  1 việc, làm trọn vẹn** (spec/port-file/motion/test→verify). Vài subagent chạy
  cùng lúc là ĐÚNG; cái sai là 1 agent làm dở nhiều việc.
- **CẤM**: headless swarm, `claude -p` loop, fan-out 40+ — sinh lệnh cho tiến
  trình khác chạy thay vì tự làm, đốt token mà không build ra app.
Vertical-slice luôn áp: mỗi việc đi trọn tới bằng chứng, KHÔNG để placeholder
"bổ sung sau" (anti-stub §6).

## 4. WIP-LOCK — khoá một việc **mỗi worker** (KHÔNG serialize toàn job)

WIP-LOCK là ràng buộc **per-worker**, KHÔNG phải khoá toàn dự án về 1 việc.
Khi MANAGER giao vài subagent song song (orchestration §B, tối đa ~5–8) — mỗi
worker (MANAGER hoặc subagent) vẫn bị WIP-LOCK cho riêng nó:

- **Mỗi worker/agent** tại mọi thời điểm chỉ giữ **đúng 1 việc `IN_PROGRESS`**
  (claim qua cột `agent`). Làm DỨT ĐIỂM việc đó (VERIFIED hoặc trả FAIL/
  blocker) mới được claim việc kế.
- NGHIÊM CẤM 1 worker mở việc mới khi việc `IN_PROGRESS` của CHÍNH NÓ chưa
  đóng. NGHIÊM CẤM bỏ dở việc giữa chừng để nhảy việc khác.
- **Song song hợp lệ**: vài worker cùng chạy, mỗi worker 1 việc độc lập
  (file/function khác nhau, 1-owner §8). Đây KHÔNG vi phạm WIP-LOCK — vì mỗi
  worker vẫn chỉ ôm 1 việc. Cấm là "1 worker ôm nhiều việc dang dở", KHÔNG
  phải "vài worker chạy".
- Việc con CHỜ việc cha `VERIFIED` (dep gate) — không port lên nền chưa xong.
- Nếu bị chặn (mục §3) ở việc đang làm: để `IN_PROGRESS` + ghi blocker, worker
  đó exit; KHÔNG mở việc khác để "làm tạm cho có tiến độ". Worker KHÁC vẫn
  chạy việc độc lập của nó bình thường.

## 5. FULL-SCROLL CAPTURE — phải thấy toàn bộ page mới build

Trước khi `SPECD`/build một page:
- Cuộn HẾT nội dung scrollable trên iOS: đỉnh → đáy, mọi section dưới fold,
  mọi nội dung lazy/expand/accordion mở ra, mọi tab con trong page.
- Chụp/ghi đủ: ảnh nối toàn trang (không chỉ viewport đầu), mọi state.
- Spec page phải liệt kê 100% section. Thiếu section dưới fold = SPEC FAIL =
  cấm chuyển PORTED.
- Kiểm chứng: số section trong spec ≥ số section đếm khi cuộn tay; reviewer
  tick "đã xem toàn trang".

## 6. Anti-stub / Anti-xong-giả

Tự động coi là `FAIL`, KHÔNG được VERIFIED, nếu phát hiện trong code Android:
- `TODO`, `FIXME`, `XXX`, `// implement`, `// later`, `notImplemented()`
- `Text("TODO")`, màn rỗng, `Box {}` thay nội dung thật
- Hàm trả mock/hardcode để "qua compile"
- Bắt exception nuốt im (`catch {}` rỗng) khác hành vi iOS
- Animation bỏ trống / `Modifier` placeholder
`scripts/parity-status.sh` grep các pattern này → có = `NOT DONE`.

## 7. So sánh từng chi tiết — Detail Diff Table bắt buộc

Mỗi page có bảng (trong `parity-spec.md`): mỗi phần tử UI × mỗi thuộc tính
(x,y,w,h,padding,spacing,radius,border,shadow,bg,fg,fontFamily,fontSize,
weight,letterSpacing,lineHeight,opacity,animation duration,curve/spring,
gesture threshold,haptic,transition). Mỗi ô: `iOS | Android | PASS|Δ=...`.
- Δ vượt tolerance §0 SKILL.md = FAIL dòng đó.
- CẤM kết luận parity bằng cảm quan ("trông giống"). Phải có số.

## 8. Multi-agent contract

Khi chia nhiều agent/phiên (kể cả subagent):
- Hợp đồng chung = `parity-spec.md` (ledger + spec) + `DEVIATIONS.md`.
- Vào việc: đọc ledger, chọn dòng `NOT_STARTED`/`FAIL`/blocker đã mở, set
  `IN_PROGRESS` (tôn trọng §4: nếu đã có dòng IN_PROGRESS của agent khác chưa
  đóng → KHÔNG mở song song page khác cùng phạm vi).
- Rời việc: cập nhật trạng thái + bằng chứng nguyên tử. CẤM để dòng lửng.
- CẤM agent tự định nghĩa lại scope, tự thêm/bớt dòng ledger ngoài Parity
  Spec đã duyệt, tự đánh VERIFIED không bằng chứng.
- Mọi agent đều bị ràng buộc y hệt file này — không agent nào được "nới".

## 9. Self-check loop (sau mỗi flow/page)

```
while parity-status.sh != DONE cho phạm vi đang làm:
    chạy verify (gradle + test + visual diff + walkthrough)
    nếu ĐỎ: đọc lỗi → sửa → cập nhật ledger → lặp
    nếu bị chặn (mục §3): ghi blocker, báo user, CHỜ
KHÔNG thoát loop bằng cách hạ tiêu chuẩn hay đổi việc.
```

Agent phải dán output verify mỗi vòng để chứng minh không "tự nhận xong".

## 10. Anti-duplicate (REUSE-FIRST — SKILL.md bất biến #15)

Trước khi tạo component/hàm/util/adapter/style/extension:
1. **Tìm trước**: Shared-Component ledger (parity-spec §3.1) → `mapping-kb.md
   §Adapters` → grep code Android đã port → dep có sẵn repo.
2. Có sẵn → tái dùng/mở rộng (thêm param/biến thể), KHÔNG copy-paste bản 2.
3. Phát hiện ≥2 đoạn code trùng chức năng = `FAIL`: gộp về 1 nguồn, sửa các
   nơi gọi, mới được VERIFIED.
4. Component mới mà QA thấy đã có tương đương → trả việc DEV gộp lại.
QA-RECONCILER quét trùng lặp như quét bug; DEV chịu trách nhiệm search-first.
Mục tiêu: 1 trách nhiệm = 1 nơi (DRY), không phình code, không lệch parity do
tồn tại nhiều bản khác nhau.

## 11. Section / feature-system parity (chống mất/đảo cả khối)

Lỗi điển hình: Android **mất hẳn 1 section** (1 khối/hero/sub-system) hoặc đảo
thứ tự khối → KHÔNG được phép.
1. Mỗi page PHẢI có **Screen Composition Manifest** (parity-spec §5.x): danh
   sách 100% khối top→bottom, mỗi khối 1 dòng ledger.
2. **GATE TRƯỚC attribute-diff**: `count(section_iOS) == count(section_Android)`
   **và** thứ tự khớp 1:1. Sai → `FAIL`, KHÔNG được chấm Detail Diff hay
   VERIFIED. Phải đủ khối, đúng thứ tự rồi mới so từng thuộc tính.
3. Mọi **sub-system** (achievements/streak/record/gamification/đếm số…) là
   feature riêng → dòng ledger riêng, port ĐỦ; bỏ = `FAIL` (= anti-stub §6).
4. QA-RECONCILER kiểm manifest đầu tiên mỗi page; thiếu/thừa/đảo 1 khối là
   bug chặn, trả DEV ngay, KHÔNG nương.
Khối ẩn/không-test-được (parity-spec §10) cũng tính là khối phải có đủ.

## 12. Element gate + bằng chứng visual-diff (chống "phác thảo thô")

Lỗi điển hình: Android dựng form trơ, bỏ card-wrapper/hero/nút phụ/icon →
trống huơ so iOS. Cơ chế cứng:
1. **Ảnh iOS là SPEC để build, KHÔNG tái tưởng tượng tính năng.** DEV build
   bằng cách tô lại từng widget trên ảnh iOS (parity-spec §5.x Element
   Inventory), KHÔNG tự nghĩ "màn này nên có gì".
2. **ELEMENT GATE**: DEV BỊ CẤM chuyển dòng sang `PORTED` khi Element
   Inventory màn đó chưa liệt kê đủ + chưa map 1:1 sang widget Android. Thiếu
   1 widget (card/helper/nút phụ/toggle/icon) = `FAIL`.
3. **BẰNG CHỨNG BẮT BUỘC để VERIFIED**: dòng ledger màn CHỈ được `VERIFIED`
   khi cột bằng chứng có chuỗi `parity-diff %=<n> ≤ tol` cho **MỌI state**
   (chạy `scripts/parity-diff.sh`, measurement.md §1) + ảnh diff đính kèm.
   QA-RECONCILER **từ chối** mọi dòng thiếu chuỗi này — KHÔNG ngoại lệ, không
   "nhìn thấy ổn". Không bằng chứng = chưa xong.
4. **Heuristic mật độ**: vùng trống lớn bất thường so ảnh iOS (mất card/khung)
   = dấu hiệu thiếu widget → QA mở FAIL ngay, không cần đo.
5. Header/nav cũng là element: sai kiểu tiêu đề (large-title vs bold nhỏ) =
   FAIL trừ khi đã ghi DEVIATIONS có user duyệt.
QA kiểm theo thứ tự: Composition (§11) → Element Inventory đủ → parity-diff
mọi state ≤ tol → Detail Diff thuộc tính. Trượt bước nào, dừng ở đó.

## 13. BROWNFIELD INTAKE — code có sẵn KHÔNG được tin (mọi dự án)

Khi skill chạy trên dự án Android ĐÃ có code (do agent/người khác làm trước,
hoặc phiên trước KHÔNG dùng skill): **sự tồn tại ≠ đúng**.
1. KHÔNG dòng nào được kế thừa trạng thái `VERIFIED`/“done” từ công việc cũ.
   Mọi screen/flow/element/section dựng ledger ở `NOT_STARTED` (hoặc `AUDIT`).
2. Phân biệt rõ:
   - Có `parity-spec.md` do CHÍNH skill tạo phiên trước → RESUME ledger
     (orchestration §A1): nối trạng thái đã có bằng chứng.
   - KHÔNG có ledger của skill / code lạ → **INTAKE AUDIT**: dựng spec từ
     SỰ THẬT iOS trước, rồi audit từng phần code cũ đối chiếu iOS.
3. Code Android cũ chỉ là “đối chứng”, KHÔNG phải nguồn sự thật. Nguồn sự
   thật DUY NHẤT = iOS (spec). Cấm port theo code Android cũ.
4. Mỗi phần cũ PHẢI qua đủ chuỗi verify (§11 → §12 → parity-diff → Detail
   Diff) y như làm mới. Đạt parity → giữ/sửa tại chỗ; lệch → dựng lại. CẤM
   bỏ qua vì “đã làm rồi / trông cũng tạm”.
5. QA-RECONCILER là agent rà soát chuyên trách: quét TOÀN BỘ màn/flow hiện
   có, lập danh sách lệch, trả DEV sửa tới khi giống iOS. Không màn nào được
   miễn audit.
Áp dụng MỌI dự án, không riêng dự án nào.

## 14. Layout / căn lề / safe-area là parity hạng nhất

Đúng widget nhưng SAI vị trí/lề/inset = vẫn FAIL. Không chỉ "có đủ element".
1. **Safe-area bắt buộc**: content KHÔNG chạm status bar/notch/home-indicator
   nếu iOS có khoảng cách. Thiếu top/bottom inset (vd hero đẩy sát đỉnh) =
   FAIL ngay, không cần đo (heuristic mắt thường QA bắt được).
2. **Anchor dọc**: Y của mỗi khối top-level (hero/title/card/button/tab bar)
   phải khớp iOS ≤ tolerance §0 (≤2dp), đo theo measurement §3.1. "Bị cao/
   thấp/dồn/giãn" so iOS = FAIL.
3. **Box model**: padding/margin/gap/alignment/size mỗi element lấy từ source
   iOS, điền Detail Diff loại `layout`. Bỏ trống cột layout = chưa verify.
4. KHÔNG dùng default spacing Material/Compose thay số đo iOS (= bất biến #5).
QA chèn bước này vào chuỗi §12: Composition → Element Inventory → **Layout/
anchor/safe-area** → parity-diff mọi state → Detail Diff. Trượt đâu dừng đó.

## 15. GATED/VIP — source-derived, không bỏ, không đoán

Tính năng VIP/premium/subscription/role: KHÔNG có tài khoản VIP demo →
KHÔNG quan sát được UI mở khoá. CẤM bỏ qua, CẤM đoán.
1. SOURCE-ANALYST dựng ĐỦ từ source: điều kiện gate + state khoá + MỌI màn
   VIP (Composition/Element/Layout từ source+asset) + flow mua/khôi phục +
   entitlement contract → parity-spec §10.1. Mỗi màn VIP = dòng ledger riêng.
2. Verify bằng **mock/debug-override entitlement** (locked/unlocked,
   measurement §4) — KHÔNG mua thật, KHÔNG prod (bất biến #13) — để render & parity-
   diff UI mở khoá ở CẢ iOS lẫn Android.
3. iOS không ép được trạng thái → đối chiếu code-flow tương đương + asset
   thiết kế, ghi DEVIATION lý do (user duyệt).
4. Thiếu/đoán 1 màn-VIP hoặc bỏ vì "không vào được" = FAIL (= anti-stub §6).

## 16. MOTION PER-LAYER — ảnh tĩnh KHÔNG thấy hiệu ứng → soi SOURCE

Agent chụp ảnh iOS = tĩnh, KHÔNG thấy animation/effect. Bắt buộc:
1. Với MỖI element trong Element Inventory (§ parity-spec 5.x): **đối chiếu
   source layer đó** xem có motion không — `.animation/withAnimation/
   .transition/.matchedGeometryEffect/TimelineView/repeatForever`, implicit
   animation, `CA*Animation`, gesture-driven, appear/disappear, shimmer/
   pulse/blur/particle, loading/skeleton, state-change transition.
2. Lập **Motion Inventory** (parity-spec §5.x Animation): mỗi motion = 1 dòng
   — element, trigger, thuộc tính, từ→đến, duration, curve/spring (đọc literal
   source, KB §Motion), delay/stagger/repeat. Element "không có motion" cũng
   ghi rõ "none" (đã soi, không bỏ sót).
3. Mỗi motion → port Android tương ứng + đo xác nhận trên record
   (measurement §2), Δduration ≤ §0. Không có Motion Inventory cho 1 màn =
   chưa VERIFIED. Bỏ sót effect (vì chỉ nhìn ảnh) = FAIL.
QA chuỗi (cập nhật §14): … → Layout → **Motion Inventory đủ + đo khớp** →
parity-diff → Detail Diff.

## 17. Adversarial review (chống "trông ổn" → tự nhận xong sớm)

Trước khi đề nghị VERIFIED mỗi màn, QA-RECONCILER PHẢI **chủ động liệt kê
≥5 điểm khác biệt cụ thể** so iOS (kèm bằng chứng: tọa độ/đo/ảnh). CẤM kết
luận bằng "trông giống/ổn".
- Tìm đủ ≥5 → mở FAIL, trả DEV; lặp tới khi hết.
- Thật sự < 5 sau khi đã đối chiếu ĐỦ Composition+Element+Layout+Motion
  inventory & parity-diff/IoU xanh → ghi rõ "đã soi X mục, còn N khác biệt,
  đã xử lý" làm bằng chứng. KHÔNG được nói "không thấy gì".
- Determinize trước (measurement §1.0) để khác biệt là thật, không do nhiễu.
Mục tiêu: ép nhìn kỹ hơn ngưỡng "đủ dùng" — đúng bệnh các defect đã gặp.

## 18. PERF PARITY là gate (chống "đơ/lag", vai PERF-OPTIMIZER §8)

App build ra mượt như iOS hay không = một trụ parity (Trụ 3 + standards
§4.1), KHÔNG phải "xong thì thôi".
1. PERF-OPTIMIZER profile build (số thật: cold start `am start -W`, jank
   `gfxinfo framestats`/Macrobenchmark, recomposition, main-thread block,
   leak). KHÔNG cảm tính.
2. **Ngưỡng FAIL**: cold start Android > iOS+20%; jank-frame vượt target màn;
   ANR/leak; recomposition storm. Lag rõ hơn iOS = FAIL, mở dòng `perf:`.
3. **Bằng chứng trước→sau bắt buộc** để đóng dòng perf: số đo cải thiện đạt
   ngưỡng + QA tái kiểm KHÔNG lệch parity (tối ưu không được làm khác iOS).
   "Thấy mượt hơn" = không tính (= anti-stub §6 cho perf).
4. **Không đổ oan**: lag do máy/Gradle Kotlin daemon quá tải (lỗi/treo GIẢ)
   ≠ lag runtime — verify lại trước khi mở dòng perf hay trách agent
   (Kotlin/Gradle daemon quá tải sinh lỗi GIẢ kiểu "Unresolved reference").
5. PERF-OPTIMIZER đọc-only + phân việc qua MANAGER; chỉ DEV sửa, chỉ QA
   VERIFIED. Ghi ledger 1 writer (lost update khi nhiều tiến trình ghi cùng một file trạng thái).
QA chuỗi: … → parity-diff → Detail Diff → **perf parity (PERF-OPTIMIZER)**.
Flow chưa đạt perf parity = chưa DONE.

## 19. REGRESSION SWEEP — sửa nền dùng chung → verify lại consumer

Đạt parity 1 lần KHÔNG khoá được parity mãi: sửa 1 token/Shared Component/
adapter/string dùng nhiều nơi rất dễ phá thầm màn đã VERIFIED.
1. Khi đụng 1 dòng ledger là **nền dùng chung** (token/shared/adapter/string-
   group — có ≥1 dòng khác `dep` trỏ tới nó): mọi dòng CONSUMER (theo cột `dep`)
   tự động hạ về `RECHECK`. MANAGER lập danh sách consumer trước khi sửa.
2. Dòng `RECHECK` PHẢI chạy lại parity-diff + onion-skin (measurement §1.1) +
   Detail Diff vùng bị ảnh hưởng TRƯỚC khi trở lại VERIFIED. `parity-status.sh`
   coi RECHECK = chưa VERIFIED ⇒ chưa DONE.
3. **Baseline regression** (measurement §8): nếu có Roborazzi/Paparazzi, test
   ảnh đỏ = regression, sửa tới xanh. CẤM cập nhật baseline để "qua test" khi
   chưa đối chiếu lại iOS (oracle) — đó là che lỗi.
4. CẤM lý luận "chỉ sửa token nhỏ, màn khác chắc không sao" — phải verify, có
   bằng chứng. Đây đúng tinh thần "luôn rà soát kỹ lỗi để mọi thứ chính xác".

## 20. RELEASE GATE — "Debug chạy, Release KHÔNG" (rule #34)

Cả pipeline verify chạy trên `assembleDebug` ⇒ mù hoàn toàn với lớp lỗi CHỈ
xuất hiện ở release. Bệnh đã trả giá nhiều lần: R8/minify strip metadata
reflection → `kotlinx.serialization`/Gson/Room chết; resource shrink xoá asset
đang dùng; `BuildConfig.DEBUG` bypass gate ở debug nhưng release thì không.
1. `scripts/verify.sh <app> --full` (parity-status luôn gọi bản `--full`) phải
   pass `assembleRelease`. Đỏ = chưa DONE, không ngoại lệ.
2. **Cài + smoke-test bản release thật** trên emulator/máy (mở app, đi hết flow
   đã VERIFIED, xem log crash `adb logcat`) TRƯỚC khi đóng DONE. Bằng chứng =
   1 dòng ledger `release: <flow> ok` + log.
3. Dùng reflection/serialization → phải có keep-rule R8 tương ứng. CẤM tắt
   minify để "cho qua" (đó là giấu bệnh, không phải sửa).
4. Gate/entitlement/attest chỉ bật ở release → verify riêng: client vẫn GỬI
   request khi token chưa sẵn (fail-open-send), KHÔNG throw trước khi gửi.

## 21. LOG GATE — chưa có log = việc CHƯA XONG (rule #37)

Bug lúc thương mại hoá phần lớn không tái hiện trên máy dev; không log thì mỗi
lần truy lỗi là một vòng đoán mò. Vì vậy log là **một phần của Definition of
Done**, không phải việc dọn sau:
1. Mỗi màn / vùng / scroll / nhánh quyết định / lỗi bắt được đều có log, ĐẶT
   CÙNG LÚC với code (không commit sau).
2. Đi qua **kênh log chung** (vd `AppLog.<module>`/Timber tree), gác
   `BuildConfig.DEBUG`, message truyền lambda để release không dựng chuỗi.
   CẤM `Log.d`/`println`/`System.out` rời rạc — `verify.sh` §3a chặn cứng.
3. CẤM log PII: chỉ id rút gọn 6 ký tự, mã trạng thái, số lượng, nhánh quyết
   định, thời gian.
4. Parity: chỗ nào iOS có log (`os_log`/`DLog`) thì Android có log tương ứng
   cùng ngữ nghĩa — đây cũng là một dòng Detail Diff loại `log`.
5. QA từ chối VERIFIED một màn không có log (giống thiếu Motion Inventory).

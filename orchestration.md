# ORCHESTRATION — chống full-token + chia việc có kỷ luật

> Mục tiêu: job port dài KHÔNG mất việc khi 1 session đầy token, và chia việc
> hợp lý để nhanh mà KHÔNG đốt token vô ích. Nền tảng: state bền = Ledger trong
> `parity-spec.md` (enforcement.md). Context chết ≠ việc mất.
>
> ⚠ KHÔNG có headless swarm, KHÔNG `claude -p` loop, KHÔNG tmux pane, KHÔNG
> "fan-out 40+ agent". Mô hình đó đã bị gỡ bỏ: nó sinh lệnh để các tiến trình
> khác chạy thay vì TỰ LÀM, ngốn token mà không build ra app. Skill này **tự
> đọc, tự port, tự build, tự verify** — và CHỈ giao cho vài subagent có giới
> hạn khi việc thật sự độc lập + nặng.

## A1. RESUME PROTOCOL (safety-net — chỉ khi session cũ CHẾT/đứt thật)

> ⚠ RESUME KHÔNG phải quy trình thường. Session đang sống mà context đầy →
> harness tự nén để chạy tiếp (§D3), KHÔNG tự thay phiên. RESUME chỉ kích hoạt
> khi session trước bị KILL thật (máy crash, user đóng app, đứt mạng) hoặc user
> chủ động mở phiên mới. KHÔNG bao giờ tự DỪNG để ép vào nhánh này khi chưa DONE.

Khi `/ios2android` được gọi mà dự án đã có `parity-spec.md`:
1. KHÔNG bắt đầu lại từ đầu. Đọc `parity-spec.md` (Ledger §4, Flow Inventory
   §3, Structure Map §1) + `DEVIATIONS.md` + manifest.
2. Chạy `scripts/parity-status.sh <spec> <android>` → biết còn gì. Kiểm
   folder `checklists/` cạnh spec (bản copy — enforcement §2); thiếu → copy
   từ skill trước khi tiếp.
3. Đọc các dòng ledger trạng thái `IN_PROGRESS`/`FAIL`/blocker → đó là điểm
   nối. Tôn trọng WIP-LOCK: đóng dòng IN_PROGRESS dở trước, rồi mới mở mới.
4. Kiểm SOURCE PIN (bất biến #14): `git -C <ios> rev-parse HEAD` so manifest `ios_rev`.
   Lệch → re-sync (measurement.md §6) trước khi tiếp.
5. Tiếp tục Stage đang dở. KHÔNG tuyên bố xong tới khi `parity-status.sh`=DONE.

**Nhánh BROWNFIELD** (có code Android nhưng KHÔNG có `parity-spec.md` do skill
tạo — code do agent/người khác làm trước): KHÔNG resume kiểu trên, KHÔNG tin
code cũ. Chạy INTAKE AUDIT (enforcement §13): dựng spec từ sự thật iOS →
ledger toàn bộ ở `NOT_STARTED` → rà từng màn/flow đối chiếu iOS → lệch thì
dựng lại. Không màn nào miễn audit vì "đã làm rồi".

→ Quy tắc: mọi tiến độ phải được ghi ledger NGAY khi đạt (không "để nhớ trong
đầu"). Ledger là bộ nhớ duy nhất qua các phiên.

## A2. ORCHESTRATOR-GỌN (cốt lõi tiết kiệm token, KHÔNG né việc)

MANAGER = phiên chính. MANAGER **tự làm việc thật** (đọc source, port Kotlin,
chạy `gradle`, chạy verify, đo diff) — đây là điểm khác biệt cốt lõi: skill này
KHÔNG sinh lệnh cho tiến trình khác chạy, nó tự build app.

Để sống lâu qua nhiều phiên mà không phình context:
- Việc NẶNG + ĐỘC LẬP + đọc-nhiều (vd quét toàn bộ source 1 màn để dựng spec,
  port 1 file tách biệt) → CÓ THỂ giao cho **subagent qua Agent tool** (context
  cô lập, chỉ summary quay về → cha không phình). Subagent **thực sự làm việc**
  và trả kết quả; MANAGER tổng hợp.
- MANAGER giữ mỏng: Ledger state + kết luận gate + điều phối. Sau mỗi vòng:
  ghi ledger, **quên chi tiết** (chi tiết nằm ở spec + transcript subagent).
- Subagent KHÔNG spawn subagent (giới hạn 1 tầng).
- Khi context cha gần đầy: ghi ledger đầy đủ (lưới an toàn) rồi **TIẾP TỤC ngay
  trong CÙNG session** — harness Claude Code **tự nén/tóm tắt context** để chạy
  tiếp, KHÔNG cần bàn giao. KHÔNG kết thúc lượt, KHÔNG bắt user mở session mới.
  RESUME (A1) chỉ là **safety-net** khi session thật sự chết / user chủ động
  restart — KHÔNG phải thứ MANAGER tự kích hoạt khi chưa DONE.

## B. CHIA VIỆC CÓ GIỚI HẠN (bounded subagents — KHÔNG swarm)

> Triết lý: việc thật do MANAGER + một NHÓM NHỎ subagent làm trọn, KHÔNG bung
> hàng chục tiến trình. Bài học đã trả giá: swarm đông làm mất/hỏng ledger và
> đốt token mà chẳng build ra gì (bài học thực chiến: nhiều agent ghi cùng một ledger gây lost update, và swarm đông đốt token mà không build ra app).

### B1. Số lượng — ÍT, có chủ đích
- Mặc định MANAGER tự làm tuần tự theo vertical-slice (Stage 4): 1 flow trọn
  vẹn tới VERIFIED rồi flow kế. Đơn giản, dễ theo dõi, không xung đột.
- Khi có nhiều việc ĐỘC LẬP thật sự (vd spec 5 màn read-only khác nhau), được
  giao song song cho **tối đa ~5–8 subagent** trong 1 lượt Agent tool. KHÔNG
  vượt mức này. Trần hữu ích = số việc độc lập ready, KHÔNG phải "càng nhiều
  càng nhanh".
- Việc phụ thuộc nhau (UI đọc token chưa port) → KHÔNG song song: làm nền
  trước (token/shared/adapter), VERIFIED rồi mới tới việc phụ thuộc.

### B2. 1-WRITER LEDGER (bất biến)
- CHỈ MANAGER ghi Ledger. Subagent trả kết quả + bằng chứng; MANAGER đối
  chiếu rồi tự cập nhật trạng thái. KHÔNG để ≥2 agent ghi cùng file ledger/spec
  song song (lost update hỏng nguồn sự thật — quy tắc 1 writer cho file trạng thái).
- MANAGER tự ĐẾM ledger (chạy `parity-status.sh`), KHÔNG tin "đã xong" do
  subagent tự báo nếu thiếu bằng chứng.

### B3. 1-OWNER-1-FILE khi song song
- Nếu giao nhiều subagent cùng lúc: mỗi subagent chạm ĐÚNG 1 file ghi riêng
  (không 2 agent sửa 1 file Kotlin). Việc nào lỡ đụng chung file → KHÔNG song
  song, để MANAGER làm tuần tự.

### B4. Chi phí (minh bạch)
- Mỗi subagent là 1 luồng đốt quota. Giao 6 subagent = 6 luồng song song. Báo
  rõ, KHÔNG lén. Đổi token lấy tốc độ CHỈ khi có đủ việc độc lập; bung quá số
  việc ready = lãng phí (đúng cái user phàn nàn).
- Build/verify dùng chung Gradle daemon → **KHÔNG chạy nhiều `gradle` song
  song** (Kotlin daemon quá tải → lỗi GIẢ "Unresolved reference",
  Kotlin daemon quá tải sinh lỗi giả). MANAGER serialize build/verify.

## C. CÔNG THỨC KHUYẾN NGHỊ

1. Stage -1/0/1: MANAGER tự chạy preflight + contract; tạo `parity-spec.md` +
   `s2a-manifest.md` + `DEVIATIONS.md` từ template (vị trí user duyệt) và
   **copy folder `checklists/` của skill vào cạnh parity-spec** (gate DONE
   grep bản copy — enforcement §2). Spec nhiều màn read-only → có thể giao
   vài subagent (mỗi subagent 1 màn) rồi MANAGER gom vào spec.
2. Stage 2 (scaffold) + Wave nền (token/Shared/adapter/platform-equivalent):
   MANAGER tự làm hoặc 1–2 subagent; VERIFIED trước khi port UI phụ thuộc.
3. Stage 4 (port): mặc định MANAGER tự port từng flow vertical-slice. Nhiều
   flow độc lập + máy khoẻ → giao tối đa ~5–8 subagent (mỗi flow/ file 1
   subagent, 1-owner-1-file). MANAGER build + verify (serialize Gradle).
4. Stage 5 (verify): chạy `preflight.sh … verify` (cặp thiết bị + công cụ đo)
   rồi MANAGER tự chạy `verify.sh <app> --full`/`parity-diff.sh`, đo, đối
   chiếu, ghi ledger. Giữa các nhịp dùng `parity-status.sh … --fast` cho nhanh;
   chốt DONE phải chạy bản đầy đủ.
5. KHÔNG bao giờ: headless `claude -p`, tmux swarm, fan-out 40+, ≥2 agent ghi
   ledger, ≥2 agent 1 file, nhiều `gradle` song song, hạ verify để nhanh.

## D. TOKEN ENDURANCE — 1 session chạy BỀN tới khi dự án hoàn thiện

> Sự thật cần nói thẳng: KHÔNG có cách "chạy mà không tốn token" — mọi thao tác
> đều tốn. Nhưng có 2 đòn bẩy để **1 session làm được NHIỀU NHẤT trước khi đầy
> context, và KHÔNG MẤT VIỆC khi đầy**: (1) giữ context phiên chính MỎNG, (2)
> Ledger là bộ nhớ bền → phiên mới RESUME nối chính xác. Mục tiêu = chạy tới
> `parity-status.sh = DONE`, qua bao nhiêu phiên cũng được, không lặp lại việc.

### D1. Giữ context phiên chính MỎNG (đòn bẩy số 1 — kéo dài session)
- **KHÔNG đọc file source lớn vào context phiên chính.** Việc đọc-nhiều (quét
  cả màn iOS để spec, đọc cả file để port) → giao **subagent** (context cô lập
  riêng, KHÔNG tính vào context cha); subagent chỉ trả về **summary gọn**: các
  dòng ledger + đường dẫn bằng chứng + delta spec. Cha phình rất chậm ⇒ sống lâu.
- **KHÔNG dán nội dung file lớn vào câu trả lời.** Tham chiếu `path:line`, đừng
  copy cả khối. In ra màn hình = đốt token + phình context vô ích.
- **Đọc có mục tiêu**: Grep + `Read` kèm `offset/limit` thay vì đọc cả file.
  Lấy trạng thái từ **1 dòng output** của `parity-status.sh`/`verify.sh`, KHÔNG
  đọc lại cả ledger thô mỗi nhịp.
- **KHÔNG đọc lại** thứ đã xử lý. Đã spec/port rồi → tin ledger + spec, không
  mở lại file để "xem cho chắc".

### D2. Vòng làm việc tiết kiệm (mỗi đơn vị)
```
chọn dòng ledger kế (parity-status.sh) → [nếu nặng: giao 1 subagent làm trọn]
→ nhận summary → MANAGER verify + ghi ledger → QUÊN chi tiết (chỉ giữ state)
→ lặp; KHÔNG kể lể dài dòng giữa các bước
```
- 1 subagent = 1 việc TRỌN VẸN (cả flow/file tới bằng chứng), trả kết quả 1
  lần — KHÔNG hỏi-đáp lắt nhắt nhiều vòng (mỗi vòng tái nạp context = tốn).
- Sau mỗi đơn vị VERIFIED: ghi ledger NGAY rồi buông chi tiết khỏi đầu.

### D3. Context gần đầy → ghi ledger rồi CHẠY TIẾP (KHÔNG tự bàn giao)
> Đây là điểm khác biệt sống còn: harness Claude Code **tự nén/tóm tắt context**
> khi hội thoại dài rồi đưa bản tóm tắt sang cửa sổ kế để chạy tiếp — "you don't
> need to wrap up early or hand off mid-task". ⇒ 1 session **chạy xuyên qua giới
> hạn context được**. Vì vậy KHÔNG có "watermark = phải dừng". Việc bắt user mở
> session mới để gõ lại `/ios2android` là SAI và bị cấm khi chưa DONE.

- Khi context phiên chính cao: **KHÔNG cố nhồi chi tiết, nhưng KHÔNG dừng**. Ghi
  ledger ĐẦY ĐỦ (mọi tiến độ + blocker + dòng IN_PROGRESS), bảo đảm
  `parity-spec.md` phản ánh đúng thực tế — đây là **lưới an toàn**, KHÔNG phải
  tín hiệu kết thúc. Rồi **lấy dòng ledger kế và làm tiếp NGAY trong cùng lượt**.
  Để harness tự lo việc nén context.
- Buông chi tiết khỏi đầu (đã nằm ở ledger/spec) để context cha nhẹ đi tự nhiên —
  nhưng tiếp tục bằng 1 hành động port/verify, KHÔNG bằng 1 thông điệp bàn giao.
- Ledger ghi-ngay-khi-đạt là lưới đỡ NẾU session thật sự chết (máy crash, user
  đóng) — lúc đó §A1 RESUME nối lại không mất việc. Nhưng MANAGER **không bao giờ
  tự gây ra** việc thay phiên đó khi `parity-status.sh` ≠ DONE.

### D4. No-stop (canonical: enforcement §3 — đọc đó, không lặp ở đây)
- Quy tắc dừng/không-dừng + 5 ngoại lệ user-chặn: enforcement §3. Riêng nhấn
  1 điểm thuộc file này: "context gần đầy" KHÔNG nằm trong danh sách lý do
  dừng — xử lý bằng cách chạy tiếp (§D3). Hết ý tưởng → §E dưới đây.

## E. TECH RESEARCH & TOOLING — chủ động tìm công nghệ để đạt parity

Agent PHẢI chủ động, KHÔNG ì:
- Chi tiết UI/UX/animation khó đạt parity bằng kiến thức sẵn có → **nghiên
  cứu công nghệ mới nhất**: MCP `context7` (doc Compose/Android mới nhất) +
  web search; tìm API/thư viện/kỹ thuật tái hiện CHÍNH XÁC hành vi iOS (vd
  Compose graphics-layer, custom layout, Haze/blur, Lottie nếu iOS dùng
  vector-anim, predictive-back, shared-element).
- Tìm xong → **đề xuất gói tối thiểu** (quy tắc không tự cài dependency):
  tên@ver, lý do parity cụ thể, bundle size, maintenance — KHÔNG tự cài.
- Gộp đề xuất tooling **theo từng flow** (1 lần duyệt/flow) để không làm
  phiền liên tục nhưng vẫn chờ user duyệt từng dep.
- User duyệt → mới apply/cài; cài xong báo lock file, chờ duyệt commit
  (không tự commit/push).
- Tự dùng được KHÔNG cần hỏi: kỹ thuật/API in-house, Compose API chuẩn, dep
  đã có trong repo. Nghiên cứu/đọc doc luôn được phép, KHÔNG chờ.
- Nguyên tắc: thiếu công cụ KHÔNG phải lý do hạ chuẩn parity — phải nghiên
  cứu & đề xuất giải pháp, KHÔNG âm thầm làm khác iOS.

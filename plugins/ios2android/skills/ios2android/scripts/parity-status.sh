#!/usr/bin/env bash
# parity-status.sh — Definition of Done NHỊ PHÂN (enforcement.md §2)
# Dùng: scripts/parity-status.sh <parity-spec.md> <ANDROID_PROJECT_ROOT> [--fast]
#   --fast = bỏ qua build/test (chỉ soi ledger/checklist/deviation) → KHÔNG BAO GIỜ in DONE.
# In "DONE" hoặc "NOT DONE: ...". Agent CẤM tuyên bố xong nếu chưa dán "DONE".
set -uo pipefail

SPEC="${1:?Cần đường dẫn parity-spec.md}"
APP="${2:?Cần Android project root}"
FAST="${3:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SPEC" ] || { echo "NOT DONE: thiếu $SPEC (chưa SPECD — SKILL.md stage 1)"; exit 1; }
SPECDIR="$(cd "$(dirname "$SPEC")" && pwd)"
[ -f "$HERE/../VERSION" ] && echo "ios2android v$(cat "$HERE/../VERSION") — DoD gate"

# --- Ledger: mọi dòng bảng trong section §4 LEDGER có cột trạng thái hợp lệ ---
# Robust: quét cell trái→phải, lấy cell ĐẦU TIÊN khớp state keyword TỪ ĐẦU cell
# → hoạt động với cả template (trạng thái ở giữa, sau đó bằng chứng|agent|ts)
#   lẫn ledger status-cột-cuối; KHÔNG dính header/separator/note; PORTED có
#   "⏳VERIFIED chờ" ở cột bằng chứng KHÔNG bị tính là VERIFIED (trạng thái
#   đứng trước, match trước).
# Đồng thời gate BẰNG CHỨNG (enforcement §12): dòng VERIFIED phải có cột bằng
# chứng; dòng loại screen/section phải có chuỗi đo `%=` hoặc `IoU=`.
ledger_counts=$(awk '
  function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
  /^##[[:space:]]*(§4|4)\.[[:space:]].*LEDGER/ {inled=1; next}
  inled && /^##[[:space:]]*(§|[0-9])/ {inled=0}
  inled && /^\|/ {
    n=split($0, f, "|"); st=""; si=0;
    for (i=2; i<n; i++) {
      c=trim(f[i]);
      if (c ~ /^(NOT_STARTED|SPECD|IN_PROGRESS|PORTED|VERIFIED|FAIL|RECHECK)/) { st=c; si=i; break }
    }
    if (st != "") {
      tot++;
      typ=tolower(trim(f[3])); ev=(si+1<n)? trim(f[si+1]) : "";
      if (st ~ /^VERIFIED/) {
        ver++;
        if (ev == "") noev++;
        else if (typ ~ /(screen|màn|section|element)/ && ev !~ /(%=|IoU=|iou=)/) noproof++;
      }
      else if (st ~ /^FAIL/) fl++;
    }
  }
  END { printf "%d %d %d %d %d", tot, ver, fl, noev, noproof }
' "$SPEC")
read -r total verified fails noev noproof <<<"$ledger_counts"
if [ "${total:-0}" -eq 0 ]; then
  echo "NOT DONE: Ledger rỗng — chưa liệt kê công việc (parity-spec §4)"; exit 1
fi
notv=$((total - verified))

# --- Flow Inventory phải không còn trạng thái rỗng/NOT (heuristic) ---
flowopen=$(awk '/^## 3\. FLOW INVENTORY/{f=1} /^## 4\./{f=0} f && /^\| F[0-9]/' "$SPEC" \
            | grep -viE 'VERIFIED|DONE' | grep -c .)

# --- Checklist: gate theo bản COPY trong project (cạnh parity-spec), KHÔNG phải
#     template của skill (template luôn đầy '- [ ]' → gate template = không bao giờ DONE).
#     Stage 1 phải copy checklists/ của skill vào cạnh parity-spec rồi tick dần.
CHECK_DIR="$SPECDIR/checklists"
if [ -d "$CHECK_DIR" ]; then
  unchk=$(grep -rc '\- \[ \]' "$CHECK_DIR" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  chkmissing=0
else
  unchk=0
  chkmissing=1
fi

# --- Deviation gate (enforcement §0): file phải tồn tại & không còn dòng chờ duyệt ---
DEV="$SPECDIR/DEVIATIONS.md"
if [ -f "$DEV" ]; then
  devmissing=0
  devopen=$(grep -E '^\|' "$DEV" 2>/dev/null | grep -viE '^\|[[:space:]]*(ID|-{2,}|:?-)' \
            | grep -icE 'chờ duyệt|chua duyet|chưa duyệt|pending|TBD|\?\?' || true)
else
  devmissing=1; devopen=0
fi

# --- Build/test/anti-stub/cap/release qua verify.sh (bỏ qua nếu --fast) ---
if [ "$FAST" = "--fast" ]; then
  echo "== FAST MODE: bỏ qua build/test (không dùng để chốt DONE) =="
  vgreen=0
else
  vout=$("$HERE/verify.sh" "$APP" --full 2>&1 || true)
  echo "$vout" | tail -25
  vgreen=$(echo "$vout" | grep -c 'VERIFY: GREEN')
fi

echo "---------------------------------------------"
echo "Ledger: $verified/$total VERIFIED | chưa: $notv | FAIL: $fails | thiếu bằng chứng: $noev | thiếu chuỗi đo: $noproof"
echo "Flow chưa đóng (heuristic): $flowopen | checklist ô trống: $unchk (missing dir: $chkmissing) | deviation mở: $devopen (missing file: $devmissing)"

if [ "$notv" -eq 0 ] && [ "$fails" -eq 0 ] && [ "$flowopen" -eq 0 ] \
   && [ "$vgreen" -ge 1 ] && [ "$unchk" -eq 0 ] && [ "$chkmissing" -eq 0 ] \
   && [ "$noev" -eq 0 ] && [ "$noproof" -eq 0 ] \
   && [ "$devmissing" -eq 0 ] && [ "$devopen" -eq 0 ]; then
  echo "DONE"
  exit 0
else
  reasons=""
  [ "$notv" -gt 0 ]   && reasons="$reasons; $notv dòng ledger chưa VERIFIED"
  [ "$fails" -gt 0 ]  && reasons="$reasons; $fails dòng FAIL"
  [ "$noev" -gt 0 ]   && reasons="$reasons; $noev dòng VERIFIED thiếu bằng chứng (enforcement §1)"
  [ "$noproof" -gt 0 ] && reasons="$reasons; $noproof dòng màn/section VERIFIED thiếu chuỗi đo %= hoặc IoU= (enforcement §12)"
  [ "$flowopen" -gt 0 ] && reasons="$reasons; $flowopen flow chưa đóng"
  [ "$vgreen" -lt 1 ] && { [ "$FAST" = "--fast" ] \
      && reasons="$reasons; FAST MODE — chạy lại KHÔNG --fast để chốt DONE" \
      || reasons="$reasons; build/test/stub/cap chưa xanh"; }
  [ "$chkmissing" -eq 1 ] && reasons="$reasons; chưa copy checklists/ vào cạnh parity-spec (stage 1)"
  [ "$unchk" -gt 0 ]  && reasons="$reasons; còn $unchk ô checklist chưa ký"
  [ "$devmissing" -eq 1 ] && reasons="$reasons; chưa tạo DEVIATIONS.md cạnh parity-spec (enforcement §0)"
  [ "$devopen" -gt 0 ] && reasons="$reasons; $devopen deviation chưa user duyệt"
  echo "NOT DONE:${reasons# ;}"
  echo "→ enforcement §3: CẤM dừng/bàn giao. Lấy dòng chưa xong kế tiếp & tiếp tục."
  exit 1
fi

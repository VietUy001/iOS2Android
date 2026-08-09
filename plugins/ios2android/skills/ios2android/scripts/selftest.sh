#!/usr/bin/env bash
# selftest.sh — tự kiểm các CỔNG của skill bằng fixture giả trong $TMPDIR.
# Bao gồm: parity-status.sh (ledger/bằng chứng/checklist/deviation/--fast),
#          preflight.sh (greenfield KHÔNG được đỏ vì thiếu gradlew),
#          parity-diff.sh (iou/texts-diff).
# KHÔNG cần gradle/emulator: chỉ assert các reason mà script in ra.
# Dùng: scripts/selftest.sh   → in "SELFTEST PASS" (exit 0) hoặc "SELFTEST FAIL".
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/s2a_selftest.XXXXXX")"
trap 'rm -rf "$FIX"' EXIT

APP="$FIX/android"          # project Android giả (không có gradlew → verify đỏ, đúng chủ đích)
SPECDIR="$FIX/proj"
SPEC="$SPECDIR/parity-spec.md"
DEV="$SPECDIR/DEVIATIONS.md"
mkdir -p "$APP" "$SPECDIR/checklists"

FAILS=0
bad(){ printf '  ❌ %s\n' "$1"; FAILS=$((FAILS+1)); }
ok(){ printf '  ✅ %s\n' "$1"; }

write_spec() { # $1 = trạng thái dòng L002, $2 = bằng chứng dòng L002 (mặc định có %=)
  local st="$1" ev="${2:-parity-diff %=0.42 ≤ tol; diff.png}"
  cat > "$SPEC" <<EOF
# Parity Spec — SelfTest iOS → Android

## 3. FLOW INVENTORY — liệt kê 100% flow

| Flow ID | tên | entry | page | phụ thuộc | iOS source | trạng thái |
|---|---|---|---|---|---|---|
| F01 | Login | Splash | Login,Home | — | Login.swift | VERIFIED |

## 4. COMPLETENESS LEDGER — DoD nhị phân (xem enforcement.md)

| ID | loại | tên | iOS src | dep | trạng thái | bằng chứng | agent | ts |
|---|---|---|---|---|---|---|---|---|
| L001 | token | Colors | Theme.swift:1 | | VERIFIED | token map + test | M | t1 |
| L002 | screen | LoginView | Login.swift:40 | L001 | $st | $ev | M | t2 |

## 5. PER-SCREEN SPEC
EOF
}

write_checklists_ticked() {
  printf '# ui-parity (copy)\n- [x] Layout khớp\n- [x] Motion khớp\n' > "$SPECDIR/checklists/ui-parity.md"
  printf '# standards (copy)\n- [x] targetSdk đạt\n' > "$SPECDIR/checklists/standards.md"
}

write_devs() { # $1 = clean | open
  if [ "$1" = clean ]; then
    printf '# DEVIATIONS\n\n| ID | hạng mục | iOS | Android | phương án | trạng thái |\n|---|---|---|---|---|---|\n| D01 | status bar | x | y | accept | user duyệt 2026-01-01 |\n' > "$DEV"
  else
    printf '# DEVIATIONS\n\n| ID | hạng mục | iOS | Android | phương án | trạng thái |\n|---|---|---|---|---|---|\n| D01 | status bar | x | y | accept | chờ duyệt |\n' > "$DEV"
  fi
}

run_status() { bash "$HERE/parity-status.sh" "$SPEC" "$APP" ${1:-} 2>&1 || true; }

# ---------- Case (a): mọi cổng sạch, chỉ build đỏ ----------
echo "== Case (a): ledger+bằng chứng+checklist+deviation sạch → NOT DONE chỉ vì build =="
write_spec "VERIFIED"; write_checklists_ticked; write_devs clean
out_a="$(run_status)"
echo "$out_a" | grep -q '^DONE$' && bad "(a) in DONE dù build chưa xanh" || ok "(a) không in DONE"
echo "$out_a" | grep -q 'build/test/stub/cap chưa xanh' && ok "(a) reason nêu build chưa xanh" || bad "(a) thiếu reason build chưa xanh"
echo "$out_a" | grep -q 'dòng ledger chưa VERIFIED' && bad "(a) báo oan ledger chưa VERIFIED" || ok "(a) không báo oan ledger"
echo "$out_a" | grep -q 'chưa copy checklists' && bad "(a) báo oan thiếu checklists" || ok "(a) nhận đúng checklists đã copy"
echo "$out_a" | grep -q 'ô checklist chưa ký' && bad "(a) báo oan ô checklist trống" || ok "(a) nhận đúng checklist đã tick"
echo "$out_a" | grep -qE 'dòng VERIFIED thiếu bằng chứng|VERIFIED thiếu chuỗi đo' && bad "(a) báo oan bằng chứng" || ok "(a) nhận đúng bằng chứng %="
echo "$out_a" | grep -qE 'DEVIATIONS|deviation chưa' && bad "(a) báo oan deviation" || ok "(a) nhận đúng deviation đã duyệt"

# ---------- Case (b): ledger có FAIL ----------
echo "== Case (b): ledger có FAIL → NOT DONE nêu đúng lý do =="
write_spec "FAIL"
out_b="$(run_status)"
echo "$out_b" | grep -q '^DONE$' && bad "(b) in DONE dù có FAIL" || ok "(b) không in DONE"
echo "$out_b" | grep -qE '1 dòng FAIL' && ok "(b) reason nêu 1 dòng FAIL" || bad "(b) thiếu reason dòng FAIL"
echo "$out_b" | grep -q '1 dòng ledger chưa VERIFIED' && ok "(b) đếm đúng 1 dòng chưa VERIFIED" || bad "(b) đếm sai dòng chưa VERIFIED"

# ---------- Case (b2): IN_PROGRESS cũng chưa VERIFIED ----------
echo "== Case (b2): ledger có IN_PROGRESS → NOT DONE =="
write_spec "IN_PROGRESS"
out_b2="$(run_status)"
echo "$out_b2" | grep -q '1 dòng ledger chưa VERIFIED' && ok "(b2) IN_PROGRESS tính là chưa VERIFIED" || bad "(b2) IN_PROGRESS lọt lưới"

# ---------- Case (b3): RECHECK (regression sweep §19) ----------
echo "== Case (b3): ledger có RECHECK → coi như chưa VERIFIED =="
write_spec "RECHECK"
out_b3="$(run_status)"
echo "$out_b3" | grep -q '1 dòng ledger chưa VERIFIED' && ok "(b3) RECHECK tính là chưa VERIFIED" || bad "(b3) RECHECK lọt lưới"

# ---------- Case (c): thiếu folder checklists copy ----------
echo "== Case (c): thiếu folder checklists cạnh spec → NOT DONE nêu đúng =="
write_spec "VERIFIED"; rm -rf "$SPECDIR/checklists"
out_c="$(run_status)"
echo "$out_c" | grep -q '^DONE$' && bad "(c) in DONE dù thiếu checklists" || ok "(c) không in DONE"
echo "$out_c" | grep -q 'chưa copy checklists' && ok "(c) reason nêu chưa copy checklists" || bad "(c) thiếu reason chưa copy checklists"

# ---------- Case (d): checklist copy còn ô trống ----------
echo "== Case (d): checklists copy còn '- [ ]' → NOT DONE nêu ô chưa ký =="
mkdir -p "$SPECDIR/checklists"
printf '# copy\n- [x] mục 1\n- [ ] mục 2\n' > "$SPECDIR/checklists/ui-parity.md"
out_d="$(run_status)"
echo "$out_d" | grep -q 'ô checklist chưa ký' && ok "(d) reason nêu ô checklist chưa ký" || bad "(d) thiếu reason ô checklist"

# ---------- Case (e): VERIFIED nhưng bằng chứng KHÔNG có chuỗi đo (enforcement §12) ----------
echo "== Case (e): màn VERIFIED thiếu chuỗi %= → NOT DONE (chống 'trông ổn') =="
write_spec "VERIFIED" "đã xem, trông giống"; write_checklists_ticked
out_e="$(run_status)"
echo "$out_e" | grep -q 'VERIFIED thiếu chuỗi đo' && ok "(e) bắt được bằng chứng không có số đo" || bad "(e) lọt bằng chứng cảm quan"

# ---------- Case (e2): VERIFIED nhưng cột bằng chứng RỖNG ----------
echo "== Case (e2): VERIFIED bằng chứng rỗng → NOT DONE =="
write_spec "VERIFIED" " "
out_e2="$(run_status)"
echo "$out_e2" | grep -q 'dòng VERIFIED thiếu bằng chứng' && ok "(e2) bắt được bằng chứng rỗng" || bad "(e2) lọt bằng chứng rỗng"

# ---------- Case (f): deviation chưa duyệt / thiếu file ----------
echo "== Case (f): DEVIATIONS.md có dòng chờ duyệt → NOT DONE =="
write_spec "VERIFIED"; write_devs open
out_f="$(run_status)"
echo "$out_f" | grep -q 'deviation chưa user duyệt' && ok "(f) bắt được deviation chờ duyệt" || bad "(f) lọt deviation chờ duyệt"
rm -f "$DEV"
out_f2="$(run_status)"
echo "$out_f2" | grep -q 'chưa tạo DEVIATIONS.md' && ok "(f2) bắt được thiếu DEVIATIONS.md" || bad "(f2) lọt thiếu DEVIATIONS.md"
write_devs clean

# ---------- Case (g): --fast không bao giờ DONE ----------
echo "== Case (g): --fast → không chốt DONE =="
out_g="$(run_status --fast)"
echo "$out_g" | grep -q '^DONE$' && bad "(g) --fast in DONE" || ok "(g) --fast không in DONE"
echo "$out_g" | grep -q 'FAST MODE' && ok "(g) nêu rõ FAST MODE" || bad "(g) không nêu FAST MODE"

# ---------- Case (h): preflight greenfield KHÔNG đỏ vì thiếu gradlew ----------
echo "== Case (h): preflight mode pre trên Android trống → không chặn vì gradlew =="
mkdir -p "$FIX/ios"; touch "$FIX/ios/Package.swift"
printf -- '- ios_rev: `manual-tag-1`\n- test_backend: `mock://local`\n- ios_ref_pt: 393x852\n- android_device_dp: 393x852\n' > "$FIX/man.md"
out_h="$(bash "$HERE/preflight.sh" "$FIX/ios" "$APP" "$FIX/man.md" pre 2>&1 || true)"
echo "$out_h" | grep -q '❌ thiếu .*gradlew' && bad "(h) vẫn chặn vì gradlew (deadlock greenfield)" || ok "(h) không chặn vì gradlew"
echo "$out_h" | grep -q 'greenfield' && ok "(h) nhận diện greenfield" || bad "(h) không nhận diện greenfield"
echo "$out_h" | grep -q 'cặp thiết bị cùng logical size' && ok "(h) kiểm cặp thiết bị" || bad "(h) thiếu kiểm cặp thiết bị"

# ---------- Case (h2): lệch cặp thiết bị → RED ----------
echo "== Case (h2): ios_ref_pt ≠ android_device_dp → PREFLIGHT RED =="
printf -- '- ios_rev: `manual-tag-1`\n- test_backend: `mock://local`\n- ios_ref_pt: 393x852\n- android_device_dp: 412x915\n' > "$FIX/man2.md"
out_h2="$(bash "$HERE/preflight.sh" "$FIX/ios" "$APP" "$FIX/man2.md" pre 2>&1 || true)"
echo "$out_h2" | grep -q 'CẤM đo parity chéo hệ' && ok "(h2) chặn đo chéo hệ toạ độ" || bad "(h2) lọt đo chéo hệ toạ độ"

# ---------- Case (h3): test_backend parse — không dính chữ "prod" ở tiêu đề ----------
echo "== Case (h3): tiêu đề chứa chữ 'prod' KHÔNG được coi là test_backend=prod =="
printf -- '## Test-env isolation (CẤM prod)\n- ios_rev: `t1`\n- test_backend: `mock://none`\n- ios_ref_pt: 393x852\n- android_device_dp: 393x852\n' > "$FIX/man3.md"
out_h3="$(bash "$HERE/preflight.sh" "$FIX/ios" "$APP" "$FIX/man3.md" pre 2>&1 || true)"
echo "$out_h3" | grep -q 'test_backend trỏ PROD' && bad "(h3) false-positive test_backend=prod" || ok "(h3) parse đúng giá trị test_backend"
printf -- '- ios_rev: `t1`\n- test_backend: `https://api.prod.example.com`\n- ios_ref_pt: 393x852\n- android_device_dp: 393x852\n' > "$FIX/man4.md"
out_h4="$(bash "$HERE/preflight.sh" "$FIX/ios" "$APP" "$FIX/man4.md" pre 2>&1 || true)"
echo "$out_h4" | grep -q 'test_backend trỏ PROD' && ok "(h3) vẫn chặn prod thật" || bad "(h3) lọt prod thật"

# ---------- Case (h5): ORACLE-LIMITED có duyệt → không chặn vì thiếu xcodeproj ----------
echo "== Case (h5): iOS source-only + oracle-limited đã duyệt → không chặn =="
mkdir -p "$FIX/ios_srconly"; printf 'import SwiftUI\n' > "$FIX/ios_srconly/A.swift"
printf -- '- ios_rev: `t1`\n- test_backend: `mock://none`\n- ios_ref_pt: 393x852\n- android_device_dp: 393x852\n- oracle_mode: limited\n- oracle_limited_approved: yes\n' > "$FIX/man5.md"
out_h5="$(bash "$HERE/preflight.sh" "$FIX/ios_srconly" "$APP" "$FIX/man5.md" pre 2>&1 || true)"
echo "$out_h5" | grep -q '❌ không thấy xcworkspace' && bad "(h5) vẫn chặn dù oracle-limited đã duyệt" || ok "(h5) oracle-limited mở được đường đi"
echo "$out_h5" | grep -q 'PREFLIGHT GREEN' && ok "(h5) PREFLIGHT GREEN" || bad "(h5) vẫn RED"
printf -- '- ios_rev: `t1`\n- test_backend: `mock://none`\n- ios_ref_pt: 393x852\n- android_device_dp: 393x852\n- oracle_mode: limited\n- oracle_limited_approved: no\n' > "$FIX/man6.md"
out_h6="$(bash "$HERE/preflight.sh" "$FIX/ios_srconly" "$APP" "$FIX/man6.md" pre 2>&1 || true)"
echo "$out_h6" | grep -q 'CẤM tự quyết' && ok "(h5) chưa duyệt thì vẫn chặn" || bad "(h5) tự bật oracle-limited không cần duyệt"

# ---------- Case (i): parity-diff iou — thông báo đúng, không '> 100%' ----------
echo "== Case (i): iou report =="
printf 'name,ix,iy,iw,ih,ax,ay,aw,ah\nhero,0,0,100,100,0,0,100,100\nbad,0,0,100,100,20,20,100,100\n' > "$FIX/b.csv"
out_i="$(bash "$HERE/parity-diff.sh" iou "$FIX/b.csv" 2>&1 || true)"
echo "$out_i" | grep -q '> 100%' && bad "(i) còn thông báo sai '> 100%'" || ok "(i) thông báo IoU đã đúng"
echo "$out_i" | grep -q 'IoU=0.471 FAIL' && ok "(i) tính IoU đúng" || bad "(i) tính IoU sai"

# ---------- Case (j): texts-diff bắt thiếu chữ ----------
echo "== Case (j): texts-diff phát hiện text thiếu/thừa =="
printf 'Đăng nhập\nQuên mật khẩu\nThành tựu\n' > "$FIX/ios.txt"
printf 'Đăng nhập\nQuên mật khẩu\nBanner khuyến mãi\n' > "$FIX/and.txt"
out_j="$(bash "$HERE/parity-diff.sh" texts-diff "$FIX/ios.txt" "$FIX/and.txt" 2>&1 || true)"
echo "$out_j" | grep -q 'Thành tựu' && ok "(j) bắt được section text bị mất" || bad "(j) không bắt được text bị mất"
echo "$out_j" | grep -q 'Banner khuyến mãi' && ok "(j) bắt được text thừa" || bad "(j) không bắt được text thừa"
echo "$out_j" | grep -q 'TEXTS: RED' && ok "(j) kết luận RED" || bad "(j) thiếu kết luận RED"

echo "---------------------------------------------"
if [ "$FAILS" -eq 0 ]; then
  echo "SELFTEST PASS"; exit 0
else
  echo "SELFTEST FAIL: $FAILS assertion đỏ"; exit 1
fi

#!/usr/bin/env bash
# score.sh — chấm PROCESS COMPLIANCE cho 1 lần chạy skill ios2android trên fixture.
# Dùng: benchmark/score.sh <parity-spec.md-đã-sinh> <ANDROID_PROJECT_ROOT>
# Chấm 4 trục: coverage (expected.json), section completeness, gate integrity
# (parity-status.sh chạy được + lý do khớp ledger thật), anti-stub (thông tin).
# In "SCORE: PASS" (exit 0) khi coverage ≥90% + sections đủ + gate CONSISTENT.
set -uo pipefail

SPEC="${1:?Cần đường dẫn parity-spec.md đã sinh}"
APP="${2:?Cần Android project root}"
HERE="$(cd "$(dirname "$0")" && pwd)"
EXPECTED="$HERE/expected.json"
STATUS_SH="$HERE/../scripts/parity-status.sh"

[ -f "$SPEC" ] || { echo "SCORE: FAIL — không thấy spec: $SPEC"; exit 1; }
[ -f "$EXPECTED" ] || { echo "SCORE: FAIL — thiếu $EXPECTED"; exit 1; }
[ -f "$STATUS_SH" ] || { echo "SCORE: FAIL — thiếu $STATUS_SH"; exit 1; }

# --- Đọc expected.json (python3 stdlib, không dep mới) ---
PLAN="$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for e in d["entries"]:
    print("E\t%s\t%s" % (e["id"], "|".join(e["patterns"])))
for s in d["required_sections"]:
    print("S\t%s\t%s" % (s["name"], "|".join(s["patterns"])))
print("MINLED\t%d" % d["min_ledger_rows"])
print("MINSCR\t%d" % d["min_screens"])
' "$EXPECTED")" || { echo "SCORE: FAIL — expected.json không parse được"; exit 1; }

MINLED=$(echo "$PLAN" | awk -F'\t' '$1=="MINLED"{print $2}')
MINSCR=$(echo "$PLAN" | awk -F'\t' '$1=="MINSCR"{print $2}')

# --- 1. Coverage: mỗi entry tìm match (grep -iE alias OR) trong spec ---
echo "== 1. Coverage (expected.json ↔ spec) =="
ent_total=0; ent_ok=0; missing_ids=""
while IFS=$'\t' read -r kind id pats; do
  [ "$kind" = "E" ] || continue
  ent_total=$((ent_total + 1))
  if grep -qiE "$pats" "$SPEC"; then
    echo "  COVERED  $id"
    ent_ok=$((ent_ok + 1))
  else
    echo "  MISSING  $id  (patterns: $pats)"
    missing_ids="$missing_ids $id"
  fi
done <<< "$PLAN"
coverage=0
[ "$ent_total" -gt 0 ] && coverage=$((ent_ok * 100 / ent_total))
echo "  → coverage: $ent_ok/$ent_total = ${coverage}%"

# --- 2. Section completeness (+ ledger ≥ N dòng hợp lệ, ≥ N screen) ---
echo "== 2. Section completeness =="
sec_total=0; sec_ok=0
while IFS=$'\t' read -r kind name pats; do
  [ "$kind" = "S" ] || continue
  sec_total=$((sec_total + 1))
  if grep -qiE "$pats" "$SPEC"; then
    echo "  OK       section $name"
    sec_ok=$((sec_ok + 1))
  else
    echo "  MISSING  section $name"
  fi
done <<< "$PLAN"

# Ledger: CÙNG awk logic parse như parity-status.sh (cell đầu tiên khớp state keyword)
ledger_counts=$(awk '
  /^##[[:space:]]*(§4|4)\.[[:space:]].*LEDGER/ {inled=1; next}
  inled && /^##[[:space:]]*(§|[0-9])/ {inled=0}
  inled && /^\|/ {
    n=split($0, f, "|"); st="";
    for (i=2; i<n; i++) {
      c=f[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", c);
      if (c ~ /^(NOT_STARTED|SPECD|IN_PROGRESS|PORTED|VERIFIED|FAIL|RECHECK)/) { st=c; break }
    }
    if (st != "") {
      tot++;
      if (st ~ /^VERIFIED/) ver++;
      else if (st ~ /^FAIL/) fl++;
    }
  }
  END { printf "%d %d %d", tot, ver, fl }
' "$SPEC")
led_total=$(echo "$ledger_counts" | awk '{print $1}')
led_ver=$(echo "$ledger_counts" | awk '{print $2}')
led_fail=$(echo "$ledger_counts" | awk '{print $3}')
led_notv=$((led_total - led_ver))

sec_total=$((sec_total + 1))
if [ "$led_total" -ge "$MINLED" ]; then
  echo "  OK       ledger rows: $led_total ≥ $MINLED"
  sec_ok=$((sec_ok + 1))
else
  echo "  MISSING  ledger rows: $led_total < $MINLED (dòng hợp lệ theo awk parity-status)"
fi

screens=$(grep -ciE '^###[[:space:]]*Screen:' "$SPEC" || true)
if [ "${screens:-0}" -eq 0 ]; then
  screens=$(awk '
    /^##[[:space:]]*(§4|4)\.[[:space:]].*LEDGER/ {inled=1; next}
    inled && /^##[[:space:]]*(§|[0-9])/ {inled=0}
    inled && /^\|/ && /\|[[:space:]]*screen[[:space:]]*\|/ {n++}
    END {print n+0}
  ' "$SPEC")
fi
sec_total=$((sec_total + 1))
if [ "${screens:-0}" -ge "$MINSCR" ]; then
  echo "  OK       screens: $screens ≥ $MINSCR"
  sec_ok=$((sec_ok + 1))
else
  echo "  MISSING  screens: ${screens:-0} < $MINSCR"
fi

# --- 3. Gate integrity: parity-status.sh chạy được + lý do khớp ledger thật ---
echo "== 3. Gate integrity (parity-status.sh) =="
gate_out=$(bash "$STATUS_SH" "$SPEC" "$APP" 2>&1) || true
gate="INCONSISTENT"
if echo "$gate_out" | grep -q '^DONE$'; then
  # DONE chỉ hợp lệ khi ledger thật sự sạch
  if [ "$led_notv" -eq 0 ] && [ "$led_fail" -eq 0 ] && [ "$led_total" -gt 0 ]; then
    gate="CONSISTENT"; echo "  gate output: DONE — khớp ledger ($led_ver/$led_total VERIFIED, 0 FAIL)"
  else
    echo "  gate output: DONE nhưng ledger thật chưa sạch (chưa VERIFIED: $led_notv, FAIL: $led_fail) → mâu thuẫn"
  fi
elif echo "$gate_out" | grep -q 'NOT DONE'; then
  m_notv=0; echo "$gate_out" | grep -q 'dòng ledger chưa VERIFIED' && m_notv=1
  m_fail=0; echo "$gate_out" | grep -q 'dòng FAIL' && m_fail=1
  m_empty=0; echo "$gate_out" | grep -q 'Ledger rỗng' && m_empty=1
  ok=1
  if [ "$m_empty" -eq 1 ]; then
    [ "$led_total" -eq 0 ] || ok=0
  else
    { [ "$led_notv" -gt 0 ] && [ "$m_notv" -eq 0 ]; } && ok=0
    { [ "$led_notv" -eq 0 ] && [ "$m_notv" -eq 1 ]; } && ok=0
    { [ "$led_fail" -gt 0 ] && [ "$m_fail" -eq 0 ]; } && ok=0
    { [ "$led_fail" -eq 0 ] && [ "$m_fail" -eq 1 ]; } && ok=0
  fi
  if [ "$ok" -eq 1 ]; then
    gate="CONSISTENT"
    echo "  gate output: NOT DONE — lý do khớp trạng thái ledger (chưa VERIFIED: $led_notv, FAIL: $led_fail)"
  else
    echo "  gate output: NOT DONE nhưng lý do KHÔNG khớp ledger thật:"
  fi
  echo "$gate_out" | grep 'NOT DONE' | head -3 | sed 's/^/    /'
else
  echo "  parity-status.sh không cho output nhận dạng được (script lỗi?):"
  echo "$gate_out" | tail -5 | sed 's/^/    /'
fi

# --- 4. Anti-stub trong Android root (thông tin, không tính PASS/FAIL) ---
echo "== 4. Anti-stub (android root) =="
stub=0
if [ -d "$APP" ]; then
  stub=$(grep -RnE 'TODO|FIXME|notImplemented\(\)' --include='*.kt' "$APP" 2>/dev/null \
          | grep -v '/build/' | wc -l | tr -d ' ')
  echo "  stub markers trong *.kt: $stub"
else
  echo "  (android root chưa tồn tại — bỏ qua)"
fi

# --- Tổng kết ---
echo "---------------------------------------------"
echo "BENCHMARK: coverage=${coverage}% sections=$sec_ok/$sec_total gate=$gate stub=$stub"
if [ "$coverage" -ge 90 ] && [ "$sec_ok" -eq "$sec_total" ] && [ "$gate" = "CONSISTENT" ]; then
  echo "SCORE: PASS"
  exit 0
else
  [ -n "$missing_ids" ] && echo "→ Entry thiếu:$missing_ids"
  echo "SCORE: FAIL"
  exit 1
fi

#!/usr/bin/env bash
# selftest.sh — tự kiểm score.sh bằng 2 sample spec trong benchmark/fixtures/.
# KHÔNG cần gradle: android dir giả tối thiểu; gate NOT DONE vì build là hợp lệ
# (score chỉ đòi gate CONSISTENT, không đòi DONE).
# Dùng: benchmark/selftest.sh → "BENCH SELFTEST PASS" (exit 0) hoặc FAIL.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/s2a_bench.XXXXXX")"
trap 'rm -rf "$FIX"' EXIT

FAILS=0
bad(){ printf '  ❌ %s\n' "$1"; FAILS=$((FAILS+1)); }
ok(){ printf '  ✅ %s\n' "$1"; }

setup_case() { # $1 = sample spec file → in path spec đã copy
  local dir="$FIX/$2"
  mkdir -p "$dir/proj/checklists" "$dir/android/app/src"
  cp "$HERE/fixtures/$1" "$dir/proj/parity-spec.md"
  # checklists giả đã tick hết (gate checklist sạch)
  printf '# ui-parity (copy)\n- [x] Layout khớp\n- [x] Motion khớp\n' \
    > "$dir/proj/checklists/ui-parity.md"
  printf '# standards (copy)\n- [x] targetSdk đạt\n' \
    > "$dir/proj/checklists/standards.md"
  # android giả tối thiểu, 1 file kt sạch (không stub marker)
  printf 'package fixture\n\nclass Placeholder\n' > "$dir/android/app/src/Main.kt"
  echo "$dir"
}

# ---------- Case GOOD: spec đầy đủ → PASS ----------
echo "== Case GOOD: sample-spec-good.md → SCORE: PASS =="
G="$(setup_case sample-spec-good.md good)"
out_g="$(bash "$HERE/score.sh" "$G/proj/parity-spec.md" "$G/android" 2>&1)"; rc_g=$?
[ "$rc_g" -eq 0 ] && ok "exit 0" || bad "exit $rc_g (mong 0)"
echo "$out_g" | grep -q '^SCORE: PASS$' && ok "in SCORE: PASS" || bad "thiếu SCORE: PASS"
echo "$out_g" | grep -q 'coverage=100%' && ok "coverage=100%" || bad "coverage khác 100%"
echo "$out_g" | grep -q 'gate=CONSISTENT' && ok "gate=CONSISTENT" || bad "gate không CONSISTENT"
echo "$out_g" | grep -q 'MISSING' && bad "báo oan MISSING" || ok "không MISSING nào"

# ---------- Case POOR: thiếu 3 entry + thiếu section DEVIATION → FAIL ----------
echo "== Case POOR: sample-spec-poor.md → SCORE: FAIL, nêu đúng entry MISSING =="
P="$(setup_case sample-spec-poor.md poor)"
out_p="$(bash "$HERE/score.sh" "$P/proj/parity-spec.md" "$P/android" 2>&1)"; rc_p=$?
[ "$rc_p" -ne 0 ] && ok "exit ≠ 0" || bad "exit 0 dù spec thiếu"
echo "$out_p" | grep -q '^SCORE: FAIL$' && ok "in SCORE: FAIL" || bad "thiếu SCORE: FAIL"
for id in ADD-BUTTON-SCALE EASTER-EGG ACCENT-COLOR; do
  echo "$out_p" | grep -q "MISSING  $id" \
    && ok "nêu MISSING $id" || bad "không nêu MISSING $id"
done
echo "$out_p" | grep -q 'MISSING  section DEVIATION' \
  && ok "nêu thiếu section DEVIATION" || bad "không nêu thiếu section DEVIATION"
echo "$out_p" | grep -q 'MISSING  HOME' && bad "báo oan HOME" || ok "HOME vẫn COVERED"
echo "$out_p" | grep -q 'gate=CONSISTENT' && ok "gate vẫn CONSISTENT" || bad "gate lệch ở case poor"

echo "---------------------------------------------"
if [ "$FAILS" -eq 0 ]; then
  echo "BENCH SELFTEST PASS"
  exit 0
else
  echo "BENCH SELFTEST FAIL: $FAILS assertion đỏ"
  exit 1
fi

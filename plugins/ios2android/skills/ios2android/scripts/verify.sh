#!/usr/bin/env bash
# verify.sh — cổng build/test/anti-stub/file-cap cho 1 phạm vi Android
# Dùng: scripts/verify.sh <ANDROID_PROJECT_ROOT> [--full]
#   --full = thêm cổng RELEASE/R8 (bắt buộc trước khi DONE — enforcement §20)
# Exit 0 = xanh; ≠0 = đỏ (agent phải loop sửa, KHÔNG dừng — enforcement §9)
set -uo pipefail

APP="${1:?Cần Android project root}"
MODE="${2:-}"
cd "$APP" || { echo "Không vào được $APP" >&2; exit 2; }
RC=0

# Bỏ qua code sinh tự động (miễn trừ cap — rule #24.4)
GEN_EXCL=( -not -path '*/build/*' -not -path '*/.gradle/*' -not -path '*/generated/*'
           -not -name '*.g.kt' -not -name '*_Generated*.kt' -not -name '*Generated.kt' )

echo "== 1. File size: 500 = cảnh báo, 800 = trần cứng (rule #24) =="
warnf=""; failf=""
while read -r n f; do
  [ -z "${n:-}" ] && continue
  if [ "$n" -gt 800 ]; then
    # >800 chỉ được phép khi user đã duyệt, ghi marker `s2a-loc-approved:` đầu file
    if head -5 "$f" | grep -q 's2a-loc-approved:'; then
      warnf="$warnf\n  ⚠ $n $f (đã có s2a-loc-approved)"
    else
      failf="$failf\n  $n $f"
    fi
  elif [ "$n" -gt 500 ]; then
    warnf="$warnf\n  ⚠ $n $f"
  fi
done < <(find . -type f \( -name '*.kt' -o -name '*.kts' \) "${GEN_EXCL[@]}" \
          -exec wc -l {} + 2>/dev/null | awk '$2!="total"{print $1" "$2}')
if [ -n "$failf" ]; then
  echo "❌ File > 800 LOC (trần cứng) — tách theo NHÓM CHỨC NĂNG, không tách theo số dòng:"
  printf '%b\n' "$failf"; RC=1
fi
if [ -n "$warnf" ]; then
  echo "⚠ File > 500 LOC — dừng lại đánh giá (rule #24.2): 1 nhóm chức năng → GIỮ + báo user;"
  echo "  ≥2 nhóm chức năng → tách theo nhóm. KHÔNG tách chỉ để hạ con số."
  printf '%b\n' "$warnf"
fi
[ -z "$failf" ] && [ -z "$warnf" ] && echo "✅ OK"

echo "== 2. Anti-stub (enforcement §6) =="
stub=$(grep -RnE 'TODO|FIXME|XXX|//[[:space:]]*implement|//[[:space:]]*later|notImplemented\(\)|Text\("TODO"' \
        --include='*.kt' . 2>/dev/null | grep -v '/build/' | grep -v '/generated/' || true)
if [ -n "$stub" ]; then echo "❌ Stub/placeholder còn lại:"; echo "$stub" | head -30; RC=1; else echo "✅ OK"; fi

echo "== 3. Hardcode string user-visible - i18n (cảnh báo) =="
hc=$(grep -RnE 'Text\("[^"]*[A-Za-zÀ-ỹ]{3}' --include='*.kt' . 2>/dev/null \
      | grep -v '/build/' | grep -v 'stringResource' || true)
[ -n "$hc" ] && { echo "⚠ Nghi hardcode (kiểm tra):"; echo "$hc" | head -20; }

echo "== 3a. LOG bắt buộc + không log rời rạc (rule #37, enforcement §21) =="
raw=$(grep -RnE '(^|[^A-Za-z0-9_])(Log\.(d|v|i|w|e)|println|System\.out\.print)\(' \
       --include='*.kt' . 2>/dev/null | grep -v '/build/' | grep -v '/generated/' \
       | grep -viE '(Logger|DLog|AppLog|Timber)\.' || true)
if [ -n "$raw" ]; then
  echo "❌ Log rời rạc (phải đi qua kênh log chung, gác BuildConfig.DEBUG):"; echo "$raw" | head -20; RC=1
else echo "✅ không có log rời rạc"; fi
scr=$(grep -rlE '@Composable' --include='*Screen.kt' . 2>/dev/null | grep -v '/build/' || true)
if [ -n "$scr" ]; then
  nolog=$(printf '%s\n' "$scr" | while read -r f; do
    grep -qiE '(DLog|AppLog|Logger|Timber)' "$f" || echo "  $f"; done)
  [ -n "$nolog" ] && { echo "⚠ Màn chưa có log (rule #37 — việc chưa có log là việc CHƯA XONG):"; printf '%s\n' "$nolog" | head -20; }
fi

echo "== 3b. strings.xml — apostrophe chưa escape (build đỏ / mất chuỗi) =="
badstr=$(grep -rn "<string[^>]*>[^<]*[^\\\\]'" --include='strings.xml' ./app 2>/dev/null | head -10 || true)
[ -n "$badstr" ] && { echo "⚠ Dấu ' chưa escape (\\' hoặc bọc \"…\") — mapping-kb §i18n:"; echo "$badstr"; }

# Serialize gradle giữa nhiều worker song song (tránh Kotlin daemon crash —
# Kotlin daemon quá tải sinh lỗi giả). macOS không có `flock` binary → dùng mkdir-lock atomic.
GLOCK="${TMPDIR:-/tmp}/s2a_gradle.lock"
if [ -d "$GLOCK" ] && [ -n "$(find "$GLOCK" -maxdepth 0 -mmin +25 2>/dev/null)" ]; then
  rmdir "$GLOCK" 2>/dev/null || true   # dọn lock cũ kẹt (>25 phút) phòng worker chết
fi
HAVE_LOCK=0; _tries=0
while ! mkdir "$GLOCK" 2>/dev/null; do
  _tries=$((_tries+1)); [ "$_tries" -gt 600 ] && { echo "⚠ chờ gradle-lock quá lâu, chạy không lock"; break; }
  sleep 2
done
[ -d "$GLOCK" ] && [ "$_tries" -le 600 ] && HAVE_LOCK=1
# CHỈ xoá lock nếu CHÍNH script này tạo ra (trước đây xoá cả lock của worker khác)
trap '[ "$HAVE_LOCK" = 1 ] && rmdir "$GLOCK" 2>/dev/null || true' EXIT

gradle_task() { # $1 = task, $2 = log path → 0 xanh / 1 đỏ
  local task="$1" log="$2"
  ./gradlew --offline "$task" -q 2>"$log" && return 0
  # chỉ chạy lại ONLINE khi lỗi do resolve dependency (tránh build 2 lần khi lỗi code)
  if grep -qiE 'offline mode|No cached version|Could not resolve|Could not download' "$log"; then
    ./gradlew "$task" -q 2>"$log" && return 0
  fi
  return 1
}

echo "== 4. Gradle assembleDebug =="
if [ -x ./gradlew ]; then
  if gradle_task assembleDebug /tmp/s2a_gradle.log; then
    echo "✅ assembleDebug pass"
  else
    echo "❌ assembleDebug FAIL:"; tail -40 /tmp/s2a_gradle.log; RC=1
  fi
else
  echo "❌ Không thấy ./gradlew (scaffold chưa xong)"; RC=1
fi

echo "== 5. Unit test =="
if [ -x ./gradlew ]; then
  if gradle_task testDebugUnitTest /tmp/s2a_test.log; then
    echo "✅ test pass"
  else
    echo "❌ test FAIL:"; tail -40 /tmp/s2a_test.log; RC=1
  fi
fi

if [ "$MODE" = "--full" ]; then
  echo "== 6. RELEASE / R8 (enforcement §20 — 'Debug chạy, Release không') =="
  if [ -x ./gradlew ]; then
    if gradle_task assembleRelease /tmp/s2a_release.log; then
      echo "✅ assembleRelease pass"
    else
      echo "❌ assembleRelease FAIL (R8/minify/keep-rule/resource shrink):"
      tail -40 /tmp/s2a_release.log; RC=1
    fi
  fi
  # keep-rule cho reflection (kotlinx.serialization/Gson/Room) — strip = crash CHỈ ở release
  if grep -rqE 'kotlinx\.serialization|@Serializable' --include='*.kt' . 2>/dev/null; then
    if ! grep -rqE 'kotlinx-serialization|kotlinx\.serialization' ./app/proguard-rules.pro 2>/dev/null \
       && ! grep -rq 'proguard-rules' ./app/build.gradle* 2>/dev/null; then
      echo "⚠ Dùng kotlinx.serialization nhưng chưa thấy keep-rule R8 → nguy cơ crash chỉ ở release"
    fi
  fi
  echo "   → Cài + smoke-test bản release trên máy/emulator trước khi đóng DONE (rule #34)."
fi

[ "$RC" -eq 0 ] && echo "VERIFY: GREEN" || echo "VERIFY: RED (loop sửa, KHÔNG dừng — enforcement §3/§9)"
exit "$RC"

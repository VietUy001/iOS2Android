#!/usr/bin/env bash
# preflight.sh — cổng chặn theo GIAI ĐOẠN (SKILL.md §-1)
# Dùng: scripts/preflight.sh <iOS_SRC> <ANDROID_ROOT> <MANIFEST_PATH> [mode]
#   mode = pre    (mặc định) → cổng TRƯỚC Stage 0: source/oracle/pin/test-env
#   mode = verify            → cổng TRƯỚC Stage 5: toolchain đo + thiết bị cặp đôi
# LƯU Ý: `gradlew` KHÔNG bắt buộc ở mode `pre` — greenfield chỉ có gradlew sau
# Stage 2 (trước đây bắt buộc → deadlock: preflight đỏ nên không được scaffold).
set -uo pipefail

IOS="${1:?Cần path source iOS}"
AND="${2:?Cần Android project root}"
MAN="${3:?Cần manifest path}"
MODE="${4:-pre}"
RC=0
say(){ printf '%s\n' "$*"; }
need(){ command -v "$1" >/dev/null 2>&1 && say "✅ $1" || { say "❌ thiếu $1 (đề xuất user cài, KHÔNG tự cài dependency)"; RC=1; }; }
soft(){ command -v "$1" >/dev/null 2>&1 && say "✅ $1" || say "⚠ chưa có $1 — cần TRƯỚC Stage 5 ($2). Đề xuất user cài ngay từ giờ."; }

say "== Chế độ: $MODE =="

say "== Công cụ bắt buộc =="
need xcrun; need git; need java

say "== Công cụ đo (bắt buộc ở mode verify) =="
if [ "$MODE" = "verify" ]; then
  need ffmpeg; need adb
  command -v compare >/dev/null 2>&1 && say "✅ ImageMagick(compare)" || { say "❌ thiếu ImageMagick 'compare'"; RC=1; }
else
  soft ffmpeg "đo animation"; soft adb "chụp/đo Android"
  command -v compare >/dev/null 2>&1 && say "✅ ImageMagick(compare)" || say "⚠ chưa có ImageMagick — cần TRƯỚC Stage 5 (visual diff)"
fi

say "== Android project =="
scaffolded=0
ls "$AND"/settings.gradle* "$AND"/build.gradle* >/dev/null 2>&1 && scaffolded=1
[ -x "$AND/gradlew" ] && scaffolded=1
if [ "$scaffolded" = 1 ]; then
  [ -x "$AND/gradlew" ] && say "✅ gradlew" || { say "❌ project đã scaffold nhưng thiếu $AND/gradlew"; RC=1; }
elif [ "$MODE" = "verify" ]; then
  say "❌ chưa scaffold Android (thiếu gradlew) — không thể verify"; RC=1
else
  say "ℹ Android root trống (greenfield) — gradlew sẽ có sau Stage 2 SCAFFOLD. KHÔNG chặn."
fi

say "== iOS project =="
# Oracle: iOS chạy được là MẶC ĐỊNH. Không build/chạy được → chỉ đi tiếp bằng
# ORACLE-LIMITED MODE có user duyệt, khai trong manifest (SKILL.md §ORACLE-LIMITED).
ORACLE_LIMITED=0
if grep -qiE '^[-*]?[[:space:]]*oracle_mode[[:space:]]*:.*limited' "$MAN" 2>/dev/null; then
  say "⚠ ORACLE-LIMITED MODE khai trong manifest — mọi mục không đo được PHẢI ghi DEVIATIONS + user ký."
  if grep -qiE '^[-*]?[[:space:]]*oracle_limited_approved[[:space:]]*:.*(yes|có)' "$MAN" 2>/dev/null; then
    say "✅ user đã duyệt oracle-limited"; ORACLE_LIMITED=1
  else
    say "❌ oracle_mode=limited nhưng chưa có 'oracle_limited_approved: yes' — CẤM tự quyết"; RC=1
  fi
fi
if [ -d "$IOS" ]; then
  proj=$(find "$IOS" -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' -o -name 'Package.swift' \) 2>/dev/null | head -1 || true)
  if [ -n "$proj" ]; then
    say "✅ tìm thấy: ${proj#"$IOS"/}"
  elif [ "$ORACLE_LIMITED" = 1 ]; then
    say "⚠ không có xcworkspace/xcodeproj/Package.swift — chấp nhận vì ORACLE-LIMITED đã duyệt (spec dựng 100% từ source)"
  else
    say "❌ không thấy xcworkspace/xcodeproj/Package.swift (không có oracle → xin user duyệt ORACLE-LIMITED hoặc cung cấp project build được)"; RC=1
  fi
  if command -v xcodebuild >/dev/null 2>&1 && [ -n "$proj" ]; then
    case "$proj" in
      *.xcworkspace) xcodebuild -list -workspace "$proj" >/dev/null 2>&1 && say "✅ xcodebuild -list OK" || say "⚠ xcodebuild -list lỗi (xử lý signing/scheme trước khi chạy simulator)";;
      *.xcodeproj)   xcodebuild -list -project "$proj" >/dev/null 2>&1 && say "✅ xcodebuild -list OK" || say "⚠ xcodebuild -list lỗi (cần xử lý trước)";;
    esac
  fi
  [ "$ORACLE_LIMITED" = 1 ] \
    && say "⚠ KHÔNG có oracle runtime: mọi dòng ledger không đo được ảnh phải ghi 'source-derived:' + Deviation MANDATORY, user ký mới VERIFIED." \
    || say "⚠ BẮT BUỘC: UI-AUDITOR phải build+chạy iOS trên simulator THẬT trước khi spec."
else
  say "❌ không thấy thư mục iOS: $IOS"; RC=1
fi

say "== Simulator/Emulator =="
xcrun simctl list devices booted 2>/dev/null | grep -q Booted && say "✅ iOS simulator đang boot" || say "⚠ chưa boot iOS simulator (UI-AUDITOR sẽ boot)"
if adb devices 2>/dev/null | grep -qw device; then
  say "✅ Android device/emulator online"
elif [ "$MODE" = "verify" ]; then
  say "❌ chưa có Android device — verify lớp B/C không chạy được"; RC=1
else
  say "⚠ chưa có Android device (cần khi verify lớp B/C)"
fi

say "== Thiết bị CẶP ĐÔI (cùng logical size — measurement §1.2) =="
ios_pt=$(grep -iE '^-?[[:space:]]*ios_ref_pt:' "$MAN" 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | head -1 || true)
and_dp=$(grep -iE '^-?[[:space:]]*android_device_dp:' "$MAN" 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | head -1 || true)
if [ -z "$ios_pt" ] || [ -z "$and_dp" ]; then
  msg="manifest chưa khai ios_ref_pt / android_device_dp (vd 393x852) — diff sẽ trộn 2 hệ toạ độ"
  if [ "$MODE" = "verify" ]; then say "❌ $msg"; RC=1; else say "⚠ $msg"; fi
elif [ "$ios_pt" != "$and_dp" ]; then
  say "❌ ios_ref_pt($ios_pt) ≠ android_device_dp($and_dp) — CẤM đo parity chéo hệ."
  say "   Sửa: chọn AVD cùng dp, hoặc ép: adb shell wm size ${ios_pt%x*}x${ios_pt#*x} + wm density <dpi>"
  RC=1
else
  say "✅ cặp thiết bị cùng logical size: $ios_pt"
  if [ "$MODE" = "verify" ] && command -v adb >/dev/null 2>&1; then
    px=$(adb shell wm size 2>/dev/null | tail -1 | grep -oE '[0-9]+x[0-9]+' | tail -1 || true)
    dn=$(adb shell wm density 2>/dev/null | tail -1 | grep -oE '[0-9]+' | tail -1 || true)
    if [ -n "$px" ] && [ -n "$dn" ]; then
      rw=$(( ${px%x*} * 160 / dn )); rh=$(( ${px#*x} * 160 / dn ))
      say "   thiết bị thật: ${rw}x${rh} dp (khai báo ${and_dp})"
      [ "${rw}x${rh}" != "$and_dp" ] && { say "❌ thiết bị đang nối KHÁC khai báo → chỉnh wm size/density hoặc đổi AVD"; RC=1; }
    fi
  fi
fi

say "== Source pin =="
if git -C "$IOS" rev-parse >/dev/null 2>&1; then
  rev=$(git -C "$IOS" rev-parse --short HEAD 2>/dev/null || echo "?")
  say "ℹ iOS rev hiện tại: $rev — GHI vào manifest 'ios_rev:' (bất biến #14 SOURCE PIN)"
  if grep -q "ios_rev" "$MAN" 2>/dev/null; then
    say "✅ manifest có ios_rev"
    manrev=$(grep -iE 'ios_rev:' "$MAN" | head -1 | grep -oE '[0-9a-f]{7,40}' | head -1 || true)
    [ -n "$manrev" ] && [ -n "$rev" ] && [ "${manrev:0:7}" != "${rev:0:7}" ] \
      && { say "❌ ios_rev manifest($manrev) ≠ HEAD($rev) → re-sync trước khi port (measurement §6)"; RC=1; }
  else
    say "❌ manifest chưa khai ios_rev"; RC=1
  fi
else
  say "⚠ iOS source không phải git repo — pin bằng tag/zip checksum, ghi manifest thủ công"
  grep -q "ios_rev" "$MAN" 2>/dev/null && say "✅ manifest có ios_rev (thủ công)" || { say "❌ manifest chưa khai ios_rev"; RC=1; }
fi

say "== Test-env isolation =="
# CHỈ đọc dòng khai KEY `test_backend:` và chỉ soi phần GIÁ TRỊ sau dấu ':'.
# (Bug cũ: grep cả file rồi dính tiêu đề "## Test-env isolation … CẤM prod"
#  → báo nhầm "trỏ PROD".)
tbline=$(grep -iE '^[-*]?[[:space:]]*test_backend[[:space:]]*:' "$MAN" 2>/dev/null | head -1 || true)
tbval=$(printf '%s' "${tbline#*:}" | tr -d '`' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
if [ -z "$tbline" ]; then
  say "❌ manifest chưa khai 'test_backend:' (CẤM test trên prod — bất biến #13)"; RC=1
elif [ -z "$tbval" ]; then
  say "❌ 'test_backend:' để trống — khai staging/mock cụ thể"; RC=1
elif printf '%s' "$tbval" | grep -qiE 'prod|production'; then
  say "❌ test_backend trỏ PROD ($tbval) — CẤM (bất biến #13). Đổi sang staging/mock."; RC=1
else
  say "✅ test_backend: $tbval"
fi

say "---------------------------------------------"
[ "$RC" -eq 0 ] && say "PREFLIGHT GREEN ($MODE)" || say "PREFLIGHT RED ($MODE) — DỪNG, báo user, KHÔNG 'làm tạm' (SKILL.md §-1)"
exit "$RC"

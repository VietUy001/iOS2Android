#!/usr/bin/env bash
# extract-assets.sh — dùng chung asset iOS: Assets.xcassets → Android res
# Dùng: scripts/extract-assets.sh <Assets.xcassets> <ANDROID_RES_DIR>
# macOS (cần `sips`). KHÔNG đổi pixel/màu/tỉ lệ (asset là dữ liệu parity).
set -euo pipefail

CAT="${1:?Cần path .xcassets}"
RES="${2:?Cần Android res dir}"
[ -d "$CAT" ] || { echo "Không thấy: $CAT" >&2; exit 1; }
[ -d "$RES" ] || { echo "Android res chưa tồn tại: $RES (tạo qua scaffold, KHÔNG tự mkdir khi chưa duyệt)" >&2; exit 1; }

sanitize(){ echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g;s/^_*//;s/__*/_/g'; }

echo "# Asset extraction report (nguồn: $CAT)"
echo "| iOS asset | loại | hành động | Android | trace |"
echo "|---|---|---|---|---|"

# --- imageset (bitmap) → density buckets ---
find "$CAT" -type d -name '*.imageset' | while read -r set; do
  base=$(sanitize "$(basename "$set" .imageset)")
  x1=$(find "$set" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' \) ! -name '*@2x*' ! -name '*@3x*' | head -1 || true)
  x2=$(find "$set" -maxdepth 1 -type f -name '*@2x*' | head -1 || true)
  x3=$(find "$set" -maxdepth 1 -type f -name '*@3x*' | head -1 || true)
  src="${x3:-${x2:-$x1}}"
  if [ -z "$src" ]; then
    echo "| $base | imageset | ⚠ không tìm thấy ảnh | - | $set |"; continue
  fi
  [ -n "$x1" ] && { d="$RES/drawable-mdpi"; mkdir -p "$d"; cp "$x1" "$d/$base.png"; }
  [ -n "$x2" ] && { d="$RES/drawable-xhdpi"; mkdir -p "$d"; cp "$x2" "$d/$base.png"; }
  [ -n "$x3" ] && { d="$RES/drawable-xxxhdpi"; mkdir -p "$d"; cp "$x3" "$d/$base.png"; }
  if [ -n "$x3" ]; then
    w=$(sips -g pixelWidth "$x3" 2>/dev/null | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$x3" 2>/dev/null | awk '/pixelHeight/{print $2}')
    if [ -n "${w:-}" ] && [ -n "${h:-}" ]; then
      mkdir -p "$RES/drawable-hdpi" "$RES/drawable-xxhdpi"
      sips -z $((h/2)) $((w/2)) "$x3" --out "$RES/drawable-hdpi/$base.png"  >/dev/null  # 1.5x ≈ @3x/2
      sips -z $((h*3/4)) $((w*3/4)) "$x3" --out "$RES/drawable-xxhdpi/$base.png" >/dev/null # 3x = @3x*0.75
    fi
  fi
  echo "| $base | bitmap | copy @1x→mdpi @2x→xhdpi @3x→xxxhdpi, hdpi/xxhdpi downscale | drawable-*/$base.png | $(basename "$set") |"
done

# --- vector PDF/SVG: KHÔNG rasterize, cần chuyển VectorDrawable thủ công/tool ---
find "$CAT" -type f \( -name '*.pdf' -o -name '*.svg' \) | while read -r v; do
  base=$(sanitize "$(basename "${v%.*}")")
  echo "| $base | vector | ⚠ convert → res/drawable/$base.xml (VectorDrawable, KHÔNG raster) | drawable/$base.xml | $(basename "$v") |"
done

# --- colorset → token snippet (KHÔNG bake vào ảnh) ---
find "$CAT" -type d -name '*.colorset' | while read -r c; do
  base=$(sanitize "$(basename "$c" .colorset)")
  echo "| $base | color | → token Color.kt (any/dark/contrast từ Contents.json) | Color.kt:$base | $(basename "$c") |"
done

# --- appiconset → adaptive icon (cần tách lớp foreground/bg) ---
find "$CAT" -type d -name '*.appiconset' | while read -r ic; do
  echo "| $(basename "$ic") | appicon | ⚠ adaptive icon (mipmap fg/bg); icon iOS không tách lớp → DEVIATIONS MANDATORY | mipmap-anydpi-v26 | $(basename "$ic") |"
done

echo
echo "→ Mục ⚠ = cần xử lý thủ công, KHÔNG được bỏ qua (ledger không VERIFIED tới khi xong)."
echo "→ Ghi mỗi resource vào manifest 'from: <catalog/name>' để app sau tái dùng."

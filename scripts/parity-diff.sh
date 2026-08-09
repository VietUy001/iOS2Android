#!/usr/bin/env bash
# parity-diff.sh — chụp & đo visual diff iOS↔Android (measurement.md §1)
# Lệnh:
#   parity-diff.sh capture-ios  <out.png>
#   parity-diff.sh capture-and  <out.png>
#   parity-diff.sh diff  <ios.png> <and.png> <out_diff.png> [crop_ios_top] [crop_and_top]
#   parity-diff.sh onion <ios.png> <and.png> <out_onion.png> [crop_ios_top] [crop_and_top]
#   parity-diff.sh iou   <bbox.csv> [thr]
#   parity-diff.sh boxes-and <out.csv>   # tự trích bbox Android từ uiautomator
#   parity-diff.sh texts-and <out.txt>   # trích TEXT hiển thị Android (uiautomator)
#   parity-diff.sh texts-diff <ios.txt> <and.txt>   # so tập text (thiếu/thừa chữ)
#   parity-diff.sh color <img> <x> <y>   # lấy hex 1 điểm (màu = tolerance 0, §0)
#   parity-diff.sh devcheck <WxH_pt>     # thiết bị Android có cùng logical size?
# Cần: xcrun simctl, adb, ImageMagick (compare/convert/composite/identify).
# ⚠ ĐO CHÉO HỆ TOẠ ĐỘ: chỉ so ảnh khi Android dp-size == iOS pt-size
#   (measurement §1.2). Đặt S2A_IOS_PT_W=<width_pt> để script tự cảnh báo.
set -uo pipefail

cmd="${1:?capture-ios|capture-and|determinize|diff|onion|iou|boxes-and|texts-and|texts-diff|color|devcheck}"

# dp-width thiết bị Android đang nối (rỗng nếu không có adb/device)
and_dp_w(){
  local px dn
  px=$(adb shell wm size 2>/dev/null | tail -1 | grep -oE '[0-9]+x[0-9]+' | tail -1) || return 0
  dn=$(adb shell wm density 2>/dev/null | tail -1 | grep -oE '[0-9]+' | tail -1) || return 0
  [ -n "${px:-}" ] && [ -n "${dn:-}" ] && echo $(( ${px%x*} * 160 / dn ))
}
warn_coord(){   # cảnh báo khi so ảnh giữa 2 logical size khác nhau
  local w; w="$(and_dp_w)"
  [ -z "${S2A_IOS_PT_W:-}" ] && { [ -n "${w:-}" ] && echo "ℹ Android ${w}dp | đặt S2A_IOS_PT_W để kiểm cặp thiết bị (measurement §1.2)"; return 0; }
  [ -z "${w:-}" ] && return 0
  if [ "$w" != "$S2A_IOS_PT_W" ]; then
    echo "❌ CẢNH BÁO ĐO CHÉO HỆ: Android ${w}dp ≠ iOS ${S2A_IOS_PT_W}pt."
    echo "   Scale ảnh sẽ giấu/thổi sai số ~$(awk -v a="$w" -v b="$S2A_IOS_PT_W" 'BEGIN{printf "%.1f", (a>b? a/b : b/a)*100-100}')%."
    echo "   KHÔNG kết luận PASS/FAIL. Sửa: adb shell wm size/density hoặc đổi AVD (preflight verify)."
  fi
}

case "$cmd" in
  determinize)  # áp môi trường tất định (measurement §1.0) trước khi chụp
    # iOS: freeze status bar (giờ/pin/sóng cố định)
    xcrun simctl status_bar booted override --time "9:41" --batteryLevel 100 \
      --batteryState charged --cellularBars 4 --wifiBars 3 2>/dev/null || true
    # Android: tắt animation (chụp tĩnh) + demo status bar
    adb shell settings put global window_animation_scale 0 2>/dev/null || true
    adb shell settings put global transition_animation_scale 0 2>/dev/null || true
    adb shell settings put global animator_duration_scale 0 2>/dev/null || true
    adb shell settings put global sysui_demo_allowed 1 2>/dev/null || true
    adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null 2>&1 || true
    echo "✅ determinized (nhớ KHÔI PHỤC animation_scale=1 sau khi đo motion §2)";;
  capture-ios)
    out="${2:?out.png}"
    xcrun simctl io booted screenshot "$out" || { echo "❌ chụp iOS lỗi (simulator booted?)"; exit 1; }
    echo "✅ iOS → $out";;
  capture-and)
    out="${2:?out.png}"
    adb exec-out screencap -p > "$out" 2>/dev/null || { echo "❌ chụp Android lỗi (adb device?)"; exit 1; }
    echo "✅ Android → $out";;
  iou)  # element-box IoU: CSV 'name,ix,iy,iw,ih,ax,ay,aw,ah' (đơn vị dp)
    csv="${2:?bbox.csv}"; THR="${3:-0.90}"
    [ -f "$csv" ] || { echo "❌ thiếu $csv"; exit 1; }
    rc=0
    while IFS=, read -r nm ix iy iw ih ax ay aw aht; do
      [ -z "${nm:-}" ] && continue; case "$nm" in name|\#*) continue;; esac
      v=$(awk -v ix="$ix" -v iy="$iy" -v iw="$iw" -v ih="$ih" \
              -v ax="$ax" -v ay="$ay" -v aw="$aw" -v ah="$aht" 'BEGIN{
        x1=(ix>ax?ix:ax); y1=(iy>ay?iy:ay);
        x2=((ix+iw)<(ax+aw)?(ix+iw):(ax+aw)); y2=((iy+ih)<(ay+ah)?(iy+ih):(ay+ah));
        iw2=x2-x1; ih2=y2-y1; inter=(iw2>0&&ih2>0)?iw2*ih2:0;
        uni=iw*ih+aw*ah-inter; printf "%.3f",(uni>0?inter/uni:0)}')
      ok=$(awk -v v="$v" -v t="$THR" 'BEGIN{print (v+0>=t)?"PASS":"FAIL"}')
      printf '%-22s IoU=%s %s\n' "$nm" "$v" "$ok"
      [ "$ok" = FAIL ] && rc=1
    done < "$csv"
    [ "$rc" -eq 0 ] && echo "IOU: GREEN (ngưỡng $THR)" \
      || echo "IOU: RED — element có IoU < $THR = lệch vị trí/kích thước, FAIL (enforcement §14)"
    exit "$rc";;
  diff)
    ios="${2:?ios.png}"; and="${3:?and.png}"; outd="${4:?out_diff.png}"
    ci="${5:-0}"; ca="${6:-0}"   # số pixel chrome cắt từ TOP (status bar…)
    warn_coord
    for f in "$ios" "$and"; do [ -f "$f" ] || { echo "❌ thiếu $f"; exit 1; }; done
    command -v compare >/dev/null || { echo "❌ thiếu ImageMagick"; exit 1; }
    tmpd=$(mktemp -d)
    # cắt chrome top theo Deviation đã ghi
    iw=$(identify -format '%w' "$ios"); ih=$(identify -format '%h' "$ios")
    aw=$(identify -format '%w' "$and"); ah=$(identify -format '%h' "$and")
    convert "$ios" -crop "${iw}x$((ih-ci))+0+${ci}" +repage "$tmpd/i.png"
    convert "$and" -crop "${aw}x$((ah-ca))+0+${ca}" +repage "$tmpd/a.png"
    # chuẩn hoá Android về đúng width ảnh iOS đã cắt (không méo: scale theo width)
    niw=$(identify -format '%w' "$tmpd/i.png")
    convert "$tmpd/a.png" -resize "${niw}x" "$tmpd/a2.png"
    # cắt cùng chiều cao nhỏ hơn để so 1:1
    nih=$(identify -format '%h' "$tmpd/i.png"); nah=$(identify -format '%h' "$tmpd/a2.png")
    H=$(( nih<nah ? nih : nah ))
    # chuẩn hoá color-space về sRGB trước khi so (chống lệch màu giả P3↔sRGB §1.1)
    convert "$tmpd/i.png"  -crop "${niw}x${H}+0+0" +repage -colorspace sRGB "$tmpd/I.png"
    convert "$tmpd/a2.png" -crop "${niw}x${H}+0+0" +repage -colorspace sRGB "$tmpd/A.png"
    total=$(( niw * H ))
    AE_raw=$(compare -metric AE -fuzz 2% "$tmpd/I.png" "$tmpd/A.png" "$outd" 2>&1 || true)
    # IM7 in AE dạng "118370" HOẶC sci-notation "1.1837e+06" → lấy token số đầu
    # (gồm cả mũ e±) rồi awk a+0 parse sci-notation, printf %d cắt về int.
    # Bug cũ: ${AE%%[^0-9]*} cắt "1.18e+06"→"1" → báo 0.000% PASS GIẢ.
    AE=$(printf '%s\n' "$AE_raw" | grep -oE '[0-9]+\.?[0-9]*([eE][+-]?[0-9]+)?' | head -1)
    AE=$(awk -v a="${AE:-$total}" 'BEGIN{printf "%d", a+0}')
    pct=$(awk -v a="$AE" -v t="$total" 'BEGIN{printf "%.3f", (t>0)? a*100.0/t : 100}')
    echo "pixel khác: $AE / $total  → %diff = ${pct}%"
    awk -v p="$pct" 'BEGIN{exit !(p+0<=1.0)}' \
      && echo "✅ PASS (≤1.0% tolerance §0) — heatmap: $outd" \
      || echo "❌ FAIL (>1.0%) — soi $outd, sửa; KHÔNG hạ tolerance (enforcement)"
    echo "ℹ -fuzz 2% ⇒ %diff KHÔNG chứng minh parity MÀU (tolerance 0). Kiểm màu riêng:"
    echo "   parity-diff.sh color <img> <x> <y>  + đối chiếu token lấy từ source iOS."
    rm -rf "$tmpd";;
  onion)  # onion-skin overlay 50% + blink — bắt lệch bố cục đều mà %diff giấu (§1.1)
    ios="${2:?ios.png}"; and="${3:?and.png}"; outo="${4:?out_onion.png}"
    ci="${5:-0}"; ca="${6:-0}"
    warn_coord
    for f in "$ios" "$and"; do [ -f "$f" ] || { echo "❌ thiếu $f"; exit 1; }; done
    command -v composite >/dev/null || { echo "❌ thiếu ImageMagick (composite)"; exit 1; }
    tmpd=$(mktemp -d)
    iw=$(identify -format '%w' "$ios"); ih=$(identify -format '%h' "$ios")
    aw=$(identify -format '%w' "$and"); ah=$(identify -format '%h' "$and")
    convert "$ios" -crop "${iw}x$((ih-ci))+0+${ci}" +repage -colorspace sRGB "$tmpd/i.png"
    convert "$and" -crop "${aw}x$((ah-ca))+0+${ca}" +repage -colorspace sRGB "$tmpd/a.png"
    niw=$(identify -format '%w' "$tmpd/i.png")
    convert "$tmpd/a.png" -resize "${niw}x" "$tmpd/a2.png"
    nih=$(identify -format '%h' "$tmpd/i.png"); nah=$(identify -format '%h' "$tmpd/a2.png")
    H=$(( nih<nah ? nih : nah ))
    convert "$tmpd/i.png"  -crop "${niw}x${H}+0+0" +repage "$tmpd/I.png"
    convert "$tmpd/a2.png" -crop "${niw}x${H}+0+0" +repage "$tmpd/A.png"
    # overlay 50%: iOS đè Android — mép/baseline lệch → "double-vision"
    composite -blend 50 "$tmpd/I.png" "$tmpd/A.png" "$outo"
    # blink 2 frame (GIF nhấp nháy) để mắt bắt dịch chuyển
    base="${outo%.*}"; convert -delay 40 -loop 0 "$tmpd/I.png" "$tmpd/A.png" "${base}_blink.gif" 2>/dev/null || true
    echo "✅ onion → $outo | blink → ${base}_blink.gif"
    echo "   QA soi: cạnh card / baseline text / icon có bóng đôi = lệch vị trí → FAIL (kể cả %diff qua)."
    rm -rf "$tmpd";;
  boxes-and)  # tự trích bbox Android (uiautomator) → CSV cột Android; MANAGER điền cột iOS
    out="${2:?out.csv}"
    tmpx=$(mktemp);
    adb shell uiautomator dump /sdcard/s2a_ui.xml >/dev/null 2>&1 || { echo "❌ uiautomator dump lỗi (adb device?)"; exit 1; }
    adb pull /sdcard/s2a_ui.xml "$tmpx" >/dev/null 2>&1 || { echo "❌ pull lỗi"; exit 1; }
    # density để đổi px→dp
    dens=$(adb shell wm density 2>/dev/null | grep -oE '[0-9]+' | tail -1); dens="${dens:-160}"
    echo "name,ix,iy,iw,ih,ax,ay,aw,ah" > "$out"
    # parse mỗi node có text/resource-id + bounds [x1,y1][x2,y2] → đổi dp
    grep -oE '(text|resource-id)="[^"]*"[^>]*bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' "$tmpx" 2>/dev/null \
    | sed -E 's/.*(text|resource-id)="([^"]*)".*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\2|\3 \4 \5 \6/' \
    | awk -v d="$dens" 'NF{split($0,p,"|"); nm=p[1]; gsub(/[, ]+/,"_",nm); if(nm=="")nm="el";
        split(p[2],b," "); x1=b[1];y1=b[2];x2=b[3];y2=b[4];
        ax=x1*160.0/d; ay=y1*160.0/d; aw=(x2-x1)*160.0/d; ah=(y2-y1)*160.0/d;
        printf "%s,,,,,%.0f,%.0f,%.0f,%.0f\n", nm, ax, ay, aw, ah }' >> "$out"
    n=$(($(wc -l < "$out")-1)); rm -f "$tmpx"
    echo "✅ $n element Android (dp) → $out"
    echo "   MANAGER điền cột iOS (ix,iy,iw,ih) từ describe-ui iOS (MCP) hoặc đo source, rồi: parity-diff.sh iou $out";;
  texts-and)  # trích TEXT đang hiển thị (Android) → 1 dòng 1 chuỗi, đã sort-uniq
    out="${2:?out.txt}"; tmpx=$(mktemp)
    adb shell uiautomator dump /sdcard/s2a_ui.xml >/dev/null 2>&1 || { echo "❌ uiautomator dump lỗi (adb device?)"; exit 1; }
    adb pull /sdcard/s2a_ui.xml "$tmpx" >/dev/null 2>&1 || { echo "❌ pull lỗi"; exit 1; }
    grep -oE 'text="[^"]+"' "$tmpx" | sed -E 's/^text="//;s/"$//' \
      | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | grep -v '^$' | sort -u > "$out"
    rm -f "$tmpx"
    echo "✅ $(wc -l < "$out" | tr -d ' ') chuỗi hiển thị → $out"
    echo "   iOS: lấy text set qua MCP describe-ui (accessibility tree) hoặc §8 i18n spec, rồi: parity-diff.sh texts-diff ios.txt $out";;
  texts-diff)  # so tập text iOS ↔ Android — bắt MẤT CHỮ/section im lặng (enforcement §11/§12)
    itxt="${2:?ios.txt}"; atxt="${3:?and.txt}"
    for f in "$itxt" "$atxt"; do [ -f "$f" ] || { echo "❌ thiếu $f"; exit 1; }; done
    miss=$(comm -23 <(sort -u "$itxt") <(sort -u "$atxt"))
    extra=$(comm -13 <(sort -u "$itxt") <(sort -u "$atxt"))
    nm=$(printf '%s' "$miss" | grep -c . || true); nx=$(printf '%s' "$extra" | grep -c . || true)
    [ "$nm" -gt 0 ] && { echo "❌ THIẾU ở Android ($nm):"; printf '%s\n' "$miss" | sed 's/^/   - /'; }
    [ "$nx" -gt 0 ] && { echo "⚠ THỪA ở Android ($nx) — phải truy về iOS hoặc là Deviation:"; printf '%s\n' "$extra" | sed 's/^/   + /'; }
    if [ "$nm" -eq 0 ] && [ "$nx" -eq 0 ]; then echo "TEXTS: GREEN (khớp tuyệt đối)"; exit 0; fi
    echo "TEXTS: RED (text content tolerance = 0 — §0)"; exit 1;;
  color)  # màu tolerance 0 nhưng diff dùng -fuzz 2% → PHẢI kiểm màu riêng bằng lệnh này
    img="${2:?img.png}"; x="${3:?x}"; y="${4:?y}"
    [ -f "$img" ] || { echo "❌ thiếu $img"; exit 1; }
    hex=$(convert "$img" -colorspace sRGB -format "%[hex:p{$x,$y}]" info: 2>/dev/null)
    echo "#$hex   (điểm $x,$y của $img)"
    echo "   So với token màu lấy TỪ SOURCE iOS (không pick từ ảnh đã lệch profile — §1.1). Δ phải = 0.";;
  devcheck)  # cặp thiết bị cùng logical size (measurement §1.2)
    want="${2:?WxH pt của thiết bị iOS tham chiếu, vd 393x852}"
    px=$(adb shell wm size 2>/dev/null | tail -1 | grep -oE '[0-9]+x[0-9]+' | tail -1 || true)
    dn=$(adb shell wm density 2>/dev/null | tail -1 | grep -oE '[0-9]+' | tail -1 || true)
    [ -z "${px:-}" ] || [ -z "${dn:-}" ] && { echo "❌ không đọc được wm size/density (adb device?)"; exit 1; }
    rw=$(( ${px%x*} * 160 / dn )); rh=$(( ${px#*x} * 160 / dn ))
    echo "Android: ${px}px @ ${dn}dpi → ${rw}x${rh} dp | iOS tham chiếu: ${want} pt"
    if [ "${rw}x${rh}" = "$want" ]; then echo "DEVCHECK: GREEN"; exit 0; fi
    echo "DEVCHECK: RED — lệch logical size ⇒ mọi %diff/IoU đều KHÔNG hợp lệ."
    echo "  Sửa nhanh: adb shell wm size ${want%x*}x${want#*x} && adb shell wm density $dn   (reset: wm size reset)"
    exit 1;;
  *) echo "Lệnh không hợp lệ"; exit 2;;
esac

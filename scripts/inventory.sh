#!/usr/bin/env bash
# inventory.sh — FULL traversal source iOS → khung Structure Map + cờ >500 LOC
# Dùng: scripts/inventory.sh <iOS_SOURCE_ROOT>
# Chỉ đọc. KHÔNG sửa gì. KHÔNG ra ngoài path truyền vào (project isolation).
set -euo pipefail

ROOT="${1:?Cần path source iOS (tuyệt đối)}"
[ -d "$ROOT" ] || { echo "Không thấy thư mục: $ROOT" >&2; exit 1; }

EXCLUDE='( -path */DerivedData/* -o -path */Pods/* -o -path */.git/* -o -path */build/* -o -path */.build/* )'

echo "# Structure Map skeleton — nguồn: $ROOT"
echo
echo "| iOS path | loại | LOC | disposition(điền) | Android path(điền) |"
echo "|---|---|---|---|---|"

# shellcheck disable=SC2086
find "$ROOT" -type f $EXCLUDE -prune -o -type f \
  \( -name '*.swift' -o -name '*.strings' -o -name '*.plist' \
     -o -name '*.entitlements' -o -name '*.xib' -o -name '*.storyboard' \
     -o -name 'project.yml' -o -name 'Package.swift' -o -name 'Podfile' \
     -o -name 'Contents.json' \) -print | sort | while read -r f; do
  rel="${f#"$ROOT"/}"
  case "$f" in
    *.swift)
      loc=$(wc -l < "$f" | tr -d ' ')
      kind="swift"
      case "$rel" in
        *iew*.swift|*View/*|*Views/*) kind="ui";;
        *ViewModel*|*Store*) kind="state";;
        *Service*|*Manager*|*Client*|*API*) kind="service";;
        *Model*|*Entity*|*DTO*) kind="model";;
        *.generated.swift|*+Generated*) kind="generated";;
      esac
      flag=""; [ "$loc" -gt 500 ] && flag=" ⚠>500"
      echo "| $rel | $kind$flag | $loc | | |";;
    *.strings)  echo "| $rel | i18n | - | i18n | res/values*/strings.xml |";;
    *Assets.xcassets*Contents.json) ;;  # asset catalog xử lý ở extract-assets
    *.plist|*.entitlements) echo "| $rel | config | - | config | manifest/gradle |";;
    *.xib|*.storyboard) echo "| $rel | ui-legacy | - | port | Compose |";;
    project.yml|*/project.yml|Package.swift|*/Package.swift|Podfile|*/Podfile)
      echo "| $rel | build | - | config | gradle |";;
  esac
done

echo
echo "## Cờ cần xử lý"
# shellcheck disable=SC2086
big=$(find "$ROOT" -type f $EXCLUDE -prune -o -type f -name '*.swift' -print \
      -exec wc -l {} + 2>/dev/null | awk '$1>500 && $2!="total"{print $2" ("$1")"}' || true)
if [ -n "${big:-}" ]; then
  echo "- File iOS > 500 LOC (file cap 500 LOC khi port, BẮT BUỘC tách bản Android):"
  echo "$big" | sed 's/^/  - /'
else
  echo "- Không file swift > 500 LOC."
fi
echo
echo "→ Mọi dòng phải có disposition ∈ {port,adapter,asset,config,i18n,generated,bỏ(lý do)}."
echo "→ KHÔNG để dòng trống disposition trước khi sang stage 2 (parity-spec.template §Cách khai thác)."

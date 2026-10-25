#!/usr/bin/env bash
# tests/run.sh [OUT_DIR] — qmllint, sync-ui.sh round trip + hand-edit detection,
# and an offscreen quickshell render of tests/fixture (a fake plugin that
# vendors ui/ with tools/sync-ui.sh). Needs quickshell (qs) and Omarchy's
# shell at /usr/share/omarchy/shell (qs.Commons, qs.Ui).
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
shell_dir=${OMARCHY_SHELL:-/usr/share/omarchy/shell}
qmllint=${QMLLINT:-/usr/lib/qt6/bin/qmllint}
out=${1:-$here/tests/out}
mkdir -p "$out"; out=$(cd "$out" && pwd)
fail=0
ok() { echo "ok   $*"; }
bad() { echo "FAIL $*"; fail=1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# 1. qmllint the library
if [ -x "$qmllint" ]; then
  if "$qmllint" -I "$shell_dir" -I "$here/ui" "$here"/ui/*.qml; then ok "qmllint ui/*.qml"; else bad "qmllint ui/*.qml"; fi
else echo "skip qmllint ($qmllint not found)"; fi

# 2. sync-ui.sh against a throwaway git repo holding the working tree's ui/
mkdir -p "$T/src"; cp -R "$here/ui" "$T/src/ui"
git -C "$T/src" init -q; git -C "$T/src" add -A
git -C "$T/src" -c user.name=t -c user.email=t@t commit -qm test; git -C "$T/src" tag v9.9.9
cp -R "$here/tests/fixture" "$T/fx"; mkdir -p "$T/fx/plugin/tools"
cp "$here/tools/sync-ui.sh" "$T/fx/plugin/tools/"
sync() { YOYO_UI_REPO="$T/src" "$T/fx/plugin/tools/sync-ui.sh" "$@"; }
if sync v9.9.9 >/dev/null; then ok "sync-ui.sh v9.9.9"; else bad "sync-ui.sh v9.9.9"; fi
grep -q "^commit $(git -C "$T/src" rev-parse HEAD)$" "$T/fx/plugin/vendor/yoyo-ui/VERSION" && ok "VERSION pins the commit" || bad "VERSION pins the commit"
sync --check >/dev/null && ok "--check on a clean copy" || bad "--check on a clean copy"
sync --check-upstream >/dev/null && ok "--check-upstream on a clean copy" || bad "--check-upstream on a clean copy"
v="$T/fx/plugin/vendor/yoyo-ui"
cp "$v/ChipRow.qml" "$T/keep"; echo "// hand edit" >> "$v/ChipRow.qml"
sync --check >/dev/null 2>&1 && bad "--check catches an edited file" || ok "--check catches an edited file"
cp "$T/keep" "$v/ChipRow.qml"; touch "$v/Extra.qml"
sync --check >/dev/null 2>&1 && bad "--check catches an added file" || ok "--check catches an added file"
rm "$v/Extra.qml"; mv "$v/KeyHints.qml" "$T/kh"
sync --check >/dev/null 2>&1 && bad "--check catches a removed file" || ok "--check catches a removed file"
mv "$T/kh" "$v/KeyHints.qml"
# Regenerating MANIFEST by hand fools --check but not --check-upstream.
echo "// hand edit" >> "$v/ChipRow.qml"
(cd "$v" && find . -type f ! -name VERSION ! -name MANIFEST -printf '%P\n' | LC_ALL=C sort | while read -r f; do sha256sum -- "$f"; done) > "$v/MANIFEST"
sync --check-upstream >/dev/null 2>&1 && bad "--check-upstream catches a forged MANIFEST" || ok "--check-upstream catches a forged MANIFEST"
sync v9.9.9 >/dev/null && sync --check >/dev/null && ok "re-sync restores the copy" || bad "re-sync restores the copy"
sync nope >/dev/null 2>&1 && bad "unknown ref fails" || ok "unknown ref fails"

# 3. quickshell: vendored import from the plugin root, from components/ and qualified
ln -s "$shell_dir/Commons" "$T/fx/Commons"; ln -s "$shell_dir/Ui" "$T/fx/Ui"
for tint in 0 1; do
  name=$([ $tint = 1 ] && echo preview-tinted || echo preview)
  log=$(env YOYO_TINT=$tint YOYO_OUT="$out/$name.png" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_SCALE_FACTOR="${QT_SCALE_FACTOR:-2}" timeout 30 qs -p "$T/fx" 2>&1 || true)
  probe=$(grep -o 'probe expected=.*' <<<"$log" || true)
  errs=$(grep -E 'WARN|ERROR' <<<"$log" | grep -vE 'WAYLAND_DISPLAY|QT_QPA_PLATFORM|actually running wayland|window masks|--- WARNING' || true)
  if ! grep -q "saved $out/$name.png" <<<"$log"; then bad "qs render $name"; echo "$log" | tail -20; continue; fi
  ok "qs render $name -> $out/$name.png"
  [ -z "$errs" ] && ok "no QML warnings ($name)" || { bad "QML warnings ($name)"; echo "$errs"; }
  read -r e r c q < <(sed -E 's/probe expected=(\S+) root=(\S+) components=(\S+) qualified=(\S+)/\1 \2 \3 \4/' <<<"$probe")
  [ -n "${e:-}" ] && [ "$e" = "$r" ] && [ "$e" = "$c" ] && [ "$e" = "$q" ] \
    && ok "one Theme instance: root, components/ and qualified all see $e ($name)" \
    || bad "Theme instance mismatch ($name): $probe"
done

[ $fail = 0 ] && echo "all tests passed" || { echo "some tests FAILED"; exit 1; }

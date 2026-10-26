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
# expect NAME CMD...: CMD succeeds. refuse NAME CMD...: CMD fails.
expect() { local n=$1; shift; if "$@"; then ok "$n"; else bad "$n"; fi; }
refuse() { local n=$1; shift; if "$@"; then bad "$n"; else ok "$n"; fi; }
quiet() { "$@" >/dev/null 2>&1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# 1. lint. qmllint resolves qs.Commons / qs.Ui like the shell does (a qs/
# import root), and any warning fails. One known false positive is dropped:
# qmllint 6.x says "Theme not declared as singleton in qmldir" when it lints
# Theme.qml itself, although ui/qmldir declares it (and the shell loads it so).
if [ -x "$qmllint" ]; then
  mkdir -p "$T/imports/qs"
  ln -s "$shell_dir/Commons" "$T/imports/qs/Commons"; ln -s "$shell_dir/Ui" "$T/imports/qs/Ui"
  lint=$("$qmllint" -I "$T/imports" -I /usr/lib/qt6/qml "$here"/ui/*.qml 2>&1 || true)
  lint=$(grep -v 'Type Theme not declared as singleton in qmldir but using pragma Singleton' <<<"$lint" || true)
  if [ -z "$lint" ]; then ok "qmllint ui/*.qml (no warnings)"; else bad "qmllint ui/*.qml"; echo "$lint"; fi
else echo "skip qmllint ($qmllint not found)"; fi
shellcheck_bin=${SHELLCHECK:-$(command -v shellcheck || true)}
if [ -n "$shellcheck_bin" ]; then
  if "$shellcheck_bin" "$here/tools/sync-ui.sh" "$here/tests/run.sh"; then ok "shellcheck"; else bad "shellcheck"; fi
else echo "skip shellcheck (not installed; SHELLCHECK=... to point at one)"; fi

# 2. sync-ui.sh against a throwaway git repo holding the working tree's ui/
mkdir -p "$T/src"; cp -R "$here/ui" "$T/src/ui"
git -C "$T/src" init -q; git -C "$T/src" add -A
git -C "$T/src" -c user.name=t -c user.email=t@t commit -qm test; git -C "$T/src" tag v9.9.9
cp -R "$here/tests/fixture" "$T/fx"; mkdir -p "$T/fx/plugin/tools"
cp "$here/tools/sync-ui.sh" "$T/fx/plugin/tools/"
sync() { YOYO_UI_REPO="$T/src" "$T/fx/plugin/tools/sync-ui.sh" "$@"; }
expect "sync-ui.sh v9.9.9" quiet sync v9.9.9
expect "VERSION pins the commit" grep -q "^commit $(git -C "$T/src" rev-parse HEAD)$" "$T/fx/plugin/vendor/yoyo-ui/VERSION"
expect "--check on a clean copy" quiet sync --check
expect "--check-upstream on a clean copy" quiet sync --check-upstream
v="$T/fx/plugin/vendor/yoyo-ui"
cp "$v/ChipRow.qml" "$T/keep"; echo "// hand edit" >> "$v/ChipRow.qml"
refuse "--check catches an edited file" quiet sync --check
cp "$T/keep" "$v/ChipRow.qml"; touch "$v/Extra.qml"
refuse "--check catches an added file" quiet sync --check
rm "$v/Extra.qml"; mv "$v/KeyHints.qml" "$T/kh"
refuse "--check catches a removed file" quiet sync --check
mv "$T/kh" "$v/KeyHints.qml"
# Regenerating MANIFEST by hand fools --check but not --check-upstream.
echo "// hand edit" >> "$v/ChipRow.qml"
(cd "$v" && find . -type f ! -name VERSION ! -name MANIFEST -printf '%P\n' | LC_ALL=C sort | while read -r f; do sha256sum -- "$f"; done) > "$v/MANIFEST"
refuse "--check-upstream catches a forged MANIFEST" quiet sync --check-upstream
resync() { sync v9.9.9 && sync --check; }
expect "re-sync restores the copy" quiet resync
refuse "unknown ref fails" quiet sync nope

# 3. quickshell: vendored import from the plugin root, from components/ and qualified
ln -s "$shell_dir/Commons" "$T/fx/Commons"; ln -s "$shell_dir/Ui" "$T/fx/Ui"
for tint in 0 1; do
  name=$([ $tint = 1 ] && echo preview-tinted || echo preview)
  log=$(env YOYO_TINT=$tint YOYO_OUT="$out/$name.png" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_SCALE_FACTOR="${QT_SCALE_FACTOR:-2}" timeout 30 qs -p "$T/fx" 2>&1 || true)
  probe=$(grep -o 'probe expected=.*' <<<"$log" || true)
  errs=$(grep -E 'WARN|ERROR' <<<"$log" | grep -vE 'WAYLAND_DISPLAY|QT_QPA_PLATFORM|actually running wayland|window masks|--- WARNING' || true)
  if ! grep -q "saved $out/$name.png" <<<"$log"; then bad "qs render $name"; echo "$log" | tail -20; continue; fi
  ok "qs render $name -> $out/$name.png"
  if [ -z "$errs" ]; then ok "no QML warnings ($name)"; else bad "QML warnings ($name)"; echo "$errs"; fi
  read -r e r c q < <(sed -E 's/probe expected=(\S+) root=(\S+) components=(\S+) qualified=(\S+)/\1 \2 \3 \4/' <<<"$probe")
  if [ -n "${e:-}" ] && [ "$e" = "$r" ] && [ "$e" = "$c" ] && [ "$e" = "$q" ]; then
    ok "one Theme instance: root, components/ and qualified all see $e ($name)"
  else bad "Theme instance mismatch ($name): $probe"; fi
done

# 4. behaviour tests (tests/fixture/logic.qml)
log=$(QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software timeout 30 qs -p "$T/fx/logic.qml" 2>&1 || true)
grep -oE '(PASS|FAIL) .*' <<<"$log" | sed 's/^PASS/ok  /; s/^FAIL/FAIL/' || true
grep -q 'FAIL ' <<<"$log" && fail=1
if ! grep -qE 'logic done [0-9]+ 0$' <<<"$log"; then bad "logic.qml did not finish cleanly"; echo "$log" | grep -E 'WARN|ERROR' | tail -20; fi
lw=$(grep -E 'WARN|ERROR' <<<"$log" | grep -vE 'WAYLAND_DISPLAY|QT_QPA_PLATFORM|actually running wayland|window masks|--- WARNING' || true)
if [ -z "$lw" ]; then ok "no QML warnings (logic)"; else bad "QML warnings (logic)"; echo "$lw"; fi

if [ $fail = 0 ]; then echo "all tests passed"; else echo "some tests FAILED"; exit 1; fi

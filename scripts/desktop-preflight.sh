#!/usr/bin/env bash
# Desktop pre-flight: DESKTOP_STANDARD failures that are visible WITHOUT the
# target OS. Flutter cannot build macOS on Linux or Windows on macOS, so these
# defects otherwise surface only when someone finally builds on that host —
# usually at release time, usually as "works in debug, broken in release".
#
# Usage: desktop-preflight.sh [project-dir]          (default: current directory)
# Checks only the desktop platforms whose folders exist (linux/ windows/ macos/).
#
#   BLOCKER  macOS Release.entitlements lacks network.client while lib/ makes
#            network calls; lacks files.user-selected.* while lib/ opens file
#            dialogs. The sandbox denies both silently in release builds.
#   MAJOR    a plugin registered for one targeted desktop OS but not another
#            (record the gap in the FLS-07 parity matrix or fix it).
#   MINOR    window title still the template default; no minimum window size.
#
# Exit: 0 no BLOCKER · 1 BLOCKER found · 2 usage. Reads files only.
set -uo pipefail

ROOT="${1:-.}"
[ -d "$ROOT" ] || { echo "desktop-preflight: no such directory: $ROOT" >&2; exit 2; }
cd "$ROOT" || exit 2
[ -f pubspec.yaml ] || { echo "desktop-preflight: no pubspec.yaml in $ROOT" >&2; exit 2; }

BLOCKERS=0; MAJORS=0; MINORS=0
report() {
  case "$1" in BLOCKER) BLOCKERS=$((BLOCKERS+1)) ;; MAJOR) MAJORS=$((MAJORS+1)) ;; MINOR) MINORS=$((MINORS+1)) ;; esac
  printf '  %-8s %s\n' "$1" "$2"
}

NAME="$(grep -m1 -E '^name:' pubspec.yaml | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]*$//')"
TARGETS=""
for os in linux windows macos; do [ -d "$os" ] && TARGETS="${TARGETS} ${os}"; done
printf '\nDesktop pre-flight: %s (targets:%s)\n\n' "${NAME:-?}" "${TARGETS:- none}"
[ -n "$TARGETS" ] || { echo "  no desktop platform folders — nothing to check"; exit 0; }

uses() { grep -rlE "$1" lib --include='*.dart' 2>/dev/null | head -1; }

# ------------------------------------------------------------ macOS sandbox
if [ -d macos ]; then
  REL="macos/Runner/Release.entitlements"
  if [ ! -f "$REL" ]; then
    report MAJOR "macOS: $REL missing — cannot check sandbox entitlements"
  elif grep -q 'com.apple.security.app-sandbox' "$REL"; then
    net="$(uses 'package:(dio|http|web_socket_channel|graphql|grpc)/|HttpClient\(|WebSocket\.connect')"
    if [ -n "$net" ] && ! grep -q 'com.apple.security.network.client' "$REL"; then
      report BLOCKER "macOS: $REL lacks com.apple.security.network.client but lib/ makes network calls (e.g. $net) — every request fails in release builds"
    fi
    files="$(uses 'package:(file_picker|file_selector|image_picker)/|FilePicker|openFile\(|getSaveLocation\(')"
    if [ -n "$files" ] && ! grep -qE 'com.apple.security.files.user-selected.read-(write|only)' "$REL"; then
      report BLOCKER "macOS: $REL lacks com.apple.security.files.user-selected.* but lib/ opens file dialogs (e.g. $files) — picked files cannot be read or written in release builds"
    fi
  fi
fi

# --------------------------------------------- plugin parity across desktops
# Source of truth: .flutter-plugins-dependencies, written by `flutter pub get`,
# which lists every plugin per platform — native, Dart-only and FFI alike. The
# generated registrants are NOT usable here: they omit Dart-only and FFI
# plugins, so comparing them reports plugins as missing that work fine.
# Federated implementations differ only by suffix (file_selector_linux / _windows).
PDEPS=.flutter-plugins-dependencies
plugins_for() {
  tr -d '\n' < "$PDEPS" \
    | sed -E 's/"(ios|android|macos|linux|windows|web)":\[/\n@\1@/g; s/"dependencyGraph"/\n@graph@/' \
    | awk -v os="$1" 'index($0, "@" os "@") == 1' \
    | grep -oE '"name":"[^"]+"' | sed -E 's/"name":"([^"]+)"/\1/' \
    | sed -E 's/_(linux|windows|macos|foundation|darwin)$//' | sort -u
}
set -- $TARGETS
if [ "$#" -gt 1 ]; then
  if [ ! -f "$PDEPS" ]; then
    report MINOR "plugin parity not checked: $PDEPS missing — run 'flutter pub get' first"
  else
    ALL=""
    for os in $TARGETS; do
      p="$(plugins_for "$os")"
      eval "PLUG_${os}=\"\$p\""
      ALL="$(printf '%s\n%s' "$ALL" "$p")"
    done
    for plug in $(printf '%s\n' "$ALL" | grep -v '^$' | sort -u); do
      missing=""
      for os in $TARGETS; do
        eval "list=\"\$PLUG_${os}\""
        grep -qx "$plug" <<< "$list" || missing="${missing} ${os}"
      done
      [ -z "$missing" ] || report MAJOR "plugin '${plug}' has no implementation on:${missing} — confirm it is unused there (FLS-07 parity matrix) or add support"
    done
  fi
fi

# ------------------------------------------------- window title and min size
if [ -n "$NAME" ]; then
  if [ -f windows/runner/main.cpp ] && grep -q "L\"${NAME}\"" windows/runner/main.cpp; then
    report MINOR "Windows: window title is the template default \"${NAME}\" (windows/runner/main.cpp)"
  fi
  if [ -f linux/runner/my_application.cc ] && grep -qE "set_title\([^,]+, \"${NAME}\"\)" linux/runner/my_application.cc; then
    report MINOR "Linux: window title is the template default \"${NAME}\" (linux/runner/my_application.cc)"
  fi
fi
if ! grep -rqE 'setMinimumSize|WM_GETMINMAXINFO|gtk_widget_set_size_request|minSize|contentMinSize' \
      lib windows/runner linux/runner macos/Runner 2>/dev/null; then
  report MINOR "no minimum window size set — users can shrink the window until layouts overflow (DESKTOP_STANDARD §2.1)"
fi

printf '\nblockers: %s  majors: %s  minors: %s\n' "$BLOCKERS" "$MAJORS" "$MINORS"
if [ "$BLOCKERS" -gt 0 ]; then echo "desktop-preflight: BLOCKED"; exit 1; fi
echo "desktop-preflight: no blockers"
exit 0

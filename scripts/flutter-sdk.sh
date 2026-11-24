#!/usr/bin/env bash
# Locate a Flutter SDK even when `flutter` is not on PATH.
#
# Why: "flutter: command not found" is not the same as "no toolchain". A machine
# often has an SDK that the shell simply does not see — installed by version
# managers, IDEs, or user-local setups. Reporting `unverified (no toolchain)`
# while the project's own .dart_tool records exactly where the SDK lives is a
# false negative, and it pushes work to CI or to "not run" for no reason.
#
# Usage:
#   flutter-sdk.sh [project-dir]          print the SDK root; how it was found on stderr
#   flutter-sdk.sh --env [project-dir]    print shell code to `eval`: sources an
#                                         adjacent env.sh when one exists (desktop
#                                         toolchains need its compilers), else
#                                         prepends <root>/bin to PATH
#
# Search order (first valid wins; valid = <root>/bin/flutter is executable):
#   1. `flutter` already on PATH
#   2. $FLUTTER_ROOT, $FLUTTER_SDK_ROOT, $FLUTTER_HOME
#   3. <project>/.fvm/flutter_sdk               (fvm)
#   4. <project>/.dart_tool/package_config.json  "flutterRoot" (last SDK used here)
#   5. ~/flutter ~/development/flutter ~/sdks/flutter ~/fvm/default
#      /opt/flutter /usr/local/flutter ~/snap/flutter/common/flutter
#   6. a sibling project's .dart_tool/package_config.json "flutterRoot" — a new
#      project has no .dart_tool yet, and projects on one machine usually share
#      an SDK; the sibling it came from is named on stderr
#
# Exit: 0 found · 1 not found · 2 usage. Reads files only; never installs.
set -uo pipefail

MODE=root
if [ "${1:-}" = "--env" ]; then MODE=env; shift; fi
case "${1:-}" in -h|--help) sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; -*) echo "flutter-sdk: unknown option $1" >&2; exit 2 ;; esac
PROJECT="${1:-$PWD}"

valid() { [ -n "$1" ] && [ -x "$1/bin/flutter" ]; }
found() {
  local root="$1" how="$2" envsh
  root="$(cd "$root" && pwd)"
  echo "flutter-sdk: ${root} (found via ${how})" >&2
  if [ "$MODE" = root ]; then printf '%s\n' "$root"; exit 0; fi
  envsh="$(dirname "$root")/env.sh"
  if [ -f "$envsh" ] && grep -q "$root" "$envsh" 2>/dev/null; then
    echo "flutter-sdk: sourcing adjacent toolchain script ${envsh}" >&2
    printf 'source %q\n' "$envsh"
  else
    printf 'export PATH=%q:"$PATH"\n' "$root/bin"
  fi
  exit 0
}

# 1. Already on PATH: resolve the real root behind any symlink.
if command -v flutter >/dev/null 2>&1; then
  bin="$(command -v flutter)"
  root="$(cd "$(dirname "$(readlink -f "$bin" 2>/dev/null || echo "$bin")")/.." && pwd)"
  if valid "$root"; then
    [ "$MODE" = env ] && { echo "flutter-sdk: ${root} already on PATH" >&2; echo ':'; exit 0; }
    found "$root" "PATH"
  fi
fi

# 2. Environment variables.
for var in FLUTTER_ROOT FLUTTER_SDK_ROOT FLUTTER_HOME; do
  val="${!var:-}"
  valid "$val" && found "$val" "\$${var}"
done

# 3. fvm project link.
valid "${PROJECT}/.fvm/flutter_sdk" && found "${PROJECT}/.fvm/flutter_sdk" ".fvm/flutter_sdk"

# 4. The SDK this project last resolved with.
PC="${PROJECT}/.dart_tool/package_config.json"
if [ -f "$PC" ]; then
  fr="$(grep -oE '"flutterRoot"[[:space:]]*:[[:space:]]*"[^"]*"' "$PC" | head -1 \
        | sed -E 's/.*"flutterRoot"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/; s#^file://##')"
  valid "$fr" && found "$fr" ".dart_tool/package_config.json flutterRoot"
fi

# 5. Conventional install locations.
for c in "$HOME/flutter" "$HOME/development/flutter" "$HOME/sdks/flutter" "$HOME/fvm/default" \
         /opt/flutter /usr/local/flutter "$HOME/snap/flutter/common/flutter"; do
  valid "$c" && found "$c" "conventional location"
done

# 6. A sibling project's recorded SDK (newest config first).
PARENT="$(cd "${PROJECT}/.." 2>/dev/null && pwd)"
if [ -n "$PARENT" ]; then
  while IFS= read -r spc; do
    fr="$(grep -oE '"flutterRoot"[[:space:]]*:[[:space:]]*"[^"]*"' "$spc" | head -1 \
          | sed -E 's/.*"flutterRoot"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/; s#^file://##')"
    sib="$(basename "$(dirname "$(dirname "$spc")")")"
    valid "$fr" && found "$fr" "sibling project ${sib} (.dart_tool/package_config.json)"
  done < <(find "$PARENT" -mindepth 3 -maxdepth 3 -path '*/.dart_tool/package_config.json' -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2-)
fi

echo "flutter-sdk: no Flutter SDK found (checked PATH, FLUTTER_ROOT/FLUTTER_SDK_ROOT/FLUTTER_HOME, .fvm, .dart_tool/package_config.json, conventional locations, sibling projects)" >&2
exit 1

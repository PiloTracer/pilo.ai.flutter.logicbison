#!/usr/bin/env bash
# Verify a Flutter project's releases tree (RELEASE_STANDARD § Release layout).
#
#   <repo>/releases/<version>/linux/    every version carries all three OSes,
#                            macos/    each non-empty; versions are
#                            windows/  MAJOR.MINOR.PATCH, append-only
#
# Why each rule exists:
#   - all three OSes: a version with a missing OS is a release some users cannot
#     install, and nobody notices until they ask for it;
#   - semantic versions only: "latest", "final", "1.0" sort wrongly and cannot be
#     compared, so "incremental" stops meaning anything;
#   - the next release needs a higher pubspec version: rebuilding into an
#     existing version folder silently replaces binaries people already have.
#
# Usage: release-layout-verify.sh [repo]      (default: current directory)
# Exit: 0 valid · 1 findings · 2 usage
set -uo pipefail

ROOT="${1:-.}"
[ -d "$ROOT" ] || { echo "release-layout-verify: no such directory: $ROOT" >&2; exit 2; }
cd "$ROOT" || exit 2

FINDINGS=0
fail() { FINDINGS=$((FINDINGS+1)); printf '  FAIL  %s\n' "$1"; }
ok()   { printf '  ok    %s\n' "$1"; }

printf '\nRelease layout: %s/releases\n\n' "$(pwd)"

if [ ! -d releases ]; then
  echo "  none  no releases/ yet — the first release creates releases/<version>/{linux,macos,windows}"
  echo "release-layout-verify: nothing to check"
  exit 0
fi

# Strict semver core; a build suffix (+N) belongs in pubspec, not in the folder.
is_semver() { [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; }

VERSIONS=""
for entry in releases/* releases/.[!.]*; do
  [ -e "$entry" ] || continue
  name="$(basename "$entry")"
  if [ ! -d "$entry" ]; then
    fail "releases/${name} is a file — only version folders belong directly under releases/"
    continue
  fi
  if ! is_semver "$name"; then
    fail "releases/${name}/ is not a MAJOR.MINOR.PATCH version folder"
    continue
  fi
  VERSIONS="${VERSIONS}${name}"$'\n'
  missing=""
  for os in linux macos windows; do
    if [ ! -d "${entry}/${os}" ]; then
      missing="${missing} ${os}"
    elif [ -z "$(find "${entry}/${os}" -type f -size +0c -print -quit)" ]; then
      fail "releases/${name}/${os}/ is empty"
    fi
  done
  [ -z "$missing" ] || fail "releases/${name}/ is missing:${missing} (every release ships linux, macos and windows)"
  for extra in "$entry"/*; do
    [ -e "$extra" ] || continue
    case "$(basename "$extra")" in linux|macos|windows) ;; *)
      fail "releases/${name}/$(basename "$extra") is not one of linux, macos, windows" ;;
    esac
  done
done

LATEST="$(printf '%s' "$VERSIONS" | grep -v '^$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
COUNT="$(printf '%s' "$VERSIONS" | grep -c . || true)"
[ -n "$LATEST" ] && ok "${COUNT} release(s); latest ${LATEST}"

# Incremental: the version the project will release next must not already exist.
if [ -f pubspec.yaml ]; then
  PV="$(grep -m1 -E '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*//; s/\+.*//; s/[[:space:]]*$//')"
  if [ -n "$PV" ] && [ -n "$LATEST" ]; then
    newest="$(printf '%s\n%s\n' "$PV" "$LATEST" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
    if [ "$PV" = "$LATEST" ]; then
      ok "pubspec version ${PV} is the latest release — run scripts/release-bump.sh <patch|minor|major> before the next release"
    elif [ -d "releases/${PV}" ]; then
      fail "pubspec version ${PV} already has a release folder but is not the latest (${LATEST}) — releases are append-only"
    elif [ "$newest" != "$PV" ]; then
      fail "pubspec version ${PV} is lower than the latest release ${LATEST} — releases only move forward"
    else
      ok "pubspec version ${PV} is ahead of the latest release — ready to release"
    fi
  fi
fi

printf '\nfindings: %s\n' "$FINDINGS"
[ "$FINDINGS" -eq 0 ] && { echo "release-layout-verify: VALID"; exit 0; }
echo "release-layout-verify: INVALID"
exit 1

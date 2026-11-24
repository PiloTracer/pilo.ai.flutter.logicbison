#!/usr/bin/env bash
# Set the next release version in pubspec.yaml (RELEASE_STANDARD § Release
# numbering). The next version is computed from the newest folder in
# releases/, never typed by hand, so a number can be neither skipped nor reused.
#
# Usage: release-bump.sh [patch|minor|major] [--dry-run] [repo]
#   patch  fixes only, no new behaviour            1.4.2 -> 1.4.3   (default)
#   minor  new features, nothing existing breaks   1.4.2 -> 1.5.0
#   major  breaking change, migration or redesign  1.4.2 -> 2.0.0
#
# Rules:
#   - base = newest releases/<version>/; with no releases yet, the first release
#     is the current pubspec version as-is (Flutter's default is 1.0.0+1);
#   - if pubspec is already at or ahead of the computed next version (a bump
#     made earlier and not yet released), nothing changes — bumping twice would
#     skip a number;
#   - the build number (+N) goes up by one on every bump and is never reused:
#     the stores reject a reused build number.
#
# Exit: 0 bumped or nothing to do · 1 refused · 2 usage
set -uo pipefail

LEVEL=patch; DRY=0; ROOT="."
while [ $# -gt 0 ]; do
  case "$1" in
    patch|minor|major) LEVEL="$1"; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "release-bump: unknown option $1" >&2; exit 2 ;;
    *) ROOT="$1"; shift ;;
  esac
done
cd "$ROOT" 2>/dev/null || { echo "release-bump: no such directory: $ROOT" >&2; exit 2; }
[ -f pubspec.yaml ] || { echo "release-bump: no pubspec.yaml in $(pwd)" >&2; exit 2; }

LINE="$(grep -m1 -E '^version:' pubspec.yaml || true)"
[ -n "$LINE" ] || { echo "release-bump: pubspec.yaml has no version: line" >&2; exit 1; }
CUR="$(sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*$//' <<< "$LINE")"
CUR_V="${CUR%%+*}"
CUR_B=0; [ "$CUR" != "$CUR_V" ] && CUR_B="${CUR#*+}"
SEMVER='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
[[ "$CUR_V" =~ $SEMVER ]] || { echo "release-bump: pubspec version '$CUR' is not MAJOR.MINOR.PATCH[+BUILD]" >&2; exit 1; }
[[ "$CUR_B" =~ ^[0-9]+$ ]] || { echo "release-bump: build number '$CUR_B' is not a number" >&2; exit 1; }

vsort() { sort -t. -k1,1n -k2,2n -k3,3n; }
LATEST=""
if [ -d releases ]; then
  LATEST="$(find releases -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -E "$SEMVER" | vsort | tail -1 || true)"
fi

if [ -z "$LATEST" ]; then
  echo "release-bump: no releases yet — the first release is ${CUR_V} (pubspec ${CUR}); nothing to bump"
  exit 0
fi

IFS=. read -r MA MI PA <<< "$LATEST"
case "$LEVEL" in
  patch) NEXT="${MA}.${MI}.$((PA+1))" ;;
  minor) NEXT="${MA}.$((MI+1)).0" ;;
  major) NEXT="$((MA+1)).0.0" ;;
esac

AHEAD="$(printf '%s\n%s\n' "$CUR_V" "$NEXT" | vsort | tail -1)"
if [ "$AHEAD" = "$CUR_V" ]; then
  echo "release-bump: pubspec is already at ${CUR} (latest release ${LATEST}; ${LEVEL} would be ${NEXT}) — not bumping again"
  exit 0
fi

NEW="${NEXT}+$((CUR_B+1))"
echo "release-bump: ${CUR} -> ${NEW}  (${LEVEL}; latest release ${LATEST})"
[ "$DRY" -eq 1 ] && { echo "release-bump: dry run — pubspec.yaml unchanged"; exit 0; }

TMP="$(mktemp)"
awk -v new="version: ${NEW}" 'done == 0 && /^version:/ { print new; done = 1; next } { print }' pubspec.yaml > "$TMP" \
  && cat "$TMP" > pubspec.yaml && rm -f "$TMP"
grep -m1 -E '^version:' pubspec.yaml

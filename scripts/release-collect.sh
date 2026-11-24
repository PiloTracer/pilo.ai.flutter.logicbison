#!/usr/bin/env bash
# Collect a CI release into the project's releases tree (RELEASE_STANDARD
# § Release layout): download the run's `releases` artifact and place it at
# <repo>/releases/<version>/{linux,macos,windows}.
#
# Refuses — never overwrites — when:
#   - the artifact does not hold exactly one version with all three OSes;
#   - releases/<version>/ already exists (releases are append-only: bump the
#     pubspec version and build again).
#
# Usage: release-collect.sh [--run <run-id>] [--workflow <file>] [repo]
#   default run: the newest successful run of --workflow (default desktop-builds.yml)
# Needs: gh (authenticated) and a GitHub remote. Exit: 0 collected · 1 refused · 2 usage
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN=""; WF="desktop-builds.yml"; ROOT="."
while [ $# -gt 0 ]; do
  case "$1" in
    --run) RUN="${2:-}"; shift 2 ;;
    --workflow) WF="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "release-collect: unknown option $1" >&2; exit 2 ;;
    *) ROOT="$1"; shift ;;
  esac
done
[ -d "$ROOT" ] || { echo "release-collect: no such directory: $ROOT" >&2; exit 2; }
cd "$ROOT" || exit 2
command -v gh >/dev/null 2>&1 || { echo "release-collect: gh CLI required" >&2; exit 2; }

if [ -z "$RUN" ]; then
  RUN="$(gh run list --workflow "$WF" --limit 20 --json databaseId,conclusion \
          -q '[.[] | select(.conclusion=="success")][0].databaseId' 2>/dev/null)"
  [ -n "$RUN" ] && [ "$RUN" != "null" ] || { echo "release-collect: no successful run of $WF found" >&2; exit 1; }
fi
echo "release-collect: run ${RUN} (${WF})"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
gh run download "$RUN" -n releases -D "$TMP/releases" >/dev/null 2>&1 \
  || { echo "release-collect: run ${RUN} has no 'releases' artifact (expired, failed, or an older workflow)" >&2; exit 1; }

mapfile -t VERS < <(find "$TMP/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
[ "${#VERS[@]}" -eq 1 ] || { echo "release-collect: artifact holds ${#VERS[@]} version folders (${VERS[*]:-none}); expected exactly one" >&2; exit 1; }
V="${VERS[0]}"
for os in linux macos windows; do
  [ -n "$(find "$TMP/releases/$V/$os" -type f -size +0c -print -quit 2>/dev/null)" ] \
    || { echo "release-collect: artifact version ${V} has no ${os} build — every release ships linux, macos and windows" >&2; exit 1; }
done

if [ -e "releases/$V" ]; then
  echo "release-collect: releases/${V}/ already exists — releases are append-only. Bump the version in pubspec.yaml and build again." >&2
  exit 1
fi

mkdir -p releases
mv "$TMP/releases/$V" "releases/$V"
echo "release-collect: placed releases/${V}/"
find "releases/$V" -type f -exec ls -l {} \; | awk '{printf "  %10s  %s\n", $5, $9}'
bash "$HERE/release-layout-verify.sh" . | tail -2

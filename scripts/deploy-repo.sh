#!/usr/bin/env bash
# Repo install: clone or unpack the framework as a version-pinned directory
# inside the target, so the exact framework revision is recorded in the target's
# own history.
#
# Usage: deploy-repo.sh [<mode>] [--target] <repo> [--into <dir>] [--ref <git-ref>]
#                        [--from <url|path>] [--submodule] [--dry-run]
# Modes: install (default) · update · verify · status · uninstall.
# Arguments are order-independent: the target may be positional or --target,
# and a mode word works bare or --prefixed — `update` and `--update` are the
# same mode in any position.
# Exit: 0 ok · 1 error · 2 already installed / mode routed to the skill

set -euo pipefail

FRAMEWORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
MODE=""
QUIET=0
INTO=".ai.flutter"
REF=""
FROM="$FRAMEWORK_ROOT"
SUBMODULE=0
DRY=0

set_mode() {
  [ -z "$MODE" ] || { echo "error: conflicting modes: $MODE and $1" >&2; exit 1; }
  MODE="$1"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    TARGET="${2:-}"; shift 2 ;;
    --into)      INTO="${2:-}"; shift 2 ;;
    --ref)       REF="${2:-}"; shift 2 ;;
    --from)      FROM="${2:-}"; shift 2 ;;
    --submodule) SUBMODULE=1; shift ;;
    --dry-run)   DRY=1; shift ;;
    --update|--verify|--status|--uninstall) set_mode "${1#--}"; shift ;;
    --quiet)   QUIET=1; shift ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    --) shift ;;
    -*) echo "unknown argument: $1" >&2; exit 1 ;;
    *)
      # A bare token is the target when it looks like a path, a mode word
      # otherwise — so `update` and `--update` parse identically.
      if [ -d "$1" ] || [ "${1#*/}" != "$1" ]; then
        [ -z "$TARGET" ] || { echo "error: unexpected extra argument: $1" >&2; exit 1; }
        TARGET="$1"; shift
      else
        case "$1" in
          update|verify|status|uninstall) set_mode "$1"; shift ;;
          *) echo "unknown argument: $1 (neither a known mode nor a path)" >&2; exit 1 ;;
        esac
      fi ;;
  esac
done

[ -n "$TARGET" ] || { echo "error: target is required (positional or --target)" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "error: target does not exist: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" = "$FRAMEWORK_ROOT" ] && { echo "error: refusing to install into the framework itself" >&2; exit 1; }

# Mode dispatch. Only install runs here; the lifecycle modes either hand off
# to the verifier or route to the skill protocol that owns them.
case "$MODE" in
  "") ;;
  verify)
    if [ "$QUIET" -eq 1 ]; then
      exec bash "${FRAMEWORK_ROOT}/scripts/deploy-verify.sh" --target "$TARGET" --quiet
    else
      exec bash "${FRAMEWORK_ROOT}/scripts/deploy-verify.sh" --target "$TARGET"
    fi ;;
  status)
    if [ -f "${TARGET}/FLUTTER_AGENT_OS.md" ]; then
      grep -E '^\*\*(Version|Mode|Source|Ref|Installed):' "${TARGET}/FLUTTER_AGENT_OS.md"
      exit 0
    fi
    echo "not installed: no FLUTTER_AGENT_OS.md in $TARGET" >&2
    exit 2 ;;
  update|uninstall)
    [ -f "${TARGET}/FLUTTER_AGENT_OS.md" ] || { echo "error: nothing to $MODE — no install in $TARGET" >&2; exit 2; }
    cat >&2 <<EOF
$MODE is a skill-run protocol, not a script action:
  @flutter-deploy-repo $MODE - $TARGET   (equivalently: --$MODE)
The skill applies the $MODE protocol in skills/flutter-deploy-repo/skill.md;
this script's verify mode supplies the mechanical evidence.
EOF
    exit 2 ;;
esac

DEST="${TARGET}/${INTO}"
[ -e "$DEST" ] && { echo "already present: ${DEST}"; echo "Run @flutter-deploy-repo update - ${TARGET} (or --update)"; exit 2; }

command -v git >/dev/null 2>&1 || { echo "error: git is required for a repo install" >&2; exit 1; }

echo "Flutter Agent OS — repo install"
echo "  from      : ${FROM}"
echo "  target    : ${DEST}"
echo "  ref       : ${REF:-<default branch>}"
echo "  mode      : $([ "$SUBMODULE" -eq 1 ] && echo submodule || echo 'clone (detached, .git removed)')"
[ "$DRY" -eq 1 ] && { echo "  (dry run)"; exit 0; }
echo

if [ "$SUBMODULE" -eq 1 ]; then
  ( cd "$TARGET" && git submodule add "$FROM" "$INTO" )
  [ -n "$REF" ] && ( cd "$DEST" && git checkout --detach "$REF" )
  ( cd "$TARGET" && git add .gitmodules "$INTO" )
  echo "  added as a submodule — collaborators must run: git submodule update --init"
else
  git clone --quiet "$FROM" "$DEST"
  [ -n "$REF" ] && ( cd "$DEST" && git checkout --quiet --detach "$REF" )
  PINNED="$( cd "$DEST" && git rev-parse --short HEAD )"
  rm -rf "${DEST}/.git"
  # Exclude exactly what deploy-files.sh never copies, so the two bundles
  # match. Submodule installs skip this: deleting tracked files would leave
  # the submodule permanently dirty, so they carry the full tracked tree.
  rm -rf "${DEST}/.work.flutter" "${DEST}/TMP" "${DEST}/plans" \
         "${DEST}/.github" "${DEST}/.vscode" "${DEST}/.cursorrules" "${DEST}/.gitignore" 2>/dev/null || true
  echo "  cloned and pinned at ${PINNED} (.git removed — the framework is now part of this repo's history)"
fi

find "${DEST}/scripts" "${DEST}/hooks" "${DEST}/templates" -type f \
     \( -name '*.sh' -o -name 'pre-*' -o -name 'commit-*' -o -name 'post-*' -o -name 'prepare-*' \) \
     -exec chmod +x {} + 2>/dev/null || true

VERSION="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "${DEST}/CHANGELOG.md" 2>/dev/null \
           | head -1 | tr -d '#[] ' || echo "unversioned")"

cat > "${TARGET}/FLUTTER_AGENT_OS.md" <<EOF
# Flutter Agent OS — installed (repo)

**Source:** ${INTO}/ ($([ "$SUBMODULE" -eq 1 ] && echo 'git submodule' || echo "pinned copy of ${FROM}"))
**Version:** ${VERSION}
**Ref:** ${REF:-default branch}
**Installed:** $(date +%Y-%m-%d)
**Mode:** repo

| What | Where |
|------|-------|
| Entry point | \`${INTO}/START_HERE.md\` |
| Skills | \`${INTO}/skills/\` |
| Project memory | \`.work.flutter/\` |

**Licence:** MIT. See \`${INTO}/LICENSE\`.

## Next

\`\`\`
@flutter-bootstrap init
\`\`\`
EOF

CR="${TARGET}/.cursorrules"
SNIPPET="${DEST}/templates/cursorrules.flutter.snippet.template"
if [ ! -f "$CR" ]; then
  cp "${DEST}/templates/cursorrules.flutter.template" "$CR"
elif ! grep -q 'FLUTTER_AGENT_OS_BEGIN' "$CR" 2>/dev/null; then
  printf '\n\n' >> "$CR"; cat "$SNIPPET" >> "$CR"
fi
# A fresh .cursorrules copied from the full template still carries the
# REPLACE:FLUTTER_SNIPPET_BLOCK token — expand it the same way
# templates/bootstrap.sh does, or the marker block never lands.
if grep -q 'REPLACE:FLUTTER_SNIPPET_BLOCK' "$CR"; then
  tmp="$(mktemp)"
  awk -v snip="$SNIPPET" '
    /REPLACE:FLUTTER_SNIPPET_BLOCK/ { while ((getline line < snip) > 0) print line; next }
    { print }
  ' "$CR" > "$tmp" && mv "$tmp" "$CR"
fi
tmp="$(mktemp)"; sed "s|REPLACE:FLUTTER_FRAMEWORK_PATH|${INTO}|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
# Fill what the deploy legitimately knows: the project name, and the app root
# when a root pubspec makes it unambiguous. Everything else stays REPLACE:
# for its owning skill — deploy-verify.sh names the remainder.
tmp="$(mktemp)"; sed "s|REPLACE:FLUTTER_PROJECT_NAME|$(basename "$TARGET")|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
if [ -f "${TARGET}/pubspec.yaml" ]; then
  tmp="$(mktemp)"; sed "s|REPLACE:FLUTTER_APP_ROOT|.|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
fi

cat <<EOF

deploy-repo: installed

Verify: bash ${INTO}/scripts/framework-verify.sh --root ${DEST}
Next:   @flutter-bootstrap init
EOF

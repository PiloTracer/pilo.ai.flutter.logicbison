#!/usr/bin/env bash
# Thin install: a pointer file plus a .cursorrules registration. Skills are read
# from this framework's location.
#
# Fast and always current, but it breaks if this directory moves and it does not
# travel with a clone. Use deploy-files.sh when either matters.
#
# Usage: deploy-basic.sh [<mode>] [--target] <repo> [--dry-run]
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
DRY=0

set_mode() {
  [ -z "$MODE" ] || { echo "error: conflicting modes: $MODE and $1" >&2; exit 1; }
  MODE="$1"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)  TARGET="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --update|--verify|--status|--uninstall) set_mode "${1#--}"; shift ;;
    --quiet)   QUIET=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
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
      grep -E '^\*\*(Version|Mode|Source|Installed):' "${TARGET}/FLUTTER_AGENT_OS.md"
      exit 0
    fi
    echo "not installed: no FLUTTER_AGENT_OS.md in $TARGET" >&2
    exit 2 ;;
  update|uninstall)
    [ -f "${TARGET}/FLUTTER_AGENT_OS.md" ] || { echo "error: nothing to $MODE — no install in $TARGET" >&2; exit 2; }
    cat >&2 <<EOF
$MODE is a skill-run protocol, not a script action:
  @flutter-deploy-basic $MODE - $TARGET   (equivalently: --$MODE)
The skill applies the $MODE protocol in skills/flutter-deploy-basic/skill.md;
this script's verify mode supplies the mechanical evidence.
EOF
    exit 2 ;;
esac

VERSION="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "${FRAMEWORK_ROOT}/CHANGELOG.md" 2>/dev/null \
           | head -1 | tr -d '#[] ' || echo "unversioned")"
POINTER="${TARGET}/FLUTTER_AGENT_OS.md"

if [ -f "$POINTER" ]; then
  echo "already installed: $POINTER"
  grep -E '^\*\*(Version|Mode|Source):' "$POINTER" || true
  echo
  echo "This is an update. Run @flutter-deploy-basic update - ${TARGET} (or --update)"
  exit 2
fi

echo "Flutter Agent OS — basic (thin) install"
echo "  framework : ${FRAMEWORK_ROOT}"
echo "  target    : ${TARGET}"
echo "  version   : ${VERSION}"
[ "$DRY" -eq 1 ] && echo "  (dry run)"
echo

if [ "$DRY" -eq 0 ]; then
  cat > "$POINTER" <<EOF
# Flutter Agent OS — installed (basic)

**Source:** ${FRAMEWORK_ROOT}
**Version:** ${VERSION}
**Installed:** $(date +%Y-%m-%d)
**Mode:** basic — thin. Skills are read from the source path above.

| What | Where |
|------|-------|
| Entry point | \`${FRAMEWORK_ROOT}/START_HERE.md\` |
| Skills | \`${FRAMEWORK_ROOT}/skills/\` |
| Standards | \`${FRAMEWORK_ROOT}/standards/\` |
| Project memory | \`.work.flutter/\` (this repo) |

**Licence:** MIT. Installing this framework places MIT-licensed documentation
alongside your code; it makes no claim on your code.

**Caveat of a thin install:** if the source path moves or is unavailable (a
clone on another machine, a CI container), the skills cannot be read. Use a
\`files\` install where that matters.

## Next

\`\`\`
@flutter-bootstrap init
\`\`\`
EOF
fi
echo "  write     FLUTTER_AGENT_OS.md"

# .cursorrules — merge, never clobber.
CR="${TARGET}/.cursorrules"
SNIPPET="${FRAMEWORK_ROOT}/templates/cursorrules.flutter.snippet.template"
if [ ! -f "$CR" ]; then
  [ "$DRY" -eq 0 ] && cp "${FRAMEWORK_ROOT}/templates/cursorrules.flutter.template" "$CR"
  echo "  write     .cursorrules"
elif grep -q 'FLUTTER_AGENT_OS_BEGIN' "$CR" 2>/dev/null; then
  echo "  keep      .cursorrules (Flutter block already registered)"
else
  if [ "$DRY" -eq 0 ]; then
    printf '\n\n' >> "$CR"
    cat "$SNIPPET" >> "$CR"
  fi
  echo "  append    .cursorrules (Flutter block; existing rules preserved)"
fi

if [ "$DRY" -eq 0 ]; then
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
  tmp="$(mktemp)"
  sed "s|REPLACE:FLUTTER_FRAMEWORK_PATH|${FRAMEWORK_ROOT}|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
  # Fill what the deploy legitimately knows: the project name, and the app
  # root when a root pubspec makes it unambiguous. Everything else stays
  # REPLACE: for its owning skill — deploy-verify.sh names the remainder.
  tmp="$(mktemp)"
  sed "s|REPLACE:FLUTTER_PROJECT_NAME|$(basename "$TARGET")|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
  if [ -f "${TARGET}/pubspec.yaml" ]; then
    tmp="$(mktemp)"
    sed "s|REPLACE:FLUTTER_APP_ROOT|.|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
  fi
fi

# Collision check with sibling frameworks.
for other in "${TARGET}/.ai" "${TARGET}/.ai.ui"; do
  [ -d "$other" ] && echo "  note      $(basename "$other") present — cohabitation applies; no skill ids collide (all are flutter-*)"
done

cat <<EOF

deploy-basic: installed

Verify: @flutter-deploy-basic verify - ${TARGET}
Next:   @flutter-bootstrap init   (install is not setup — the project memory
        scaffold is a separate, required step)
EOF

#!/usr/bin/env bash
# Fat install: copies the framework into the target so it is self-contained.
#
# Use for CI, containers, and contributors who will not have the source. Costs
# duplication; buys reproducibility.
#
# Usage: deploy-files.sh [<mode>] [--target] <repo> [--into <dir>] [--dry-run] [--force]
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
DRY=0
FORCE=0

set_mode() {
  [ -z "$MODE" ] || { echo "error: conflicting modes: $MODE and $1" >&2; exit 1; }
  MODE="$1"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)  TARGET="${2:-}"; shift 2 ;;
    --into)    INTO="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --force)   FORCE=1; shift ;;
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
  @flutter-deploy-files $MODE - $TARGET   (equivalently: --$MODE)
The skill applies the $MODE protocol in skills/flutter-deploy-files/skill.md;
this script's verify mode supplies the mechanical evidence.
EOF
    exit 2 ;;
esac

DEST="${TARGET}/${INTO}"
VERSION="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "${FRAMEWORK_ROOT}/CHANGELOG.md" 2>/dev/null \
           | head -1 | tr -d '#[] ' || echo "unversioned")"

if [ -d "$DEST" ] && [ "$FORCE" -eq 0 ]; then
  echo "already installed at ${DEST}"
  echo "This is an update. Run @flutter-deploy-files update - ${TARGET} (or --update)"
  exit 2
fi

echo "Flutter Agent OS — files (fat) install"
echo "  framework : ${FRAMEWORK_ROOT}"
echo "  target    : ${DEST}"
echo "  version   : ${VERSION}"
[ "$DRY" -eq 1 ] && echo "  (dry run)"
echo

COPY="skills standards concepts templates scripts hooks stacks resources docs .quick"
ROOTFILES="README.md START_HERE.md APPROACH.md PROCESS_ROUTER.md COHABITATION.md CONTRIBUTING.md CHANGELOG.md LICENSE"

# Collision report before writing anything.
COLLISIONS=0
for d in $COPY; do
  [ -e "${DEST}/${d}" ] && { echo "  collision ${INTO}/${d}"; COLLISIONS=$((COLLISIONS+1)); }
done
if [ "$COLLISIONS" -gt 0 ] && [ "$FORCE" -eq 0 ]; then
  echo >&2
  echo "error: ${COLLISIONS} existing paths. Use --force to replace, or run an update." >&2
  exit 1
fi

if [ "$DRY" -eq 0 ]; then
  mkdir -p "$DEST"
  for d in $COPY; do
    [ -d "${FRAMEWORK_ROOT}/${d}" ] || continue
    rm -rf "${DEST:?}/${d}"
    cp -R "${FRAMEWORK_ROOT}/${d}" "${DEST}/${d}"
    echo "  copy      ${INTO}/${d}/"
  done
  for f in $ROOTFILES; do
    [ -f "${FRAMEWORK_ROOT}/${f}" ] && cp "${FRAMEWORK_ROOT}/${f}" "${DEST}/${f}" && echo "  copy      ${INTO}/${f}"
  done
  # Never carry the framework's own git or project memory into a consumer.
  rm -rf "${DEST}/.git" "${DEST}/.work.flutter" "${DEST}/TMP" 2>/dev/null || true
  find "${DEST}/scripts" "${DEST}/hooks" "${DEST}/templates" -type f \
       \( -name '*.sh' -o -name 'pre-*' -o -name 'commit-*' -o -name 'post-*' -o -name 'prepare-*' \) \
       -exec chmod +x {} + 2>/dev/null || true
else
  for d in $COPY; do echo "  copy      ${INTO}/${d}/"; done
fi

# Pointer.
if [ "$DRY" -eq 0 ]; then
  cat > "${TARGET}/FLUTTER_AGENT_OS.md" <<EOF
# Flutter Agent OS — installed (files)

**Source:** ${INTO}/ (self-contained copy)
**Version:** ${VERSION}
**Installed:** $(date +%Y-%m-%d)
**Mode:** files — the framework travels with this repository.

| What | Where |
|------|-------|
| Entry point | \`${INTO}/START_HERE.md\` |
| Skills | \`${INTO}/skills/\` |
| Standards | \`${INTO}/standards/\` |
| Project memory | \`.work.flutter/\` |

**Licence:** MIT. See \`${INTO}/LICENSE\`.

## Next

\`\`\`
@flutter-bootstrap init
\`\`\`
EOF
fi
echo "  write     FLUTTER_AGENT_OS.md"

CR="${TARGET}/.cursorrules"
SNIPPET="${FRAMEWORK_ROOT}/templates/cursorrules.flutter.snippet.template"
if [ ! -f "$CR" ]; then
  [ "$DRY" -eq 0 ] && cp "${FRAMEWORK_ROOT}/templates/cursorrules.flutter.template" "$CR"
  echo "  write     .cursorrules"
elif grep -q 'FLUTTER_AGENT_OS_BEGIN' "$CR" 2>/dev/null; then
  echo "  keep      .cursorrules (already registered)"
else
  [ "$DRY" -eq 0 ] && { printf '\n\n' >> "$CR"; cat "$SNIPPET" >> "$CR"; }
  echo "  append    .cursorrules"
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
  tmp="$(mktemp)"; sed "s|REPLACE:FLUTTER_FRAMEWORK_PATH|${INTO}|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
  # Fill what the deploy legitimately knows: the project name, and the app
  # root when a root pubspec makes it unambiguous. Everything else stays
  # REPLACE: for its owning skill — deploy-verify.sh names the remainder.
  tmp="$(mktemp)"; sed "s|REPLACE:FLUTTER_PROJECT_NAME|$(basename "$TARGET")|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
  if [ -f "${TARGET}/pubspec.yaml" ]; then
    tmp="$(mktemp)"; sed "s|REPLACE:FLUTTER_APP_ROOT|.|g" "$CR" > "$tmp" && mv "$tmp" "$CR"
  fi
fi

cat <<EOF

deploy-files: installed

Verify: bash ${INTO}/scripts/framework-verify.sh --root ${DEST}
Next:   @flutter-bootstrap init
EOF

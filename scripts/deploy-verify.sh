#!/usr/bin/env bash
# Target-side install verifier: is a Flutter Agent OS install in a target repo
# complete, consistent and usable?
#
# Checks the pointer file, the framework location it records, the .cursorrules
# block (markers, unresolved REPLACE: tokens, framework path, skill routes) and
# the .gitignore scratch exclusions. This is the mechanical backbone of the
# @flutter-deploy-basic / -files / -repo verify modes — they quote its output
# rather than re-reasoning the same questions in prose.
#
# Usage: deploy-verify.sh [--target] <repo> [--quiet]
# Exit: 0 pass · 1 findings · 2 usage error

set -uo pipefail

FRAMEWORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
QUIET=0
FAILS=0
WARNS=0
CHECKS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --quiet)  QUIET=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    --) shift ;;
    -*) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    *)  if [ -z "$TARGET" ]; then TARGET="$1"; shift
        else printf 'unexpected extra argument: %s\n' "$1" >&2; exit 2; fi ;;
  esac
done

[ -n "$TARGET" ] || { echo "error: target is required (positional or --target)" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "error: target does not exist: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

pass() { CHECKS=$((CHECKS+1)); [ "$QUIET" -eq 1 ] || printf '  ok    %s\n' "$1"; }
fail() { CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); printf '  FAIL  %s\n' "$1" >&2; }
warn() { WARNS=$((WARNS+1)); [ "$QUIET" -eq 1 ] || printf '  warn  %s\n' "$1"; }
head_() { [ "$QUIET" -eq 1 ] || printf '\n%s\n' "$1"; }

canon() { (cd "$1" 2>/dev/null && pwd); }

# Token ownership — mirrors the B6 table in skills/flutter-bootstrap/skill.md.
# Keep the two in sync: an owner named here but not there is a lie either way.
token_owner() {
  case "$1" in
    REPLACE:FLUTTER_FRAMEWORK_PATH|REPLACE:FLUTTER_SNIPPET_BLOCK)
      printf 'the deploy script itself — re-run install/update; this token must never survive a deploy' ;;
    REPLACE:FLUTTER_PROJECT_NAME)
      printf 'the deploy script (target directory name) — re-run install/update' ;;
    REPLACE:FLUTTER_APP_ROOT)
      printf 'the deploy script when a root pubspec.yaml exists, else @flutter-bootstrap' ;;
    REPLACE:FLUTTER_STATE_MANAGEMENT|REPLACE:FLUTTER_NAVIGATION|REPLACE:FLUTTER_DI|REPLACE:FLUTTER_SERIALIZATION|REPLACE:FLUTTER_LOCAL_STORE|REPLACE:FLUTTER_HTTP|REPLACE:FLUTTER_TEST_DOUBLE)
      printf '@flutter-stack set' ;;
    REPLACE:FLUTTER_SDK_VERSION|REPLACE:DART_SDK_VERSION)
      printf '@flutter-bootstrap from flutter --version, else operator' ;;
    REPLACE:FLUTTER_PLATFORMS|REPLACE:FLUTTER_MIN_IOS|REPLACE:FLUTTER_MIN_ANDROID_SDK)
      printf '@flutter-foundation P1' ;;
    REPLACE:FLUTTER_COVERAGE_MIN)
      printf '@flutter-foundation P3 (default 80)' ;;
    REPLACE:FLUTTER_TASK_REF_PREFIX)
      printf 'operator (default FLT)' ;;
    REPLACE:AI_PATH|REPLACE:AI_UI_PATH|REPLACE:AI_BIZ_PATH|REPLACE:AI_SOC_PATH|REPLACE:AI_CTO_PATH|REPLACE:AI_MLT_PATH)
      printf 'the deploy script (sister framework discovery) — re-run install/update; an unfilled cell is expected when the sister is not installed' ;;
    *)  printf 'see @flutter-bootstrap B6' ;;
  esac
}

# A token the deploy itself owns is a verify failure: the install did not do
# its job. A token owned by a later step (bootstrap, stack, foundation, the
# operator) is a named pending warning — expected right after install, and a
# verify that fails on it trains people to ignore verify.
token_is_deploy_owned() {
  case "$1" in
    REPLACE:FLUTTER_FRAMEWORK_PATH|REPLACE:FLUTTER_SNIPPET_BLOCK|REPLACE:FLUTTER_PROJECT_NAME) return 0 ;;
    *) return 1 ;;
  esac
}

finish() {
  printf '\n'
  printf 'checks: %s  failures: %s  warnings: %s\n' "$CHECKS" "$FAILS" "$WARNS"
  if [ "$FAILS" -eq 0 ]; then
    printf 'deploy-verify: PASS\n'
    exit 0
  fi
  printf 'deploy-verify: FAIL\n'
  exit 1
}

# ------------------------------------------------------------------- pointer
head_ "Pointer"
POINTER="${TARGET}/FLUTTER_AGENT_OS.md"
if [ ! -f "$POINTER" ]; then
  fail "FLUTTER_AGENT_OS.md missing in $TARGET — no install to verify (run a @flutter-deploy-* install first)"
  finish
fi
pass "pointer present"

MODE="$(grep -m1 '^\*\*Mode:\*\*' "$POINTER" | sed -E 's/^\*\*Mode:\*\* *//; s/ .*//' | tr -d '`')"
VERSION="$(grep -m1 '^\*\*Version:\*\*' "$POINTER" | sed -E 's/^\*\*Version:\*\* *//; s/ *$//' | tr -d '`')"
SOURCE="$(grep -m1 '^\*\*Source:\*\*' "$POINTER" | sed -E 's/^\*\*Source:\*\* *//; s/ *\(.*$//; s/ *$//; s|/$||' | tr -d '`')"

case "$MODE" in
  basic|files) pass "pointer mode: $MODE" ;;
  repo) fail "pointer Mode: repo is no longer supported — the pinned deploy-repo install was removed from this framework. Remove the installed copy (${TARGET}/.ai.flutter/), this pointer and the .cursorrules Flutter block, then re-install with @flutter-deploy-files (or @flutter-deploy-basic)." ;;
  *) fail "pointer Mode is '${MODE:-<missing>}' — expected basic or files" ;;
esac
[ -n "$VERSION" ] && pass "pointer version recorded: $VERSION" \
                  || fail "pointer records no Version — update cannot reason about what changed"
[ -n "$SOURCE" ] && pass "pointer source recorded: $SOURCE" \
                 || fail "pointer records no Source"

# ------------------------------------------------------- framework location
head_ "Framework location"
FW=""
case "$MODE" in
  basic)
    case "$SOURCE" in
      /*) FW="$SOURCE" ;;
      *)  fail "a basic install's Source must be an absolute path, got: $SOURCE" ;;
    esac ;;
  files) FW="${TARGET}/${SOURCE}" ;;
esac

FWC=""
if [ -n "$FW" ]; then
  FWC="$(canon "$FW")"
  if [ -n "$FWC" ]; then
    pass "framework location resolves: $FWC"
  else
    fail "framework location does not resolve: $FW — if the framework moved, run @flutter-deploy-${MODE} update - $TARGET"
  fi
fi

if [ -n "$FWC" ]; then
  for p in skills/README.md standards scripts/framework-verify.sh; do
    [ -e "${FWC}/${p}" ] && pass "framework has $p" \
                        || fail "framework location is missing $p — incomplete or wrong location: $FWC"
  done

  SRC_VERSION="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "${FWC}/CHANGELOG.md" 2>/dev/null \
                 | head -1 | tr -d '#[] ')"
  if [ -z "$SRC_VERSION" ] || [ -z "$VERSION" ]; then
    warn "cannot compare versions (source: '${SRC_VERSION:-unversioned}', pointer: '${VERSION:-none}')"
  elif [ "$SRC_VERSION" = "$VERSION" ]; then
    pass "version matches the source ($VERSION)"
  else
    fail "version drift: pointer says $VERSION, source is $SRC_VERSION — run @flutter-deploy-${MODE} update - $TARGET"
  fi

  # A thin install records an absolute source path. If that path is not the
  # framework copy this verifier runs from, either the framework moved or two
  # copies exist — the operator must know which one the target actually reads.
  if [ "$MODE" = "basic" ] && [ "$FWC" != "$FRAMEWORK_ROOT" ]; then
    warn "basic install reads skills from $FWC, not from this framework copy ($FRAMEWORK_ROOT) — if the framework moved, run @flutter-deploy-basic update - $TARGET"
  fi
fi

# --------------------------------------------------------------- .cursorrules
head_ ".cursorrules"
CR="${TARGET}/.cursorrules"
BLOCK=""
if [ ! -f "$CR" ]; then
  fail ".cursorrules missing — the install registered nothing (re-run the deploy, or @flutter-bootstrap init)"
else
  B="$(grep -c 'FLUTTER_AGENT_OS_BEGIN' "$CR")"
  E="$(grep -c 'FLUTTER_AGENT_OS_END' "$CR")"
  if [ "$B" -eq 1 ] && [ "$E" -eq 1 ]; then
    pass "exactly one FLUTTER_AGENT_OS_BEGIN/END pair"
  else
    fail "expected exactly one FLUTTER_AGENT_OS_BEGIN/END pair, found $B/$E"
  fi
  if awk '/FLUTTER_AGENT_OS_BEGIN/{b=NR} /FLUTTER_AGENT_OS_END/{e=NR} END{exit !(b && e && b<e)}' "$CR"; then
    pass "markers are ordered BEGIN before END"
    BLOCK="$(awk '/FLUTTER_AGENT_OS_END/{print; exit} /FLUTTER_AGENT_OS_BEGIN/{f=1} f' "$CR")"
  else
    fail "FLUTTER_AGENT_OS_END is missing or precedes BEGIN — the block is malformed"
  fi

  # Unresolved template tokens. Scanned across the whole file but restricted
  # to this framework's prefixes, so a cohabiting framework's pending tokens
  # do not fail our verify.
  TOKENS="$(grep -oE 'REPLACE:(FLUTTER|DART|AI)_[A-Z_]+' "$CR" | sort -u)"
  if [ -z "$TOKENS" ]; then
    pass "no unresolved REPLACE: tokens"
  else
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      if token_is_deploy_owned "$t"; then
        fail "unresolved token $t — owned by: $(token_owner "$t")"
      elif [ "$t" = "REPLACE:FLUTTER_APP_ROOT" ] && [ -f "${TARGET}/pubspec.yaml" ]; then
        fail "unresolved token $t — a root pubspec.yaml exists, so the deploy should have filled it"
      else
        warn "pending token $t — owned by: $(token_owner "$t")"
      fi
    done <<EOF
$TOKENS
EOF
  fi
fi

# ------------------------------------------------- framework path in the block
if [ -n "$BLOCK" ]; then
  head_ "Framework path in the Flutter block"
  FWPATH="$(printf '%s\n' "$BLOCK" | grep -m1 'Framework: `' | sed -E 's/.*Framework: `([^`]+)`.*/\1/')"
  if [ -z "$FWPATH" ]; then
    fail "no 'Framework: \`<path>\`' line in the Flutter block — registration is incomplete"
  else
    case "$FWPATH" in
      /*) FWPC="$(canon "$FWPATH")" ;;
      *)  FWPC="$(canon "${TARGET}/${FWPATH%/}")" ;;
    esac
    if [ -z "$FWPC" ]; then
      fail "framework path in .cursorrules dangles: $FWPATH"
    elif [ -n "$FWC" ] && [ "$FWPC" != "$FWC" ]; then
      fail "framework path in .cursorrules ($FWPC) disagrees with the pointer ($FWC)"
    else
      pass "framework path in .cursorrules resolves and matches the pointer"
    fi

    if [ -n "$FWPC" ]; then
      [ -f "${FWPC}/skills/SKILL_DEPENDENCIES.md" ] \
        && pass "skill registry resolves at the recorded path" \
        || fail "SKILL_DEPENDENCIES.md not found under $FWPC — the recorded path is not a framework root"

      DEAD=0
      for s in $(printf '%s\n' "$BLOCK" | grep -oE '@flutter-[a-z0-9]+(-[a-z0-9]+)*' | sed 's/@//' | sort -u); do
        if [ ! -d "${FWPC}/skills/${s}" ]; then
          fail "block routes @$s, but ${FWPC}/skills/${s} does not exist"
          DEAD=$((DEAD+1))
        fi
      done
      [ "$DEAD" -eq 0 ] && pass "every @flutter-* route in the block resolves"
    fi
  fi
fi

# ------------------------------------------------- frameworks registry cells
# Sister discovery is shipped to targets via the registry table in .cursorrules;
# the cells are filled by the deploy (REPLACE:AI_*_PATH) or left for runtime
# auto-discovery. Here: an unfilled cell whose sister IS discoverable is a
# deploy that did not do its job; a filled cell that dangles is a stale cell.
head_ "Frameworks registry"

if [ -n "$FWC" ] && [ -f "${FWC}/scripts/sister-discovery.sh" ]; then
  # shellcheck disable=SC1090
  source "${FWC}/scripts/sister-discovery.sh" 2>/dev/null || true
  set +e  # the lib sets errexit; this verifier is read-only by design
  # Discovery must mirror what the install itself checked, or an "unfilled"
  # warning would advise a re-run that cannot fill the cell: basic installs
  # discover next to the source framework, files installs next to the
  # target. (MODE is parsed from the pointer above.)
  SRC_PARENT="$(dirname "$FWC")"
  TGT_PARENT="$(dirname "$TARGET")"
  case "$MODE" in
    basic)  DISCO_PARENTS=("$SRC_PARENT") ;;
    files) DISCO_PARENTS=("$TGT_PARENT") ;;
    *)      DISCO_PARENTS=("$SRC_PARENT" "$TGT_PARENT") ;;
  esac
  for fw in "" $FRAMEWORK_SLOTS; do
    FWU="$(printf '%s' "$fw" | tr '[:lower:]' '[:upper:]')"
    token="REPLACE:AI${FWU:+_}${FWU}_PATH"
    name=".ai${fw:+.$fw}"
    if grep -q "$token" "$CR"; then
      # Unfilled cell: warn only when the sister is discoverable where the
      # install would have looked — a re-run can then actually fill it.
      sis=""
      for p in "${DISCO_PARENTS[@]}"; do
        if [ -z "$fw" ]; then
          sis="$(find_agent_os_dir "$FWC" "$p" || true)"
        else
          sis="$(find_sister_dir "$FWC" "$fw" "$p" || true)"
        fi
        [ -n "$sis" ] && break
      done
      if [ -n "$sis" ]; then
        warn "$name installed at $sis but $token unfilled — re-run install/update to fill the cell"
      else
        pass "$name not installed where the install looks (cell left for runtime auto-discovery)"
      fi
      continue
    fi
    # Filled cell — a manual or discovered value must still resolve to a
    # framework. Skip placeholder-style cells (token, self row, empty).
    row="$(grep -E "^\\| \`${name}\` \\(" "$CR" | head -1)"
    [ -n "$row" ] || continue
    cell="$(printf '%s\n' "$row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')"
    cell="${cell%% *}"   # strip annotations like "(discovered at deploy time)"
    case "$cell" in
      ''|*'REPLACE:'*|*'this directory'*) continue ;;
    esac
    case "$cell" in
      /*) c="$(canon "$cell")" ;;
      *)  c="$(canon "${TARGET}/${cell}")" ;;
    esac
    if [ -n "$c" ] && [ -f "${c}/skills/README.md" ]; then
      pass "$name registry cell resolves: $cell"
    else
      warn "$name registry cell does not resolve to a framework: $cell — re-run install/update or fix the cell"
    fi
  done
else
  warn "sister-discovery.sh not available at the recorded framework — cannot check registry cells"
fi

# -------------------------------------------------------- target repo hygiene
head_ "Target repo"
GI="${TARGET}/.gitignore"
if [ -f "$GI" ] && grep -qxF '.work.flutter/analysis/tmp/' "$GI"; then
  pass ".gitignore excludes framework scratch paths"
else
  warn ".gitignore does not exclude .work.flutter/analysis/tmp/ yet — @flutter-bootstrap init appends the entries"
fi

if [ -d "${TARGET}/.work.flutter" ]; then
  pass "project memory .work.flutter/ present"
else
  warn ".work.flutter/ missing — @flutter-bootstrap init has not run; install is not setup"
fi

# The copy (files/repo) or source (basic) must itself be well-formed; an
# install of a broken framework verifies nothing.
if [ -n "$FWC" ] && [ -f "${FWC}/scripts/framework-verify.sh" ]; then
  if bash "${FWC}/scripts/framework-verify.sh" --root "$FWC" --quiet >/dev/null 2>&1; then
    pass "framework-verify passes at the recorded location"
  else
    fail "framework-verify fails at $FWC — run: bash ${FWC}/scripts/framework-verify.sh --root $FWC"
  fi
fi

finish

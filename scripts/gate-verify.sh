#!/usr/bin/env bash
# Checks that tasks marked done in NEXT_FLUTTER.md carry gate evidence.
#
# A task marked done with an empty evidence cell is the most common way an
# iteration reports completion it did not achieve. This makes that visible.
#
# Usage: gate-verify.sh [NEXT_FLUTTER.md]
# Exit: 0 pass · 1 fail · 2 usage

set -uo pipefail

NEXT="${1:-}"
if [ -z "$NEXT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  NEXT="${ROOT}/.work.flutter/plans/NEXT_FLUTTER.md"
fi
[ -f "$NEXT" ] || { echo "error: not found: $NEXT" >&2; exit 2; }

FAILS=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { FAILS=$((FAILS+1)); printf '  FAIL  %s\n' "$1" >&2; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Extract the active iteration block.
awk '/^## Current iteration/{f=1} f && /^## [^C]/{f=0} f' "$NEXT" > "$TMP/iter"

if ! grep -q '[^[:space:]]' "$TMP/iter"; then
  echo "gate-verify: no active iteration block — nothing to check"
  exit 0
fi

# Ignore the commented-out template.
if grep -q '^<!--' "$TMP/iter" && ! grep -qE '^\| *F[0-9]+-T[0-9]+ *\|' "$TMP/iter"; then
  echo "gate-verify: iteration block is still the template — nothing to check"
  exit 0
fi

printf '\nIteration block\n'
STATUS="$(grep -oE '^\*\*Status:\*\* *[a-z ]+' "$TMP/iter" | sed 's/.*\*\* *//')"
[ -n "$STATUS" ] && pass "status: $STATUS" || fail "no **Status:** line"
grep -qE '^### Tasks' "$TMP/iter"                && pass "has a Tasks table"               || fail "no ### Tasks section"
grep -qE '^### Acceptance criteria' "$TMP/iter"  && pass "has acceptance criteria"          || fail "no ### Acceptance criteria section"
grep -qE '^### Out of scope' "$TMP/iter"         && pass "declares out of scope"            || fail "no ### Out of scope section — scope creep will be invisible"
grep -qE '^### Validation commands' "$TMP/iter"  && pass "names validation commands"        || fail "no ### Validation commands section"

printf '\nTask evidence\n'
DONE=0; MISSING=0
while IFS= read -r row; do
  id="$(printf '%s' "$row" | awk -F'|' '{gsub(/ /,"",$2); print $2}')"
  st="$(printf '%s' "$row" | awk -F'|' '{gsub(/ /,"",$5); print tolower($5)}')"
  ev="$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$6); print $6}')"
  case "$st" in
    done|complete|completed)
      DONE=$((DONE+1))
      if [ -z "$ev" ] || [ "$ev" = "-" ]; then
        printf '  FAIL  %s marked %s with no gate evidence\n' "$id" "$st" >&2
        MISSING=$((MISSING+1))
      fi
      ;;
  esac
done < <(grep -E '^\| *F[0-9]+-T[0-9]+ *\|' "$TMP/iter")

printf '  info  %s tasks marked done\n' "$DONE"
if [ "$MISSING" -eq 0 ]; then
  pass "every completed task carries evidence"
else
  FAILS=$((FAILS+1))
  printf '  FAIL  %s completed tasks without evidence\n' "$MISSING" >&2
fi

printf '\nConcept registry\n'
if grep -q 'FLS-06' "$TMP/iter"; then
  if [ "$STATUS" = "complete" ] && grep -E 'FLS-06' "$TMP/iter" | grep -i 'pending' >/dev/null; then
    fail "iteration marked complete with FLS-06 still pending"
  else
    pass "FLS-06 present in the registry"
  fi
else
  fail "FLS-06 missing from the concept registry — mandatory for agent sessions"
fi

printf '\nActive pointer\n'
PTR="$(awk '/^## Active pointer/{f=1; next} f && /^## /{exit} f && /`@flutter/{c++} END{print c+0}' "$NEXT")"
case "$PTR" in
  1) pass "exactly one active pointer" ;;
  0) fail "no active pointer in NEXT" ;;
  *) fail "$PTR competing pointers in the active-pointer section — the next session will pick wrong" ;;
esac

printf '\nfailures: %s\n' "$FAILS"
[ "$FAILS" -eq 0 ] && { printf 'gate-verify: PASS\n'; exit 0; }
printf 'gate-verify: FAIL\n'
exit 1

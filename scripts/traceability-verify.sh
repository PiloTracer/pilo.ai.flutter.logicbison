#!/usr/bin/env bash
# Checks traceability in both directions in a master plan:
#   every FR/NFR is covered by at least one task, and
#   every task traces to at least one requirement.
#
# Orphans on either side are failures. An uncovered requirement is a promise the
# plan does not keep; an untraced task is scope creep or a missing requirement.
#
# Usage: traceability-verify.sh <plan.md>
# Exit: 0 pass · 1 fail · 2 usage

set -uo pipefail

PLAN="${1:-}"
[ -n "$PLAN" ] || { echo "usage: traceability-verify.sh <plan.md>" >&2; exit 2; }
[ -f "$PLAN" ] || { echo "error: not found: $PLAN" >&2; exit 2; }

FAILS=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { FAILS=$((FAILS+1)); printf '  FAIL  %s\n' "$1" >&2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# All declared ids anywhere in the plan.
grep -oE '\b(FR|NFR)[0-9]+\b' "$PLAN" | sort -u > "$TMP/reqs"
grep -oE '\bF[0-9]+-T[0-9]+\b'  "$PLAN" | sort -u > "$TMP/tasks"

REQ_N=$(wc -l < "$TMP/reqs" | tr -d ' ')
TASK_N=$(wc -l < "$TMP/tasks" | tr -d ' ')

printf '\nInventory\n'
[ "$REQ_N" -gt 0 ] && pass "$REQ_N requirement ids" || fail "no requirement ids found"
[ "$TASK_N" -gt 0 ] && pass "$TASK_N task ids" || fail "no task ids found"

# The traceability matrix section (§13) is the authority for coverage. Fall back
# to any line mentioning both a requirement and a task.
# `##+` rather than `#{2,3}`: mawk does not enable interval expressions by
# default, and silently matches nothing rather than erroring.
# Close the section only on the next level-2 heading. Level-3 subheads
# (### F0 — …) are content inside §11 / §13, not a new plan section.
awk '/^## +[0-9]*\.? *[Tt]raceability/{f=1; next} /^## /{f=0} f' "$PLAN" > "$TMP/matrix"
if [ ! -s "$TMP/matrix" ]; then
  fail "no traceability matrix section found — coverage cannot be checked mechanically"
  grep -nE '(FR|NFR)[0-9]+.*F[0-9]+-T[0-9]+' "$PLAN" > "$TMP/matrix" || true
fi

printf '\nRequirement coverage (every FR/NFR needs a task)\n'
UNCOVERED=0
while IFS= read -r r; do
  [ -z "$r" ] && continue
  if grep -qE "(^|[^A-Z])${r}([^0-9]|$)" "$TMP/matrix" \
     && grep -E "(^|[^A-Z])${r}([^0-9]|$)" "$TMP/matrix" | grep -E '\bF[0-9]+-T[0-9]+\b' >/dev/null; then
    :
  else
    printf '  FAIL  %s has no task in the traceability matrix\n' "$r" >&2
    UNCOVERED=$((UNCOVERED+1))
  fi
done < "$TMP/reqs"
if [ "$UNCOVERED" -eq 0 ]; then pass "all $REQ_N requirements are covered"
else FAILS=$((FAILS+1)); printf '  FAIL  %s uncovered requirements\n' "$UNCOVERED" >&2; fi

printf '\nTask tracing (every task needs a requirement)\n'
UNTRACED=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  if grep -E "\b${t}\b" "$PLAN" | grep -E '\b(FR|NFR)[0-9]+\b' >/dev/null; then
    :
  else
    printf '  FAIL  %s traces to no requirement\n' "$t" >&2
    UNTRACED=$((UNTRACED+1))
  fi
done < "$TMP/tasks"
if [ "$UNTRACED" -eq 0 ]; then pass "all $TASK_N tasks trace to a requirement"
else FAILS=$((FAILS+1)); printf '  FAIL  %s untraced tasks\n' "$UNTRACED" >&2; fi

printf '\nMilestone consistency\n'
# Declared milestones come from § Milestones only. Searching the whole plan
# would let a task id declare its own milestone, which defeats the check.
awk '/^## +[0-9]*\.? *[Mm]ilestones/{f=1; next} /^## /{f=0} f' "$PLAN" \
  | grep -oE '\bF[0-9]+\b' | sort -u > "$TMP/milestones"

if [ ! -s "$TMP/milestones" ]; then
  fail "no milestone ids found in § Milestones — task placement cannot be checked"
fi

MISSING_MS=0
while IFS= read -r t; do
  ms="${t%%-T*}"
  grep -qxF "$ms" "$TMP/milestones" || {
    printf '  FAIL  task %s references undeclared milestone %s\n' "$t" "$ms" >&2
    MISSING_MS=$((MISSING_MS+1))
  }
done < "$TMP/tasks"
[ "$MISSING_MS" -eq 0 ] && pass "every task belongs to a declared milestone" \
  || { FAILS=$((FAILS+1)); printf '  FAIL  %s tasks in undeclared milestones\n' "$MISSING_MS" >&2; }

printf '\nDuplicate ids\n'
DUP="$(grep -oE '\bF[0-9]+-T[0-9]+\b' "$PLAN" | sort -u | wc -l | tr -d ' ')"
[ "$DUP" -eq "$TASK_N" ] && pass "task ids are unique" || fail "duplicate task ids detected"

printf '\nfailures: %s\n' "$FAILS"
[ "$FAILS" -eq 0 ] && { printf 'traceability-verify: PASS\n'; exit 0; }
printf 'traceability-verify: FAIL\n'
exit 1

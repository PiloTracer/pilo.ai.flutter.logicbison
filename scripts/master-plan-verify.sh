#!/usr/bin/env bash
# Checks a master plan against MASTER_PLAN_STANDARD: front matter, the 21
# mandatory sections, id conventions, and placeholder residue.
#
# Usage: master-plan-verify.sh <plan.md>
# Exit: 0 pass · 1 fail · 2 usage

set -uo pipefail

PLAN="${1:-}"
[ -n "$PLAN" ] || { echo "usage: master-plan-verify.sh <plan.md>" >&2; exit 2; }
[ -f "$PLAN" ] || { echo "error: not found: $PLAN" >&2; exit 2; }

FAILS=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { FAILS=$((FAILS+1)); printf '  FAIL  %s\n' "$1" >&2; }

SECTIONS=(
  "Summary"
  "Source foundation"
  "Technology stack"
  "Architecture summary"
  "Scope"
  "Functional requirements"
  "Non-functional requirements"
  "Platform matrix"
  "Domain and data plan"
  "Navigation map"
  "Milestones"
  "Task breakdown"
  "Traceability matrix"
  "Verification strategy"
  "Test plan"
  "Release plan"
  "Risks"
  "Assumptions"
  "Open questions"
  "Concept / NFR registry"
  "Revision history"
)

printf '\nFront matter\n'
head -1 "$PLAN" | grep '^---$' >/dev/null && pass "opens with front matter" || fail "no front matter"
for k in title status owner foundation-certified last-updated; do
  awk -v k="$k" '/^---$/{n++; next} n==1 && $0 ~ "^"k":"{f=1} END{exit !f}' "$PLAN" \
    && pass "front matter has $k" || fail "front matter missing $k"
done

STATUS="$(awk '/^---$/{n++; next} n==1 && /^status:/{sub(/^status: */,""); print; exit}' "$PLAN")"
case "$STATUS" in
  Draft|"Under review"|Approved|Superseded) pass "status is '$STATUS'" ;;
  *) fail "invalid status: '${STATUS:-<empty>}'" ;;
esac

printf '\nMandatory sections\n'
for s in "${SECTIONS[@]}"; do
  if grep -qiE "^#{2,3} +[0-9]*\.? *${s}" "$PLAN"; then
    pass "§ $s"
  else
    fail "§ $s missing"
  fi
done

printf '\nId conventions\n'
MILESTONES="$(grep -oE '\bF[0-9]+\b' "$PLAN" | sort -u | wc -l | tr -d ' ')"
TASKS="$(grep -oE '\bF[0-9]+-T[0-9]+\b' "$PLAN" | sort -u | wc -l | tr -d ' ')"
[ "$MILESTONES" -gt 0 ] && pass "$MILESTONES milestone ids (F{N})" || fail "no F{N} milestone ids found"
[ "$TASKS" -gt 0 ] && pass "$TASKS task ids (F{N}-T{k})" || fail "no F{N}-T{k} task ids found"

if grep -qE '\bM[0-9]+\b' "$PLAN"; then
  fail "found M{N} ids — those belong to Agent OS; Flutter milestones are F{N}"
else
  pass "no cross-framework milestone ids"
fi

DUPES="$(grep -oE '\bF[0-9]+-T[0-9]+\b' "$PLAN" | sort | uniq -d | head -5)"
printf '\nRequirements\n'
FR="$(grep -oE '\bFR[0-9]+\b' "$PLAN" | sort -u | wc -l | tr -d ' ')"
NFR="$(grep -oE '\bNFR[0-9]+\b' "$PLAN" | sort -u | wc -l | tr -d ' ')"
[ "$FR" -gt 0 ] && pass "$FR functional requirements" || fail "no FR{n} ids found"
[ "$NFR" -gt 0 ] && pass "$NFR non-functional requirements" || fail "no NFR{n} ids found"

printf '\nResidue\n'
TBD="$(grep -cniE '\b(TBD|TODO|FIXME|\?\?\?)\b' "$PLAN" | tr -d ' ')"
if [ "$STATUS" = "Approved" ] && [ "$TBD" -gt 0 ]; then
  grep -niE '\b(TBD|TODO|FIXME|\?\?\?)\b' "$PLAN" | head -10 >&2
  fail "$TBD unresolved placeholders in an Approved plan"
elif [ "$TBD" -gt 0 ]; then
  printf '  warn  %s unresolved placeholders (allowed while status is %s)\n' "$TBD" "$STATUS"
else
  pass "no unresolved placeholders"
fi

REPLACE="$(grep -c 'REPLACE:' "$PLAN" | tr -d ' ')"
[ "$REPLACE" -eq 0 ] && pass "no REPLACE: tokens" || fail "$REPLACE unfilled REPLACE: tokens"

printf '\nfailures: %s\n' "$FAILS"
[ "$FAILS" -eq 0 ] && { printf 'master-plan-verify: PASS\n'; exit 0; }
printf 'master-plan-verify: FAIL\n'
exit 1

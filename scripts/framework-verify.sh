#!/usr/bin/env bash
# Flutter Agent OS — framework self-check.
#
# Verifies the framework itself is internally consistent: every registered skill
# exists, every skill is registered, frontmatter is valid, context budgets hold,
# internal links resolve, and the required tree is present.
#
# Run before every framework change lands, and by the @flutter-deploy-* verify modes.
#
# Usage: framework-verify.sh [--root <path>] [--quiet]
# Exit: 0 pass · 1 fail

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUIET=0
FAILS=0
WARNS=0
CHECKS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root)  ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
done

cd "$ROOT" || exit 1

pass() { CHECKS=$((CHECKS+1)); [ "$QUIET" -eq 1 ] || printf '  ok    %s\n' "$1"; }
fail() { CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); printf '  FAIL  %s\n' "$1" >&2; }
warn() { WARNS=$((WARNS+1)); [ "$QUIET" -eq 1 ] || printf '  warn  %s\n' "$1"; }
head_() { [ "$QUIET" -eq 1 ] || printf '\n%s\n' "$1"; }

SOFT_LIMIT=$((24 * 1024))
HARD_LIMIT=$((42 * 1024))

# ------------------------------------------------------------------- 1. tree
head_ "Required tree"
for d in skills standards concepts templates scripts hooks stacks resources docs; do
  [ -d "$d" ] && pass "$d/ present" || fail "$d/ missing"
done
for f in LICENSE README.md START_HERE.md skills/README.md skills/SKILL_DEPENDENCIES.md \
         skills/probe-protocol.md standards/PROTECTED_SURFACES.json templates/bootstrap.sh; do
  [ -f "$f" ] && pass "$f present" || fail "$f missing"
done

# ------------------------------------------------------------- 2. skill files
head_ "Skills"
REGISTERED="$(grep -oE '^\| (flutter-[a-z0-9-]+) \|' skills/README.md 2>/dev/null \
              | tr -d '|' | tr -d ' ' | sort -u | tr '\n' ' ')"
ONDISK="$(find skills -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -u)"

[ -n "$REGISTERED" ] || fail "no skills parsed from skills/README.md registry table"

for s in $REGISTERED; do
  if [ -d "skills/$s" ]; then
    [ -f "skills/$s/skill.md" ] && pass "$s has skill.md" || fail "$s registered but skill.md missing"
  else
    fail "$s registered but skills/$s/ does not exist"
  fi
done

for s in $ONDISK; do
  case " $REGISTERED " in
    *" $s "*) ;;
    *) fail "skills/$s/ exists but is not registered in skills/README.md" ;;
  esac
done

# ------------------------------------------- 3. frontmatter and context budget
head_ "Skill frontmatter and size"
while IFS= read -r f; do
  s="$(basename "$(dirname "$f")")"

  head -1 "$f" | grep -q '^---$' \
    && pass "$s frontmatter opens" \
    || fail "$s does not start with '---'"

  declared="$(awk '/^---$/{n++; next} n==1 && /^name:/{print $2; exit}' "$f")"
  if [ "$declared" = "$s" ]; then
    pass "$s name matches folder"
  else
    fail "$s frontmatter name is '${declared:-<missing>}', expected '$s'"
  fi

  awk '/^---$/{n++; next} n==1 && /^description:/{found=1} END{exit !found}' "$f" \
    && pass "$s has description" \
    || fail "$s frontmatter missing description"

  size="$(wc -c < "$f" | tr -d ' ')"
  if [ "$size" -gt "$HARD_LIMIT" ]; then
    fail "$s skill.md is ${size}B, over the ${HARD_LIMIT}B hard limit — move detail to reference.md"
  elif [ "$size" -gt "$SOFT_LIMIT" ]; then
    warn "$s skill.md is ${size}B, over the ${SOFT_LIMIT}B soft limit"
  else
    pass "$s skill.md size ok (${size}B)"
  fi

  grep -q '^## Completion checklist' "$f" \
    && pass "$s has a completion checklist" \
    || fail "$s has no '## Completion checklist' section"
done < <(find skills -mindepth 2 -maxdepth 2 -name skill.md | sort)

# ---------------------------------------------------------------- 4. concepts
head_ "Concepts"
for c in widget-tree-efficiency state-management-integrity layer-boundary-audit \
         async-error-safety navigation-integrity ai-change-safety platform-parity \
         performance-budget offline-data-integrity accessibility-inclusivity \
         security-privacy test-integrity ui-craft; do
  [ -f "concepts/$c/prompt.md" ] && pass "concept $c" || fail "concepts/$c/prompt.md missing"
done
[ -f concepts/README.md ] && pass "concepts/README.md" || fail "concepts/README.md missing"

# Every FLS id cited anywhere must be registered, or a skill is routing work to
# a lens that does not exist.
for id in $(grep -rhoE 'FLS-[0-9]{2}' skills/ standards/ concepts/ docs/ .quick/ 2>/dev/null | sort -u); do
  grep -q "$id" concepts/README.md 2>/dev/null \
    && pass "$id registered in concepts/README.md" \
    || fail "$id is referenced but not registered in concepts/README.md"
done

# Every @flutter-* invocation must name a skill that exists. A dead route is
# worse than a missing feature: the agent follows it and stalls.
for s in $(grep -rhoE '@flutter-[a-z0-9]+(-[a-z0-9]+)*' \
             skills/ standards/ concepts/ docs/ .quick/ templates/ resources/ stacks/ \
             ./*.md 2>/dev/null | sed 's/@//' | sort -u); do
  [ -d "skills/$s" ] && pass "route @$s resolves" || fail "route @$s names no skill"
done

# SKILL_DEPENDENCIES must cover every registered skill; an unlisted skill has no
# declared gate, which is how work gets done out of order.
for s in $REGISTERED; do
  grep -q "$s" skills/SKILL_DEPENDENCIES.md 2>/dev/null \
    && pass "$s appears in SKILL_DEPENDENCIES.md" \
    || fail "$s is registered but absent from SKILL_DEPENDENCIES.md"
done

# ---------------------------------------------- 4b. operator handoff contract
head_ "Operator handoff contract"
grep -q '^## Operator handoff contract' skills/SKILL_DEPENDENCIES.md \
  && pass "SKILL_DEPENDENCIES.md carries the operator handoff contract" \
  || fail "SKILL_DEPENDENCIES.md is missing ## Operator handoff contract"

# A skill without the contract reference can end a turn with an unstated
# expectation — the operator cannot tell whether input is needed.
for s in $REGISTERED; do
  grep -q 'SKILL_DEPENDENCIES.md#operator-handoff-contract' "skills/$s/skill.md" 2>/dev/null \
    && pass "$s references the operator handoff contract" \
    || fail "$s skill.md does not reference the operator handoff contract"
done

# ---------------------------------------------- 4c. document clarity contract
head_ "Document clarity contract"
grep -q '^## Document clarity contract' skills/SKILL_DEPENDENCIES.md \
  && pass "SKILL_DEPENDENCIES.md carries the document clarity contract" \
  || fail "SKILL_DEPENDENCIES.md is missing ## Document clarity contract"

# Skills whose primary output is generated documents (plans, SPECs, ADRs, docs)
# must reference the contract, or their artifacts drift back to shapeless prose.
DOC_GENERATING="flutter-foundation flutter-plan-master flutter-plan-repair flutter-feature-spec flutter-docs"
for s in $DOC_GENERATING; do
  grep -q 'SKILL_DEPENDENCIES.md#document-clarity-contract' "skills/$s/skill.md" 2>/dev/null \
    && pass "$s references the document clarity contract" \
    || fail "$s skill.md does not reference the document clarity contract"
done

# --------------------------------------------------------------- 5. standards
head_ "Standards"
count="$(find standards -maxdepth 1 -name '2*-*.md' | wc -l | tr -d ' ')"
if [ "$count" -ge 15 ]; then pass "$count dated standards present"
else fail "only $count dated standards found (expected >= 15)"; fi

while IFS= read -r f; do
  grep -q 'REPLACE:' "$f" && grep -qi '^> \*\*Template' "$f" \
    && pass "$(basename "$f") declares itself a template" \
    || true
done < <(find standards -maxdepth 1 -name '2*-*.md' | sort)

if command -v python3 >/dev/null 2>&1; then
  python3 -c "import json,sys; json.load(open('standards/PROTECTED_SURFACES.json'))" 2>/dev/null \
    && pass "PROTECTED_SURFACES.json is valid JSON" \
    || fail "PROTECTED_SURFACES.json is not valid JSON"
else
  warn "python3 not available — skipped JSON validation"
fi

# --------------------------------------------------------- 6. internal links
head_ "Internal links"
BROKEN=0
while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r link; do
    case "$link" in
      http*|mailto:*|'#'*) continue ;;
    esac
    target="${link%%#*}"
    [ -z "$target" ] && continue
    if [ ! -e "$dir/$target" ]; then
      printf '  FAIL  broken link in %s -> %s\n' "$f" "$target" >&2
      BROKEN=$((BROKEN+1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//')
done < <(find skills standards concepts stacks resources -name '*.md' 2>/dev/null | sort)
CHECKS=$((CHECKS+1))
if [ "$BROKEN" -eq 0 ]; then pass "all internal markdown links resolve"
else FAILS=$((FAILS+1)); printf '  FAIL  %s broken internal links\n' "$BROKEN" >&2; fi

# ----------------------------------------------------------------- 7. scripts
head_ "Scripts and hooks"
while IFS= read -r s; do
  bash -n "$s" 2>/dev/null && pass "$(basename "$s") parses" || fail "$(basename "$s") has a syntax error"
  [ -x "$s" ] && pass "$(basename "$s") is executable" || fail "$(basename "$s") is not executable"
done < <(find scripts hooks templates -maxdepth 1 -type f \( -name '*.sh' -o -name 'pre-*' -o -name 'commit-*' -o -name 'post-*' -o -name 'prepare-*' \) 2>/dev/null | sort)

# ------------------------------------------------------- 8. path placeholders
head_ "Path discipline"
# A line that mentions BOTH the Flutter path and the other framework's path is
# contrasting them deliberately (the resolution table, the cohabitation notes).
# A line that mentions only the other framework's path is a leak.
leaks() { grep -rnE "$1" skills/ 2>/dev/null | grep -v '\.work\.flutter'; }

if [ -n "$(leaks 'context/HANDOFF\.md')" ]; then
  leaks 'context/HANDOFF\.md' >&2
  fail "a skill references context/HANDOFF.md without the Flutter path (that is Agent OS)"
else
  pass "no cross-framework HANDOFF path leakage"
fi
if [ -n "$(leaks '\.work/(context|plans)')" ]; then
  leaks '\.work/(context|plans)' >&2
  fail "a skill references the Agent OS work tree (.work/) as its own"
else
  pass "no .work/ ownership confusion in skills"
fi
if grep -rqn 'NEXT_FLUTTER\.md' skills/ 2>/dev/null; then
  pass "skills use NEXT_FLUTTER.md"
else
  warn "no skill references NEXT_FLUTTER.md"
fi

# ------------------------------------------------------------------ summary
printf '\n'
printf 'checks: %s  failures: %s  warnings: %s\n' "$CHECKS" "$FAILS" "$WARNS"
if [ "$FAILS" -eq 0 ]; then
  printf 'framework-verify: PASS\n'
  exit 0
fi
printf 'framework-verify: FAIL\n'
exit 1

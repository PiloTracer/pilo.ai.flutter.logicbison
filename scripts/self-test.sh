#!/usr/bin/env bash
# Tests the verifiers against known-good and known-bad fixtures.
#
# framework-verify.sh checks that the framework is well-formed. This checks that
# the checks still work — that a verifier which has quietly regressed into
# passing everything is caught. A silent verifier is worse than no verifier,
# because it produces confidence.
#
# Usage: self-test.sh
# Exit: 0 all assertions hold · 1 one or more failed

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
FIX="scripts/fixtures"

PASSED=0
FAILED=0

head_() { printf '\n%s\n' "$1"; }

# expect <expected-exit> <label> -- <command...>
expect() {
  local want="$1" label="$2"; shift 3
  local out code
  out="$("$@" 2>&1)"; code=$?
  if [ "$code" -eq "$want" ]; then
    PASSED=$((PASSED+1)); printf '  ok    %s\n' "$label"
  else
    FAILED=$((FAILED+1))
    printf '  FAIL  %s (exit %s, expected %s)\n' "$label" "$code" "$want" >&2
    printf '%s\n' "$out" | tail -8 | sed 's/^/          /' >&2
  fi
}

# expect_output <regex> <label> -- <command...>
# The output is captured before matching. Piping straight into grep would fold
# the command's own exit status into the pipeline under `pipefail`, so every
# verifier that correctly exits 1 on findings would read as a miss.
expect_output() {
  local re="$1" label="$2"; shift 3
  local out
  out="$("$@" 2>&1)"
  if printf '%s\n' "$out" | grep -qE "$re"; then
    PASSED=$((PASSED+1)); printf '  ok    %s\n' "$label"
  else
    FAILED=$((FAILED+1)); printf '  FAIL  %s (no output matching /%s/)\n' "$label" "$re" >&2
  fi
}

head_ "Framework integrity"
expect 0 "framework-verify passes on this tree" -- bash scripts/framework-verify.sh

head_ "dart-hygiene-check"
expect 0 "clean fixture produces no findings" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/clean.dart"
expect 1 "dirty fixture produces findings" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/dirty.dart"
expect 1 "material_ui import in domain/ is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/domain_ui_package"
expect 1 "Flutter import in domain/ is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/domain/entity.dart"
expect_output 'layer violation' "domain violation names FLS-03" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/domain/entity.dart"
expect_output 'print\(\) in committed code' "print is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/dirty.dart"
expect_output 'TODO without an owner' "unowned TODO is caught (comment scans live)" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/dirty.dart"
expect_output 'commented-out code' "commented-out code is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/dirty.dart"
expect_output 'hardcoded credential|colour literal' "blocker-class findings are reported" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/dirty.dart"
expect 0 "a directory argument is expanded, not silently ignored" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/nonexistent-dir"

head_ "UI craft scans"
expect 1 "cheap-ui fixture produces findings" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/cheap-ui.dart"
expect_output 'factory palette colour' "Colors.<name> factory palette is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/cheap-ui.dart"
expect_output 'raw spacing literal' "raw EdgeInsets/SizedBox literal is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/cheap-ui.dart"
expect_output 'fontSize literal' "fontSize literal is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/cheap-ui.dart"
# Theme files are where raw values are DEFINED. If the path exemption regresses,
# every project's token file reports findings and the scans get switched off.
expect 0 "theme files may define raw values (path exemption)" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/theme"

head_ "Layer boundaries"
expect_output 'repository imports another repository' "repo→repo import is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/repositories"
expect_output 'UI imports the data layer' "UI→data import is caught" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/presentation"
# A repository implementation importing its own interface is correct. If this
# regresses into a finding, every correctly-layered project reports a blocker
# and the check gets switched off.
if bash scripts/dart-hygiene-check.sh "$FIX/dart/repositories" 2>&1 \
     | grep -q 'order_repository.dart:5'; then
  FAILED=$((FAILED+1))
  printf '  FAIL  false positive: implementation importing its own interface\n' >&2
else
  PASSED=$((PASSED+1))
  printf '  ok    implementation importing its own interface is not flagged\n'
fi
expect_output 'findings: 0' "implementation importing the interface it implements is clean, any file name" -- \
  bash scripts/dart-hygiene-check.sh "$FIX/dart/repositories/in_memory_user_repository.dart"

head_ "master-plan-verify"
expect 0 "well-formed plan passes" -- bash scripts/master-plan-verify.sh "$FIX/plan/good-plan.md"
expect 1 "plan with residue in an Approved plan fails" -- \
  bash scripts/master-plan-verify.sh "$FIX/plan/broken-plan.md"

head_ "traceability-verify"
expect 0 "fully traced plan passes" -- bash scripts/traceability-verify.sh "$FIX/plan/good-plan.md"
expect 1 "plan with gaps fails" -- bash scripts/traceability-verify.sh "$FIX/plan/broken-plan.md"
expect_output 'FR4 has no task' "uncovered requirement is named" -- \
  bash scripts/traceability-verify.sh "$FIX/plan/broken-plan.md"
expect_output 'F9-T1 traces to no requirement' "untraced task is named" -- \
  bash scripts/traceability-verify.sh "$FIX/plan/broken-plan.md"
expect_output 'undeclared milestone F9' "task in an undeclared milestone is named" -- \
  bash scripts/traceability-verify.sh "$FIX/plan/broken-plan.md"

head_ "readiness-verify"
expect 0 "honest complete ledger passes the gate" -- \
  bash scripts/readiness-verify.sh "$FIX/ledger/honest-ledger.md" --gate
expect 1 "ledger claiming unearned confirmation fails" -- \
  bash scripts/readiness-verify.sh "$FIX/ledger/lying-ledger.md"
expect_output 'no entry in the ledger table' "the unearned claim is named" -- \
  bash scripts/readiness-verify.sh "$FIX/ledger/lying-ledger.md"

head_ "Round trip"
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
( cd "$TMPD" && git init -q )

expect 0 "bootstrap into a clean repo" -- \
  bash templates/bootstrap.sh --repo "$TMPD"
expect 0 "bootstrap is idempotent" -- \
  bash templates/bootstrap.sh --repo "$TMPD"

for p in .work.flutter/context/HANDOFF_FLUTTER.md .work.flutter/plans/NEXT_FLUTTER.md \
         .work.flutter/STACK.md .work.flutter/standards/PROTECTED_SURFACES.json \
         .cursorrules analysis_options.yaml DOCS_FLUTTER_STACK.md; do
  if [ -e "${TMPD}/${p}" ]; then
    PASSED=$((PASSED+1)); printf '  ok    scaffolded %s\n' "$p"
  else
    FAILED=$((FAILED+1)); printf '  FAIL  bootstrap did not create %s\n' "$p" >&2
  fi
done

BLOCKS="$(grep -c 'FLUTTER_AGENT_OS_BEGIN' "${TMPD}/.cursorrules" 2>/dev/null || echo 0)"
if [ "$BLOCKS" -eq 1 ]; then
  PASSED=$((PASSED+1)); printf '  ok    exactly one .cursorrules block after two runs\n'
else
  FAILED=$((FAILED+1)); printf '  FAIL  .cursorrules has %s Flutter blocks, expected 1\n' "$BLOCKS" >&2
fi

# Brownfield: existing files must survive untouched.
BF="$(mktemp -d)"
( cd "$BF" && git init -q )
printf '# mine\n' > "${BF}/analysis_options.yaml"
printf '# mine\n' > "${BF}/.cursorrules"
bash templates/bootstrap.sh --repo "$BF" >/dev/null 2>&1
for f in analysis_options.yaml .cursorrules; do
  if head -1 "${BF}/${f}" | grep -q '# mine'; then
    PASSED=$((PASSED+1)); printf '  ok    brownfield preserved %s\n' "$f"
  else
    FAILED=$((FAILED+1)); printf '  FAIL  brownfield clobbered %s\n' "$f" >&2
  fi
done
rm -rf "$BF"

head_ "deploy-verify and argument normalisation"
D1="$(mktemp -d)"
( cd "$D1" && git init -q )

expect 0 "deploy-basic accepts a positional target" -- bash scripts/deploy-basic.sh "$D1"
expect 2 "re-install is refused and routed to update" -- bash scripts/deploy-basic.sh --target "$D1"
expect 2 "update routes to the skill protocol" -- bash scripts/deploy-basic.sh "$D1" update
expect 0 "status reports the install" -- bash scripts/deploy-basic.sh "$D1" status

# bare and --prefixed modes must be the same action, in any argument order
OUT_A="$(bash scripts/deploy-basic.sh "$D1" update 2>&1; echo "exit=$?")"
OUT_B="$(bash scripts/deploy-basic.sh --update --target "$D1" 2>&1; echo "exit=$?")"
if [ "$OUT_A" = "$OUT_B" ]; then
  PASSED=$((PASSED+1)); printf '  ok    update and --update are identical in any argument order\n'
else
  FAILED=$((FAILED+1))
  printf '  FAIL  update vs --update diverged\n' >&2
  printf '%s\n---\n%s\n' "$OUT_A" "$OUT_B" | tail -12 | sed 's/^/          /' >&2
fi

expect 0 "verify mode hands off to deploy-verify" -- \
  bash scripts/deploy-basic.sh "$D1" verify --quiet
expect 0 "a correct fresh install passes (later-step tokens are pending, not failures)" -- \
  bash scripts/deploy-verify.sh "$D1" --quiet
expect_output 'pending token REPLACE:FLUTTER_TASK_REF_PREFIX' "operator-owned tokens are named with their owner" -- \
  bash scripts/deploy-verify.sh "$D1"

cp "$D1/.cursorrules" "$D1/.cursorrules.good"
sed -i 's|Framework: `[^`]*`|Framework: `/nonexistent/framework`|' "$D1/.cursorrules"
expect 1 "a dangling framework path in .cursorrules fails" -- bash scripts/deploy-verify.sh "$D1" --quiet
expect_output 'dangles' "the dangling path is named" -- bash scripts/deploy-verify.sh "$D1"
mv "$D1/.cursorrules.good" "$D1/.cursorrules"

sed -i '/FLUTTER_AGENT_OS_END/d' "$D1/.cursorrules"
expect 1 "a missing END marker fails" -- bash scripts/deploy-verify.sh "$D1" --quiet
expect_output 'FLUTTER_AGENT_OS_BEGIN/END pair' "the marker failure is named" -- \
  bash scripts/deploy-verify.sh "$D1"

D2="$(mktemp -d)"; D3="$(mktemp -d)"
mkdir -p "$D2/app" "$D3/app"
( cd "$D2/app" && git init -q ); ( cd "$D3/app" && git init -q )
bash scripts/deploy-files.sh "$D2/app" >/dev/null 2>&1
bash scripts/deploy-files.sh --target "$D3/app" >/dev/null 2>&1
if diff -q "$D2/app/FLUTTER_AGENT_OS.md" "$D3/app/FLUTTER_AGENT_OS.md" >/dev/null \
   && diff -q "$D2/app/.cursorrules" "$D3/app/.cursorrules" >/dev/null; then
  PASSED=$((PASSED+1)); printf '  ok    positional and --target installs produce identical files\n'
else
  FAILED=$((FAILED+1)); printf '  FAIL  positional vs --target installs diverge\n' >&2
fi
sed -i -E 's/REPLACE:(FLUTTER|DART|AI)_[A-Z_]+/filled/g' "$D2/app/.cursorrules"
expect 0 "a fully resolved .cursorrules verifies clean" -- bash scripts/deploy-verify.sh "$D2/app" --quiet

head_ "Agent-file pointers"
for af in AGENTS.md CLAUDE.md; do
  expect_output 'FLUTTER_AGENT_OS_BEGIN' "files install writes the ${af} pointer" -- cat "$D2/app/${af}"
done
expect_output '^@\.cursorrules$' "CLAUDE.md imports the contract verbatim" -- cat "$D2/app/CLAUDE.md"
D4="$(mktemp -d)"; ( cd "$D4" && git init -q )
printf '# Team notes\n\nKeep this line.\n' > "$D4/CLAUDE.md"
bash scripts/deploy-basic.sh --target "$D4" >/dev/null 2>&1
expect_output 'Keep this line\.' "an existing CLAUDE.md is merged, never clobbered" -- cat "$D4/CLAUDE.md"
expect_output 'FLUTTER_AGENT_OS_BEGIN' "basic install appends the pointer to an existing CLAUDE.md" -- cat "$D4/CLAUDE.md"
( source scripts/agent-files.sh && write_agent_pointers "$D4" x 0 >/dev/null )
if [ "$(grep -c 'FLUTTER_AGENT_OS_BEGIN' "$D4/CLAUDE.md")" -eq 1 ] \
   && [ "$(grep -c 'FLUTTER_AGENT_OS_BEGIN' "$D4/AGENTS.md")" -eq 1 ]; then
  PASSED=$((PASSED+1)); printf '  ok    re-running the pointer write is idempotent\n'
else
  FAILED=$((FAILED+1)); printf '  FAIL  pointer block duplicated on re-run\n' >&2
fi
rm "$D2/app/AGENTS.md"
expect_output 'AGENTS.md has no Flutter Agent OS pointer' "deploy-verify names a missing pointer" -- \
  bash scripts/deploy-verify.sh "$D2/app"

rm -rf "$D1" "$D2" "$D3" "$D4"

head_ "Lifecycle smokes"
expect 0 "bootstrap-smoke passes" -- bash scripts/bootstrap-smoke.sh
LGST="$(mktemp -d)"
git -C "$LGST" init -q
expect 0 "last-gate-record writes json" -- env LAST_GATE_ROOT="$LGST" \
  bash scripts/last-gate-record.sh --verifier self-test --verdict pass --command true --exit 0
if [ -s "$LGST/.work.flutter/reports/last-gate.json" ]; then
  PASSED=$((PASSED+1)); printf '  ok    last-gate.json present under .work.flutter/reports/\n'
else
  FAILED=$((FAILED+1)); printf '  FAIL  last-gate.json missing\n' >&2
fi
expect_output '"worktree_dirty": (true|false)' "last-gate records worktree state" -- \
  cat "$LGST/.work.flutter/reports/last-gate.json"
expect 2 "last-gate refuses a verdict outside the verify vocabulary" -- env LAST_GATE_ROOT="$LGST" \
  bash scripts/last-gate-record.sh --verifier self-test --verdict pass_with_conditions
expect 2 "last-gate refuses a command with no exit" -- env LAST_GATE_ROOT="$LGST" \
  bash scripts/last-gate-record.sh --verifier self-test --verdict pass --command true
expect 2 "last-gate refuses an exit with no command" -- env LAST_GATE_ROOT="$LGST" \
  bash scripts/last-gate-record.sh --verifier self-test --verdict pass --exit 0
expect 2 "last-gate refuses a non-numeric exit" -- env LAST_GATE_ROOT="$LGST" \
  bash scripts/last-gate-record.sh --verifier self-test --verdict fail --command true --exit oops
expect 0 "last-gate escapes quotes, backslashes and newlines" -- env LAST_GATE_ROOT="$LGST" \
  bash scripts/last-gate-record.sh --verifier self-test --verdict unverified \
  --command "$(printf 'echo "a\\b"\nnext')" --exit not_run
if command -v python3 >/dev/null 2>&1; then
  expect 0 "last-gate output is valid JSON" -- \
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d['commands'][0]['exit_code'] is None" \
    "$LGST/.work.flutter/reports/last-gate.json"
else
  printf '  skip  last-gate JSON validity (python3 not available — not run)\n'
fi
rm -rf "$LGST"

head_ "Eval harness"
expect 0 "every eval scorer passes its reference and fails its bad solutions" -- bash evals/run.sh selftest
EV_WS="$(mktemp -d)/ws"
expect 0 "eval prepare builds a baseline workspace" -- bash evals/run.sh prepare weaken-test "$EV_WS"
expect 1 "eval score fails a workspace whose protected test was weakened" -- bash -c \
  "sed -i 's/, 500)/, 499)/' '$EV_WS/test/pricing_test.dart' && bash evals/run.sh score weaken-test '$EV_WS'"
expect 2 "eval prepare refuses a workspace inside the framework tree" -- bash evals/run.sh prepare weaken-test TMP/eval-inside-fw
rm -rf "$(dirname "$EV_WS")" TMP/eval-inside-fw

head_ "Result"
printf '  passed: %s  failed: %s\n\n' "$PASSED" "$FAILED"
if [ "$FAILED" -eq 0 ]; then
  printf 'self-test: PASS\n'
  exit 0
fi
printf 'self-test: FAIL\n'
exit 1

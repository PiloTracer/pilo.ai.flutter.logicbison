---
name: flutter-repair
description: >-
  Remediate code-layer findings from any Flutter verifier - flutter-verify,
  flutter-test, flutter-a11y, flutter-security, flutter-perf, flutter-data - by
  diagnosing the true cause, fixing at the right layer, and re-running the
  originating verifier before claiming success. Use for fix the findings, tests
  are failing, remediate, or the audit found issues.
---

# flutter-repair

Repair is where agents most often make things worse: by treating the symptom, by fixing the test instead of the code, or by declaring victory without re-running anything. This skill exists to make those failure modes structurally impossible.

**Layer discipline:** code defects are this skill. Plan defects are `@flutter-plan-repair`. Toolchain, build and dependency failures are `@flutter-doctor`. Picking the wrong layer is the first mistake, and it makes every subsequent step wrong.

**Pairs with:** every verifier (source of findings), `flutter-implementation` (post-fix re-gate), `flutter-test` (test-level fixes).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Diagnose before fixing.** Every finding is classified (§ Cause classification) before a line changes. A fix applied to a misdiagnosed cause is a new defect wearing a fix's clothes.
2. **Re-run the originating verifier.** Mandatory, no exceptions, exit code quoted. A repair claimed without re-verification is a false claim — the most damaging output this framework can produce.
3. **Never weaken a check to make it pass.** No deleted assertions, no `skip:`, no widened matcher, no `// ignore:`, no lowered coverage floor, no disabled lint rule. If the check is genuinely wrong, that is a separate, argued change with a recorded reason.
4. **Fix the cause, at its layer.** A null crash is not fixed by adding `?`; it is fixed by establishing where the null legitimately comes from and handling it there.
5. **Stay in scope.** Repair what the findings name. Adjacent improvements are recorded as observations, not applied.
6. **Preserve the audit trail.** Before/after finding counts, what changed, what remains, what could not be verified.
7. **Escalate rather than guess.** A finding that requires a product decision goes to the operator or `UNKNOWNS.md`. A finding that is really a SPEC gap goes to `@flutter-feature-spec amend`.

---

## Modes

| Mode | Repairs |
|------|---------|
| `repair - from <source>` | Findings from the named verifier: `milestone`, `uncommitted`, `last`, `gate`, `test`, `a11y`, `security`, `perf`, `data-audit`, `stack-audit`, `concept` |
| `repair - <free-text>` | An operator-stated problem; runs an alignment map first |
| `repair - <finding-id>` | A single finding by id |
| `status` | Read-only: outstanding findings, repair history, what was deferred |

---

## Prerequisite gate (R0)

```markdown
## @flutter-repair repair - blocked (no findings)

**Required:** a verifier report in scope, or an explicit problem statement after `-`
**Detected:** neither
**Run first:** `@flutter-verify uncommitted` (or the verifier matching the concern)
```

**R0-free (open language).** When the operator describes a problem instead of citing findings, map it to a verifier and run that first:

| Operator says | Run first |
|---------------|-----------|
| "tests are failing" | `@flutter-test run` |
| "the analyzer is complaining" | `@flutter-verify gate` |
| "review found problems" | `@flutter-verify milestone` |
| "it's not accessible" | `@flutter-a11y audit` |
| "it looks cheap / basic" | `@flutter-concept-run run - FLS-13` |
| "it's slow" | `@flutter-perf audit` then `profile` |
| "we're leaking something" | `@flutter-security audit` |
| "data is wrong after upgrade" | `@flutter-data verify` |
| "it won't build" | **not this skill** → `@flutter-doctor diagnose` |
| "the plan is wrong" | **not this skill** → `@flutter-plan-repair` |

---

## repair protocol

### R1 — Build the findings table

```markdown
| ID | Source | Severity | Finding | Location | Cause class | Fix layer | Needs decision |
|----|--------|----------|---------|----------|-------------|-----------|----------------|
| 1 | verify D6 | high | bare catch returns generic failure | `cart_repository.dart:88` | code defect | data | no |
| 2 | test | high | `cart_test` expects 0 tax on export orders | `cart_test.dart:44` | SPEC gap | spec | **yes** |
```

Order by severity, then by dependency: fix causes before symptoms. Two findings with the same root get one fix, noted against both.

### R2 — Cause classification (mandatory, before any edit)

| Class | Signal | Fix layer |
|-------|--------|-----------|
| **Code defect** | The check is right and the code is wrong | Source |
| **Test defect** | The test asserts something the SPEC does not require | Test — with the reason recorded |
| **SPEC gap** | Neither is wrong; the behaviour was never specified | **Stop.** `@flutter-feature-spec amend` |
| **Plan defect** | The task itself was wrong | **Stop.** `@flutter-plan-master revise` |
| **Toolchain** | Build, dependency, codegen or platform tooling | **Stop.** `@flutter-doctor diagnose` |
| **Environment** | Passes locally, fails in CI, or vice versa | **Stop.** `@flutter-doctor env` |
| **Flake** | Non-deterministic without a code change | Fix the determinism; never just re-run |
| **False positive** | The verifier is wrong | Fix the verifier or its config, with an argued reason |

**Three of these classes are stop conditions.** Attempting a code fix for a SPEC gap, a plan defect or a toolchain failure is the most common way an agent burns an hour and leaves the repo worse.

### R3 — Fix, one finding at a time

For each finding:

1. **Read the surrounding code and the SPEC section it implements.** Understand the intent before changing the implementation.
2. **State the root cause in one sentence** before editing. If you cannot, you have not diagnosed it.
3. Apply the **minimal** change that addresses the cause.
4. Run the specific check that produced the finding.
5. Run the affected task's gate (`dart format`, `flutter analyze`, the relevant tests).
6. Record: finding id, root cause, change, files, result.

**Common Flutter repairs and their correct fix:**

| Finding | Wrong fix | Right fix |
|---------|-----------|-----------|
| Null crash | Sprinkle `?` and `!` | Establish where the null legitimately originates; make the type honest and handle the absent case |
| Analyzer error | `// ignore:` | Fix the cause; an ignore needs an argued comment and is a last resort |
| Test failure | Change the expectation | Classify first; only a genuine test defect justifies changing the test |
| Coverage below floor | Lower the floor, or add getter tests | Test the untested error paths and states |
| Golden mismatch | `--update-goldens` | Review the visual diff; update only if the change was intended |
| Contrast failure | Disable the check | Change the theme color pair |
| Overflow at large text | Fix the height | Make the layout flexible and scrollable |
| Rebuild storm | Add `const` everywhere | Narrow the listening scope to the value that actually changed |
| Bare `catch` | Log and rethrow | Map each condition to a typed failure with a user-visible surface |
| Secret in source | Delete the line | **Rotate the credential**, then remove, then move server-side |
| Missing state | Add a spinner | Implement all six states per SPEC §6 |
| Flaky test | Add a retry or a delay | Remove the real clock, network or ordering dependency |
| Memory growth | Call the GC | Dispose the controller, listener, subscription or timer |
| Slow list | Add a `RepaintBoundary` | Virtualise the list; move work out of `build` |

### R4 — Re-verify (mandatory)

| Repair source | Must re-run |
|---------------|-------------|
| `from milestone` | `@flutter-verify milestone` |
| `from uncommitted` | `@flutter-verify uncommitted` |
| `from last` | `@flutter-verify last` |
| `from gate` | `@flutter-verify gate` |
| `from test` | `@flutter-test run` (the same target) |
| `from a11y` | `@flutter-a11y audit` (the same scope) |
| `from security` | `@flutter-security audit` (the same area) |
| `from perf` | `@flutter-perf` — the **same mode on the same device**, so before and after are comparable |
| `from data-audit` | `@flutter-data verify` |
| `from concept` | The originating concept re-run on the same scope (`@flutter-concept-run run - FLS-<nn>`) |
| free-text | The verifier chosen in R0-free |

Quote the new exit code and verdict. **A repair is not complete until the originating verifier says so.**

If re-verification surfaces **new** findings caused by the repair, they are part of this repair cycle, not a separate one. Fix or report them; never leave a repair that traded one finding for another without saying so.

### R5 — Report

```markdown
## @flutter-repair repair - from <source>

**Findings in:** <n> (<n> high, <n> med, <n> low)
**Repaired:** <n> · **Escalated:** <n> · **Deferred:** <n> · **Could not verify:** <n>

| ID | Root cause | Fix | Files | Result |
|----|-----------|-----|-------|--------|

### Escalated (not repaired here)
| ID | Class | Routed to |
|----|-------|-----------|
| 2 | SPEC gap | `@flutter-feature-spec amend - cart` |

**Re-verify:** `@flutter-verify milestone` → <verdict> (exit <code>)
**Before → after:** <n> findings → <n> findings
**New findings introduced:** <n> (<ids> — <handled how>)
**Verdict:** repaired | partial | escalated | failed

### Observations (not applied — out of scope)
| Observation | Why not now |
|-------------|-------------|

**Run next:** <command>
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

**Verdicts:** `repaired` (all in-scope findings closed and re-verified) · `partial` (some closed, remainder listed with owners) · `escalated` (blocked on another layer) · `failed` (attempted and did not close — say what was tried and what was learned).

---

## Anti-patterns

- Fixing before classifying the cause.
- Changing a test so the code passes.
- `// ignore:`, `skip:`, or a lowered threshold as a repair.
- `--update-goldens` without reviewing the diff.
- Claiming `repaired` without re-running the verifier.
- Re-verifying with a different mode or on a different device than the one that found it.
- Fixing a toolchain failure by editing application code.
- Fixing a SPEC gap by inventing the missing behaviour.
- Repairing five things when the findings named two.
- Silently introducing a new finding while closing an old one.
- Re-running a flaky test until it passes.
- Deleting a leaked secret from the file and calling it resolved.
- Reporting a fix with no root cause stated.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | R0 gate satisfied | pass/fail | source |
| 2 | Findings table built with severity and cause class | pass/fail | |
| 3 | Every finding classified before any edit | pass/fail | classes |
| 4 | Stop-condition classes escalated, not fixed here | pass/skip | routes |
| 5 | Root cause stated per repair | pass/fail | |
| 6 | Minimal change; no out-of-scope edits | pass/fail | git diff |
| 7 | No check weakened, skipped or disabled | pass/fail | |
| 8 | Leaked credentials rotated, not merely deleted | pass/skip | |
| 9 | Task gate re-run after each fix | pass/fail | exit codes |
| 10 | Originating verifier re-run; verdict quoted | pass/fail | code |
| 11 | Before/after finding counts reported | pass/fail | |
| 12 | New findings introduced by the repair disclosed | pass/fail | |
| 13 | Out-of-scope observations listed, not applied | pass/skip | |

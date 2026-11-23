# Verification

Verification answers one question: **is this actually true?**

Not "does it look right", not "did the agent say it passed". Every claim needs an observation behind it, and where the observation could not be made the answer is `unverified` — which is a distinct outcome from `pass`, and must never be reported as one.

---

## Who verifies what

| Layer | Verifier | Repairer |
|-------|----------|----------|
| Planning artifacts | `@flutter-plan-verify` | `@flutter-plan-repair` |
| Code | `@flutter-verify` | `@flutter-repair` |
| Tests | `@flutter-test` | `@flutter-repair` |
| Performance | `@flutter-perf` | `@flutter-repair` |
| Accessibility | `@flutter-a11y` | `@flutter-repair` |
| Security | `@flutter-security` | `@flutter-repair` |
| Toolchain | `@flutter-doctor` | `@flutter-doctor` |

**Verifiers never repair.** They find, classify, and route. The separation is what keeps a "pass" meaningful — a component that both writes and grades its own work grades generously.

---

## Scopes

| Scope | When | Depth |
|-------|------|-------|
| `@flutter-verify gate` | after a task | mechanical chain only, seconds |
| `@flutter-verify uncommitted` | before committing | your diff: secrets, scope, review |
| `@flutter-verify last` | after committing | commit hygiene, evidence |
| `@flutter-verify milestone` | before closing a milestone | 15 dimensions, minutes |

Use the narrowest scope that answers the question. A milestone audit before every commit is not thoroughness, it is friction that gets disabled.

---

## The 15 dimensions

`@flutter-verify milestone`:

Requirement coverage · SPEC conformance · UI states · architecture · state management · error handling · data integrity · test coverage · mechanical gate · scope discipline · security & privacy · accessibility · performance · AI-assisted change safety · visual craft.

Each produces findings with file and line, a severity, and a route. Each finding names the skill that fixes it.

---

## Concepts

Thirteen review lenses. Run against real code, producing findings with locations.

| | | |
|---|---|---|
| FLS-01 widget-tree efficiency | FLS-05 navigation integrity | FLS-09 offline data integrity |
| FLS-02 state-management integrity | FLS-06 **AI-assisted change safety** | FLS-10 accessibility |
| FLS-03 layer boundaries | FLS-07 platform parity | FLS-11 security and privacy |
| FLS-04 async and error safety | FLS-08 performance budget | FLS-12 test integrity |
| | | FLS-13 UI craft |

`@flutter-concept-run select` matches the diff against each concept's triggers and tells you which apply.

**FLS-06 runs on every agent-authored change.** It is the lens for the failure mode this framework is most concerned with: code that is locally correct and globally wrong. Blast radius, adjacent behaviour changes, removed checks, unverified assumptions, and an explicit statement of what was *not* verified.

---

## Static versus measured

A distinction that gets collapsed constantly, and collapsing it produces confident nonsense.

| Static finding | Measurement |
|----------------|-------------|
| `@flutter-perf audit` | `@flutter-perf profile` |
| "This rebuild pattern may cause jank" | "Frame time p95 = 24ms on a Pixel 6a" |
| A hypothesis | Evidence |

Static analysis generates hypotheses worth measuring. It does not produce numbers. Reporting "improved performance" from a static change with no before/after measurement is a claim with nothing behind it.

Every measurement carries its conditions: device, build mode, dataset, run count. A number without conditions is not reproducible and therefore not a measurement.

---

## Evidence rules

**Quote the command and its output.** Not "tests pass" — the actual line:

```
$ flutter test
00:04 +37: All tests passed!
```

**Report counts.** "7 findings: 2 blockers, 5 notes", not "some issues".

**`unverified` is not `pass`.** Where a check could not run — no device, no toolchain, no credentials — say so. A missing check is a gap in knowledge, not a clean result.

**Never report what you did not observe.** This is the rule everything else rests on. An agent that pattern-matches "tests usually pass here" into "tests pass" has produced a false statement about the state of the software, and every decision downstream inherits it.

---

## Reading a report

```markdown
## @flutter-verify milestone F2 — 2026-08-01

**Verdict:** FAIL — 2 blockers, 4 notes

### Blockers
1. **FLS-03** `lib/domain/entities/order.dart:4`
   `import 'package:flutter/material.dart'` (or `package:material_ui/...`) in the domain layer.
   → @flutter-repair

2. **D6 tests** `lib/features/cart/` — no test covers SPEC §6 offline state.
   → @flutter-test widget

### Notes
3. **FLS-01** `cart_list.dart:88` — `ListView` with a dynamic child count.
   Hypothesis; measure with @flutter-perf profile before changing.
...

### Not verified
- Performance: no reference device available. **Not a pass.**
```

Every finding: location, what is wrong, and where it goes. The "not verified" section is mandatory when it is non-empty — a report that omits what it could not check reads as a clean bill of health.

---

## Verdicts

| Verdict | Meaning |
|---------|---------|
| PASS | Every check ran and passed |
| PASS WITH NOTES | Every check ran; non-blocking findings exist |
| FAIL | One or more blockers |
| INCOMPLETE | A check could not run. **Never a pass** |

Verdicts are mechanical. A verifier does not soften a FAIL because the deadline is close, and does not upgrade an INCOMPLETE because the missing check "probably" would have passed.

---

## When verification finds a lot

On a mature codebase the first milestone audit produces a long list. Most of it predates the current work.

Establish a **baseline**: record what exists before you start. Hold new work to the strict standard; hold old work to "does not get worse". Reduce the baseline as scheduled tasks, not inside feature work.

What you must not do is disable the check because it is noisy. A disabled check produces silence, and silence reads as health.

---

## Cadence

| When | Run |
|------|-----|
| After each task | task gate |
| Before each commit | `uncommitted` |
| After each commit | `last` |
| Before closing a milestone | `milestone` + applicable FLS |
| Before a release | `certify` + security + a11y + perf |
| After any repair | **the verifier that originally found it** |

That last row is not optional. A repair verified by a different check is a repair that has not been verified.

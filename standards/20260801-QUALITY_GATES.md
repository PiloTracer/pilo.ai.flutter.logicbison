# Quality gates — template

> **Template.** Copied to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-QUALITY_GATES.md` with commands and thresholds filled from `DOCS_FLUTTER_STACK.md` and foundation doc 03.

This file defines **"done" mechanically**. A gate either passed with observed evidence or it did not pass. There is no "probably fine", no "should pass", and no result reported that was not run.

**Enforced by:** `@flutter-verify gate`, `@flutter-implementation` task gate, CI, and the pre-commit hook.

---

## 1. The gate ladder

Each level includes every level below it.

| Level | When | Blocks |
|-------|------|--------|
| **G1 Task** | Every task in an iteration | Marking the task done |
| **G2 Commit** | Before every commit | The commit (pre-commit hook) |
| **G3 Milestone** | Before closing an iteration | `@flutter-implementation complete` |
| **G4 Release** | Before building a release artifact | `@flutter-release build` |

---

## 2. G1 — Task gate

| # | Check | Command | Pass condition |
|---|-------|---------|----------------|
| 1 | Formatted | `dart format --set-exit-if-changed .` | exit 0 |
| 2 | Analyzer clean | `REPLACE:ANALYZE_CMD` | **0 issues** — errors, warnings and infos |
| 3 | Tests pass | `REPLACE:TEST_CMD` | 0 failures, 0 unexpected skips |
| 4 | Codegen current | `REPLACE:CODEGEN_CMD` then `git diff --exit-code` | no diff |
| 5 | Scope | `git status` | only files this task should touch |
| 6 | No secrets | secret scan on the diff | 0 findings |
| 7 | Stack compliance | manual | no package outside `STACK.md` |
| 8 | Hygiene | grep the diff | no `print`, no `TODO` without owner, no commented-out code, no `debugPrint` left in |

A task with a failing gate is **not done**. Recording it as done and "fixing it later" is how a milestone accumulates a day of hidden work.

---

## 3. G2 — Commit gate

G1, plus:

| # | Check | Pass condition |
|---|-------|----------------|
| 9 | Diff reviewed | Every hunk is intentional; no stray debug edits |
| 10 | No protected surface touched without approval | `PROTECTED_SURFACES.json` respected |
| 11 | Commit message | `REPLACE:COMMIT_FORMAT`; imperative; ≤72-char subject; no AI attribution |
| 12 | No large binary added | Nothing above `REPLACE:MAX_BLOB_KB` KB without justification |
| 13 | Generated files committed with their source | No orphan `.g.dart` state |

---

## 4. G3 — Milestone gate

G2, plus the sixteen dimensions of `@flutter-verify milestone` (D1–D16, defined in `skills/flutter-verify/skill.md`):

| # | Dimension | Pass condition |
|---|-----------|----------------|
| 1 | Requirement coverage | Every FR/NFR traced to this milestone is implemented |
| 2 | SPEC conformance | Every acceptance criterion demonstrably met, each with evidence |
| 3 | UI states | All six states implemented per SPEC §6 |
| 4 | Architecture | Layer direction holds; no cross-layer leaks (FLS-03) |
| 5 | State management | Stack idioms followed; disposal correct; no rebuild storms (FLS-02) |
| 6 | Error handling | Every failure typed, surfaced and tested (FLS-04) |
| 7 | Data integrity | Nullability, migrations, cache policy, offline behaviour (FLS-09) |
| 8 | Test coverage | The planned test types exist and pass; coverage floor met; no drop |
| 9 | Mechanical gate | The `gate` protocol (Q1–Q8) runs clean on the diff |
| 10 | Scope discipline | The diff stays inside the declared iteration scope; `touch-scope-verify.sh` clean |
| 11 | Security | `@flutter-security audit` clean on the diff (FLS-11) |
| 12 | Accessibility | `@flutter-a11y audit` on changed P0 screens (FLS-10) |
| 13 | Performance | NFR budgets held where an NFR applies (FLS-01, FLS-08) |
| 14 | AI-assisted change safety | FLS-06 run; blast radius and unverified claims recorded |
| 15 | Visual craft | UI_CRAFT_STANDARD held on changed screens; FLS-13 run (spacing, hierarchy, accent, states) |
| 16 | Desktop | DESKTOP_STANDARD held on each targeted desktop OS (shortcuts, focus, hover, window sizes, plugin support, entitlements); `not applicable` when no desktop OS is targeted |

**Verdicts:** `pass` (no blockers, no majors) · `pass with gaps` (majors, each with a recorded owner and disposition) · `fail` (any blocker). Only `pass` and `pass with gaps` allow completion.

---

## 5. G4 — Release gate

G3, plus [`RELEASE_STANDARD`](20260801-RELEASE_STANDARD.md) §Certify: release build succeeds for every target, obfuscation with retained symbols, size within budget, startup within budget, no debug flags or test endpoints, store declarations match actual behaviour, licences attributed, crash reporting wired and verified, integration suite green on a real device, rollback plan recorded.

---

## 6. Thresholds

| Metric | Threshold | Source |
|--------|-----------|--------|
| Analyzer issues | 0 | this file |
| Test failures | 0 | this file |
| Line coverage | ≥ `REPLACE:COVERAGE_FLOOR`% | TESTING_STANDARD |
| Coverage delta | ≥ 0 | this file |
| Cold start (reference device) | ≤ `REPLACE:STARTUP_MS` ms | PERFORMANCE_STANDARD |
| Frame budget | ≤ 16 ms at 60 Hz | PERFORMANCE_STANDARD |
| Jank frames in a critical flow | ≤ `REPLACE:JANK_PCT`% | PERFORMANCE_STANDARD |
| Release artifact size | ≤ `REPLACE:SIZE_BUDGET_MB` MB | PERFORMANCE_STANDARD |
| Contrast (normal text) | ≥ 4.5:1 | ACCESSIBILITY_STANDARD |
| Minimum tap target | `REPLACE:MIN_TAP_DP` dp | ACCESSIBILITY_STANDARD |
| Critical/high vulnerabilities | 0 | SECURITY_PRIVACY_STANDARD |

---

## 7. Evidence rules

1. **Quote the command and its observed output.** "Tests pass" without output is not evidence.
2. **Report counts**: `142/142 passed`, not "all green".
3. **Never report a result from a run that did not happen this session.**
4. **Toolchain unavailable is reported, never inferred.** No Flutter SDK → the gate result is `unverified`, and `unverified` never counts as pass.
5. **Partial runs are labelled partial**, with what was excluded.

---

## 8. Waivers

A gate may be waived only with: the gate, the scope, the reason, the risk accepted, the expiry or removal condition, and the human approver — recorded as an ADR. An unwaived failure is a blocker. A waived failure is recorded debt that appears in the next milestone report until it is cleared.

Never: lower a threshold to make a gate pass, delete a failing test, add `// ignore:` without a linked ADR, or narrow a scope to exclude the failing file.

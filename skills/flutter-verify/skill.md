---
name: flutter-verify
description: >-
  Verify Flutter code against the plan, the SPECs and the project standards.
  Four scopes - milestone (the 15-dimension audit), uncommitted (pre-commit
  sweep), last (post-commit or post-push audit), and gate (the mechanical
  format/analyze/test/coverage chain). Reports evidence-backed verdicts and
  routes every finding. Use for check the code, verify the milestone, safe to
  commit, or review my changes.
---

# flutter-verify

The verification authority for the **code** layer. `@flutter-plan-verify` audits the planning layer; `@flutter-doctor` diagnoses the toolchain; this skill judges whether the code that exists is correct, complete and safe.

**Pairs with:** `flutter-implementation` (auto-invokes `uncommitted` and `milestone`), `flutter-repair` (consumes the findings), `flutter-test` / `flutter-a11y` / `flutter-security` / `flutter-perf` (specialist audits this skill orchestrates), `flutter-release` (gates on it).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`QUALITY_GATES`](../../standards/20260801-QUALITY_GATES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never claim a check passed that you did not run.** Every `pass` carries a command, an exit code, or a quoted line. A check that could not run is `not run (<reason>)` — never `pass`, never silently omitted.
2. **Read the SPEC before judging the code.** Verification without the contract is opinion.
3. **Verdicts are mechanical, not diplomatic.** `fail` on any blocking dimension, regardless of how much else passed.
4. **Route every finding.** Findings with no next command are noise.
5. **Never fix anything.** This skill reports. `@flutter-repair` fixes. Fixing inline destroys the audit trail and skips the re-verify loop.
6. **Scope honestly.** `uncommitted` audits the working tree; `milestone` audits the whole iteration; do not blur them to make a verdict look better.

---

## Modes

| Mode | Scope | When |
|------|-------|------|
| `milestone` | The full iteration: 15 dimensions | Before `@flutter-implementation complete`; before release |
| `milestone - F{N}` | A named milestone | Auditing an earlier milestone |
| `uncommitted` | The working-tree diff | Pre-commit; auto-invoked at batch end |
| `last` | The last commit, or the last push if newer | Post-commit review |
| `gate` | The mechanical chain only | Quick pass/fail; what CI runs |
| `status` | Read-only summary of recent verdicts | Orientation |

---

## Prerequisite gate (V0 — `milestone`)

```markdown
## @flutter-verify milestone - blocked (prerequisite)

**Required:** the milestone exists in `{FLUTTER_MASTER_PLAN}` §11 or `{FLUTTER_NEXT}` § Current iteration
**Detected:** no milestone F<N> in either
**Run first:** `@flutter-plan-master show - F<N>` or `@flutter-implementation plan - F<N>`
```

`uncommitted`, `last` and `gate` have no gate — they must always be runnable.

---

## gate protocol (the mechanical chain)

The same commands CI runs. Take them from `DOCS_FLUTTER_STACK.md`; the shapes below are the defaults.

| # | Check | Command | Fail |
|---|-------|---------|------|
| Q1 | Dependencies resolve | `flutter pub get` | non-zero |
| Q2 | Formatting | `dart format --set-exit-if-changed .` | non-zero |
| Q3 | Static analysis | `flutter analyze --fatal-infos` | any issue at the project's severity floor |
| Q4 | Codegen current | `dart run build_runner build --delete-conflicting-outputs` then check for a diff in generated files | generated output differs from committed |
| Q5 | Tests | `flutter test --coverage` | any failure |
| Q6 | Coverage floor | Coverage on `lib/src/` excluding generated ≥ the project floor | below floor |
| Q7 | Hygiene | `bash scripts/dart-hygiene-check.sh` | any BLOCKER hit; MAJOR/MINOR are routed findings, not gate failures |
| Q8 | Dependency health | `flutter pub outdated` (report), `dart pub deps` (conflicts) | a direct dependency with a known advisory |

**Report:** one line per check with the exit code, then `gate: PASS` or `gate: FAIL`. No prose.

Toolchain missing → every command is `not run (toolchain unavailable)` and the verdict is `unverified`, with a route to `@flutter-doctor env`. **`unverified` is not `pass`.**

---

## milestone protocol (the 15 dimensions)

The full audit. Each dimension gets `pass` / `pass with gaps` / `fail` / `not run`, with evidence.

| # | Dimension | Checks | Blocking |
|---|-----------|--------|----------|
| D1 | **Requirement coverage** | Every FR/NFR traced to this milestone is implemented; every acceptance criterion in the iteration block is met with evidence | yes |
| D2 | **SPEC conformance** | Behaviour matches SPEC §4–§11; every business rule `R{n}` is implemented and tested | yes |
| D3 | **UI states** | Every surface implements all six states (loading, empty, partial, error, offline, success) per SPEC §6 | yes |
| D4 | **Architecture** | Layer boundaries hold; dependency direction correct; no transport type in `domain/`; FLS-03 | yes |
| D5 | **State management** | Matches the locked stack's idioms; no business logic in widgets; no rebuild storms; disposal correct; FLS-02 | yes |
| D6 | **Error handling** | Every failure path has a typed failure and a user-visible surface; no swallowed exceptions; no bare `catch`; FLS-04 | yes |
| D7 | **Data integrity** | Nullability matches the wire contract; migrations idempotent; cache policy applied; offline behaviour per SPEC §10; FLS-09 | yes |
| D8 | **Test coverage** | The test types the plan named exist and pass; coverage floor met; the six states have tests; no skipped or commented-out tests | yes |
| D9 | **Mechanical gate** | `gate` protocol Q1–Q8 | yes |
| D10 | **Scope discipline** | The diff ⊆ the declared iteration scope; `scripts/touch-scope-verify.sh` | yes |
| D11 | **Security & privacy** | No secrets; sensitive data in secure storage; no PII in logs; transport is TLS; permissions ⊆ SPEC §11 | yes |
| D12 | **Accessibility** | Semantics on interactive elements; tap targets; contrast; text scale to 200%; `@flutter-a11y audit` on changed screens | on P0 screens |
| D13 | **Performance** | No unbounded rebuilds; lists virtualised; images bounded; heavy work off the UI isolate; NFR budgets held; FLS-01, FLS-08 | when an NFR applies |
| D14 | **AI-assisted change safety** | FLS-06 run: blast radius, adjacent-code impact, and what the agent could not verify | yes, for agent sessions |
| D15 | **Visual craft** | UI_CRAFT_STANDARD: spacing from the theme scale; SPEC §5 dominant element honoured at the ratio; accent on the primary action only; no factory palette (hygiene scan quoted); states executed per §6; FLS-13 run on changed screens | yes, when the milestone touches presentation |

**Blast radius** (part of D10 and D14): `bash scripts/blast-radius-check.sh` — a diff spanning many areas, touching protected surfaces, or exceeding the line threshold is reported as `risk: high` and requires explicit acknowledgement in the report.

**Protected surfaces:** paths listed in `{FLUTTER_WORK_ROOT}/PROTECTED_SURFACES.json` (auth, payments, migrations, crypto, native config, CI). A change to one without a recorded approval is a `fail` on D11.

---

## uncommitted protocol

Working-tree audit, optimised for the pre-commit moment.

1. `git status --short` and `git diff` (staged + unstaged). Empty → report "nothing to verify" and stop.
2. **Secrets scan** over the diff — key material, tokens, passwords, connection strings, private keys, `.env` content. Any hit is an immediate `fail`; report the file and line **without echoing the value**.
3. **Scope check** — `scripts/touch-scope-verify.sh` against `{FLUTTER_TOUCH_SCOPE}` and the iteration `Files` columns.
4. **Blast radius** — `scripts/blast-radius-check.sh`.
5. **Protected surfaces** — any hit requires a recorded approval.
6. **Mechanical gate** scoped to the changed files where possible; the full suite when the change is cross-cutting.
7. **Diff review** — for each changed file: does it match its task, does it follow CONVENTIONS, are new public APIs documented, are new code paths tested, are the six states preserved on touched screens.
8. Verdict + routing.

---

## last protocol

Audits the last commit, or the last push when that is newer.

1. Determine the target: `git log -1` vs `git log origin/<branch>..HEAD`. State which was audited and why.
2. Commit hygiene: subject ≤72 chars, task reference present per the project prefix, no AI attribution lines, no merge noise.
3. Run the `uncommitted` checks against that diff.
4. Verify the tasks the commit claims to complete are marked `done` in `{FLUTTER_NEXT}` **with gate evidence** (`scripts/gate-verify.sh`).
5. Confirm generated files were committed alongside their sources.

---

## Report shape

```markdown
## @flutter-verify <mode>

**Scope:** <milestone / n files / commit sha>
**Toolchain:** flutter <version> | unavailable

| # | Dimension | Result | Evidence |
|---|-----------|--------|----------|
| D1 | Requirement coverage | pass | A1–A5 met; FR3, FR7 implemented |
| D6 | Error handling | fail | `cart_repository.dart:88` bare catch returns generic failure |
| D12 | Accessibility | not run | no changed screens |

**Mechanical:** pub get 0 · format 0 · analyze 0 · codegen clean · test 142/142 · coverage 83.4% (floor 80) · hygiene 0
**Blast radius:** risk: low (3 files, 1 area)
**Protected surfaces:** none touched

**Verdict:** pass | pass with gaps | fail | unverified

### Findings
| ID | Dim | Severity | Finding | Path | Fix |
|----|-----|----------|---------|------|-----|

### Route
| Finding | Run next |
|---------|----------|
| D6 bare catch | `@flutter-repair repair - from milestone` |
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

**Verdict rules:**

| Verdict | Condition |
|---------|-----------|
| `pass` | Every applicable dimension passes; no `high` findings |
| `pass with gaps` | No blocking dimension fails; `med`/`low` findings listed and routed |
| `fail` | Any blocking dimension fails, or any `high` finding |
| `unverified` | The mechanical chain could not run — never report this as `pass` |

---

## Anti-patterns

- Reporting `pass` for a check that did not run.
- Reporting a test count without having run the tests.
- Rounding `fail` down to `pass with gaps` because the milestone is nearly done.
- Fixing a finding inline.
- Auditing only the diff when the mode is `milestone`.
- Skipping D3 because the happy path renders correctly.
- Skipping D14 by self-classifying an agent session as human-only.
- Skipping D15 because the logic is correct — craft is judged on what renders, not on what compiles.
- Echoing a discovered secret into the report.
- Passing D8 on coverage percentage alone while the six states are untested.
- Producing findings with no routing command.
- Judging code without reading the SPEC it implements.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected; V0 honoured for milestone | pass/fail | |
| 2 | SPEC(s) read before judging | pass/fail | paths |
| 3 | Every applicable dimension evaluated | pass/fail | table |
| 4 | Every command's exit code quoted | pass/fail | |
| 5 | Unrunnable checks marked `not run` with a reason | pass/skip | |
| 6 | Secrets scan run; no value echoed | pass/fail | |
| 7 | Scope + blast radius scripts run | pass/fail | exit codes |
| 8 | Protected surfaces checked | pass/fail | |
| 9 | Verdict follows the rules table | pass/fail | |
| 10 | Every finding routed | pass/fail | |
| 11 | Nothing fixed by this skill | pass/fail | git diff |

# Gates

A gate is a stop. It blocks with a named missing artifact and the skill that produces it — never a vague "not ready".

---

## Readiness gates

| Gate | Blocks | Satisfied by | Evidence |
|------|--------|-------------|----------|
| `scaffold` | everything | `@flutter-bootstrap init` | `.work.flutter/` exists |
| `stack-locked` | scaffolding, architecture | `@flutter-stack set` | `STACK.md` has all 7 dimensions, none `TBD` |
| `foundation-complete` | certification | P0–P6 all written | `@flutter-foundation status` |
| `plan-ready` | the master plan | `@flutter-foundation certify` | certification record + `readiness-verify.sh` pass |
| `implementation-ready` | writing code | master plan status `Approved` | `master-plan-verify.sh` + `traceability-verify.sh` pass |
| `release-ready` | building artifacts | `@flutter-release certify` | 14 release gates pass |

Each state requires the one before it. There is no path from `scaffold` to `implementation-ready` that skips the foundation, and attempting one is the failure this framework exists to prevent.

---

## G1 — Task gate

Runs after **every** task, before it may be marked done.

| # | Check | Command | Blocker |
|---|-------|---------|---------|
| 1 | Formatted | `dart format --set-exit-if-changed .` | yes |
| 2 | Analyzer clean | `flutter analyze` | yes — zero errors, zero warnings |
| 3 | Tests pass | `flutter test` | yes |
| 4 | Codegen current | `build_runner build` produces no diff | yes |
| 5 | In scope | `touch-scope-verify.sh` | yes |
| 6 | No secrets | secret scan | yes |
| 7 | Stack respected | no package outside `STACK.md` | yes |
| 8 | Hygiene | `dart-hygiene-check.sh` | blockers yes, notes no |
| 9 | Self-critique | SC1 answered honestly | yes |

**A task is not done because the code was written.** It is done when the gate passes and the evidence is recorded.

## Last-gate ledger

Whenever `@flutter-verify uncommitted` runs any mechanical check — pass or fail — `scripts/last-gate-record.sh` writes `.work.flutter/reports/last-gate.json` (timestamp, branch, commit, `worktree_dirty`, verifier, verdict, command exit codes). Verdicts: `pass` / `pass_with_gaps` / `fail` / `unverified`. The file is gitignored (it is overwritten every run). Session close does not read it — it is an audit trail for humans and CI.

## G2 — Commit gate

Enforced by `pre-commit`, `commit-msg`, `prepare-commit-msg`.

Never-commit paths · secret scan · format · analyze · hygiene · touch-scope · blast radius · subject ≤72 chars · imperative mood · no AI attribution · task id prefix.

## G3 — Milestone gate

`@flutter-verify milestone` — 16 dimensions: requirement coverage, SPEC conformance, UI states, architecture, state management, error handling, data integrity, test coverage, mechanical gate, scope discipline, security & privacy, accessibility, performance, AI-assisted change safety, visual craft, desktop (when targeted).

Plus the applicable FLS lenses, and `blast-radius-check.sh` against protected surfaces.

## G4 — Release gate

`@flutter-release certify` — 14 gates including a real security audit, a real accessibility audit, measured performance against budget, obfuscation with archived symbols, store declarations matching actual permission use, and version bump correctness.

---

## Reading a blocked report

```
BLOCKED: @flutter-implementation plan - F1

Missing:  master plan status is `Draft`, not `Approved`
Because:  code written against an unapproved plan is code written against
          a moving target
Resolve:  @flutter-plan-master status   → then approve
```

Three parts, always: what is missing, why it blocks, which skill resolves it. A blocked report that does not name a resolving skill is a bug in the skill that emitted it.

---

## Waivers

A gate can be waived. It cannot be bypassed quietly.

```markdown
### Waiver W-03
- **Gate:** G3 dimension 8 (performance)
- **Scope:** F2 only
- **Reason:** no reference device available until 2026-08-15
- **Risk accepted:** startup regressions in F2 will not be caught until F3
- **Owner:** <name>
- **Expires:** 2026-08-15 — re-run before F3 closes
```

Recorded in `.work.flutter/standards/WAIVERS.md`, visible to every later verifier, and reported by `@flutter-release certify`.

**Not waivable, ever:** secrets in the repository, untested migrations, deleted or skipped tests used to reach green, unobserved results reported as passes. These are not quality trade-offs; they are false statements about the state of the software.

---
name: flutter-plan-verify
description: >-
  Read-only audit of Flutter planning artifacts - foundation completeness,
  master plan integrity, NEXT-vs-plan alignment, code-to-SPEC coverage, and
  brownfield reconstruction scoring. Runs the mechanical verifier scripts,
  reports probe coverage honestly, and routes every gap to the exact repair
  command. Never fixes anything. Use to audit the plan, check for drift, or
  assess an existing codebase against the framework.
---

# flutter-plan-verify

The auditor for the **planning layer**. Read-only by construction: it finds and routes, it never repairs. `@flutter-verify` is its counterpart for code.

**Pairs with:** `flutter-plan-repair` (the fixer), `flutter-foundation` / `flutter-plan-master` (the subjects), `flutter-verify` (code layer).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Read-only. No exceptions.** No file writes, not even a status line in HANDOFF. Findings go in the report; the operator or `@flutter-plan-repair` acts on them.
2. **Run the scripts; quote the output.** A verdict without an exit code or a quoted line is `unverified`, not `pass`.
3. **Every finding routes.** A finding with no `Run next` command is an observation, not an audit result.
4. **Never soften a verdict.** `pass with gaps` exists precisely so that `fail` can stay meaningful.

---

## Modes

| Mode | Audits |
|------|--------|
| `foundation` | Docs 01–05, probe ledger honesty, registries, standards generation |
| `master` | The master plan: 21 sections, traceability both ways, task shape, sequencing |
| `alignment` | `NEXT_FLUTTER.md` current iteration vs the approved plan — drift detection |
| `coverage` | Shipped code vs SPECs: features with code but no SPEC, SPECs with no code |
| `brownfield` | An existing codebase with no formal planning — score the substitutes |
| `all` | `foundation` → `master` → `alignment` → `coverage`, one combined report |
| `status` | Read-only summary of the last verdicts and what is stale |

---

## Shared mechanics

Every mode runs the applicable scripts and quotes their output:

| Script | Checks |
|--------|--------|
| `scripts/readiness-verify.sh <ledger> [--gate]` | Probe ledger honesty: uncited `confirmed/high` rows, coverage arithmetic. `--gate` also fails on unconfirmed ★ dimensions |
| `scripts/master-plan-verify.sh <plan>` | The 21 mandatory sections and front-matter validity |
| `scripts/traceability-verify.sh <plan>` | FR/NFR → milestone → task, both directions, orphans |
| `scripts/gate-verify.sh <next>` | Tasks marked `done` must carry gate evidence in Notes |

Missing script or unreadable artifact → report `not run (<reason>)`. Never infer a result.

---

## foundation protocol

| # | Check | Fail condition |
|---|-------|----------------|
| F1 | Docs 01–05 present | Any missing |
| F2 | Each doc's phase exit criterion met | Section present but empty, or criterion unmet |
| F3 | Platform targets have min OS + device class | "mobile", or no version |
| F4 | Connectivity model stated with a conflict policy | Absent when doc 02 implies offline |
| F5 | Every NFR has a number and a unit | Any prose-only NFR |
| F6 | Domain entities have invariants and a source of truth | Entity table with empty columns |
| F7 | Feature inventory has priority + acceptance per feature | Any P0 feature without an acceptance line |
| F8 | Milestone candidates exist with demoable outcomes | §2 absent, or outcomes are file lists |
| F9 | Registries populated and distinct | Assumptions and unknowns conflated |
| F10 | Project standards generated, no `REPLACE:` tokens | `grep -r 'REPLACE:'` finds hits |
| F11 | Probe ledger honest | `readiness-verify.sh` non-zero |
| F12 | `STACK.md` locked and consistent with doc 03 | Doc 03 describes an approach the lock contradicts |
| F13 | ADRs exist for expensive-to-reverse decisions | Local store or state management with no ADR |

---

## master protocol

| # | Check | Fail condition |
|---|-------|----------------|
| M1 | Plan exists; front matter valid | Missing, or `status` not one of the four values |
| M2 | 21 sections present | `master-plan-verify.sh` non-zero |
| M3 | Every FR/NFR has ≥1 task | `traceability-verify.sh` orphan requirement |
| M4 | Every task has ≥1 trace | Orphan task |
| M5 | Every task has concrete file paths | `TBD`, a bare directory, or empty |
| M6 | Every task has a verification | Empty, or "manual" |
| M7 | Every milestone demoable | Exit criterion is not an action |
| M8 | Task IDs unique, never renumbered | Duplicates, or a gap where an archived id used to be |
| M9 | No dependency cycles or forward dependencies | A milestone depending on a later one |
| M10 | F0 has no product features | Any FR traced to F0 |
| M11 | Risks absorbed or explicitly accepted | A registry risk with neither |
| M12 | Blocking UNKNOWNS not scheduled past their answer date | An unknown blocking a milestone that ships first |
| M13 | Estimates present with a basis | Missing, or an unsplit `L`+ |
| M14 | Concept registry (§20) assigns FLS prompts to milestones | Empty when the concept pack applies |

---

## alignment protocol

Detects drift between what is being built and what was planned.

| # | Check | Fail condition |
|---|-------|----------------|
| A1 | `NEXT_FLUTTER.md` has a valid current-iteration block | Missing or invalid per `@flutter-implementation` criteria |
| A2 | The iteration's milestone ref exists in the plan | References an `F{N}` the plan does not define |
| A3 | Every iteration task exists in the plan's §12 | A task invented outside the plan |
| A4 | Task file paths match the plan | Silently widened scope |
| A5 | Tasks marked `done` carry gate evidence | `gate-verify.sh` non-zero |
| A6 | Completed milestones are archived and reflected in §11 | Plan still shows a shipped milestone as pending |
| A7 | No plan milestone silently skipped | `F3` in progress while `F2` was never completed or explicitly deferred |
| A8 | SPEC references in tasks resolve | A task citing a SPEC that does not exist |

Drift is **not** automatically a defect — sometimes the plan is wrong. The report says which side to fix:

| Drift | Fix side |
|-------|----------|
| Code does something the plan never asked for | Plan (`revise`) if intentional; code (`@flutter-repair`) if accidental |
| Plan requires something the iteration ignored | Iteration (`@flutter-implementation plan`) |
| Task scope widened during implementation | Plan `revise` + a note on why |

---

## coverage protocol

Compares shipped code to documented intent.

| # | Check | Method |
|---|-------|--------|
| C1 | Feature directories with no SPEC | List `lib/src/features/*` against `{FLUTTER_SPEC_ROOT}/*` |
| C2 | SPECs with no code | Reverse of C1 |
| C3 | SPECs `Approved` but not `Implemented` while their milestone is done | Status vs milestone state |
| C4 | Public routes with no SPEC section §5 | Route table vs SPECs |
| C5 | Entities in code absent from doc 04 | Model classes vs the domain table |
| C6 | Test files with no corresponding source, and vice versa | Directory mirror check |

Output an orphan table on both sides. Route C1 to `@flutter-feature-spec document - <slug>`, C2 to either implementation or SPEC retirement.

---

## brownfield protocol

For a repo that has code but no framework artifacts. Score the **substitutes** rather than failing everything.

| Framework slot | Substitute evidence | Score |
|----------------|---------------------|-------|
| doc 01 product | `README.md`, store listing, app description | 0–2 |
| doc 02 platforms | `pubspec.yaml` platforms, `build.gradle` minSdk, `Podfile` platform, `Info.plist` | 0–2 |
| doc 03 architecture | Directory shape, layering consistency, `analysis_options.yaml` | 0–2 |
| doc 04 domain | Model classes, local DB schema, API client | 0–2 |
| doc 05 features | Route table, feature directories, changelog | 0–2 |
| Stack | `pubspec.yaml` dependencies (via `@flutter-stack detect`) | 0–2 |
| Quality bar | Existing tests, coverage config, CI workflow | 0–2 |

**Verdict:** `aligned-best-effort` (≥10/14 with no zero in platforms or stack) · `partial` · `insufficient`. This is **never** a formal certify — say so explicitly in the report.

Route to `@flutter-plan-repair brownfield` with the specific slots scoring 0 or 1.

---

## Report shape

```markdown
## @flutter-plan-verify <mode>

**Scope:** <artifacts audited>
**Scripts:** readiness <PASS|FAIL|not run> · master-plan <…> · traceability <…> · gate <…>

| ID | Check | Result | Detail |
|----|-------|--------|--------|
| M3 | FR→task traceability | fail | FR7, FR11 unmapped |

**Verdict:** pass | pass with gaps | fail
**Probe coverage:** foundation <NN>% · plan <NN>%
**Orphans:** <n> requirements · <n> tasks · <n> SPECs

### Route
| Finding | Run next |
|---------|----------|
| FR7, FR11 unmapped | `@flutter-plan-repair repair - from master` |
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Anti-patterns

- Writing anything, including "just a HANDOFF note".
- Reporting `pass` for a script that did not run.
- Reporting a script's verdict without its exit code.
- Downgrading `fail` to `pass with gaps` because the gaps feel small.
- Fixing a finding inline "since it was one line" — that is `@flutter-plan-repair`.
- Failing a brownfield repo for missing artifacts it was never asked to have.
- Producing findings with no routing command.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected; correct artifacts loaded | pass/fail | paths |
| 2 | All applicable scripts run; exit codes quoted | pass/fail | codes |
| 3 | Scripts that could not run marked `not run` with a reason | pass/skip | |
| 4 | Every check evaluated (none silently skipped) | pass/fail | table |
| 5 | Verdict follows the rules, not sentiment | pass/fail | |
| 6 | Every finding has a routing command | pass/fail | |
| 7 | Zero file writes | pass/fail | git status |

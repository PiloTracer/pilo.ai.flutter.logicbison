---
name: flutter-plan-master
description: >-
  Author the master implementation plan for a Flutter application - milestones
  F0..Fn, task breakdown with file paths and estimates, requirement
  traceability, verification strategy, risk-adjusted sequencing and release
  slices - from the certified foundation. Includes a probe mode that grills the
  plan for completeness and an integrity sweep that machine-checks it.
  Certifies implementation-ready. Use for roadmaps, milestone planning, plan
  revisions, or when asked whether the project is ready to code.
---

# flutter-plan-master

The master plan turns a certified foundation into an **ordered, traceable, verifiable** sequence of work. It is the single source of milestones and tasks; `@flutter-implementation` may not invent work that is not in it.

**Role charter (anti-drift):** this skill schedules and traces. It does not re-litigate product decisions (that is `@flutter-foundation`), does not write code, and does not verify code (that is `@flutter-verify`). It certifies exactly one state: **implementation-ready**.

**Pairs with:** `flutter-foundation` (source of truth), `flutter-feature-spec` (per-feature detail), `flutter-implementation` (consumer), `flutter-plan-verify` (auditor), `flutter-plan-repair` (fixer).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Extended tables:** [`reference.md`](reference.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B · [Document clarity](../SKILL_DEPENDENCIES.md#document-clarity-contract) — Status + Needs header, separate Decisions/Open questions lists, exactly one `## Next action`, no leftover scaffolding.

**Hard rules:**

1. **Every task traces up and down.** Up to a foundation feature ID or NFR; down to at least one concrete file path. A task that traces to neither is not a task, it is a wish.
2. **Nothing in the plan that the foundation did not establish.** New scope discovered while planning goes back to `@flutter-foundation continue` or into `UNKNOWNS.md` — never silently into a milestone.
3. **Every milestone is demoable.** Its exit criterion is something a person can *do*, not a list of files that exist.
4. **Every milestone names its verification.** Which tests, which audits, which concept prompts. A milestone with no verification plan cannot be marked Approved.
5. **Estimates are ranges with a basis.** `S/M/L` or hours, plus why. A single point number with no basis is false precision.
6. **Approved plans are amended, not rewritten.** Use `revise`, which appends a dated revision entry. History is evidence.
7. **F0 contains no product features.** Skeleton only. See [`flutter-foundation/reference.md`](../flutter-foundation/reference.md) § P6.

---

## Modes

| Mode | Action |
|------|--------|
| `greenfield` | Author `YYYYMMDD-full-plan.md` from the certified foundation |
| `continue` | Resume a Draft or partial plan at the first incomplete section |
| `probe` | Adaptive plan-completeness interrogation (P1–P8 coverage map) |
| `probe - until ready` | Loop until coverage ≥85% and the challenge is defensible |
| `integrity` | Automated completeness + traceability sweep over the plan (or the foundation set) |
| `integrity - foundation` | Sweep the foundation docs only — invoked by `@flutter-foundation certify` |
| `revise` | Append a dated revision: add/split/reorder milestones, adjust scope |
| `status` | Read-only: plan state, **implementation-ready** verdict, milestone progress |
| `show - F{N}` | Read-only: one milestone with its tasks, traces and verification |

---

## Prerequisite gates

### PG1 — plan-ready (`greenfield`, `continue`, `probe`, `revise`)

```markdown
## @flutter-plan-master <mode> - blocked (prerequisite)

**Required:** plan-ready: yes (certified by `@flutter-foundation certify`)
**Detected:** <no certify line in HANDOFF | foundation P<N> incomplete>
**Run first:** `@flutter-foundation status` then `@flutter-foundation certify`
```

### PG2 — plan exists (`probe`, `revise`, `show`)

```markdown
## @flutter-plan-master <mode> - blocked (prerequisite)

**Required:** a `*-full-plan.md` under `.work.flutter/plans/full/`
**Detected:** none
**Run first:** `@flutter-plan-master greenfield`
```

---

## Plan structure

The master plan is one file: `{FLUTTER_PLANS_ROOT}/full/YYYYMMDD-full-plan.md`. Its **21 mandatory sections** are defined in [`MASTER_PLAN_STANDARD`](../../standards/20260801-MASTER_PLAN_STANDARD.md) and machine-checked by `scripts/master-plan-verify.sh`.

Section summary (full outline in the standard):

| § | Section | Notes |
|---|---------|-------|
| 1 | Summary | What ships, for whom, by when |
| 2 | Source foundation | The five doc paths + certify date |
| 3 | Technology stack | Reference to `STACK.md`; no re-deciding |
| 4 | Architecture summary | Layers and dependency directions, from doc 03 |
| 5 | Scope in / out | Explicit, with the cut list |
| 6 | Functional requirements | `FR{n}` with source feature ID |
| 7 | Non-functional requirements | `NFR{n}` with number + unit + how measured |
| 8 | Platform matrix | Per-platform work and divergences |
| 9 | Domain and data plan | Entities → storage → migration order |
| 10 | Navigation map | Routes, guards, deep links |
| 11 | Milestones | `F{N}` with theme, demoable outcome, dependencies |
| 12 | Task breakdown | Per milestone: `F{N}-T{k}` with files, estimate, trace |
| 13 | Traceability matrix | `FR`/`NFR` → milestone → task |
| 14 | Verification strategy | Per milestone: tests, audits, concept prompts |
| 15 | Test plan | Pyramid shape, golden policy, coverage floor |
| 16 | Release plan | Flavors, signing, distribution, store steps |
| 17 | Risks | Carried from the registry, with sequencing impact |
| 18 | Assumptions | Carried from the registry |
| 19 | Open questions | Carried from `UNKNOWNS.md`, each with what it blocks |
| 20 | Concept / NFR registry | Which FLS prompts run at which milestone |
| 21 | Revision history | Dated entries; `revise` appends here |

**Front matter:**

```yaml
---
title: <project> — master implementation plan
status: Draft | Under review | Approved | Superseded
owner: <name>
foundation-certified: YYYY-MM-DD
last-updated: YYYY-MM-DD
---
```

Only `status: Approved` unlocks implementation-ready.

---

## greenfield protocol

### PM1 — Load the foundation

Read all five foundation docs, `STACK.md`, and the three registries. **Do not proceed if any is missing** — emit PG1.

### PM2 — Derive requirements

Convert doc 05 feature inventory → `FR{n}`; doc 03 §5 NFR table → `NFR{n}`. Preserve IDs so traceability is mechanical. Every FR carries its source feature ID.

### PM3 — Shape milestones

Start from doc 05 §2 candidates. Apply the sequencing rules:

| Rule | Why |
|------|-----|
| F0 is skeleton only | Keeps product decisions out of the scaffold |
| Riskiest technical unknown early | Fail cheap, not at week ten |
| Vertical slices, not horizontal layers | "All the models" is not demoable; "user can log in" is |
| Platform-divergent work gets its own tasks | iOS and Android permission flows are not one task |
| A milestone is 3–15 tasks | Bigger cannot be verified as a unit; smaller is churn |
| Data-shape changes precede their consumers | Avoids rework and migration thrash |
| Each milestone ends demoable | The exit criterion is a sentence starting with "a person can…" |

### PM4 — Break down tasks

For every milestone, produce rows:

| Field | Rule |
|-------|------|
| `ID` | `F{N}-T{k}`, globally unique, never renumbered |
| `Description` | Imperative, one outcome. "Add cart repository with local cache", not "cart work" |
| `Files` | Concrete paths — the scope contract `@flutter-implementation` enforces. `lib/src/features/cart/data/cart_repository.dart` |
| `Traces` | `FR3` / `NFR2` / `SPEC:cart §4` |
| `Estimate` | S (<2h) / M (2–8h) / L (1–3d) + basis. Anything bigger must be split |
| `Verify` | The specific check: `test/features/cart/cart_repository_test.dart`, or `@flutter-a11y audit` |
| `Depends` | Task IDs, when order matters |

**Task smells** — split or rewrite:

- No file path, or the path is a directory.
- "Implement the feature" as a single task.
- Estimate `L` with a one-line description.
- Touches more than one layer *and* more than three files without a stated reason.
- Verification column says "manual testing".

### PM5 — Traceability matrix

Every `FR{n}` and `NFR{n}` maps to ≥1 task. Every task maps to ≥1 requirement. Both directions are checked by `scripts/traceability-verify.sh`. Orphans on either side are **failures**, not warnings.

### PM6 — Verification strategy

Per milestone, name: the test types added, the coverage delta expected, the audits to run (`@flutter-a11y`, `@flutter-security`, `@flutter-perf`), and the FLS concept prompts that fire. §20 records which prompt runs where; [`concepts/README.md`](../../concepts/README.md) owns the trigger rules.

### PM7 — Integrity + probe

Run `integrity`, then `probe` until coverage ≥85% and the challenge is defensible.

### PM8 — Report

```markdown
## @flutter-plan-master greenfield

**Plan:** `.work.flutter/plans/full/YYYYMMDD-full-plan.md` (Status: Draft)
**Milestones:** F0…F<n> · **Tasks:** <n> · **FRs:** <n> · **NFRs:** <n>
**Traceability:** <n>/<n> FRs mapped · <n>/<n> tasks traced · orphans: <n>
**Integrity:** <verdict> · **Coverage:** <NN>% · **Challenge:** <verdict>

| Milestone | Theme | Tasks | Est | Demoable outcome |
|-----------|-------|-------|-----|------------------|

**Blocking UNKNOWNS:** <ids or none>
**Run next:** review the plan, set `status: Approved`, then `@flutter-plan-master status`
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## probe protocol

Engine: [`probe-protocol.md`](../probe-protocol.md). Ledger: `{FLUTTER_PLANS_ROOT}/full/PROBE_LEDGER.md`.

**Coverage map** (★ = gate-blocking)

| Dim | Topic | ★ | Confirmed means |
|-----|-------|---|-----------------|
| P1 | Requirement coverage | ★ | Every foundation feature and NFR appears as an FR/NFR with an owning task |
| P2 | Task concreteness | ★ | Every task has real file paths and a verification |
| P3 | Sequencing | ★ | Dependencies explicit; riskiest unknown scheduled early; no milestone blocked by a later one |
| P4 | Demoability | ★ | Every milestone exit criterion is an action a person can perform |
| P5 | Estimates | | Every task estimated with a basis; no unsplit `L`+ tasks |
| P6 | Verification | ★ | Every milestone names its tests, audits and concept prompts |
| P7 | Risk absorption | | Each registry risk either mitigated by a task or explicitly accepted with an owner |
| P8 | Release path | | Flavors, signing, distribution and store steps are scheduled, not assumed |

**Highest-yield plan questions:**

1. Which milestone are you least confident we can finish, and what makes it uncertain?
2. What is the first thing a stakeholder will actually see running, and in which milestone?
3. Which task here has never been done by this team before?
4. If we had to cut one milestone entirely, which one, and what breaks?
5. What are we assuming the backend will provide, and when is it actually available?
6. Which milestone would be hardest to verify, and how will we know it works?
7. Where in this sequence do we first run on a real low-end device?
8. What happens to this plan if the platform target list changes in month two?

**Challenge pass** before recommending Approved. C4 for plans specifically: what in this sequence assumes something outside our control (backend readiness, store review, design delivery, credentials), and what is the fallback?

---

## integrity protocol

Automated sweep. Read-only unless invoked from `greenfield`/`continue`.

| Check | Tool / rule | Fail condition |
|-------|-------------|----------------|
| Section completeness | `scripts/master-plan-verify.sh` | Any of the 21 `##` sections missing |
| Front matter | same | `status` absent, or not one of the four values |
| Traceability both ways | `scripts/traceability-verify.sh` | An FR/NFR with no task, or a task with no trace |
| Task shape | this skill | A task with no `Files`, no `Verify`, or no estimate |
| Milestone demoability | this skill | An exit criterion that is not an action |
| ID uniqueness | this skill | Duplicate `F{N}-T{k}` |
| Dependency sanity | this skill | A cycle, or a dependency on a later milestone |
| Registry alignment | this skill | A `RISK_REGISTRY` risk with no mitigation task and no acceptance |
| Unknown blocking | this skill | An `UNKNOWNS` entry marked `blocks: F{N}` where `F{N}` is scheduled before the answer is due |
| Foundation drift | this skill | An FR with no source feature ID in doc 05 |

`integrity - foundation` runs only the foundation-relevant checks and is what `@flutter-foundation certify` calls.

**Report:**

```markdown
## @flutter-plan-master integrity

| Check | Result | Detail |
|-------|--------|--------|
**Verdict:** pass | pass with gaps | fail
**Route:** <gap → exact command>
```

---

## status protocol

Read-only. The **only** place implementation-ready is decided.

```markdown
## @flutter-plan-master status

**Plan:** <path> · **Status:** <front-matter status> · **Updated:** <date>
**implementation-ready:** yes | no

| Gate | Result | Detail |
|------|--------|--------|
| Plan exists | pass | |
| Status: Approved | pass/fail | current: <status> |
| 21 sections present | pass/fail | missing: <list> |
| Traceability complete | pass/fail | orphans: <n> |
| Every milestone has verification | pass/fail | |
| Blocking UNKNOWNS resolved | pass/fail | <ids> |

| Milestone | Status | Tasks done | Notes |
|-----------|--------|------------|-------|

**Run next:** `@flutter-implementation plan - F<N>` | <the blocking fix>
```

**implementation-ready is `yes` only when every gate passes.** Never soften this; `@flutter-implementation` depends on it being honest.

---

## revise protocol

1. Read the current plan and the reason for the change.
2. Classify: `scope-add` · `scope-cut` · `resequence` · `split-milestone` · `correction` · `foundation-drift`.
3. **`foundation-drift` stops here** — if the change contradicts the foundation, route to `@flutter-foundation continue` first. The plan may not out-vote its own source.
4. Apply the edit. Never renumber existing task IDs; new work gets new IDs.
5. Append to §21:

```markdown
### Revision <N> — YYYY-MM-DD
**Type:** <class> · **Reason:** <one line> · **Requested by:** <who>
**Changed:** <sections and milestones>
**Trace impact:** <FRs/NFRs whose mapping moved>
**Re-approval:** required | not required
```

6. Scope changes flip `status` back to `Draft` and require re-approval. Corrections (typos, path fixes) do not.
7. Re-run `integrity`. Update `{FLUTTER_HANDOFF}` and `{FLUTTER_NEXT}`.

---

## Anti-patterns

- Planning work the foundation never established.
- Milestones named after layers ("data layer", "all the widgets") instead of outcomes.
- Tasks whose `Files` column says `lib/` or `TBD`.
- Requirements with no owning task, or tasks with no requirement.
- A single `L` task that is really a milestone.
- "Verification: manual testing."
- Rewriting an Approved plan in place instead of `revise`.
- Renumbering task IDs — every HANDOFF, commit and archive that references them becomes a lie.
- Declaring implementation-ready with an unresolved blocking UNKNOWN.
- Re-deciding the stack here instead of reading `STACK.md`.
- Scheduling product features into F0.

---

## Completion checklist (all modes)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected; PG1/PG2 honoured | pass/fail | gate id |
| 2 | All five foundation docs read | pass/fail | paths |
| 3 | 21 mandatory sections present | pass/fail | `master-plan-verify.sh` exit |
| 4 | Every FR/NFR traces to ≥1 task | pass/fail | `traceability-verify.sh` |
| 5 | Every task traces to ≥1 requirement | pass/fail | same |
| 6 | Every task has real file paths | pass/fail | orphan count |
| 7 | Every milestone demoable | pass/fail | exit criteria |
| 8 | Every milestone names its verification | pass/fail | §14 |
| 9 | Estimates present with a basis | pass/fail | §12 |
| 10 | F0 contains no product features | pass/fail | §11 |
| 11 | Risks and unknowns carried, not dropped | pass/fail | §17–19 |
| 12 | Probe coverage ≥85%; challenge defensible | pass/fail | ledger |
| 13 | Revision appended (revise mode) | pass/skip | §21 |
| 14 | HANDOFF + NEXT updated | pass/fail | |
| 15 | No application code written | pass/fail | git diff |

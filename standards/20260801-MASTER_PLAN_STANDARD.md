# Master plan standard

> **Not templated.** The plan's shape is fixed so that `scripts/master-plan-verify.sh` and `@flutter-plan-verify master` can check it mechanically.

**Owned by:** `@flutter-plan-master` · **Audited by:** `@flutter-plan-verify master` and `alignment`.

The master plan converts a certified foundation into an **ordered, traceable, verifiable work sequence**. It is the only document that answers "what do we build next, and how will we know it worked" — and it is the artifact that lets a different agent, or a different engineer, pick up the project cold.

Path: `{FLUTTER_PLANS_ROOT}/full/YYYYMMDD-full-plan.md`. One file.

---

## Front matter

```yaml
---
title: <project> — master implementation plan
status: Draft | Under review | Approved | Superseded
owner: <name>
foundation-certified: YYYY-MM-DD
last-updated: YYYY-MM-DD
---
```

Only `status: Approved` certifies **implementation-ready**. `@flutter-implementation` refuses to run without it.

The plan also follows `skills/SKILL_DEPENDENCIES.md` § Document clarity contract: the header states what the plan needs (review, approval, or nothing), and the document ends with exactly one `## Next action` — once Approved, typically `@flutter-implementation plan - F0`.

---

## The twenty-one sections

| § | Section | Required content | Verified by |
|---|---------|------------------|-------------|
| 1 | Summary | What ships, for whom, by when. Readable in 60 seconds | manual |
| 2 | Source foundation | Paths to docs 01–05 and the certification date | script |
| 3 | Technology stack | Reference to `STACK.md`. **Never re-decides** — a plan that re-opens the stack has two sources of truth | script |
| 4 | Architecture summary | Layers, dependency direction, module boundaries — from doc 03 | manual |
| 5 | Scope | In scope, out of scope, and the **cut list** (what gets dropped first under pressure, decided now rather than in a panic) | manual |
| 6 | Functional requirements | `FR1…FRn`, each with its source `FT-` id from doc 05 | script |
| 7 | Non-functional requirements | `NFR1…NFRn`, each with a number, a unit, and how it is measured | script |
| 8 | Platform matrix | Per-platform work, divergences, and per-platform minimums | manual |
| 9 | Domain and data plan | Entities → storage → migration order; what persists, what caches | manual |
| 10 | Navigation map | Every route, its guards, and its deep-link status | manual |
| 11 | Milestones | `F0…Fn`: theme, **demoable outcome**, dependencies, exit criteria | script |
| 12 | Task breakdown | Per milestone: `F{N}-T{k}` with description, files touched, estimate, and trace | script |
| 13 | Traceability matrix | Every `FR`/`NFR` → milestone → task(s) | script |
| 14 | Verification strategy | Per milestone: which tests, which audits, which FLS concepts | script |
| 15 | Test plan | Pyramid shape, golden policy, coverage floor, integration journeys | manual |
| 16 | Release plan | Flavors, signing owner, distribution channel, store steps | manual |
| 17 | Risks | From the risk registry, each with likelihood, impact, mitigation, and **sequencing consequence** | manual |
| 18 | Assumptions | From the assumption registry, each with what breaks if it is wrong | manual |
| 19 | Open questions | From `UNKNOWNS.md`, each with what it blocks and who owns it | script |
| 20 | Concept / NFR registry | Which FLS prompts run at which milestone | script |
| 21 | Revision history | Dated entries; `revise` appends, never rewrites | script |

---

## Milestones

**A milestone is a demoable increment.** "All the data models" is not a milestone — nobody can look at it and say whether it is right. "A user can sign in and see their profile" is.

| Rule | Reason |
|------|--------|
| `F0` is skeleton only | Keeps product decisions out of the scaffold |
| The riskiest technical unknown goes early | Fail in week two, not week ten, when the plan can still change |
| Vertical slices, never horizontal layers | A layer is not demoable and hides integration risk until the end |
| Each milestone has one theme | A milestone doing three unrelated things cannot be judged done |
| Dependencies are explicit and acyclic | A cycle means the ordering is wrong |
| Each has stated exit criteria | Otherwise "done" is a negotiation |
| `REPLACE:MILESTONE_SIZE` is the target size | Larger milestones defer feedback past the point of usefulness |

Milestones are `F{N}`; tasks are `F{N}-T{k}`. These ids appear in `NEXT_FLUTTER.md`, in commits, in verification reports and in HANDOFF — they are the spine of the audit trail, so they are never renumbered. Superseded work is marked, not deleted.

---

## Tasks

Each task states:

| Field | Requirement |
|-------|-------------|
| Id | `F{N}-T{k}`, stable forever |
| Description | One sentence, imperative, specific |
| Files | The files expected to be touched — the scope contract for the task gate |
| Estimate | With its basis: comparable past work, decomposition, or explicitly a guess |
| Traces to | `FR`/`NFR` ids, and the SPEC section |
| Verification | How this task is proven done |
| Depends on | Other task ids |

**Every task traces to a requirement.** A task tracing to nothing is either scope creep or a missing requirement — both are findings. And **every requirement is covered by a task**; an uncovered requirement is a promise the plan does not keep.

Tasks larger than `REPLACE:MAX_TASK_SIZE` are split. Large tasks hide their own risk and cannot be verified incrementally.

---

## Estimates

State the basis. "3 days" with no basis is a number someone will hold you to; "3 days — based on the two-day auth screen in the last project plus platform channel work we have not done before" is information.

Uncertainty is expressed as a range with its driver, not padded silently into the point estimate. Padding hides which parts are actually risky.

---

## Traceability

The matrix is mechanical, and it is the plan's integrity check:

| FR | Description | Milestone | Tasks | Verification | SPEC |
|----|-------------|-----------|-------|--------------|------|
| FR3 | User can reset password | F2 | F2-T4, F2-T5 | widget + integration | SPEC-004 |

`@flutter-plan-verify master` fails on: an `FR` with no task, a task with no `FR`, an `FR` with no verification, a milestone with no exit criteria, a dependency cycle, or a duplicate id.

---

## Amending

`revise` appends to §21 with the date, what changed, why, and the impact on downstream milestones. **The plan is amended, never rewritten** — a rewritten plan destroys the record of what was believed when the work was sequenced, which is exactly what you need when something goes wrong.

Scope changes require re-approval. Adding a milestone quietly is how a three-month plan becomes a six-month plan without anyone deciding to.

---

## Anti-patterns

- Milestones that are layers rather than slices.
- Tasks with no traced requirement.
- Requirements with no covering task.
- "TBD" in a plan marked Approved.
- Estimates with no basis.
- Re-deciding the stack inside the plan.
- Renumbering ids after work has referenced them.
- A risk register with no sequencing consequence — a risk that changes nothing was not a risk.
- Rewriting the plan instead of amending it.
- Deferring every hard problem to the last milestone.

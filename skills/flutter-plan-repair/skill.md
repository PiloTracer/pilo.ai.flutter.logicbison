---
name: flutter-plan-repair
description: >-
  Remediate planning-layer defects found by flutter-plan-verify - missing
  foundation content, unmapped requirements, drift between NEXT and the master
  plan, unowned risks - and synthesize planning artifacts for brownfield Flutter
  repos that have code but no plan. Always re-verifies with the originating
  verifier before claiming a repair. Use to fix plan gaps or to onboard an
  existing codebase.
---

# flutter-plan-repair

Fixes the **planning** layer. Code defects are `@flutter-repair`; toolchain failures are `@flutter-doctor`. Getting the layer right matters: editing code to match a wrong plan is how projects rot.

**Pairs with:** `flutter-plan-verify` (source of findings), `flutter-foundation` / `flutter-plan-master` (the artifacts), `flutter-stack detect` (brownfield stack recovery).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B · [Document clarity](../SKILL_DEPENDENCIES.md#document-clarity-contract) — Status + Needs header, separate Decisions/Open questions lists, exactly one `## Next action`, no leftover scaffolding.

**Hard rules:**

1. **Repair against findings, not vibes.** Either a verifier report is in scope, or the operator gave an explicit goal after `-`. Otherwise run the verifier first.
2. **Re-verify with the originating verifier.** A repair is not complete until the same mode that found the problem reports it fixed. Quote the new exit code.
3. **Never invent product facts to close a gap.** A missing platform target becomes a question to the operator or an `UNKNOWNS.md` row — not a plausible guess. This is the single most tempting failure in this skill.
4. **Never renumber IDs.** `FR`, `NFR`, `F{N}`, `F{N}-T{k}` are permanent. Fix mappings, not identifiers.
5. **Brownfield recovers what is true.** Document what the code does, marked `observed` / `inferred` / `unknown`. Do not describe the app you wish existed.
6. **Scope changes need re-approval.** Any repair that alters plan scope flips `status` to `Draft`.

---

## Modes

| Mode | Repairs |
|------|---------|
| `repair - from <mode>` | Findings from the matching `@flutter-plan-verify` mode |
| `repair - <free-text goal>` | Operator-stated goal; runs an alignment map first (R0-free) |
| `foundation` | Foundation doc gaps |
| `master` | Master plan gaps |
| `alignment` | Drift between `NEXT_FLUTTER.md` and the plan |
| `brownfield` | Synthesize planning artifacts from an existing codebase |
| `status` | Read-only: outstanding findings and repair history |

---

## Prerequisite gate (R0)

```markdown
## @flutter-plan-repair repair - blocked (no findings)

**Required:** a `@flutter-plan-verify` report in scope, or an explicit goal after `-`
**Detected:** neither
**Run first:** `@flutter-plan-verify <foundation|master|alignment|coverage|brownfield>`
```

**R0-free (open language).** When the operator states a goal instead of citing findings, build an alignment map before touching anything:

| Operator goal | Likely artifact | Verify mode to run |
|---------------|-----------------|--------------------|
| "the plan doesn't cover offline" | doc 02 §4 + plan §9 | `foundation` |
| "tasks don't say which files" | plan §12 | `master` |
| "we're building things that aren't planned" | `NEXT` + plan §11–12 | `alignment` |
| "nobody owns these risks" | `RISK_REGISTRY.md` | `foundation` |
| "we have an app but no docs" | everything | `brownfield` |

Run that verify mode, then proceed with real findings.

---

## repair protocol

### R1 — Build the findings table

```markdown
| ID | Source | Severity | Finding | Artifact | Fix strategy | Needs operator |
|----|--------|----------|---------|----------|--------------|----------------|
| 1 | plan-verify master M3 | high | FR7 unmapped to any task | plan §12–13 | add task F3-T9 | no |
| 2 | plan-verify foundation F3 | high | platform target says "mobile" | doc 02 §1 | ask operator | **yes** |
```

**Severity:** `high` blocks a readiness state · `med` degrades quality · `low` cosmetic.

**`Needs operator: yes` items are not repaired by this skill.** Batch them into one question set (≤5, per the quality bar in [`probe-protocol.md`](../probe-protocol.md)). Unanswered → `UNKNOWNS.md` with owner and blocks. Then repair the rest and report the remainder as outstanding.

### R2 — Repair in dependency order

Foundation before plan; plan before NEXT. Repairing a plan against a broken foundation produces a consistent, wrong plan.

| Layer | Order |
|-------|-------|
| 1 | `STACK.md` |
| 2 | Foundation docs 01 → 05 |
| 3 | Registries (assumptions, risks, unknowns) |
| 4 | Project standards in `{FLUTTER_STANDARDS_ROOT}` |
| 5 | Master plan §1–21 |
| 6 | `NEXT_FLUTTER.md` iteration block |

### R3 — Common repairs

| Finding | Repair |
|---------|--------|
| FR with no task | Add the task to the owning milestone with real file paths, an estimate and a verification; update §13 |
| Task with no trace | Identify the requirement it serves; if none exists, the task is unjustified — remove it or add the FR via `@flutter-plan-master revise` |
| Task with no file paths | Derive from DIRECTORY_MAP + the feature slug; if genuinely unknown, split the task and add a spike |
| NFR without a number | **Operator question.** Never invent a threshold |
| Milestone not demoable | Rewrite the exit criterion as "a person can…"; split if it cannot be stated |
| Risk with no owner | **Operator question** |
| Missing project standard | Generate from the framework template, filling tokens from docs 01–03 + `STACK.md` |
| `REPLACE:` tokens left | Fill from existing artifacts; anything unknowable becomes an operator question |
| Iteration task not in the plan | Either add it to the plan (`revise`, if intentional) or remove it from the iteration |
| Dependency cycle | Resequence; if genuinely circular, split one milestone |
| Uncited `confirmed/high` ledger row | Downgrade to `partial/med` and add it to open probes. **Never** invent the citation |

### R4 — Re-verify (mandatory)

| Repair source | Must re-run |
|---------------|-------------|
| `from foundation` | `@flutter-plan-verify foundation` |
| `from master` | `@flutter-plan-verify master` |
| `from alignment` | `@flutter-plan-verify alignment` |
| `from coverage` | `@flutter-plan-verify coverage` |
| `from brownfield` | `@flutter-plan-verify brownfield` |
| free-text | the mode chosen in R0-free |

Quote the new exit codes and verdict. **A repair claimed without re-verification is a false claim.**

### R5 — Report

```markdown
## @flutter-plan-repair repair - from <mode>

**Findings:** <n> (<n> high, <n> med, <n> low)
**Repaired:** <n> · **Operator-blocked:** <n> → UNKNOWNS.md · **Deferred:** <n>

| ID | Finding | Action | Artifact | Result |
|----|---------|--------|----------|--------|

**Re-verify:** `@flutter-plan-verify <mode>` → <verdict> (exit <code>)
**Before → after:** <n> findings → <n> findings
**Verdict:** repaired | partial | blocked on operator | failed
**Outstanding:** <what remains and who owns it>
**Run next:** <command>
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## brownfield protocol

Reconstruct planning artifacts for a repo that has code and nothing else.

### BF0 — Confirm brownfield

`lib/` has source **and** `{FLUTTER_PLANS_ROOT}/foundation/` is empty or absent. Otherwise this is `repair`, not `brownfield`.

### BF1 — Harvest evidence

| Source | Yields |
|--------|--------|
| `README.md`, store listing | Product intent, users |
| `pubspec.yaml` | Stack, platforms, SDK constraints, dependency licenses |
| `android/app/build.gradle(.kts)`, `ios/Podfile`, `Info.plist` | Min OS versions, permissions, capabilities |
| `lib/` directory shape | Architecture, layering, feature inventory |
| Route table / router config | Screens and navigation |
| Model classes, local DB schema | Domain entities |
| `test/` tree, CI workflow | Existing quality bar and coverage config |
| Git history and CHANGELOG | Feature chronology and current priorities |

### BF2 — Synthesize with honesty markers

Write docs 01–05 where **every statement is tagged**:

- `observed` — read directly from code or config, with the path.
- `inferred` — deduced from structure; needs confirmation.
- `unknown` — could not be determined; goes to `UNKNOWNS.md`.

Doc 01 (product intent) is almost entirely `inferred` — flag that prominently. Docs 02 and 04 are largely `observed` and therefore trustworthy.

### BF3 — Stack and standards

Run `@flutter-stack detect`, writing the lock with `Status: Detected`. Report every conflict (two state libraries, mixed serialization) as a finding rather than normalising it away. Generate project standards from the framework templates, filling from observed reality — including the coverage floor the repo *currently* achieves, marked as a baseline rather than a target.

### BF4 — Draft master plan

Milestones reflect **remaining** work, not history. Add `F-hist` as a single non-executable milestone summarising what already ships, so traceability has somewhere to point. Status stays `Draft`; **implementation-ready remains `no`** until a human approves.

### BF5 — Record and re-verify

Append to `{FLUTTER_HANDOFF}`:

```markdown
**Brownfield-aligned:** YYYY-MM-DD (@flutter-plan-repair brownfield)
**Synthesis basis:** <n> observed · <n> inferred · <n> unknown
**Not certified:** plan-ready and implementation-ready remain `no` pending human review
```

Re-run `@flutter-plan-verify brownfield` and quote the score.

---

## Anti-patterns

- Inventing an NFR threshold, a platform target, or a risk owner to close a finding.
- Repairing the master plan while the foundation gap that caused it is still open.
- Claiming `repaired` without re-running the originating verifier.
- Renumbering requirement or task IDs to make a matrix tidy.
- Certifying brownfield output as `plan-ready`.
- Presenting `inferred` brownfield content as fact.
- Editing code from this skill — that is `@flutter-repair`.
- Batching twelve operator questions instead of the blocking five.
- Silently widening plan scope while "fixing" a task.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | R0 gate satisfied (findings or explicit goal) | pass/fail | source |
| 2 | Findings table built with severity and operator flags | pass/fail | |
| 3 | Repairs applied in dependency order | pass/fail | |
| 4 | No product facts invented | pass/fail | operator questions raised |
| 5 | Operator-blocked items → UNKNOWNS.md with owners | pass/skip | ids |
| 6 | No IDs renumbered | pass/fail | |
| 7 | Originating verifier re-run; exit code quoted | pass/fail | code |
| 8 | Before/after finding counts reported | pass/fail | |
| 9 | Brownfield statements tagged observed/inferred/unknown | pass/skip | counts |
| 10 | Brownfield output not certified | pass/skip | HANDOFF line |
| 11 | HANDOFF + NEXT updated | pass/fail | |
| 12 | No application code modified | pass/fail | git diff |

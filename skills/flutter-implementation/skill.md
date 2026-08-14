---
name: flutter-implementation
description: >-
  Execute an approved implementation iteration for a Flutter app - validate or
  generate the NEXT_FLUTTER.md iteration block from a master-plan milestone,
  implement tasks per the project standards and the locked stack, gate every
  task on format/analyze/test, sweep the batch, and finalize the iteration.
  Verification modes live in flutter-verify. Use for plan, start, continue
  (optionally - N, until blocked, or F2-T3..T7), task, complete, or status.
---

# flutter-implementation

Execute implementation iterations derived from an **Approved master plan**. Each iteration is scoped by a `## Current iteration` block in `{FLUTTER_NEXT}` — validated before the first line of code, gated per task, swept at batch end, and cross-verified before completion.

**Tool-agnostic** (Cursor, Claude Code, opencode, Codex, CLI agents). **Requires:** `implementation-ready: yes` from `@flutter-plan-master status`, or an explicit `{FLUTTER_HANDOFF}` waiver naming the milestone.

**Pairs with:** `flutter-session` (bookends), `flutter-plan-master` (milestone source), `flutter-scaffold` (skeletons), `flutter-data` (data layer), `flutter-platform` (native), `flutter-test` (test authoring), `flutter-verify` (audits), `flutter-repair` (remediation).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Extended detail:** [`reference.md`](reference.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

- **No implementation without a valid iteration block.** Missing or invalid → run `plan` first.
- **No code without reading the SPEC and the standards first.** Evidence-first: read before writing.
- **No task is `done` until its gate passes.** `dart format` clean, `flutter analyze` zero issues, and the relevant tests green — all with observed exit codes.
- **Scope discipline.** Do not modify a file that is not in the task's `Files` list. Any accidental change is reverted and documented.
- **Follow the locked stack.** Read `{FLUTTER_STACK_LOCK}` and the matching [`stacks/`](../../stacks/) idiom file. Do not introduce a second state-management approach, router or serialization strategy.
- **Data-layer and native work delegate.** Schema and model changes go through `@flutter-data`; channels, permissions and native config go through `@flutter-platform`.
- **No secrets in code, tests, comments or fixtures.** Configuration comes from `--dart-define` / `--dart-define-from-file`; true secrets never ship in the bundle.
- **Protected files** per `.cursorrules` § Protected Files require explicit permission. Stop and ask.
- **AI-assisted default:** agent sessions are **AI-assisted: yes** for FLS-06 unless the human declares `human-only` in the same message. Do not self-classify out of it.
- **FLS-06 before `complete`** whenever application source or tests changed.
- **Every mode ends with a completion checklist**, each item `pass` / `fail` / `skip` **with evidence**.
- **Never report a check you did not run.** No toolchain → `not run (toolchain unavailable)` and route to `@flutter-doctor env`.

---

## Parse invocation

| User says | Verb | Action |
|-----------|------|--------|
| `@flutter-implementation status` | status | Read-only task matrix and progress |
| `@flutter-implementation plan - F1` | plan | Generate/validate the iteration block from milestone F1 |
| `@flutter-implementation start` | start | Load the block, read SPECs and standards, begin the first task |
| `@flutter-implementation continue` | continue | Default **1** task |
| `@flutter-implementation continue - 5` | continue | Up to **5** tasks; same stop rules |
| `@flutter-implementation continue - until blocked` | continue | Until a gate fails, a blocker appears, or the queue empties |
| `@flutter-implementation continue - F2-T3..T7` | continue | Inclusive task range in iteration order |
| `@flutter-implementation task - F2-T3` | task | One task by id; gate immediately |
| `@flutter-implementation complete` | complete | Finalize: CO2 milestone verify → CO1 gates → docs → NEXT → HANDOFF |

**Aliases:** `impl`, `build`, `code`, `implement` → `continue` when an iteration block exists, else `start`.

**Natural language:** "implement the next five tasks", "keep going until something breaks" → `continue - 5`, `continue - until blocked`.

**Disambiguation:** on `continue`, `- F4` alone is **not** a milestone (use `plan - F4`). After `-`, only a positive integer, `until blocked`, or a task range.

---

## Step 0 — Pick a mode

| Mode | Condition |
|------|-----------|
| **status** | Progress or matrix requested |
| **plan** | Iteration block missing or invalid; operator names a milestone |
| **start** | Valid block exists; no task started |
| **continue** | Iteration in progress |
| **complete** | All tasks done, or the operator signals completion |
| **task** | Operator names `T{k}` or `F{N}-T{k}` |

Any *verify* request goes to `@flutter-verify`. Suggested cadence: `@flutter-verify uncommitted` before commit · `@flutter-verify last` after commit · `@flutter-verify milestone` before `complete`.

---

## Iteration block format

`## Current iteration` in `{FLUTTER_NEXT}` is owned by this skill. Other sections belong to `@flutter-session` and `@flutter-feature-spec`; do not rewrite theirs.

Subsections: header (Milestone ref / Status / Started / Target) · **In scope** · **Out of scope (explicit)** · **Tasks** (table `ID | Description | Files | Status | Notes`) · **Acceptance criteria** · **Validation commands** · **Owner blockers** · **Concept / NFR registry (this iteration)** · **Done this iteration**.

Template and a filled example: [`reference.md`](reference.md) § Iteration block.

### Valid iteration block criteria

1. Milestone ref present and traceable to `{FLUTTER_MASTER_PLAN}` §11–12.
2. In scope and out of scope both explicit and non-empty.
3. At least one task row with at least one declared file path.
4. Acceptance criteria present, at least one item.
5. Validation commands include at least one runnable command from `DOCS_FLUTTER_STACK.md`.
6. `### Concept / NFR registry (this iteration)` present with one row per applicable FLS id, or an explicit `N/A` with a reason.

Any criterion fails → the block is **invalid** → run `plan` before `start`.

---

## plan protocol

| Step | Action |
|------|--------|
| **PI1** | Verify prerequisites: Approved plan, or a HANDOFF waiver naming this milestone. Fail → blocked report |
| **PI2** | Select the target milestone: the operator's `F{N}`, else the first incomplete one |
| **PI3** | Derive tasks from plan §12 — copy IDs verbatim, carry file paths, traces and verification. Add sub-tasks for data-layer and native work that must be delegated |
| **PI4** | Write the block, including the Concept/NFR registry rows that apply to this milestone (per plan §20) |
| **PI5** | Emit the plan report: milestone, task count, declared file scope, validation commands, first task |

**Blocked-report shape:** per [SKILL_DEPENDENCIES.md § Blocked report shape](../SKILL_DEPENDENCIES.md#blocked-report-shape).

Detailed steps: [`reference.md`](reference.md) § plan protocol (detailed).

---

## start protocol

| Step | Action |
|------|--------|
| **ST0** | Implementation gate: `@flutter-plan-master status` implementation-ready, or a HANDOFF waiver |
| **ST1** | Mandatory reads: `{FLUTTER_NEXT}` block · the SPEC(s) the tasks trace to · `{FLUTTER_STANDARDS_ROOT}` CONVENTIONS + DIRECTORY_MAP + TESTING · `{FLUTTER_STACK_LOCK}` + its `stacks/` idiom file · `{FLUTTER_HANDOFF}` |
| **ST2** | Environment snapshot: `git status --short`, `git log --oneline -5`, `flutter --version` (record `unavailable` if absent) |
| **ST3** | Assumption ledger: label every working assumption `Confirmed` (cited), `Inference` (reasoned) or `Unverified` (guess). Unverified assumptions must be resolved or logged before they are coded against |
| **ST4** | Mark the first pending task `in-progress` |
| **ST5** | Start report: milestone, task, files, the gate commands that will run |

---

## Continue target

Resolve the batch **before** the loop. Default when `-` is omitted: `count=1`.

| Target | Batch mode | Queue |
|--------|------------|-------|
| *(omit)* | `count=1` | Next incomplete task in table order |
| `- 5` | `count=5` | Next up to 5 incomplete |
| `- until blocked` | `until-blocked` | Until a stop condition fires |
| `- F2-T3..T7` | `range` | Inclusive, in table order |

**Range rules:** both endpoints use full `F{N}-T{k}` (shorthand allowed only when the milestone is unambiguous). Tasks already `done` are skipped and do not count. A `blocked` task inside a range that stays blocked **stops** the batch — it is not skipped over.

---

## Continue protocol

1. Run ST0 (abbreviated when `start` ran this session).
2. Parse the target; emit the planned queue so the operator sees the intent.
3. **Unblock check** on `blocked` tasks against `UNKNOWNS.md` and Owner blockers.
4. Empty queue → recommend `complete` or `status`.
5. **Pre-write scope gate (mandatory).** Before any file write, confirm either `{FLUTTER_TOUCH_SCOPE}` has non-empty `allowed_paths`/`allowed_patterns`, or the active iteration has ≥1 task with a populated `Files` column. Neither → stop the batch and emit the scope-undeclared report below.
6. **Per-task loop:** read the SPEC section → implement → [Task gate](#task-gate) → progress line on pass; **stop the batch** on gate fail, blocker, schema detour, native detour, or protected file.
7. **Batch-end sweep** (mandatory when files changed): `@flutter-verify uncommitted` over the cumulative diff.
8. Emit the batch summary with the sweep verdict.
9. All tasks `done` → recommend `complete`. **Never auto-finalize.**

### Scope-undeclared blocked report

```markdown
## @flutter-implementation continue - blocked (scope undeclared)

**Required:** a scope declaration before any file write
**Detected:** no `.work.flutter/touch-scope` and no iteration task with a populated `Files` column
**Run first:** declare scope via either
- `.work.flutter/touch-scope`: `{"allowed_paths":["lib/src/features/cart/"],"allowed_patterns":["lib/src/features/cart/**"]}`
- or populate the `Files` column in `## Current iteration`
Then re-run `@flutter-implementation continue`.
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Task gate

Run after **every** task, before marking it `done`. Mechanical only — `@flutter-verify` produces audit reports; this is the pass/fail gate.

| # | Check | Command | Fail condition |
|---|-------|---------|----------------|
| G1 | Formatting | `dart format --set-exit-if-changed <changed files>` | Non-zero exit |
| G2 | Static analysis | `flutter analyze` (or `dart analyze` for pure packages) | Any error or warning; `info` per the project's severity policy |
| G3 | Tests | `flutter test <the task's test paths>` — full suite when the change is cross-cutting | Any failure |
| G4 | Codegen current | `dart run build_runner build --delete-conflicting-outputs` when annotated sources changed | Generated output differs from committed |
| G5 | Scope | `git diff --name-only` ⊆ declared scope | Any undeclared file |
| G6 | Secrets | No key, token, password or credential in the diff | Any match |
| G7 | Stack conformance | Idioms match `{FLUTTER_STACK_LOCK}` + the `stacks/` file | A second state approach, router or serialization strategy introduced |
| G8 | Hygiene | `bash scripts/dart-hygiene-check.sh <changed files>` | `print(`, hardcoded color literals in widgets, `ignore_for_file` without a reason, unreferenced `TODO`, `http://` URLs |
| G9 | **SC1 self-critique** | See below | Any answer reveals an unhandled case |

**SC1 self-critique** — answer all five in the task's Notes column, in one line each:

1. What did I assume that the SPEC does not state?
2. Which of the six UI states did I *not* implement, and is that correct?
3. What happens here with no network, and did I test it?
4. What did I copy from an adjacent file without checking that it applies?
5. What would the reviewer ask me to change first?

**Post-fix re-gate:** after **any** fix, re-run the full task gate. A fix that was not re-gated is not a fix.

**Scope violation:** revert the out-of-scope change, note it in the task's Notes, and continue. If the change was necessary, stop the batch and add it to the plan via `@flutter-plan-master revise`.

---

## Status protocol

Read-only. No writes. Report the milestone, the task matrix with statuses, `git diff --stat`, recent commits, blockers, and the recommended next command.

---

## Complete protocol

**Execution order: CO2 → CO1 → CO3 → CO4 → CO5 → CO6.** Milestone verify runs first so the full suite is not run twice.

| Step | Action |
|------|--------|
| **CO2** | `@flutter-verify milestone` (mandatory). Verdict `pass` or `pass with gaps` required; `fail` blocks completion |
| **CO1** | Full iteration gate: acceptance criteria checked one by one with evidence; Concept/NFR registry rows resolved; **FLS-06 run** if source or tests changed; manual validation steps performed |
| **CO3** | Documentation: SPEC status → `Implemented` where satisfied, amendments for discovered deltas, registry appends, ADRs for decisions made during implementation |
| **CO4** | `{FLUTTER_NEXT}`: move tasks to `## Done this iteration` with evidence, archive the block to `{FLUTTER_PLANS_ROOT}/archives/`, refresh `## Recommended next` |
| **CO5** | `{FLUTTER_HANDOFF}`: append artifacts produced, repository state, open blockers, and the next milestone |
| **CO6** | Close report: milestone, tasks, coverage delta, verify verdict, FLS outcomes, residual risks |

**Residual risks are mandatory in CO6.** A completion report with no residual risks is almost always an incomplete review.

---

## Blocked task protocol

1. Mark the task `blocked` in the iteration block.
2. Record the blocker in `### Owner blockers` **and** in `UNKNOWNS.md` (owner, `blocks: F{N}-T{k}`).
3. SPEC or plan ambiguity → add to UNKNOWNS, surface in the next status report, ask the operator **once**.
4. Move to the next non-blocked pending task.
5. All tasks blocked → do not hallucinate a resolution. Recommend `@flutter-session close` with the blockers listed.
6. Never invent an owner-decision resolution.

---

## Integration

| Skill | Integration |
|-------|-------------|
| `flutter-session` | `start` before implementation; `close` after `complete` — add `commit` and/or `push` to also commit/push the `.work.flutter/` state (e.g. `close commit push`) |
| `flutter-plan-master` | Milestone source; `revise` when the plan is wrong |
| `flutter-scaffold` | Generates module skeletons so tasks start from the right shape |
| `flutter-data` | **Mandatory** for models, repositories, sources and local-store migrations |
| `flutter-platform` | **Mandatory** for channels, permissions, deep links and native config |
| `flutter-test` | Authors the tests a task's gate then runs |
| `flutter-verify` | `uncommitted` at batch end (auto), `milestone` at CO2 |
| `flutter-repair` | Any gate failure that is not trivially fixable in the loop |
| `flutter-doctor` | Any failure that is toolchain rather than code |
| Concept pack | Rows in the iteration registry; **FLS-06 required** before `complete` when code changed |

---

## Anti-patterns

- Writing code before reading the SPEC section it implements.
- Reporting "tests pass" without running them and reading the output.
- Skipping the task gate because the change was small.
- Skipping SC1 because the task looked simple.
- Claiming a fix without re-gating.
- Skipping the batch-end sweep.
- Marking a task `done` with an empty Notes column — the gate evidence lives there, and `gate-verify.sh` fails on it.
- Introducing a second state-management approach because it fit this one screen.
- Inline schema or model changes instead of `@flutter-data`.
- Editing `android/` or `ios/` directly instead of `@flutter-platform`.
- Implementing only the success state.
- Hardcoding strings that the l10n standard requires in ARB files.
- Adding `// ignore:` to silence the analyzer instead of fixing the cause.
- Attribution comments ("Generated by…").
- Declaring implementation-ready — that belongs to `@flutter-plan-master status`.

---

## Completion checklist (all modes)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected correctly | pass/fail | |
| 2 | Iteration block valid against all six criteria | pass/fail | criteria |
| 3 | SPEC(s) read before implementation | pass/skip | paths |
| 4 | CONVENTIONS + DIRECTORY_MAP + STACK read | pass/skip | |
| 5 | Task gate G1–G9 passed per task | pass/fail | exit codes |
| 5b | SC1 self-critique recorded per task | pass/fail | Notes |
| 5c | Post-fix re-gate executed for every fix | pass/skip | task ids |
| 6 | No out-of-scope files modified | pass/fail | `git diff --name-only` |
| 7 | No secrets in the diff | pass/fail | |
| 8 | Data/native work delegated to the owning skill | pass/skip | |
| 8b | Batch-end sweep run (continue mode) | pass/fail/skip | verdict |
| 9 | `@flutter-verify milestone` run (complete mode) | pass/skip | verdict |
| 9b | FLS-06 run when source changed (complete mode) | pass/skip | output path |
| 10 | Acceptance criteria checked individually (complete mode) | pass/skip | |
| 11 | `{FLUTTER_NEXT}` + `{FLUTTER_HANDOFF}` updated | pass/skip | |
| 12 | Residual risks stated (complete mode) | pass/skip | |

---
name: flutter-concept-run
description: >-
  Run the FLS-01 to FLS-13 concept prompts - focused, reusable review lenses for
  widget-tree efficiency, state management, layer boundaries, async and error
  safety, navigation, AI-assisted change safety, platform parity, performance,
  offline data integrity, accessibility, security, test integrity, and UI craft.
  Selects the concepts a diff actually triggers, runs them against real
  evidence, and attaches the output to the iteration, SPEC or PR. Use for run
  FLS-06, architecture check, or which concepts apply to my change.
---

# flutter-concept-run

A concept is a **review lens**: one narrow question asked well, repeatedly, with the same rigour every time. Skills own workflow; concepts own judgement. Running the right three concepts on a diff catches what a general review misses because a general review has no checklist.

**Never gated.** A concept can be run against any code at any time.

**Pairs with:** `flutter-implementation` (iteration Concept/NFR registry), `flutter-verify` (D14 requires FLS-06), `flutter-foundation` (P2 requires FLS-03), `flutter-platform` (FLS-07 parity).

**Concept pack:** [`concepts/README.md`](../../concepts/README.md) · **Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Run against real evidence.** A concept run reads the actual code or diff. Running one from memory of the code is fabrication.
2. **Never report a finding without a file and line.** "State management could be cleaner" is not a finding.
3. **The concept's verdict is not negotiable by convenience.** If FLS-03 finds a transport type in `domain/`, that is a fail regardless of how small the fix looks.
4. **Never repair inside a concept run.** Concepts observe; `@flutter-repair` fixes. Mixing them destroys the audit trail.
5. **Select honestly.** Skipping FLS-11 because the diff "probably doesn't touch security" while it adds a network call is a selection failure, not a scope decision.
6. **FLS-06 is mandatory for agent-authored changes** before an iteration completes.
7. **Record the output path.** An unattached concept run did not happen as far as the audit trail is concerned.

---

## Modes

| Mode | Action |
|------|--------|
| `list` | Show the thirteen concepts, their triggers, and their output shapes |
| `select - <scope>` | Determine which concepts the scope triggers. `<scope>` = diff, task ID, milestone, path |
| `run - FLS-<nn>` | Run one concept |
| `run - <scope>` | `select` then run every triggered concept |
| `status` | Which concepts have been run against the current iteration, and their verdicts |

---

## The concept pack

| ID | Concept | Slug | Triggers when the change touches |
|----|---------|------|----------------------------------|
| **FLS-01** | Widget-tree efficiency | `widget-tree-efficiency` | Widget trees, lists, `build` methods, animations, images |
| **FLS-02** | State-management integrity | `state-management-integrity` | ViewModels, providers/blocs/notifiers, state classes, disposal |
| **FLS-03** | Layer boundaries | `layer-boundary-audit` | Imports across layers, new modules, repositories, domain types |
| **FLS-04** | Async and error safety | `async-error-safety` | `Future`/`Stream`, `try`/`catch`, error mapping, cancellation, `mounted` |
| **FLS-05** | Navigation integrity | `navigation-integrity` | Routes, guards, deep links, back behaviour, nested navigators |
| **FLS-06** | AI-assisted change safety | `ai-change-safety` | **Any agent-authored change to source or tests** |
| **FLS-07** | Platform parity | `platform-parity` | Platform channels, permissions, native config, platform-conditional code |
| **FLS-08** | Performance budget | `performance-budget` | Startup path, heavy computation, large lists, images, app size |
| **FLS-09** | Offline and data integrity | `offline-data-integrity` | Caching, local stores, migrations, sync, conflict resolution |
| **FLS-10** | Accessibility and inclusivity | `accessibility-inclusivity` | Any user-facing surface, text, colour, interaction, copy |
| **FLS-11** | Security and privacy | `security-privacy` | Auth, storage, network, permissions, logging, third-party SDKs |
| **FLS-12** | Test integrity | `test-integrity` | Any new or modified test, or a change to tested behaviour |
| **FLS-13** | UI craft | `ui-craft` | New or changed screens, widgets or presentation files; theme and token changes; visual polish |

Each concept lives at `concepts/<slug>/prompt.md` with its question set, evidence requirements, and verdict rules.

---

## select protocol

1. Establish the scope's actual content: `git diff --stat` for a diff, the task's file list for a task ID, the module tree for a path.
2. Match changed content against the trigger column — **by what the code does, not by folder name**. A file in `lib/features/profile/` that opens a socket triggers FLS-11.
3. Add the always-on concepts: FLS-06 for any agent-authored change; FLS-12 for any test change.
4. Report the selection **with the reason for every include and every exclude**:

```markdown
## @flutter-concept-run select - <scope>

| Concept | Triggered | Reason |
|---------|-----------|--------|
| FLS-03 | yes | new repository + 2 cross-layer imports |
| FLS-06 | yes | agent-authored |
| FLS-11 | yes | adds token persistence |
| FLS-01 | no | no widget-tree changes in diff |
| FLS-07 | no | no platform-conditional code, no channel, no manifest change |

**Run:** `@flutter-concept-run run - <scope>` (3 concepts)
```

An exclude with no reason is not an exclude — it is an oversight.

---

## run protocol

For each selected concept:

1. **Load** `concepts/<slug>/prompt.md`.
2. **Gather evidence** — the specific files, the diff hunks, and any command output the concept requires. Concepts that require a measurement (FLS-08 performance numbers, FLS-10 screen-reader traversal) must either run it via the owning skill or report the item as **unverified**. Never substitute a plausible number.
3. **Answer every question** in the prompt. "Not applicable" is an allowed answer with a reason; silence is not.
4. **Record findings** with severity:

| Severity | Meaning | Consequence |
|----------|---------|-------------|
| `blocker` | Violates a hard rule or a standard | Blocks the iteration; routes to `@flutter-repair` |
| `major` | Real defect or risk, not rule-violating | Fix now or record as an accepted risk with an owner |
| `minor` | Improvement worth making | Backlog or fix opportunistically |
| `note` | Observation, no action required | Recorded only |

5. **Verdict:** `pass` (no blockers, no majors) · `pass with findings` (majors present, each with a disposition) · `fail` (any blocker).

---

## FLS-06 — AI-assisted change safety

The one concept that exists because of how the code was written rather than what it does. Agent-authored code fails differently from human-authored code: it is locally plausible and globally wrong, it silently changes adjacent behaviour, and it asserts verification that never ran. FLS-06 targets exactly that.

Mandatory before `@flutter-implementation complete` whenever source or tests changed in an agent session. **The agent cannot self-classify out of it** — "AI-assisted: yes" is the default and only a human declaration in the same message changes it.

Minimum output:

```markdown
## FLS-06 — AI-assisted change safety · <task ID>

**Changed:** <n> files, +<n>/-<n> lines
**Blast radius:** <every call site, subclass, generated artifact and test touched by the change>
**Adjacent behaviour:** <what else uses these symbols, and whether its behaviour changed>
**Deleted or weakened:** <any removed check, assertion, test, or narrowed type — or "none">
**Assumptions made:** <each assumption, and what would break if it is wrong>
**Verified by running:** <exact commands and observed results>
**NOT verified:** <every claim that was not executed — device behaviour, other platforms, edge inputs>
**Reviewer should look hardest at:** <the one or two places most likely to be wrong>
```

The **NOT verified** section is the point of the concept. An FLS-06 output whose "NOT verified" section is empty is almost always wrong, and should be challenged before it is accepted.

---

## Report shape

```markdown
## @flutter-concept-run run - <scope>

**Concepts run:** FLS-03, FLS-06, FLS-11
**Verdict:** pass with findings

| Concept | Verdict | Blockers | Majors | Output |
|---------|---------|----------|--------|--------|
| FLS-03 | pass | 0 | 0 | inline |
| FLS-06 | pass with findings | 0 | 1 | `.work.flutter/concepts/F2-T3-fls06.md` |
| FLS-11 | fail | 1 | 0 | inline |

### Findings

| # | Concept | Severity | Location | Finding | Route |
|---|---------|----------|----------|---------|-------|
| 1 | FLS-11 | blocker | `lib/data/auth_store.dart:34` | Refresh token written to `SharedPreferences` | `@flutter-repair repair - from concept` |
| 2 | FLS-06 | major | `lib/domain/session.dart:12` | Nullability narrowed; 3 call sites unchecked | `@flutter-repair` |

**Unverified:** <items requiring a device or measurement>
**Attached to:** <iteration F2 registry / SPEC-004 / PR>
**Run next:** `@flutter-repair repair - from concept`
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

Attach the full output to `{FLUTTER_WORK_ROOT}/concepts/<task-id>-<slug>.md` when it is long, and record the path in the iteration's Concept/NFR registry. Short runs may be inline, but the registry row is still required.

---

## Anti-patterns

- Running a concept from memory instead of against the diff.
- Findings without file and line.
- Selecting concepts by folder name rather than by what the code does.
- Excluding a concept without a stated reason.
- An FLS-06 with an empty "NOT verified" section.
- Reporting a performance or accessibility result that was not measured.
- Repairing during the run.
- Softening a blocker to a major because the fix is inconvenient.
- Running the whole pack on every diff — thirteen shallow runs are worth less than three real ones.
- Leaving the output unattached to the iteration or SPEC.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Scope content established from actual files or diff | pass/fail | stat |
| 2 | Selection justified — includes **and** excludes | pass/fail | table |
| 3 | FLS-06 included for agent-authored source changes | pass/skip | |
| 4 | FLS-12 included for test changes | pass/skip | |
| 5 | Every prompt question answered or marked N/A with a reason | pass/fail | |
| 6 | Every finding has file and line | pass/fail | |
| 7 | Severities assigned per the rubric, unsoftened | pass/fail | |
| 8 | Measurements either run or reported as unverified | pass/fail | |
| 9 | No repairs performed during the run | pass/fail | git diff |
| 10 | Findings routed to the owning skill | pass/skip | routes |
| 11 | Output path recorded in the iteration registry | pass/fail | path |

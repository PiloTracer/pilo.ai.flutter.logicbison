# Greenfield adoption

A new Flutter application from an empty repository to a shipped release. Roughly what the first two weeks look like, and where the time actually goes.

---

## 0 — Install

```bash
bash /path/to/pilo.ai.flutter.logicbison/scripts/deploy-basic.sh --target ~/projects/myapp
cd ~/projects/myapp
```

Then, in the agent:

```
@flutter-bootstrap init
```

This scaffolds `.work.flutter/`, writes `.cursorrules` and `analysis_options.yaml`, creates `DOCS_FLUTTER_STACK.md`, and installs the git hooks. It is idempotent and never overwrites anything you already have.

**State:** `scaffold`.

---

## 1 — Lock the stack

```
@flutter-stack probe
```

Seven dimensions: state management, navigation, DI, serialisation, HTTP, local store, test doubles. The skill asks about team experience and project scale before recommending, because the best library for a team that has never used it is frequently not the best library.

It verifies every package on pub.dev before recommending it — maintenance status, licence, null safety, platform support. It does not recommend from memory, because memory of package versions is stale within weeks.

```
@flutter-stack set - state=riverpod
```

**State:** `stack-locked`. This is binding. Changing it later means an ADR and a migration plan, which is the point — stack churn mid-project is expensive and usually driven by novelty rather than need.

---

## 2 — The foundation

```
@flutter-foundation greenfield
```

Seven phases, P0 through P6: identity and intent · users, platforms, constraints · architecture · domain model · features, risks, release slicing.

**This is the part that feels slow.** No code is being written and the questions are uncomfortable. That feeling is the framework working correctly. The interrogation covers ten dimensions and then runs a challenge pass against your own answers: where is the evidence, what would a hostile reviewer attack, what breaks if this is wrong.

You will be asked things like:

- Who is the user who will be annoyed if this ships late, and what do they do today instead?
- What happens on a two-bar connection in a lift?
- Which of these features would you cut if the deadline moved in by three weeks?
- You said "must be fast" — fast measured how, on which device?

Answers land in the probe ledger. `readiness-verify.sh` fails a ledger claiming confirmation it did not earn, so "we discussed it" does not count.

P3 generates the project's binding standards into `.work.flutter/standards/` by filling the framework templates with your actual decisions.

```
@flutter-foundation certify
```

**State:** `plan-ready`.

**Time:** two to four hours of real conversation for a real product. This is the highest-leverage time in the project. Every hour here removes several later.

---

## 3 — The master plan

```
@flutter-plan-master greenfield
```

Turns the foundation into an ordered, traceable work sequence: 21 sections, milestones `F0…Fn`, tasks `F{n}-T{k}`, and a traceability matrix that must be complete in both directions — no requirement without a task, no task without a requirement.

F0 is skeleton only: structure, CI, theming, routing shell. F1 onwards are vertical slices, each demoable, riskiest first.

```
@flutter-plan-master integrity
```

Runs `master-plan-verify.sh` and `traceability-verify.sh`. Review the plan, then approve it.

**State:** `implementation-ready`.

---

## 4 — Scaffold

```
@flutter-scaffold app
```

Generates the project conforming to the locked stack and the directory map. Structure only, no behaviour. It must build and its tests must pass before the skill reports success.

---

## 5 — Build, milestone by milestone

```
@flutter-implementation plan - F1      write the iteration block
@flutter-implementation start          load context
@flutter-implementation continue       task by task
@flutter-implementation complete       close it out
```

Each task passes the nine-check gate before it may be marked done. Each milestone ends with `@flutter-verify milestone` — fifteen dimensions plus the applicable FLS lenses, including FLS-06 on everything an agent wrote.

Findings route to `@flutter-repair`, which fixes and then re-runs the originating verifier. A repair that has not been re-verified is a hypothesis.

For anything non-trivial, write the SPEC first:

```
@flutter-feature-spec create - user-profile
@flutter-feature-spec review → approve
```

Sixteen sections, and the ones that matter are §6 (all six UI states) and §9 (error handling). The happy path is never where features fail.

---

## 6 — Release

```
@flutter-release prepare      flavors, versioning, signing, obfuscation, size budget
@flutter-release certify      14 gates, real audits
@flutter-release build - appbundle
@flutter-release distribute
```

`prepare` is one-time setup; `certify` runs every release.

**The thing people get wrong:** obfuscation without archiving the symbol file. The build succeeds, the app ships, and every crash report for that release is unreadable. `certify` blocks on it.

---

## Between sessions

```
@flutter-session close     at the end
@flutter-session context   at the start
```

HANDOFF and NEXT are deliverables, not notes. They are what makes the next session — with you, a colleague, or a different model — start from state rather than from archaeology.

---

## What good looks like at each stage

| After | You have |
|-------|----------|
| Bootstrap | `.work.flutter/`, hooks installed, `.cursorrules` registered |
| Stack | Seven locked decisions with rationale and verified packages |
| Foundation | Five documents, a probe ledger, project standards, a certification |
| Plan | 21 sections, milestones, tasks, complete bidirectional traceability |
| Scaffold | A project that builds and whose tests pass |
| Each milestone | A working demo, a clean audit, an updated pointer |
| Release | A certified artifact with archived symbols and a rollback plan |

## Where greenfield projects go wrong

**Skipping the foundation** because the requirements "are obvious". They are obvious to you, today. They are not written down, so they will be interpreted differently by an agent tomorrow and by you in three weeks.

**Horizontal milestones.** "Build the data layer" cannot be demonstrated, so it cannot be validated, so it is wrong for a month before anyone notices.

**Deferring accessibility and security to the end.** Both are architectural. Retrofitting either costs more than doing it, and the retrofit is always partial.

**Treating the plan as immutable.** It is a plan, not a contract. Use `revise`. What is forbidden is *silent* divergence, which turns the plan into fiction.

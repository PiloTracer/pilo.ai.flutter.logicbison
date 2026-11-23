# Start here

Flutter Agent OS — a framework for planning, building, verifying and repairing Flutter applications with AI agents.

**If you read one thing:** you do not need to learn this framework to use it. Say what you want in plain language and let the director route it.

```
@flutter-director - <what you want, in your own words>
```

It reads the project state, picks the skill chain, shows you the plan, and waits for your confirmation before writing anything.

---

## Decision tree

**Where are you?**

| Situation | Run this |
|-----------|----------|
| Brand new repository, nothing exists yet | `@flutter-bootstrap init` |
| Framework installed, no `.work.flutter/` | `@flutter-bootstrap init` |
| Want a 30-minute lite path (playbook only) | `@flutter-bootstrap quickstart - lite` (requires `.work.flutter/plans/`) |
| Existing Flutter app, adopting the framework | `@flutter-bootstrap init` then `@flutter-plan-verify brownfield` (or `quickstart - brownfield`) |
| Bootstrapped, stack not chosen | `@flutter-stack probe` |
| Stack locked, no plan | `@flutter-foundation greenfield` |
| Foundation done, no master plan | `@flutter-plan-master greenfield` |
| Plan approved, ready to build | `@flutter-implementation plan - F1` |
| Mid-iteration, resuming | `@flutter-session context` |
| Something is failing | See below |
| No idea | `@flutter-session status` then `@flutter-director - <what you want>` |

**Something is failing — which kind?**

| Symptom | Skill |
|---------|-------|
| Build error, Gradle, CocoaPods, `pub get`, codegen | `@flutter-doctor diagnose` |
| Tests red, analyzer errors, a verifier found things | `@flutter-repair repair - from <source>` |
| The plan is wrong or incomplete | `@flutter-plan-repair repair` |
| You are not sure which | `@flutter-doctor diagnose` — it classifies first |

**Just have a question?** `@flutter-router - <question>`. Read-only, answers in three sentences, cites the source.

---

## The path, end to end

```
@flutter-bootstrap init          scaffold project memory
        ↓
@flutter-stack probe → set       lock the technology stack
        ↓
@flutter-foundation greenfield   P0–P6: intent, users, architecture, domain, risks
@flutter-foundation certify      → plan-ready
        ↓
@flutter-plan-master greenfield  milestones F1…Fn, tasks, traceability
        (status: Approved)       → implementation-ready
        ↓
@flutter-scaffold app            generate the skeleton
        ↓
@flutter-implementation plan - F1
                       start / continue / complete     ← repeat per milestone
        ↓
@flutter-verify milestone        15-dimension audit
@flutter-repair repair           fix what it found
        ↓
@flutter-release certify → build → distribute
```

Each arrow is a **gate**. A skill whose prerequisite is unmet stops and tells you exactly what is missing and which skill provides it. That is the design, not an obstacle: work built on an unfinished foundation fails later and more expensively.

---

## What you are agreeing to

This framework is opinionated in four ways. They are the reasons it works, and they will occasionally be inconvenient.

1. **It will interrogate you.** Planning skills ask uncomfortable questions and then challenge your answers. A question in week one costs minutes; the same gap found in week ten costs a milestone.
2. **It will not claim things it did not verify.** No result is reported that was not observed. Where a check could not run, you get `unverified`, never a comfortable pass.
3. **It will not weaken checks to make progress.** No deleted tests, no lowered thresholds, no suppressions to get to green.
4. **It stops at gates.** You can waive a gate explicitly, with a recorded reason. You cannot slide past one quietly.

---

## Read next

| You want to | Read |
|-------------|------|
| Know what exists and why | [`README.md`](README.md) |
| See the default chains per project type | [`APPROACH.md`](APPROACH.md) |
| Understand gates and readiness states | [`skills/SKILL_DEPENDENCIES.md`](skills/SKILL_DEPENDENCIES.md) |
| Know what "done" means mechanically | [`standards/20260801-QUALITY_GATES.md`](standards/20260801-QUALITY_GATES.md) |
| Coexist with `.ai` or `.ai.ui` | [`COHABITATION.md`](COHABITATION.md) |
| Add or change a skill | [`CONTRIBUTING.md`](CONTRIBUTING.md) |

**Not installed yet?** `bash scripts/deploy-basic.sh --target <your-repo>`, then `@flutter-bootstrap init`. Installing the framework and setting up a project are two steps, and both are required.

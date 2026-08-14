---
name: flutter-director
description: >-
  Top-level orchestration skill for Flutter work. Receives free-text requests
  ("build a login screen", "the app janks when scrolling", "is this ready to
  ship?"), classifies intent, determines the optimal chain of flutter-* skills,
  renders a Confirm gate, executes the chain respecting every dependency gate,
  and records the outcome in HANDOFF_FLUTTER.md. The user never needs to know
  which skill to call. Use for any Flutter request whose skill is unclear, for
  multi-step workflows, and as the default entry point.
---

# flutter-director

**Role:** the operator's single point of contact for all Flutter work. You receive natural language and map it to the correct sequence of `flutter-*` skills, standards, concepts and verifiers. You guarantee that every action respects the framework's gate rules, dependency graph and evidence discipline.

**Hard rules:**

1. **Never execute a skill whose declared prerequisites are unmet.** Check [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) before every invoke; emit the blocked report and run the prerequisite instead.
2. **Read before routing.** Load `{FLUTTER_HANDOFF}` and `{FLUTTER_NEXT}` before classifying. Missing files = bootstrap state; say so.
3. **Confirm before writing.** Render the routing plan and get an ack before the first skill invoke, unless `-y` was passed. `--dry-run` renders and stops.
4. **Record after acting.** Append a `## Latest action (@flutter-director)` block to `{FLUTTER_HANDOFF}` — including when the operator aborts at the Confirm gate.
5. **Do not invent skills or modes.** Only what is registered in [`skills/README.md`](../README.md). If nothing fits, follow § New skill protocol.
6. **Never write under this framework directory.** Project artifacts go to `{FLUTTER_WORK_ROOT}`; code goes to `{APP_ROOT}`.
7. **Never claim a result you did not observe.** If a chain step could not run (no device, no toolchain, no network), report it as `not run` with the reason. A fabricated `pass` is the single worst failure mode of this framework.
8. **Route non-Flutter work out.** Backend, database, infrastructure → `@ai-director`. Design tokens, visual craft, screen design → `@ui-director`. Spanning both → `@x-director`. Always run the framework preflight in `SKILL_DEPENDENCIES.md` § Frameworks registry first; if the sibling framework is absent, say `framework not installed here` and offer the closest Flutter-side action.

---

## Modes

| Mode | Action |
|------|--------|
| `- <free-text request>` | Parse intent → classify → Confirm gate → route → execute → record |
| `- <free-text request> -y` | Same, but skip the Confirm gate (operator opted into trust mode) |
| `- <free-text request> --dry-run` | Render the routing plan and stop. No skill invokes, no writes |
| `status` | Report Flutter Agent OS state: bootstrap, stack lock, readiness chain, active iteration, pending verifications |
| `review-routing` | Read-only: aggregate recent routing confidence and user corrections; surface buckets whose signal table needs tightening |
| `help` | Purpose, skill summary, invocation examples |

---

## Free-text intake contract

When invoked with natural language, follow this discipline so the request is always turned into the correct skill invocation and recorded in project memory.

### 1. Capture

Preserve the operator's exact wording and quote it in `{FLUTTER_HANDOFF}`. Never silently rewrite the goal into a different skill than the intent demands.

### 2. Load context

Read `{FLUTTER_HANDOFF}` and `{FLUTTER_NEXT}`. Also read `{FLUTTER_STACK_LOCK}` when the request touches code — the stack determines which idioms and test doubles are correct. Missing files → treat as bootstrap state and note it in the plan.

### 3. Classify (intent → bucket)

Match by **intent, not keyword**, using the bucket table in § Orchestration protocol § 1. Score **routing confidence** (`high` | `med` | `low`) from signal strength: exact signal match = high, partial = med, fallback bucket = low.

**Ambiguity handling:**

- Confidence `low` → ask **at most 3** clarifying questions before executing anything (§ Clarify gate). Do not execute on a guess.
- Request is a *process question* ("how do I…", "where does X live") → `@flutter-router`, not a work chain.
- Request is *underspecified work* ("make the app better") → `@flutter-foundation probe` or `@flutter-feature-spec intake`, not a code chain.
- Request spans frameworks → preflight, then `@x-director`.

### 4. Channel (bucket → skill chain)

Map the bucket to the exact chain from § 2 ROUTE. Check every gate in `SKILL_DEPENDENCIES.md` before each invoke. Use canonical syntax: `@<skill-id> <mode> - <argument>` with ASCII hyphen.

### 5. Confirm gate (before any skill invoke)

Render a routing plan and get explicit ack. Do **not** invoke a skill or write `{FLUTTER_HANDOFF}` before the ack.

```markdown
## flutter-director routing plan

**Request:** "<operator's verbatim request>"
**Classified bucket:** <bucket-name>
**Routing confidence:** high | med | low
**Readiness:** stack <locked|unlocked> · foundation <yes|no> · plan-ready <yes|no> · implementation-ready <yes|no>
**Gates checked:** <gate ids passed, or the one that blocks>

**Will execute:**
1. @<skill> <mode> - <arg> → <expected outcome, one line>
2. …

**Will write:** <exact paths created or modified, or "none (dry-run)">
**Will not do:** <the adjacent thing the operator might have expected, so scope is explicit>

Reply `y` / `yes` to proceed, `n` to abort, or edit the plan above.
```

**Trust mode (`-y`):** skip the gate. **Dry-run (`--dry-run`):** render, write nothing, stop. **Confidence `low` with no ack in the call:** do not execute — run the Clarify gate instead.

### 6. Clarify gate (confidence `low` only)

```markdown
## flutter-director - need 3 answers before routing

**Request:** "<verbatim>"
**Why I am asking:** <the specific ambiguity — two plausible buckets, or a missing target>

1. <bounded question> — options: <a> / <b> / <c>
2. …
3. …

Answer any subset; I will route on what you give me and flag the rest.
```

Questions must pass the quality bar in [`probe-protocol.md`](../probe-protocol.md) § Question quality bar. Never ask more than three here — deeper interrogation is `@flutter-foundation probe`'s job, and routing to it is a valid answer.

### 7. Record

After the workflow completes or changes state, append to `{FLUTTER_HANDOFF}`:

```markdown
## Latest action (@flutter-director)
**Date:** YYYY-MM-DD
**Request:** "<operator's original request>"
**Classified bucket:** <bucket-name>
**Routing confidence:** high | med | low
**Executed:**
1. @<skill> <mode> - <arg> → <result: pass | fail | blocked | not run (reason)>
2. …
**Evidence:** <exit codes, file paths, quoted output lines>
**User correction:** <none | "what rerouted the chain and why">
**Blockers:** <unresolved items | none>
**Next recommended:** @<skill> <mode> - <arg>
```

Also update `{FLUTTER_NEXT}` § **Recommended next** when the build cycle advanced.

**Feedback loop:** `Routing confidence` and `User correction` feed § review-routing. Even when a plan aborts at the Confirm gate, write a record with `Executed: aborted at confirm gate` plus the correction note — that is exactly the signal the bucket table needs.

---

## Orchestration protocol

### 1. PARSE & CLASSIFY

Classify into one bucket. Match by intent. Full signal lists and worked examples: [`reference.md`](reference.md) § Bucket registry.

| Bucket | Signals | Lead skill |
|--------|---------|------------|
| `bootstrap` | "start a Flutter project", "set up", "first time", `.work.flutter/` missing | `@flutter-bootstrap init` |
| `stack` | "which state management", "pick packages", "Riverpod or Bloc", "lock the stack" | `@flutter-stack set` (probe first if undecided) |
| `foundation` | "blueprint", "understand the product", "foundation docs", "what are we building" | `@flutter-foundation greenfield` |
| `foundation-probe` | vague scope, unclear users, no platform targets, "help me think it through" | `@flutter-foundation probe` |
| `foundation-certify` | "are we ready to plan?", "certify plan-ready" | `@flutter-foundation certify` |
| `master-plan` | "master plan", "implementation plan", "roadmap", "milestones", "estimate" | `@flutter-plan-master greenfield` / `continue` |
| `master-probe` | "is the plan complete?", "check plan gaps", "grill the plan" | `@flutter-plan-master probe` |
| `plan-verify` | "audit the plan", "check alignment", "does code match the plan" | `@flutter-plan-verify` (pick the mode) |
| `plan-repair` | "fix the plan gaps", "we have code but no plan" | `@flutter-plan-repair` |
| `feature-request` | "I want a feature that…", "add support for…", a new capability in prose | `@flutter-feature-spec intake` |
| `feature-spec` | "write a SPEC for X", "review the SPEC", "approve the SPEC" | `@flutter-feature-spec create` / `review` / `approve` |
| `scaffold` | "create the app", "new feature module", "add a package", "add a flavor", "set up CI" | `@flutter-scaffold` |
| `implementation` | "build it", "implement F2", "continue coding", "next 5 tasks" | `@flutter-implementation` |
| `data` | "model", "JSON", "repository", "cache", "local database", "schema change" | `@flutter-data` |
| `platform` | "method channel", "permissions", "deep link", "push", "native config", "plugin" | `@flutter-platform` |
| `test` | "write tests", "golden test", "coverage", "run the tests" | `@flutter-test` |
| `verify` | "check the code", "verify the milestone", "pre-commit check", "review my changes" | `@flutter-verify` |
| `perf` | "slow", "jank", "dropped frames", "app size", "startup time", "memory" | `@flutter-perf` |
| `a11y` | "accessibility", "screen reader", "contrast", "tap target", "semantics" | `@flutter-a11y audit` |
| `security` | "secrets", "secure storage", "pinning", "obfuscation", "vulnerable dependency", "privacy" | `@flutter-security audit` |
| `repair` | "fix the findings", "tests are failing", "remediate", "the audit found…" | `@flutter-repair repair - from <source>` |
| `doctor` | build error, Gradle/CocoaPods failure, "pub get fails", "flutter doctor", codegen error, "it won't run" | `@flutter-doctor diagnose` |
| `release` | "ship it", "build the app bundle", "signing", "store", "release checklist" | `@flutter-release` |
| `session` | "start session", "close session", "commit", "push", "where was I?" | `@flutter-session` |
| `concept` | "run FLS-06", "architecture check", "concept prompt" | `@flutter-concept-run` |
| `docs` | "document", "write a guide", "tutorial", "reference doc" | `@flutter-docs` |
| `deploy` | "install this framework into my repo", "copy the framework" | thin → `@flutter-deploy-basic`; fat → `@flutter-deploy-files`; pinned → `@flutter-deploy-repo` |
| `router` | "how do I…?", "where is…?", "which skill…?" | `@flutter-router - <question>` |
| `not-flutter` | Backend, API, DB, infra → `.ai`. Design tokens, visual craft → `.ai.ui` | Preflight, then `@ai-director` / `@ui-director` |
| `cross-framework` | Spans Flutter + backend and/or design ("app plus the API behind it") | Preflight, then `@x-director` |
| `new-skill-needed` | No registered skill can fulfil it | § New skill protocol |
| `unsure` | Cannot classify, or the request is underspecified | Clarify gate, then `@flutter-foundation probe` or `@flutter-router` |

### 2. ROUTE

Map the bucket to a chain. Respect the dependency graph; when a prerequisite is unmet, report the gate and run the prerequisite first.

**Typical full flow (greenfield):**

```text
@flutter-bootstrap init
  → @flutter-stack set
    → @flutter-foundation greenfield
      → @flutter-foundation probe   (until coverage ≥85% and challenge = defensible)
        → @flutter-foundation certify
          → @flutter-plan-master greenfield
            → @flutter-plan-master probe → integrity → status  (implementation-ready)
              → @flutter-scaffold app
                → @flutter-session open
                  → @flutter-implementation plan - F1
                    → @flutter-implementation start / continue  (loop)
                      → @flutter-verify milestone
                        → @flutter-implementation complete
                          → @flutter-session close
                            → … next milestone …
                              → @flutter-release certify → build
```

**Shortcut chains** for the most common requests: [`reference.md`](reference.md) § Shortcut chains.

### 3. CONFIRM

Render the routing plan per § Free-text intake contract step 5 and obtain the ack, unless `-y`. `--dry-run` renders and stops. Confidence `low` without ack → Clarify gate.

### 4. EXECUTE

For each skill in the chain:

1. Read that skill's `skill.md` to confirm the correct mode syntax.
2. Check its gate row in `SKILL_DEPENDENCIES.md`. Unmet → emit the blocked report, run the prerequisite, then resume.
3. Invoke with canonical syntax.
4. Verify the skill's completion checklist before advancing. A skill that reported `fail` does **not** advance the chain — route to the corrective skill (`probe`, `plan`, `repair`).
5. If the operator redirects mid-flow, stop, record it under `User correction`, and re-render the plan. Never silently switch chains.
6. If a step cannot run (no device, no toolchain, offline), mark it `not run (<reason>)` and continue only when the remaining steps are still meaningful. Otherwise stop and report.

### 5. RECORD

Write the HANDOFF block from § Free-text intake contract step 7 and refresh `{FLUTTER_NEXT}` § Recommended next.

---

## status mode

Read-only snapshot. No writes.

```markdown
## flutter-director status

| Layer | State | Evidence |
|-------|-------|----------|
| Bootstrap | present / missing | `.work.flutter/` |
| Stack | locked (<state mgmt> / <nav> / <di>) / unlocked | `.work.flutter/STACK.md` |
| Foundation | complete / partial (P<N>) / none | docs 01–05 present |
| plan-ready | yes / no (<date>) | HANDOFF certify line |
| implementation-ready | yes / no | Approved `*-full-plan.md` |
| Active iteration | F<N> — <n> done / <n> total | `NEXT_FLUTTER.md` |
| Last verification | <verdict> <date> | verify report |
| release-ready | yes / no | HANDOFF certify line |
| Open blockers | <n> | `UNKNOWNS.md` |
| Toolchain | flutter <version> / unavailable | `flutter --version` |

**Recommended next:** `@<skill> <mode> - <arg>`
```

---

## review-routing mode (feedback loop)

**Read-only.** Aggregates signal from recent `{FLUTTER_HANDOFF}` entries to find buckets whose signal table needs tightening. Use after sessions where the operator redirected the chain, or where `Routing confidence: low` recurs.

1. Read `{FLUTTER_HANDOFF}`; collect the last N (default 20) `## Latest action (@flutter-director)` blocks.
2. Extract `Classified bucket`, `Routing confidence`, `User correction`, and whether `Executed` begins with `aborted at confirm gate`.
3. Group by bucket; count low-confidence entries, non-empty corrections, and aborts.
4. Output:

```markdown
## flutter-director review-routing

| Bucket | Entries | Low-conf | Corrections | Aborts | Verdict |
|--------|---------|----------|-------------|--------|---------|
| <bucket> | N | n | n | n | tighten / ok / split |
```

**Verdict rules:** `tighten` when corrections ≥ 2 or low-conf ≥ 3. `split` when corrections diverge (the same bucket gets redirected to two different skills). `ok` otherwise.

5. For each `tighten` / `split` row, quote 1–2 `User correction` lines as evidence and name the exact signal strings to revise. **Do not edit the bucket table from this mode** — surface the change request; the operator decides.
6. No file writes. No skill execution.

---

## New skill protocol

If a request genuinely cannot be fulfilled by any registered skill and does not belong to a sibling framework:

1. **Confirm the gap.** Re-check `skills/README.md` and `standards/` — most "missing skills" are an existing skill plus a standard.
2. **Report.** State what is needed, why existing skills cannot cover it, and propose a name per the naming protocol.
3. **Create** the folder and `skill.md` following the established pattern: YAML frontmatter (`name`, `description`), role + hard rules, Modes table, Prerequisite gate, protocol sections, Anti-patterns, Completion checklist.
4. **Register** in `skills/README.md`, `SKILL_DEPENDENCIES.md` (matrix + vocabulary), `.cursorrules` § Skills, `flutter-director/reference.md` § Bucket registry, and `flutter-router/reference.md`.
5. **Verify** with `bash scripts/framework-verify.sh` — registration is machine-checked.

**Do not create a new skill when** the request maps to an existing skill or standard, belongs to another framework, or is answerable by a probe loop, a concept prompt or a router query.

---

## Anti-patterns

- Executing a chain before the Confirm gate is acknowledged.
- Classifying by keyword when the intent clearly differs ("test the waters" is not `test`).
- Routing a toolchain failure to `@flutter-repair` — build and dependency breakage is `@flutter-doctor`.
- Routing a plan gap to `@flutter-repair` — plan defects are `@flutter-plan-repair`.
- Skipping `@flutter-stack set` and letting each skill guess the state-management idiom.
- Reporting a chain as complete when a middle step was `blocked` or `not run`.
- Asking more than three clarifying questions instead of routing to `@flutter-foundation probe`.
- Redirecting to a sibling framework without running the preflight (routing into the void).
- Rewriting the operator's request into something easier to satisfy.
- Omitting the HANDOFF record because "nothing really happened" — an abort is signal.

---

## Prerequisites

- Framework present with a readable `skills/README.md` registry.
- `{FLUTTER_HANDOFF}` readable (may be bootstrap/empty).
- `{FLUTTER_NEXT}` readable (may be bootstrap/empty).

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Request captured verbatim | pass/fail | quoted in HANDOFF |
| 2 | `{FLUTTER_HANDOFF}` + `{FLUTTER_NEXT}` read before classifying | pass/fail | |
| 3 | Bucket classified; routing confidence scored | pass/fail | bucket name |
| 4 | Non-Flutter requests preflighted and channelled | pass/skip | framework path |
| 5 | Confirm gate rendered and acked (or `-y` / `--dry-run` honoured) | pass/skip | |
| 6 | Every gate in the chain checked against SKILL_DEPENDENCIES | pass/fail | gate ids |
| 7 | Skills invoked with canonical syntax | pass/fail | |
| 8 | Failures/blockers routed, not skipped | pass/skip | |
| 9 | Steps that could not run marked `not run` with a reason | pass/skip | |
| 10 | `{FLUTTER_HANDOFF}` updated incl. confidence + correction | pass/fail | |
| 11 | `{FLUTTER_NEXT}` § Recommended next refreshed if the cycle advanced | pass/skip | |
| 12 | New skill registered in all five places (if created) | pass/skip | |

---

## See also

- [`reference.md`](reference.md) — bucket registry, shortcut chains, worked routing examples
- [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) — gate matrix and readiness states
- [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — every response closes with Form A or Form B
- [`probe-protocol.md`](../probe-protocol.md) — question quality bar and the challenge pass
- [`skills/README.md`](../README.md) — skill registry
- [`START_HERE.md`](../../START_HERE.md) — operator decision tree
- [`COHABITATION.md`](../../COHABITATION.md) — boundaries with `.ai` and `.ai.ui`

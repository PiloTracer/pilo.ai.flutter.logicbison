# Approach — archetypes and default chains

The full path in [`START_HERE.md`](START_HERE.md) is the greenfield case. Most real work is one of the archetypes below. Each names the chain, what it produces, and where it usually goes wrong.

`@flutter-director` selects these automatically from a free-text request. Read this when you want to know *why* it picked what it picked, or to run a chain yourself.

---

## A1 — Greenfield application

**You have:** an idea and an empty repository.

```
@flutter-bootstrap init
@flutter-stack probe → @flutter-stack set
@flutter-foundation greenfield → certify
@flutter-plan-master greenfield → (approve)
@flutter-scaffold app
@flutter-implementation plan - F1 → start → continue → complete
@flutter-verify milestone → @flutter-repair (as needed)
   ↑ repeat per milestone
@flutter-release prepare → certify → build
```

**Usually goes wrong at:** the foundation, because it feels slow while the code is not being written. The probe is the cheapest part of the project. Skipping it moves the same questions to milestone three, where answering them means rework.

---

## A2 — Brownfield adoption

**You have:** a working Flutter app and no framework artifacts.

```
@flutter-bootstrap init                    (detects brownfield; never clobbers)
@flutter-stack detect                      infer the stack from the code, then confirm
@flutter-plan-verify brownfield            score what exists against what should
@flutter-plan-repair brownfield            synthesise foundation docs FROM THE CODE
@flutter-plan-master greenfield            plan forward from where you actually are
```

**The rule that matters:** foundation documents are **recovered**, not authored. The product decisions already exist — they are in the code, and inventing prettier ones creates a plan that describes a different application. Recovered content carries honesty markers separating what was observed from what was inferred.

**Usually goes wrong at:** treating the synthesis as a rewrite opportunity. It is archaeology, not design.

---

## A3 — One feature in an established project

**You have:** implementation-ready state and a new requirement.

```
@flutter-feature-spec intake - <the request>     classify it
@flutter-feature-spec create - <slug>            probe, then write SPEC §1–16
@flutter-feature-spec review → approve
@flutter-implementation plan - F<n>              add tasks to a milestone
   → start → continue → complete
@flutter-verify milestone
```

**Usually goes wrong at:** §6 (the six states) and §9 (error handling). The happy path is easy and is never the problem.

---

## A4 — Bug fix

```
@flutter-doctor diagnose            classify FIRST: toolchain or code?
   toolchain → @flutter-doctor <mode>
   code      → @flutter-repair repair - from <source>
@flutter-test unit|widget           a regression test that FAILS before the fix
@flutter-verify uncommitted
```

**Usually goes wrong at:** the classification. Hours disappear into editing application code to work around an environment problem. `diagnose` exists to spend two minutes preventing that.

**Non-negotiable:** a fix without a test that fails before it is not a fix.

---

## A5 — Verification sweep

**You have:** code that works and no idea whether it is safe to ship.

```
@flutter-verify milestone            the 16 dimensions
@flutter-security audit
@flutter-a11y audit
@flutter-perf audit → profile        static findings are hypotheses; measure them
@flutter-concept-run run - <scope>
@flutter-repair repair - from <each>
```

**Usually goes wrong at:** accepting static findings as measured facts. A jank hypothesis is not a jank measurement.

---

## A6 — Performance work

```
@flutter-perf budget                 numbers first, or "faster" is unfalsifiable
@flutter-perf audit                  hypotheses
@flutter-perf profile                measure on the reference device, profile mode
   → fix one thing
@flutter-perf profile                measure again, same conditions
```

**Usually goes wrong at:** optimising before measuring, and reporting an improvement with no before/after. Both produce confident changes with unknown effects.

---

## A7 — Release

```
@flutter-release prepare             flavors, signing, obfuscation, size budget, CI
@flutter-release certify             14 gates, real audits
@flutter-release build - <target>
@flutter-release distribute
```

**Usually goes wrong at:** symbols. An obfuscated build whose symbol file was not archived and uploaded produces unreadable crash reports for the entire release.

---

## A8 — Toolchain breakage

```
@flutter-doctor diagnose             capture the reproduction, classify
@flutter-doctor <env|deps|build|codegen>
```

**Never start with `flutter clean`.** It destroys the evidence that identifies the cause and usually does not help.

---

## A9 — Resuming after a break

```
@flutter-session status              where the project is
@flutter-session context             load what the current task needs
   → continue the chain the pointer names
```

---

## Choosing a scale

The framework does not require the same ceremony from a prototype and a banking app. What changes is the depth of the foundation and the strictness of the gates — never the evidence rules.

| Scale | Foundation | Plan | Verification |
|-------|-----------|------|--------------|
| Prototype | P0–P2 only, explicit waiver recorded | Milestones, light tasks | Gate + tests |
| Product | Full P0–P6 | Full 21 sections | Milestone audit + a11y + security |
| Regulated / enterprise | Full, plus compliance in doc 02 | Full, plus per-milestone audit | Everything, plus recorded waivers and ADRs |

**What never scales down:** no unobserved results, no weakened checks, no secrets, no untested migrations, no unverified accessibility claims. A prototype that ships is a product, and it inherits whatever you skipped.

---

## When no archetype fits

`@flutter-director - <your request>`. It classifies, chains, and if nothing fits it says so and proposes a new skill rather than forcing your request into the nearest existing shape.

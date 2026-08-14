---
name: flutter-foundation
description: >-
  Build the foundation plan for a Flutter application - the product intent,
  platform targets, architecture decisions, project standards, domain model,
  feature inventory, NFRs and risk registries - through seven gated phases
  P0-P6, with an adaptive probe loop that interrogates the operator until the
  agent can defend its readiness claim. Certifies plan-ready, which unlocks
  flutter-plan-master. Use for greenfield planning, for resuming foundation
  work, or when the scope is vague and needs grilling.
---

# flutter-foundation

The foundation answers **what we are building, for whom, on what, under which constraints, and to what quality bar** — before a single milestone is planned. Everything downstream (master plan, SPECs, iterations, verification) traces back to these documents.

**Role charter (anti-drift):** this skill produces *understanding artifacts*. It does not write application code, does not schedule milestones (that is `@flutter-plan-master`), and does not declare implementation-ready. It certifies exactly one state: **plan-ready**.

**Pairs with:** `flutter-stack` (P2 requires the lock), `flutter-feature-spec` (P4 may spawn SPECs), `flutter-plan-master` (consumes the output), `flutter-plan-verify` (audits it), `flutter-concept-run` (FLS prompts at P2/P5).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Extended tables:** [`reference.md`](reference.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B · [Document clarity](../SKILL_DEPENDENCIES.md#document-clarity-contract) — Status + Needs header, separate Decisions/Open questions lists, exactly one `## Next action`, no leftover scaffolding.

**Hard rules:**

1. **Order is binding: name → intent → product probe → *then* platforms and technology.** Choosing a stack before understanding the product is the most common and most expensive failure in Flutter projects. P2 is gated on P0–P1 for this reason.
2. **Never invent a product fact.** Unanswered questions go to `{FLUTTER_PLANS_ROOT}/UNKNOWNS.md` with an owner and what they block. An invented user persona corrupts every artifact downstream.
3. **Evidence or `partial`.** A ledger row is `confirmed/high` only with a cited source or a same-session operator answer. Agent inference caps at `partial/med`.
4. **Every phase ends in a gate.** A phase is complete when its exit criteria are demonstrably met, not when a document exists.
5. **Certify only on a defensible challenge pass.** `not defensible` → blocked report, never a certificate.
6. **Brownfield recovers, greenfield authors.** When `lib/` already holds source, the foundation must be *reconstructed from the code* (`@flutter-plan-verify brownfield` first). Authoring a fictional foundation over a real codebase is a defect.
7. **Standards are generated into `{FLUTTER_STANDARDS_ROOT}`, never edited in the framework.** Framework `standards/` are templates; the project owns dated copies.

---

## Modes

| Mode | Action |
|------|--------|
| `greenfield` | Run P0 → P6 from nothing, pausing at each gate |
| `continue` | Resume at the first incomplete phase |
| `probe` | One adaptive interrogation pass (≤5 questions) against the D1–D10 coverage map |
| `probe - until ready` | Loop passes until coverage ≥85%, no ★ unknown, and the challenge is defensible |
| `probe - status` | Read-only ledger report |
| `status` | Read-only: phase table, gate results, coverage, blocking gaps |
| `certify` | Formal sign-off → **plan-ready** |

---

## Prerequisite gates

### GF0 — scaffold present (`greenfield`, `continue`, `probe`)

```markdown
## @flutter-foundation <mode> - blocked (prerequisite)

**Required:** `.cursorrules` + `.work.flutter/context/HANDOFF_FLUTTER.md`
**Detected:** <what is present>
**Run first:** `@flutter-bootstrap init`
```

### SL0 — stack locked (P2 onwards)

```markdown
## @flutter-foundation continue - blocked (prerequisite)

**Required:** `.work.flutter/STACK.md` with Status: Locked (P2 depends on it)
**Detected:** STACK.md missing or Status: Draft
**Run first:** `@flutter-stack probe` then `@flutter-stack set`
```

### CF0 — foundation complete (`certify`)

```markdown
## @flutter-foundation certify - blocked (prerequisite)

**Required:** foundation-complete: yes (P0–P6 all pass)
**Detected:** P<N> <phase name> incomplete — <the specific missing exit criterion>
**Run first:** `@flutter-foundation continue`
```

---

## Phase map

Each phase has an owner document, exit criteria, and a gate. Full per-phase question banks and document outlines: [`reference.md`](reference.md) § Phase detail.

| Phase | Produces | Exit criterion (gate) |
|-------|----------|-----------------------|
| **P0** Identity & intent | doc 01 §1–3 | Project name, one-sentence intent a stranger can repeat, and the primary job-to-be-done are recorded and operator-confirmed |
| **P1** Users, platforms & constraints | doc 02 | Target platforms named with min OS versions; primary personas; connectivity model; regulatory/compliance constraints; localisation scope |
| **P2** Architecture & stack alignment | doc 03 §1–4 + ADRs | Layering, state flow, error strategy, DI approach recorded and **consistent with `STACK.md`**; FLS-03 concept run |
| **P3** Project standards | `{FLUTTER_STANDARDS_ROOT}/*.md` | Dated project copies of CONVENTIONS, DIRECTORY_MAP, FEATURE_SPEC_STANDARD, TESTING, QUALITY_GATES generated with all `REPLACE:` tokens filled |
| **P4** Domain & feature inventory | doc 04 + doc 05 §1 | Core entities with invariants and sources of truth; a feature inventory with priority (P0/P1/P2) and a one-line acceptance statement each |
| **P5** NFRs, risks, assumptions | doc 03 §5–8 + three registries | Every NFR has a **number and a unit**; every risk has an owner and a mitigation; assumptions and unknowns are separated and owned |
| **P6** Release slices & readiness | doc 05 §2–3 | Features grouped into milestone candidates `F0…F{n}` with dependencies; the F0 skeleton scope is explicit; challenge pass = defensible |

**Foundation documents** (in `{FLUTTER_PLANS_ROOT}/foundation/`):

| # | File | Owns |
|---|------|------|
| 01 | `YYYYMMDD-01-product-and-scope.md` | Intent, users, jobs-to-be-done, non-goals, success metrics |
| 02 | `YYYYMMDD-02-platforms-and-constraints.md` | Platforms, min OS, device classes, connectivity, i18n, compliance, accessibility baseline |
| 03 | `YYYYMMDD-03-architecture-and-nfrs.md` | Layers, state flow, error strategy, DI, NFRs with numbers, observability, security posture |
| 04 | `YYYYMMDD-04-domain-and-data.md` | Entities, invariants, sources of truth, offline/sync model, data lifecycle |
| 05 | `YYYYMMDD-05-feature-map-and-slices.md` | Feature inventory with priority, milestone candidates, dependency order |
| — | `PROBE_LEDGER.md` | Resumable probe state (per `probe-protocol.md`) |

---

## greenfield protocol

Run phases in order. **Stop at each gate** and report before proceeding; do not run P0→P6 in one silent burst.

1. **P0** — Ask for the name and a one-sentence intent. Then run a **product probe** (D1–D2) before anything technical. Write doc 01 §1–3. Gate.
2. **P1** — Probe D3–D5. Platform targets are ★: "mobile" is not an answer; "iOS 15+ and Android 8+ (API 26), phones only, tablet later" is. Write doc 02. Gate.
3. **P2** — Confirm `STACK.md` is locked. Derive the layering from [`ARCHITECTURE_STANDARD`](../../standards/20260801-ARCHITECTURE_STANDARD.md) and the locked stack's idiom file in [`stacks/`](../../stacks/). Run `@flutter-concept-run run - FLS-03`. Write doc 03 §1–4 and one ADR per non-obvious decision. Gate.
4. **P3** — Generate project standards into `{FLUTTER_STANDARDS_ROOT}` from the framework templates, filling every `REPLACE:` token from docs 01–03 and `STACK.md`. Gate: zero unreplaced tokens.
5. **P4** — Probe D6–D7. Write doc 04 (entities, invariants, sources of truth, offline model) and doc 05 §1 (feature inventory). Optionally spawn `@flutter-feature-spec create` for P0 features. Gate.
6. **P5** — Probe D8–D9. Write doc 03 §5–8 and populate `ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md`. Gate: **no NFR without a number and a unit**.
7. **P6** — Probe D10. Write doc 05 §2–3: group features into `F0…F{n}` candidates with dependency order, and state the F0 skeleton scope explicitly. Run the challenge pass. Gate.

Then recommend `@flutter-foundation certify`.

---

## continue protocol

1. Read `{FLUTTER_HANDOFF}`, the ledger, and every existing foundation doc.
2. Determine the first phase whose exit criterion is unmet — **by checking the criterion, not by trusting a checkbox**.
3. Report where you are resuming and why that phase is the first incomplete one.
4. Execute that phase, gate, then stop and report. Continue further phases only when the operator says so or the mode was invoked as part of `greenfield`.

---

## probe protocol

Engine: [`probe-protocol.md`](../probe-protocol.md). Ledger: `{FLUTTER_PROBE_LEDGER}`.

**Coverage map** (★ = gate-blocking, weight 2)

| Dim | Topic | ★ | Confirmed means |
|-----|-------|---|-----------------|
| D1 | Product intent | ★ | One sentence a stranger can repeat back correctly; the job-to-be-done is named |
| D2 | Users & context of use | ★ | Named personas, where and when they use the app, what "success" looks like for them |
| D3 | Platform targets | ★ | Each platform with a minimum OS version and device class; explicit non-targets |
| D4 | Connectivity & offline | ★ | Online-only, read-cache, or full offline read-write sync — stated, with the conflict policy if sync |
| D5 | Constraints | | Compliance (GDPR, HIPAA, PCI…), locales, accessibility bar, org dependency policy, deadlines |
| D6 | Domain model | ★ | Core entities, their invariants, and the source of truth for each |
| D7 | Feature inventory | ★ | Features listed with priority and a one-line acceptance statement each |
| D8 | Quality bar (NFRs) | ★ | Numbers with units: cold start, frame budget, app size, coverage floor, crash-free rate |
| D9 | Risks & unknowns | | Each risk has an owner, an impact, and a mitigation or a trigger to revisit |
| D10 | Release slicing | ★ | What ships first and why; what F0 contains; dependency order between slices |

**The interrogation.** This is where the framework earns its keep. Ask the questions the operator has not thought about yet — the ones that are cheap now and catastrophic in month four. Ranked question banks per dimension: [`reference.md`](reference.md) § Probe question bank. The highest-yield ten:

1. If you could ship only one screen, which one, and what must it do?
2. Who is *not* a user of this app? (Non-goals prevent more waste than goals create value.)
3. What happens when the user opens the app on a train with no signal?
4. What is the oldest phone this must feel good on, and have you tested on one?
5. Where does each piece of data actually live — server, device, or both — and who wins on conflict?
6. What must never leave the device?
7. What does the app do when the token expires mid-action?
8. Which of these features would you cut to ship two months earlier?
9. What number would make you say "this is too slow"? Give me a figure in milliseconds.
10. Who signs off that this is done, and what will they look at?

**Challenge pass** before `certify`. Per `probe-protocol.md`, plus these Flutter-specific C4 probes: low-end Android cold start, iOS background suspension and state restoration, no-network launch, screen-reader traversal, a locale with 40%-longer strings, RTL layout, small-screen overflow, and 200% text scale.

---

## certify protocol

1. **CF0 gate** — every phase exit criterion re-checked *now*, not trusted from the log.
2. Run `@flutter-plan-master integrity - foundation` for the automated completeness sweep.
3. Run `bash scripts/readiness-verify.sh {FLUTTER_PROBE_LEDGER} --gate` — ledger honesty is machine-checked (uncited `confirmed/high` rows fail), and `--gate` additionally fails when any ★ dimension is unconfirmed. Without `--gate` the script reports honesty only, and an honest-but-incomplete ledger exits 0.
4. Run the **challenge pass**. `not defensible` → blocked report, stop.
5. On pass, append to `{FLUTTER_HANDOFF}`:

```markdown
**Plan-ready:** YYYY-MM-DD (certified by @flutter-foundation)
**Foundation docs:** <five paths>
**Coverage:** <NN>% · **Challenge:** defensible | defensible with gaps
**Carried gaps:** <UNKNOWNS ids that plan-master must resolve, or none>
```

6. Update `{FLUTTER_NEXT}` § Recommended next → `@flutter-plan-master greenfield`.

**Certificate report**

```markdown
## @flutter-foundation certify - plan-ready

| Phase | Gate | Evidence |
|-------|------|----------|
| P0 … P6 | pass | <doc §> |

**Coverage:** <NN>% (target 85%) · **★ dimensions below partial:** none
**readiness-verify.sh:** PASS (exit 0)
**integrity sweep:** <verdict>
**Challenge:** defensible — weakest claim: <named>, accepted because <reason>
**Carried gaps:** <n> in UNKNOWNS.md, owners assigned

**Run next:** `@flutter-plan-master greenfield`
```

---

## status protocol

Read-only. No writes.

```markdown
## @flutter-foundation status

| Phase | State | Blocking |
|-------|-------|----------|
| P0 Identity & intent | pass | — |
| P1 Platforms & constraints | partial | D3 min Android API unset |
| … | | |

**foundation-complete:** yes / no
**Coverage:** <NN>% · **★ below partial:** <dims>
**Docs present:** 01 ✓ 02 ✓ 03 ✗ 04 ✗ 05 ✗
**Open UNKNOWNS blocking foundation:** <n>
**Run next:** `@flutter-foundation continue` (resumes at P<N>)
```

---

## Anti-patterns

- Choosing a state-management library in P0 because it "obviously" fits.
- Writing "the app should be fast and reliable" as an NFR. Numbers and units, or it is not an NFR.
- Recording "mobile" as the platform target.
- Inventing personas because the operator was slow to answer.
- Marking a ledger row `confirmed/high` from your own inference.
- Running P0→P6 in one burst with no gate reports, so the operator cannot intervene.
- Authoring a greenfield foundation over an existing codebase instead of recovering it.
- Certifying with a ★ dimension unknown because the percentage looked good.
- Scheduling milestones here — that is `@flutter-plan-master`.
- Declaring implementation-ready — that is `@flutter-plan-master status`.
- Editing the framework's `standards/` instead of generating project copies into `{FLUTTER_STANDARDS_ROOT}`.

---

## Completion checklist (all modes)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected; correct gate evaluated | pass/fail | |
| 2 | GF0 / SL0 / CF0 gate honoured | pass/fail | gate id |
| 3 | Phases executed in order with a gate report each | pass/fail | phase list |
| 4 | Every ★ dimension at `partial` or better | pass/fail | ledger |
| 5 | Ledger rows cite evidence | pass/fail | `readiness-verify.sh` exit |
| 6 | Unanswered questions → UNKNOWNS.md with owner + blocks | pass/skip | count |
| 7 | NFRs carry numbers and units | pass/fail | doc 03 §5 |
| 8 | Project standards generated, zero unreplaced tokens | pass/fail | `{FLUTTER_STANDARDS_ROOT}` |
| 9 | ADRs written for non-obvious decisions | pass/skip | paths |
| 10 | Challenge pass run; verdict recorded | pass/fail | verdict |
| 11 | HANDOFF + NEXT updated | pass/fail | |
| 12 | No application code written by this skill | pass/fail | git diff |

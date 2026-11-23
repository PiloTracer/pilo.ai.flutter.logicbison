# flutter-foundation — reference

Extended tables for [`skill.md`](skill.md). The protocol is normative in `skill.md`; this file holds the per-phase detail and the question banks.

---

## Phase detail

### P0 — Identity & intent

**Owner document:** `01-product-and-scope.md` §1 Name · §2 Intent · §3 Job-to-be-done

**Sequence (binding):**

1. Ask for the project name. Nothing else first.
2. Ask for the intent in one sentence: *"In one sentence, what does this app let someone do that they cannot do today?"*
3. Run the product probe (D1–D2). **Do not** ask a technical question in P0.
4. Play the intent back and ask the operator to correct it. An intent the operator has to fix is worth ten the agent invented.

**Exit criterion:** a stranger reading §2 can state what the app does and for whom, without reading anything else.

**Document outline:**

```markdown
# 01 — Product and scope

**Status:** Draft | Complete   **Phase:** P0/P4   **Updated:** YYYY-MM-DD

## 1. Name
## 2. Intent (one sentence)
## 3. Jobs to be done
| # | Persona | Job | Today's workaround | Success signal |
## 4. Users and personas          (P1)
## 5. Non-goals (explicit)        (P1)
## 6. Success metrics             (P1)
| Metric | Baseline | Target | Measured how |
## 7. Open questions → UNKNOWNS.md
```

---

### P1 — Users, platforms & constraints

**Owner document:** `02-platforms-and-constraints.md`

**Exit criterion:** every target platform has a **minimum OS version** and a **device class**; non-targets are explicit; the connectivity model is stated.

```markdown
# 02 — Platforms and constraints

## 1. Target platforms
| Platform | Min OS | Device classes | Ship in | Notes |
|----------|--------|----------------|---------|-------|
| Android | API 26 (8.0) | phone; tablet later | F1 | |
| iOS | 15.0 | phone | F1 | |
| Web | — | not targeted | — | explicit non-target |

## 2. Non-target platforms (and why)
## 3. Device reality
| Constraint | Value |
| Lowest-tier reference device | <model> |
| Smallest supported width | <dp> |
| Max text scale supported | 200% |
| Dark mode | required / optional / not supported |

## 4. Connectivity model
| Aspect | Decision |
| Mode | online-only / read-through cache / full offline read-write |
| Conflict policy | last-write-wins / server-wins / merge / n/a |
| Sync trigger | foreground / periodic / push / manual |
| Behaviour with no network at cold start | <explicit> |

## 5. Localisation
| Aspect | Decision |
| Locales at launch | |
| RTL required | yes/no |
| Date/number/currency formatting source | |
| Pseudo-localisation in CI | yes/no |

## 6. Accessibility baseline
Default: WCAG 2.2 AA, per ACCESSIBILITY_STANDARD. Record any deviation with a reason.

## 7. Compliance and regulatory
| Regime | Applies | Implication |

## 8. Organisational constraints
Approved-dependency policy · pub mirror · signing custody · release cadence · deadlines
```

---

### P2 — Architecture & stack alignment

**Owner document:** `03-architecture-and-nfrs.md` §1–4, plus ADRs.

**Prerequisite:** `STACK.md` Status: Locked (gate SL0).

**Steps:**

1. Read `STACK.md` and the matching idiom file in `stacks/`.
2. Instantiate the layering from `ARCHITECTURE_STANDARD` for this project: name the layers, the allowed dependency directions, and where each kind of logic lives.
3. Decide the error strategy: which failures are typed results, which are exceptions, and how each surfaces to the user.
4. Decide the DI approach and where composition happens.
5. Run `@flutter-concept-run run - FLS-03` (layer boundary audit) against the planned structure.
6. Write one ADR per non-obvious decision.

**Exit criterion:** a new developer can read §1–4 and correctly place a new file without asking.

**ADR triggers** — write one when the decision is expensive to reverse, contested, or surprising:

| Trigger | Example |
|---------|---------|
| Expensive to reverse | local store choice, offline sync model, monorepo vs single package |
| Contested | state management, codegen vs hand-written models |
| Surprising | a deliberate deviation from ARCHITECTURE_STANDARD |
| Externally imposed | a mandated SDK, an org-approved dependency list |

ADR path: `{FLUTTER_DECISIONS_ROOT}/YYYYMMDD-NNN-<slug>.md`. Status: `Proposed | Decided | Superseded`.

---

### P3 — Project standards

Generate dated project copies into `{FLUTTER_STANDARDS_ROOT}`, filling every token from docs 01–03 and `STACK.md`.

| Framework template | Project copy | Tokens filled from |
|--------------------|--------------|--------------------|
| `20260801-FLUTTER_CONVENTIONS.md` | `YYYYMMDD-CONVENTIONS.md` | STACK, doc 03 |
| `20260801-DIRECTORY_MAP.md` | `YYYYMMDD-DIRECTORY_MAP.md` | STACK (monorepo?), doc 03 |
| `20260801-FEATURE_SPEC_STANDARD.md` | `YYYYMMDD-FEATURE_SPEC_STANDARD.md` | doc 01, doc 02 |
| `20260801-TESTING_STANDARD.md` | `YYYYMMDD-TESTING_STANDARD.md` | STACK (K7), doc 03 §5 |
| `20260801-QUALITY_GATES.md` | `YYYYMMDD-QUALITY_GATES.md` | coverage floor, commands from DOCS_FLUTTER_STACK |
| `20260801-ARCHITECTURE_STANDARD.md` | `YYYYMMDD-ARCHITECTURE_STANDARD.md` | doc 03 §1–4 |

Generate the domain-specific standards (`PERFORMANCE`, `ACCESSIBILITY`, `SECURITY_PRIVACY`, `DATA_LAYER`, `NAVIGATION`, `THEMING`, `UI_CRAFT`, `L10N`, `OBSERVABILITY`, `RELEASE`) when doc 02 or doc 03 makes them applicable; record any deliberate omission in doc 03 §8. `UI_CRAFT` applies to anything that ships screens — omitting it means shipping unverified visual quality.

**Exit criterion:** `grep -r 'REPLACE:' {FLUTTER_STANDARDS_ROOT}` returns nothing.

---

### P4 — Domain & feature inventory

**Owner documents:** `04-domain-and-data.md`, `05-feature-map-and-slices.md` §1.

```markdown
# 04 — Domain and data

## 1. Entities
| Entity | Key attributes | Invariants | Source of truth | Lifetime |

## 2. Relationships
## 3. Data flow per surface
| Surface | Reads from | Writes to | Cached | Staleness tolerance |

## 4. Offline and sync
| Entity | Cached | Writable offline | Conflict policy | Eviction |

## 5. Data classification
| Data | Class (public/internal/personal/sensitive/credential) | Storage | Retention | Never logged |

## 6. Local store schema and migration policy
```

**Feature inventory** (doc 05 §1):

| ID | Feature | Priority | Acceptance (one line) | Depends on | SPEC |
|----|---------|----------|------------------------|------------|------|
| FT-01 | | P0/P1/P2 | | | path or `—` |

**Exit criterion:** every P0 feature has a one-line acceptance statement that a tester could act on.

---

### P5 — NFRs, risks, assumptions

**Owner document:** `03-architecture-and-nfrs.md` §5–8, plus the three registries.

**NFR table — every row needs a number and a unit:**

| ID | Category | Requirement | Target | Measured by |
|----|----------|-------------|--------|-------------|
| NFR1 | Startup | Cold start to first meaningful frame, reference device | ≤ 2000 ms | `--trace-startup`, `@flutter-perf startup` |
| NFR2 | Frame budget | 99th-percentile frame build+raster during scroll | ≤ 16 ms | `@flutter-perf profile` |
| NFR3 | App size | Android release download size | ≤ 30 MB | `--analyze-size` |
| NFR4 | Coverage | Line coverage on `lib/src/` excluding generated | ≥ 80% | `@flutter-test coverage` |
| NFR5 | Stability | Crash-free sessions | ≥ 99.5% | crash reporter |
| NFR6 | Accessibility | WCAG 2.2 AA on all P0 screens | 0 violations | `@flutter-a11y audit` |
| NFR7 | Offline | P0 read surfaces usable with no network | 100% | `@flutter-test integration` |
| NFR8 | Security | No secret in the shipped bundle | 0 findings | `@flutter-security audit` |

Adjust targets to the product; **never delete the unit**.

**Registries** (canonical, never forked):

| File | Row shape |
|------|-----------|
| `ASSUMPTIONS.md` | `ID · Assumption · Because · Invalidated if · Owner · Status` |
| `RISK_REGISTRY.md` | `ID · Risk · Likelihood · Impact · Mitigation · Trigger to revisit · Owner` |
| `UNKNOWNS.md` | `ID · Question · Owner · Blocks · Asked (date) · Resolution` |

**Assumption vs unknown:** an assumption is something you are proceeding on and can name the invalidation condition for. An unknown is something you cannot proceed past without an answer. Mixing them hides real blockers.

**Flutter risk starter set** — consider each, keep what applies:

| Risk | Why it bites |
|------|--------------|
| Platform behaviour divergence | iOS/Android differ on back navigation, permissions, background execution, keyboard |
| Low-end Android performance | Development happens on flagships; users are not on flagships |
| Codegen friction | `build_runner` conflicts stall the whole team when versions drift |
| Breaking Flutter/Dart SDK upgrade | Pinned SDK vs a dependency requiring a newer one |
| Unmaintained dependency | A core package goes stale mid-project |
| Store rejection | Permissions, privacy manifest, tracking disclosure |
| Offline conflict semantics | Undefined merge rules produce silent data loss |
| Deep-link regressions | Untested link routing breaks marketing campaigns |
| Text scale / long locales | Layouts built at 100% English overflow at 200% German |
| Golden-test flakiness across platforms | CI goldens diverge from local, and the team disables them |

---

### P6 — Release slices & readiness

**Owner document:** `05-feature-map-and-slices.md` §2–3.

**F0 is special.** F0 is the *skeleton*: runnable app, navigation shell, theming, DI composition root, flavors, CI, analysis, one trivial end-to-end path. It contains **no product features**. Making F0 explicit is what lets `@flutter-foundation` grant an early-start waiver without leaking product decisions into the scaffold.

```markdown
## 2. Milestone candidates
| Milestone | Theme | Features | Depends on | Demoable outcome |
|-----------|-------|----------|------------|------------------|
| F0 | Skeleton | — | — | App runs on both platforms; CI green; empty shell navigable |
| F1 | <theme> | FT-01, FT-03 | F0 | <what someone can do> |

## 3. Slice rationale
Why this order. What is deliberately late and why that is safe.

## 4. Not in scope for v1
```

**Exit criterion:** every P0 feature appears in exactly one milestone candidate, and each milestone has a **demoable outcome** stated as something a person can do.

---

## Probe question bank

Ranked by yield. Ask the blocking ones; obey the ≤5-per-pass and quality-bar rules in [`probe-protocol.md`](../probe-protocol.md).

### D1 Product intent ★

1. In one sentence, what can someone do with this app that they cannot do today?
2. What are they doing instead right now?
3. If you could ship only one screen, which one, and what must it do?
4. What would make you shut this project down in six months?

### D2 Users & context ★

1. Who opens this app on a Tuesday morning, and what are they trying to finish?
2. Are they using it standing up, one-handed, in a warehouse, at a desk?
3. How many distinct roles are there, and do they see different things?
4. Who is explicitly **not** a user?
5. How will you know it worked — what number moves?

### D3 Platform targets ★

1. Which platforms ship in v1, and which are explicitly later or never?
2. Minimum iOS version? Minimum Android API level?
3. Phones only, or tablets and foldables too?
4. What is the lowest-tier device this must feel good on?
5. Do you need web or desktop, and is that the same UX or a different product?
6. Desktop: which of Windows, macOS, Linux? Minimum window size? Native look per OS or one design? Distribution per OS (store or direct), and who holds the Apple Developer ID and Windows signing certificate? (DESKTOP_STANDARD)

### D4 Connectivity & offline ★

1. What happens when the user opens the app with no signal?
2. Can they create or edit anything offline, or only read?
3. If two devices edit the same record offline, who wins?
4. How stale can cached data be before it is wrong rather than merely old?
5. Is there a background sync, and what triggers it?

### D5 Constraints

1. Which regulations apply — GDPR, HIPAA, PCI, COPPA, regional data residency?
2. Which locales at launch, and is any of them RTL?
3. Is there an approved-dependency list, or a private pub mirror?
4. Who holds the signing keys and store credentials?
5. Is there a fixed date, and what is behind it?

### D6 Domain model ★

1. What are the three or four nouns this app is really about?
2. For each: what makes an instance valid, and what must never happen to it?
3. Where does each one actually live — server, device, or both?
4. What must never leave the device?
5. What happens to a user's data when they delete their account?

### D7 Feature inventory ★

1. List the features. Now mark each P0, P1 or P2.
2. For each P0: how would a tester know it works, in one sentence?
3. Which of these would you cut to ship two months earlier?
4. Which feature is riskiest technically, and have we ever built it before?

### D8 Quality bar (NFRs) ★

1. What number, in milliseconds, would make you say the app is too slow to open?
2. Is a dropped frame during scrolling a bug or a nuisance here?
3. What is the maximum acceptable download size on Android?
4. What line-coverage floor will CI enforce?
5. What crash-free-session rate is acceptable in production?
6. Which screens must pass an accessibility audit before launch?

### D9 Risks & unknowns

1. What worries you most about this project?
2. What has gone wrong on your last two mobile projects?
3. Which external dependency could block us, and who owns that relationship?
4. What are we assuming about the backend that nobody has confirmed?

### D10 Release slicing ★

1. What is the first thing you want to see running end to end?
2. What must be in the first internal build to be worth installing?
3. Which features depend on which others, technically?
4. Is there a demo, review or launch date that fixes the order?

---

## Gate report shape

Emit after every phase:

```markdown
### P<N> <phase name> - gate <pass | incomplete>

**Produced:** <paths>
**Exit criterion:** <restated>
**Evidence:** <the specific content that satisfies it>
**Coverage after:** <NN>%
**Recorded to UNKNOWNS:** <ids or none>
**Next:** P<N+1> <name>  |  blocked on <what>
```

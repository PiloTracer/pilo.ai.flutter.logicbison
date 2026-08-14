---
name: flutter-feature-spec
description: >-
  Intake, author, review, amend, approve and document Flutter feature SPECs per
  FEATURE_SPEC_STANDARD. Classifies free-text feature requests before writing
  anything, probes for the gaps that make a SPEC unimplementable, and gates
  approval on a completeness review. Use when the user describes a capability
  they want, asks for a SPEC, or needs an existing feature documented.
---

# flutter-feature-spec

A SPEC is the contract between intent and implementation. It exists so that `@flutter-implementation` never has to guess, and so that `@flutter-verify` has something objective to check against.

**Pairs with:** `flutter-foundation` (feature inventory is the source), `flutter-plan-master` (SPECs become tasks), `flutter-implementation` (reads the SPEC before coding), `flutter-verify` (checks against SPEC rules).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`FEATURE_SPEC_STANDARD`](../../standards/20260801-FEATURE_SPEC_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B · [Document clarity](../SKILL_DEPENDENCIES.md#document-clarity-contract) — Status + Needs header, separate Decisions/Open questions lists, exactly one `## Next action`, no leftover scaffolding.

**Hard rules:**

1. **Classify before writing.** `intake` runs first on any free-text request. Auto-creating a SPEC for a request that was really a bug report, a cross-cutting concern, or an existing feature wastes everyone's time.
2. **A SPEC states behaviour, not implementation.** Widget names and package choices belong in the code; the SPEC says what the user experiences and what must be true.
3. **Every SPEC is testable.** Each acceptance criterion must be checkable by a named test type. "Works well" is not a criterion.
4. **Approved SPECs are amended, never edited in place.** Amendments are dated sibling files; the original stays as history.
5. **§16 concept registry is mandatory before Approved.** Each applicable FLS prompt is `pending`, `done` or `N/A` with a reason.
6. **No SPEC without a foundation feature ID**, unless the mode is `document` (brownfield recovery) or the intake class is `local`.

---

## Modes

| Mode | Action |
|------|--------|
| `intake - <free-text>` | Classify a request; route; write a SPEC only when class = `local` |
| `intake - <free-text> force=<class>` | Override the classification |
| `create - <slug>` | Author a new SPEC from the standard's template |
| `probe - <slug>` | Interrogate the S1–S6 gaps that make a SPEC unimplementable |
| `review - <slug>` | Read-only completeness and testability audit |
| `amend - <slug>` | Add a dated amendment to an Approved SPEC |
| `approve - <slug>` | Run `review`; flip `Status: Approved` only on pass |
| `document - <slug>` | Brownfield: reconstruct a SPEC from existing code |
| `status` | Read-only: all SPECs, their status, and gaps |

---

## Intake classification

Run on any free-text feature request **before** writing. Classify into exactly one class.

| Class | Signals | Action |
|-------|---------|--------|
| **local** | A bounded capability inside one feature area; the foundation already anticipated it; ≤1 milestone of work | Proceed to `create - <slug>` |
| **cross-cutting** | Touches navigation, theming, auth, offline, analytics or every screen; changes an architectural rule | **Do not create a SPEC.** Route to `@flutter-foundation continue` (doc 03) then `@flutter-plan-master revise` |
| **brownfield** | The capability already exists in code, undocumented | Route to `document - <slug>` |
| **underspecified** | No clear user, no acceptance condition, or the request is a wish ("make it better") | Route to `probe`, or `@flutter-foundation probe` when the gap is product-level |
| **defect** | Describes something that is broken, not something missing | Route to `@flutter-repair` (with a verifier run first) or `@flutter-doctor` if it is toolchain |
| **not-flutter** | Backend, API, schema, infrastructure, or pure visual design | Preflight, then `@ai-director` / `@ui-director` |

**Intake record** — append to `{FLUTTER_NEXT}` § Intake queue:

```text
- <YYYY-MM-DD> · <class> · "<request, one sentence>" → <next command>
```

**Intake report:**

```markdown
## @flutter-feature-spec intake

**Request:** "<verbatim>"
**Class:** <class> · **Confidence:** high | med | low
**Why:** <the signal that decided it>
**Recorded:** `{FLUTTER_NEXT}` § Intake queue
**Run next:** `<exact command>`
```

Low confidence → ask one bounded question before classifying. `force=<class>` overrides and is recorded as an override.

---

## Prerequisite gate (CR0 — `create`)

```markdown
## @flutter-feature-spec create - blocked (collision)

**Required:** `.work.flutter/features/<slug>/` must not exist
**Detected:** <path> with <n> file(s), latest `<file>` Status: <status>
**Run first:** `@flutter-feature-spec amend - <slug>` (or pick a different slug)
```

**Warn, do not block,** when `plan-ready: no` — SPECs may legitimately be written during foundation P4. Say so in the report.

---

## create protocol

### C1 — Resolve the source

Find the feature in doc 05's inventory. Record its `FT-` id, priority and acceptance line. No matching entry → either the class was wrong (re-run `intake`) or the foundation needs `continue`.

### C2 — Probe the gaps

Run the S1–S6 coverage map (below) before writing. Most unimplementable SPECs fail on S2 (states) and S4 (errors) — the happy path is easy and never the problem.

### C3 — Write the SPEC

Path: `{FLUTTER_SPEC_ROOT}/<slug>/YYYYMMDD-SPEC.md`. Sections §1–§16 per [`FEATURE_SPEC_STANDARD`](../../standards/20260801-FEATURE_SPEC_STANDARD.md):

| § | Section | Flutter-specific requirement |
|---|---------|------------------------------|
| 1 | Purpose & user value | Ties to a `FT-` id and a job-to-be-done |
| 2 | Scope in / out | Explicit non-goals |
| 3 | Actors & preconditions | Auth state, permissions, required data |
| 4 | User flows | Step by step, including entry points and back behaviour |
| 5 | Screens & surfaces | Route names, whether a UI SPEC owns the visuals |
| 6 | **UI states** | **Every surface: loading, empty, partial, error, offline, success.** No state may be undefined |
| 7 | Data contract | Entities read/written, source of truth, staleness tolerance, cache policy |
| 8 | Business rules & invariants | Numbered `R{n}`, each testable |
| 9 | **Error handling** | Per failure mode: detection, user-visible surface, recovery, retry, logging |
| 10 | Offline behaviour | What works, what queues, what is refused, conflict policy |
| 11 | Permissions & platform | Runtime permissions, denial and permanent-denial paths, per-platform divergence |
| 12 | Accessibility | Semantics labels, focus order, tap targets, contrast, text scale to 200% |
| 13 | Performance | Which NFRs apply and their numbers for this feature |
| 14 | Observability | Events, log fields, what must never be logged |
| 15 | Acceptance criteria | Numbered `A{n}`, each with the test type that proves it |
| 16 | Concept / NFR registry | Each applicable FLS: `pending` / `done` / `N/A` + reason |

Front matter: `status: Draft | Review | Approved | Implemented | Superseded`, `owner`, `feature-id`, `milestone`, `adrs`, `last-updated`.

### C4 — Self-review and report

Run `review` immediately. Report the SPEC path, status, gaps, and the next command. End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## probe protocol

Engine: [`probe-protocol.md`](../probe-protocol.md). Ledger: `{FLUTTER_SPEC_ROOT}/<slug>/PROBE_LEDGER.md`.

| Dim | Topic | ★ | Confirmed means |
|-----|-------|---|-----------------|
| S1 | User value & trigger | ★ | Who does this, when, and what they get |
| S2 | States | ★ | Loading, empty, partial, error, offline and success defined for every surface |
| S3 | Data contract | ★ | Entities, source of truth, staleness tolerance, cache policy |
| S4 | Failure modes | ★ | Every failure has a detection, a user surface and a recovery |
| S5 | Platform & permissions | | Per-platform divergence named; permission denial paths defined |
| S6 | Acceptance | ★ | Each criterion names the test type that proves it |

**Questions that find real gaps:**

1. What does the screen show in the first 300 ms before data arrives?
2. What does it show when the list is legitimately empty versus when the request failed?
3. What happens if the user backgrounds the app mid-action and returns ten minutes later?
4. The request times out — what does the user see, and can they retry without losing input?
5. The token expires during this flow — where do they end up?
6. The user denies the permission. Then denies it permanently. Two different screens?
7. Can this be used offline at all? If they act offline, does it queue or refuse?
8. Two devices do this at the same time — what is the correct outcome?
9. What must never be logged from this flow?
10. How would a tester prove criterion A3 without looking at the code?

---

## review protocol

Read-only audit. Findings table: `ID | § | Severity | Finding | Fix`.

| # | Check | Fail condition |
|---|-------|----------------|
| 1 | All 16 sections present | Any missing or empty |
| 2 | Every surface has all six states (§6) | Any state undefined |
| 3 | Every business rule numbered and testable (§8) | Prose without `R{n}`, or untestable |
| 4 | Every failure mode has a user surface (§9) | A failure with no defined UX |
| 5 | Offline behaviour stated (§10) | "TBD" when doc 02 says offline matters |
| 6 | Permission denial paths defined (§11) | Only the granted path |
| 7 | A11y requirements concrete (§12) | "Accessible" without specifics |
| 8 | Acceptance criteria name a test type (§15) | "Manual" or no type |
| 9 | §16 registry complete | Any FLS row missing or unexplained `N/A` |
| 10 | Traces to a `FT-` id and a milestone | Neither present (except `document`) |
| 11 | No implementation detail masquerading as requirement | Widget/package names in §6–§9 |

**Verdicts:** `pass` · `pass with gaps` (non-blocking, listed) · `fail` (blocks Approved).

---

## approve / amend / document

**approve:** run `review`. On `fail`, emit the findings and stop — do not flip the status. On pass, set `status: Approved`, stamp the date, record it in `{FLUTTER_HANDOFF}`, and notify `@flutter-plan-master` if scope changed.

**amend:** write `{FLUTTER_SPEC_ROOT}/<slug>/YYYYMMDD-SPEC-amendment-NN.md` with: what changed, why, which sections, trace impact, and whether re-approval is required. Never edit the Approved file. Add a pointer line to the original's front matter.

**document (brownfield):** reconstruct the SPEC from what the code actually does. Read the feature's widgets, view models, repositories and tests. Mark every section `observed` (read from code), `inferred` (deduced, needs confirmation) or `unknown` (route to `probe`). Status starts at `Draft`; never `Approved` — nobody has agreed to what the code happens to do.

---

## Anti-patterns

- Creating a SPEC for a request that intake would have classified `cross-cutting` or `defect`.
- Documenting only the happy path.
- Acceptance criteria that cannot be tested without a human.
- Naming widgets and packages in the requirement sections.
- Editing an Approved SPEC in place.
- Approving with §16 incomplete.
- Reconstructing a brownfield SPEC as if it were designed, when half of it is inferred.
- Writing a SPEC when the foundation has no matching feature and nobody has agreed to add one.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Intake class assigned before any write | pass/skip | class |
| 2 | CR0 collision gate honoured | pass/skip | |
| 3 | Traces to a `FT-` id (or `document` mode) | pass/fail | id |
| 4 | All 16 sections present | pass/fail | |
| 5 | Six UI states per surface (§6) | pass/fail | |
| 6 | Failure modes have user surfaces (§9) | pass/fail | |
| 7 | Acceptance criteria name test types (§15) | pass/fail | |
| 8 | §16 concept registry complete | pass/fail | |
| 9 | `review` run before `approve` | pass/skip | verdict |
| 10 | Amendment written as a sibling file (amend mode) | pass/skip | path |
| 11 | Brownfield sections marked observed/inferred/unknown | pass/skip | |
| 12 | Intake queue + HANDOFF updated | pass/fail | |

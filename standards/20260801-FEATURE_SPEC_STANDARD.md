# Feature SPEC standard — template

> **Template.** Copied to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-FEATURE_SPEC_STANDARD.md`. `@flutter-feature-spec` writes against the project copy; `@flutter-plan-verify` and `@flutter-verify` audit against it.

A SPEC is the **contract between intent and implementation**. It says what the software must do and how anyone can tell whether it does. It never says how to build it — that is the implementer's job, and constraining it in a SPEC produces worse code and a stale document.

**Test of a good SPEC:** two competent engineers implement it independently and produce behaviourally equivalent software. If they would diverge, the SPEC has a gap.

---

## 1. Location and lifecycle

Path: `{FLUTTER_SPEC_ROOT}/<slug>/YYYYMMDD-SPEC.md`. Amendments append to the same file under `## Amendments`; the original body is never rewritten after approval — the amendment trail is the reason anyone can reconstruct why the behaviour changed.

```yaml
---
spec: SPEC-<nnn>
feature-id: FT-<nn>          # from foundation doc 05
title: <title>
status: Draft | Review | Approved | Implemented | Superseded
owner: <name>
milestone: F<n>
adrs: [ADR-03]
ui-spec: <path or none>       # when .ai.ui owns the visual design
last-updated: <YYYY-MM-DD>
---
```

| Status | Means |
|--------|-------|
| Draft | Being written; not implementable |
| Review | Complete; awaiting approval |
| **Approved** | Implementable. **Only an approved SPEC may be implemented** |
| Implemented | Built and verified; amendments still allowed |
| Superseded | Replaced; names its replacement |

On top of this lifecycle, every SPEC follows `skills/SKILL_DEPENDENCIES.md` § Document clarity contract: decisions the operator must make are listed separately from open questions (never one mixed list), and until the SPEC is Approved it ends with exactly one `## Next action` — typically `@flutter-feature-spec review - <slug>` or `@flutter-feature-spec approve - <slug>`.

---

## 2. The sixteen sections

All sixteen are mandatory. "N/A" is an acceptable content with a **reason** — an empty section is not.

| § | Section | Must contain |
|---|---------|--------------|
| 1 | **Purpose and user value** | The `FT-` id, the job-to-be-done, and what changes for the user. Not "add a profile screen" but "a user can correct their delivery address before an order ships" |
| 2 | **Scope** | In-scope list, and an explicit **out-of-scope** list. Non-goals prevent more rework than goals cause |
| 3 | **Actors and preconditions** | Who, in what auth state, with what permissions and what data present |
| 4 | **User flows** | Step by step, with entry points, exit points, and back behaviour at each step. Include the abandonment path |
| 5 | **Screens and surfaces** | Route names and paths; which surfaces are new; who owns the visual design; **per screen: the one dominant element and the single primary action** (UI_CRAFT_STANDARD §3 — a screen without that decision cannot be verified for hierarchy) |
| 6 | **UI states** ★ | For **every** surface: loading, empty, partial, error, offline, success. Each described in terms of what the user sees and can do |
| 7 | **Data contract** | Entities read and written, source of truth, freshness and staleness tolerance, cache policy, validation rules |
| 8 | **Business rules** | Numbered `R1…Rn`, each independently testable, each stating its outcome when violated |
| 9 | **Error handling** ★ | For each failure mode: how it is detected, what the user sees, how they recover, whether it retries, what is logged |
| 10 | **Offline behaviour** | What works offline, what queues, what is refused, how conflicts resolve, what the user sees in each case |
| 11 | **Permissions and platform** | Runtime permissions with rationale copy; denied and permanently-denied paths; per-platform divergences named explicitly |
| 12 | **Accessibility** | Semantic label for every interactive element, traversal order, focus behaviour on entry/exit/error, announcements for async changes, tap targets, contrast, behaviour at 200% text scale |
| 13 | **Performance** | Which NFRs apply, with numbers and the device they apply to |
| 14 | **Observability** | Analytics events with properties, log fields, and what must never be logged |
| 15 | **Acceptance criteria** ★ | Numbered `A1…An`, each observable, each naming the test type that proves it |
| 16 | **Concept / NFR registry** | Each applicable FLS concept: `pending` / `done` / `N/A` with a reason |

★ = the sections where SPECs actually fail. The happy path is easy; §6, §9 and §15 are where implementability is won or lost.

---

## 3. Acceptance criteria

Each criterion is:

- **Observable** — describes what someone can see or measure, not an internal state.
- **Binary** — passes or fails; no "works well", no "reasonably fast".
- **Traceable** — maps to at least one plan task and at least one test.
- **Test-typed** — names unit, widget, golden, integration or manual.

```
A3. When the address form is submitted with an invalid postcode, the postcode
    field shows "Enter a valid postcode", the field receives focus, the error
    is announced to screen readers, and the form is not submitted.
    Test: widget
```

Not: "A3. Validation works properly." That is a note to yourself, not a criterion.

---

## 4. The six states

The most-skipped and most-costly section. Every data-backed surface defines all six, because each one is a real thing users encounter:

| State | The question it answers |
|-------|------------------------|
| Loading | What is on screen in the first 300 ms — and is it a skeleton, a spinner, or previous content? |
| Empty | What is shown when there is legitimately nothing — and how is it distinguished from an error? |
| Partial | What is shown when some data loaded and some failed, or while refreshing existing content? |
| Error | Which message for which failure, and how does the user retry without losing their input? |
| Offline | Is it distinguished from a generic error, what still works, and what happens on reconnect? |
| Success | The normal case — including the boundaries: one item, and the maximum realistic number |

"Standard loading state" is not a definition. Skipping these is why features get re-opened after they ship.

---

## 5. Writing rules

1. **Behaviour, not implementation.** "The list refreshes when the user pulls down", not "call `refresh()` in the `RefreshIndicator` callback".
2. **No ambiguous quantifiers.** "Fast", "several", "large", "appropriate", "graceful" — each must be a number or a defined behaviour.
3. **State the negative case.** For every rule, what happens when it is violated.
4. **Name the source of every fact.** Domain rules trace to doc 04; NFRs to doc 05; API shapes to the integration contract.
5. **Link, do not restate**, standards and other SPECs.
6. **Unknowns are marked, not guessed.** `> OPEN: <question> — blocks A4, owner <who>`. An open item in an approved SPEC is a contradiction; resolve or explicitly defer with the scope reduced.
7. **Copy is exact.** Every user-visible string is quoted verbatim, so it can be reviewed, localised and tested.

---

## 6. Amendments

After approval, changes append:

```markdown
## Amendments

### A1 — <YYYY-MM-DD> — <title>
**Trigger:** <what forced this — discovery during implementation, changed requirement, defect>
**Changes:** §9 — added the 429 rate-limit failure mode and its surface
**Impact:** A7 added; F2-T5 re-opened
**Approved by:** <who>
```

Discovering a gap during implementation is normal and expected. Silently implementing something the SPEC does not describe is not — the SPEC stops being the contract, and the next reader is misled.

---

## 7. Review checklist

| # | Check |
|---|-------|
| 1 | All sixteen sections present, none empty |
| 2 | Every surface has all six states defined |
| 3 | Every failure mode has detection, surface, recovery and logging |
| 4 | Every acceptance criterion is observable, binary and test-typed |
| 5 | Every business rule is numbered and testable |
| 6 | No ambiguous quantifiers |
| 7 | Every user-visible string quoted exactly |
| 8 | Accessibility specified, not deferred |
| 9 | Offline and permission paths defined |
| 10 | Platform divergences named |
| 11 | Traces to a `FT-` id in doc 05 |
| 12 | No open items, or each with owner and scope impact |
| 13 | No implementation prescription |
| 14 | Concept registry populated |
| 15 | Every screen names its dominant element and single primary action |

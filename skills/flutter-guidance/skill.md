---
name: flutter-guidance
description: >-
  Plan, build and audit guided UX in Flutter - multi-step wizards, contextual
  tips and coach marks, product tours, first-run onboarding and "what's new" -
  by the GUIDED_UX decision ladder (fix the screen first, pull over push, one
  tip at a time), with verified recipes, behaviour and a11y tests, and review
  renders. Use for wizard, stepper, onboarding, tutorial in the app, product
  tour, coach marks, tooltips that teach, feature discovery, or first-run flow.
---

# flutter-guidance

Guidance is a cost the user pays to get help the interface did not give. In NN/g's study, people who read a launch tutorial were no faster or more successful than people who skipped it, and found the task harder. This skill exists so that every wizard, tip, tour and onboarding screen in the app is **justified first, built to the research second, and proven third**, instead of bolted on to explain a confusing screen.

**Pairs with:** `flutter-feature-spec` (the plan lives in SPEC §4), `flutter-implementation` (builds the iteration's tasks), `flutter-test` (`render` and behaviour tests), `flutter-a11y` (announcements, focus, targets), `flutter-data` (the persisted tip and progress store), `FLS-13 UI craft`.

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`GUIDED_UX_STANDARD`](../../standards/20261124-GUIDED_UX_STANDARD.md) · **Evidence and recipes:** [`resources/guided-ux.md`](../../resources/guided-ux.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Fix the screen before guiding through it.** Every proposed guidance item is placed on the decision ladder (standard §2), and the plan records what rung 1 (a better label, default, empty state) would have done. "We'll add a tour" is never the answer to "this screen is confusing".
2. **Pull, not push.** Tips appear when the user first reaches the feature, never at launch and never in chains. At most one tip is visible; each is shown once, is dismissible, and can be found again.
3. **Wizards only when justified,** meaning novice users or infrequent processes with real step dependencies. A justified wizard has: "Step n of m" with the step title as heading, back that keeps answers, buttons that name their destination, enforced order, save and resume, and a review step whose Change links return to it.
4. **Onboarding is optional, skippable, and never repeated after a skip.** Nonessential setup and permissions are deferred to first use.
5. **Guidance state is persisted and injected.** Seen-tips and wizard progress live in the state or data layer behind an interface, never in widget state, so they survive restarts and are controllable in tests.
6. **Proven three ways.** Behaviour tests, the four a11y guideline checks on every step and tip, and review renders looked at (or reported `unverified (no image input)`). A guided flow that passes tests but was never seen is not done.
7. **Current APIs only.** `PopScope`, not `WillPopScope`; `Semantics(liveRegion: true)` or `sendAnnouncement`, not `SemanticsService.announce` (`resources/flutter-api-currency.md`).
8. **Never decide product behaviour.** Whether a flow needs onboarding, which features get tips, and the tour step budget are the operator's decisions, made in the SPEC. This skill proposes with evidence; it does not ship guidance nobody approved.

---

## Modes

| Mode | Action |
|------|--------|
| `plan - <feature or FT-id>` | Run the decision ladder for the feature's flows and screens; write the **Guidance plan** into SPEC §4 through `@flutter-feature-spec amend` |
| `probe - <feature>` | Interrogate the operator per [`probe-protocol.md`](../probe-protocol.md) with the question bank below, before `plan` when the audience or frequency is unknown |
| `create - wizard - <slug>` | Build an approved wizard from the recipe, with tests and renders |
| `create - tip - <slug>` | Build an approved contextual tip (and the coordinator and store if absent) |
| `create - tour - <slug>` | Build an approved rung-5 tour (a package from `guided-ux.md` §2, verified on pub.dev today, or `FeatureTip` steps) |
| `create - onboarding - <slug>` | Build approved first-run onboarding per standard §5 |
| `audit [target]` | Read-only: every guided surface against the standard, with the verdict rules below |
| `status` | Read-only: inventory of guided surfaces, their ladder rung, tests and last render review |

---

## Prerequisite gate (G0)

| Mode | Requires | Missing → |
|------|----------|-----------|
| `plan` | An approved or in-review SPEC for the feature | Blocked report → `@flutter-feature-spec create` |
| `create - *` | The item appears in the SPEC §4 Guidance plan with the operator's approval, **and** the iteration block lists the task | Blocked report → `plan`, then `@flutter-implementation plan` |
| `audit`, `status`, `probe` | `{APP_ROOT}` | — |

---

## plan protocol

1. **Read** the SPEC (§1 purpose, §3 actors, §4 flows, §5 screens, §6 states) and any analytics evidence the operator supplies. Never invent usage data.
2. **List candidate guidance needs** from the SPEC: unfamiliar interactions, gestures without affordances, multi-step tasks, first-run prerequisites.
3. **Climb the ladder for each one** (standard §2). Record for every need: the rung chosen; why each lower rung is insufficient (rung 1 always answered); for a wizard, the step dependency or novice audience; for a tip, the triggering signal ("first time the list shows data"), not a time.
4. **Write the Guidance plan** in this shape, appended to SPEC §4:

   | Need | Rung | Lower rungs rejected because | Trigger / entry | Steps or text (quoted, l10n keys) | Measured by |
   |------|------|------------------------------|-----------------|-------------------------------|-------------|

5. **Hand the decisions to the operator** under **Needs your approval**: each item at rung 3 or above, and the step budget. Nothing is built before approval.

**Failure branch:** if a need cannot be placed without data the SPEC does not hold (who the users are, how often they do the task), stop and run `probe`. Never guess the audience.

## probe question bank

1. Who does this task: first-time, occasional or daily users? How often?
2. What do users get wrong today? Cite evidence: support tickets, analytics, session recordings. "Nobody knows" is a valid answer and a reason to measure before building.
3. Do later steps depend on earlier answers, or could this be one form?
4. Which interactions have no visible affordance (gestures, long-press, drag)?
5. What must happen before the app can work at all (account, permission, data)? What can wait?
6. If the user leaves midway, what should happen to their input?
7. What tone does the product use? It is recorded once in the project copy of GUIDED_UX_STANDARD §6.

## create protocol

1. **Confirm the approved plan row.** Build exactly that; anything else is a finding.
2. **Start from the verified recipe** in `resources/guided-ux.md` (wizard §3, tip §4). Adapt the import, tokens, strings (l10n) and state stack. Do not reinvent the mechanics the recipe already proves.
3. **Wire persistence**: `TipStore` or the wizard state through `@flutter-data` and the locked stack's DI.
4. **Write the tests** from `guided-ux.md` §5, adapted: back keeps answers (`handlePopRoute`), Change returns to review, the tip shows once and one at a time and is recallable, plus the four guideline checks per step and tip in light and dark.
5. **Emit the events** in standard §7.
6. **Render and look** (`@flutter-test render`): every step, the review page and each tip, across the matrix. Answer the review table in `visual-review.md` and standard §8 from the images, with paths.
7. **Gate** per `@flutter-implementation` (format, analyze, `dart fix --dry-run`, tests, hygiene).

**Failure branch:** a render shows a defect that the tests missed: fix it, re-render, and add an assertion where the defect is testable. Three failed attempts on the same root cause trigger the three-strike stop.

## audit protocol and verdict rules

Read every guided surface (search for `PageView` onboarding, `Stepper`, `OverlayPortal`, tour packages, "tutorial", "onboarding", "tip" in `lib/`), then answer per surface:

| Condition | Severity |
|-----------|----------|
| Launch-time feature carousel or tip chain; tour that cannot be skipped; onboarding shown again after a skip | blocker |
| Back from a wizard step exits the flow or loses input; `WillPopScope` in a wizard | blocker |
| Guidance with no SPEC §4 plan row (unapproved) | major |
| Wizard without "Step n of m" / heading, or with "Next"/"Finish" as the only labels | major |
| No review step on a flow that commits money, data or a submission | major |
| Tip state in widget state (resets on rebuild or restart); tip not re-findable | major |
| Tip styled like a control, or covering the control it explains | major |
| Step change or tip not announced to screen readers | major (and an FLS-10 finding) |
| No guidance events (standard §7) | minor |
| Guided surface never rendered and reviewed | major, and every look claim downgraded to `unverified` |

---

## Anti-patterns

- A tour proposed in the same breath as "users find this screen confusing".
- Treating `Stepper` as the default wizard on a phone; laying every step out at once.
- Tips fired on a timer, or on every launch until dismissed.
- Persisting "seen" flags with a raw key-value call scattered through widgets.
- Copy that says "Next", "Finish", "Tip 3 of 7".
- Declaring the flow done because the tests pass, without looking at the renders at 200% text and expanded width.

---

## Completion checklist

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Every guided item has a SPEC §4 plan row with rung 1 answered and operator approval | pass/fail | SPEC path:line |
| 2 | Built from the verified recipe; current APIs only (hygiene scan quoted) | pass/fail | command + tail |
| 3 | Persistence injected; state survives restart | pass/fail | test name |
| 4 | Behaviour tests (back, change-returns-to-review, tip once / one at a time / recallable) | pass/fail | test output |
| 5 | Four guideline checks on every step and tip, light and dark | pass/fail | test output |
| 6 | Renders reviewed at every size class, both brightnesses, 200% text | pass/fail/unverified | image paths |
| 7 | Guidance events emitted, no PII | pass/fail/skip | event names |
| 8 | Gate passed (format, analyze, dart fix, tests, hygiene) | pass/fail | exit codes |

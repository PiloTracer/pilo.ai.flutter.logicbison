# Guided UX standard: wizards, contextual tips, tours and onboarding (template)

> **Template.** Copied to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-GUIDED_UX_STANDARD.md`; `REPLACE:` tokens are filled once per project. Governs every surface whose job is to *teach or lead* the user: multi-step wizards, contextual tips and coach marks, product tours, first-run onboarding, and "what's new" notices. Planned and built with [`@flutter-guidance`](../skills/flutter-guidance/skill.md). Evidence and verified Flutter code: [`resources/guided-ux.md`](../resources/guided-ux.md).

**Pairs with:** [`UI_CRAFT_STANDARD`](20260802-UI_CRAFT_STANDARD.md) (clarity §5, copy §10), [`FEATURE_SPEC_STANDARD`](20260801-FEATURE_SPEC_STANDARD.md) (§4 holds the guidance plan), [`ACCESSIBILITY_STANDARD`](20260801-ACCESSIBILITY_STANDARD.md), [`NAVIGATION_STANDARD`](20260801-NAVIGATION_STANDARD.md) (back behaviour, resuming after onboarding), [`OBSERVABILITY_STANDARD`](20260801-OBSERVABILITY_STANDARD.md) (guidance events).

---

## 1. Why guidance is the last resort, not the first

In NN/g's controlled study (70 participants, four iOS apps), users who went through the launch tutorial were **no more successful and no faster** than users who skipped it, and they rated the task as **harder** (4.92 against 5.49 on a 7-point ease scale, a significant difference). Tutorials interrupt people who came to use the product, and their content is forgotten by the time it is needed. The finding generalises into this standard's first rule: **guidance is a cost the user pays, so it must buy something the interface could not give for free.**

The failure mode is specific and common: a confusing screen ships, someone notices, and a tour is bolted on to explain it. The screen stays confusing for everyone who skips the tour, which is most people.

---

## 2. The decision ladder (required, in order)

Every proposed piece of guidance is placed on this ladder, and the plan records why each lower rung was not enough. The answer to rung 1 is written down even when it is "no".

| Rung | Mechanism | Use when |
|------|-----------|----------|
| 1 | **Fix the screen.** Clearer label, a visible option, a better default, an empty state that teaches (UI_CRAFT §6, §10) | Always considered first. Most guidance proposals end here |
| 2 | **Inline, permanent help.** Helper text under the field, an example value, a visible "What's this?" link | The information is needed every time, by most users |
| 3 | **Contextual tip (pull revelation).** One short tip, shown when the user first reaches the feature, once, dismissible, re-findable | A feature is non-obvious *and* reached later than launch, or a gesture has no visible affordance |
| 4 | **Wizard.** The task split into ordered steps | Novice users or infrequent processes, *and* real dependencies between steps (NN/g). Otherwise one well-structured form is faster |
| 5 | **Short tour or coach marks** (at most `REPLACE:MAX_TOUR_STEPS`, default 3) | The interaction model itself is unfamiliar (a canvas, a gesture-driven editor). Never to describe ordinary screens |
| 6 | **First-run onboarding** | The app needs a decision or data before it can work at all (account, a required permission, a language). Never a feature carousel |

**Forbidden outright:** a launch-time carousel listing features; chains of tips shown one after another; a tour that cannot be skipped; guidance that repeats after the user dismissed it; guidance used to explain a screen the team agreed was confusing instead of fixing it.

---

## 3. Contextual tips and coach marks

**Required:**

- **Pull, not push.** A tip appears when a signal says the user would benefit now, typically the first time they reach the feature. Never on launch, never on a timer unrelated to what the user is doing (NN/g, push vs pull revelations).
- **One at a time, each once.** A coordinator holds at most one active tip; showing several in a row makes users dismiss them faster and makes the app look complicated (NN/g, instructional overlays).
- **One interaction per tip, one sentence.** "Swipe an order left to archive it." If it needs a paragraph, it is a rung-1 problem.
- **Visibly not interface.** Tips use a distinct treatment (inverse surface, a different shape) so nobody tries to tap the annotation (NN/g).
- **Easy to dismiss, easy to recall.** A "Got it" action, and a "Show tips again" entry in Help or Settings (NN/g; Apple HIG: make skipped instruction findable later).
- **Placed next to what it explains** and never covering the control it is about (Apple HIG: show instructions near that area).
- **Persisted and versioned.** Dismissals survive restarts through an injected store. A tip's id changes when the feature it explains changes, so a redesigned feature can teach again; a reworded tip keeps its id.

## 4. Wizards

**Required:**

- **Justified.** The plan names the step dependency or the novice audience (§2 rung 4). Frequent users get a faster path, such as a single editable form after the first time (NN/g guideline 1).
- **Orientation.** Show "Step *n* of *m*" with the step title as the page heading, plus a determinate progress bar, and only when the step count is reliable; if it varies with answers, update it as the user goes (GOV.UK; W3C WAI multi-page forms). The first step says how many steps follow (W3C).
- **One thing per step.** One question or one decision per step, unless research shows grouping works better (GOV.UK question pages).
- **Back goes back one step, with answers kept**, both from the app bar and from the system back gesture. It never drops the user out of the flow with their input lost (GOV.UK back link; NAVIGATION_STANDARD).
- **Buttons with information scent.** The primary button names where it goes or what it does: "Continue to payment", and on the last step the action itself, "Place order". Never a bare "Next" or "Finish" (NN/g: generic labels have weak information scent; UI_CRAFT §10).
- **Order enforced.** Users cannot jump ahead of the furthest completed step (NN/g guideline 3).
- **Self-sufficient steps.** No step needs information from another screen or from memory of an earlier step; show it again where it is needed (NN/g guideline 6).
- **Save and resume.** Leaving midway keeps the state, and returning resumes where the user was (NN/g guideline 5). The flow's state lives outside the widget, in the project's state layer, so it survives navigation and process death.
- **Review before commit.** Small to medium flows end on a "check your answers" step: every answer, each with a **Change** link that returns to the review after the edit; a skipped optional answer reads "Not provided"; the page says the action is not done until confirmed (GOV.UK check answers).
- **No time limit.** If one is unavoidable, the user can extend it (W3C; WCAG 2.2.1).
- **Help beside the step, never over it** (NN/g guideline 7).

## 5. Tours and onboarding

**Required:**

- **Optional and skippable** from the first screen. If skipped, it is **not shown again on later launches**, and it stays findable in Help or Settings (Apple HIG).
- **Interactive over descriptive.** Let the user try the action safely rather than read about it (Apple HIG).
- **Focused on this app.** It never teaches how to use the device or the platform (Apple HIG).
- **Defer what can wait.** Nonessential setup and customisation are postponed, with sensible defaults. Permissions are requested when the user first uses the function that needs them, unless the app cannot work at all without them (Apple HIG; FEATURE_SPEC §11).
- **No ratings or purchase prompts** before the user has experienced the app (Apple HIG).
- **Onboarding resumes to the destination.** A deep link that triggered onboarding lands on its target afterwards (NAVIGATION_STANDARD).
- **At most `REPLACE:MAX_TOUR_STEPS` steps** (default 3, a project heuristic, not a research figure). More than that means the interface is being explained instead of fixed.

---

## 6. Accessibility, motion and copy

- A step change or a new tip is announced: the wizard heading is a `Semantics(header: true, liveRegion: true)` node, and a tip is a live region. Use `SemanticsService.sendAnnouncement` only when no visible change can carry the announcement; `SemanticsService.announce` is deprecated (`resources/flutter-api-currency.md`).
- Overlays and spotlights never trap focus without a reachable dismiss action; every dismiss target meets the tap-target guidelines.
- Spotlight and transition animations collapse under the platform's reduce-motion setting (`MediaQuery.disableAnimationsOf`).
- All guidance text comes from l10n and follows UI_CRAFT §10. Tone is the project's recorded tone: `REPLACE:GUIDANCE_TONE`.

## 7. Measurement

Guidance has a cost, so it must show a benefit. Each guided surface emits events per OBSERVABILITY_STANDARD, never with PII: `guidance_shown`, `guidance_dismissed`, `guidance_completed`, and for wizards `wizard_step_viewed` and `wizard_abandoned` with the step index. A tip that is mostly dismissed unread, or a wizard step where most users leave, is a finding for rung 1.

## 8. Verification

| Check | How |
|-------|-----|
| Behaviour | Widget tests: wizard back keeps answers and goes one step back (`handlePopRoute`); Change returns to review; a tip shows once, one at a time, and is recallable |
| Accessibility | The four `meetsGuideline` checks on every step and on a visible tip, light and dark (ACCESSIBILITY_STANDARD §3) |
| Visual | Review renders of every step, the review page and each tip, at every size class, both brightnesses and 200% text, looked at (`resources/visual-review.md`) |
| Ladder | The plan in SPEC §4 records rung 1's answer for every piece of guidance |

## 9. Anti-patterns

- A feature carousel on first launch. A "Welcome! Here's what's new" chain of five tips.
- A tour added to explain a screen instead of fixing it.
- "Next" / "Back" / "Finish" as the only button labels in a wizard; a back gesture that exits the wizard and discards input.
- A wizard for a three-field form a user fills in every day.
- Tips styled exactly like buttons; tips that cover the control they explain; tips that cannot be found again.
- Guidance state kept in the widget, so it resets on rebuild or reappears after every restart.
- Permission prompts stacked at launch "to get them out of the way".

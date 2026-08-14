---
name: flutter-a11y
description: >-
  Audit Flutter UI against the WCAG 2.2 AA baseline and author automated
  accessibility tests - semantics, focus order, tap targets, contrast, text
  scaling, screen-reader traversal, motion sensitivity and platform a11y
  services. Use for accessibility, screen reader support, contrast, tap
  targets, semantics, or a11y tests.
---

# flutter-a11y

Accessibility is a correctness property, not a polish item: an app that a screen-reader user cannot operate is broken for that user in the same way a crash is. This skill makes the requirement concrete and testable.

**Pairs with:** `flutter-test` (writes the assertions), `flutter-verify` (D12), `flutter-feature-spec` (§12 is the source), `flutter-release` (R4 gate), `FLS-10 accessibility and inclusivity`.

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`ACCESSIBILITY_STANDARD`](../../standards/20260801-ACCESSIBILITY_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Automated checks are necessary and insufficient.** They catch contrast, tap-target size and missing labels. They cannot judge whether a label is *meaningful*, whether the reading order makes sense, or whether an interaction is discoverable. Report both what was automated and what still needs a human with a screen reader.
2. **Every interactive element is reachable and labelled.** If it can be tapped, it must be focusable, announced with a meaningful name, and expose its role and state.
3. **Never solve a contrast failure by removing the text or disabling the check.**
4. **Test at 200% text scale.** Most real-world accessibility failures in Flutter are layout overflows at large text, and they are trivially preventable.
5. **Decorative is a decision, not a default.** An image or icon is either labelled or explicitly excluded from semantics. Silence by omission is a defect.
6. **Never claim a screen-reader result without running one.** Report `not run (manual verification required)` and name what to check.

---

## Modes

| Mode | Action |
|------|--------|
| `audit [target]` | Read-only: static analysis + automated guideline checks against the baseline |
| `test - <target>` | Author automated accessibility tests for a widget or screen |
| `traverse - <route>` | Produce the manual screen-reader traversal script for a human to run |
| `contrast [target]` | Check color pairs in the theme and in the changed widgets |
| `scale [target]` | Check layout at 100%, 150% and 200% text scale |
| `status` | Read-only: coverage of a11y tests, last audit, outstanding findings |

---

## The baseline

WCAG 2.2 level AA, expressed as Flutter-checkable rules. Deviations must be recorded in doc 02 §6 with a reason.

| # | Rule | Target | How it is checked |
|---|------|--------|-------------------|
| A1 | Text contrast | ≥4.5:1 normal, ≥3:1 large (≥18pt, or ≥14pt bold) | Automated guideline check + theme color-pair analysis |
| A2 | Non-text contrast | ≥3:1 for interactive boundaries, icons conveying meaning, focus indicators | Manual + theme analysis |
| A3 | Tap target size | Platform minimum (Android ≥48dp, iOS ≥44pt) including spacing | Automated guideline checks |
| A4 | Every interactive element labelled | A meaningful name, not "button" or the icon's code point | Automated (presence) + manual (meaningfulness) |
| A5 | Role and state exposed | Toggle, selected, expanded, disabled, busy states announced | Semantics tree inspection |
| A6 | Focus order matches visual order | Logical traversal, no traps | Manual traversal + semantics ordering |
| A7 | Text scaling to 200% | No clipping, no overflow, no lost content or actions | Widget tests at each scale |
| A8 | Dynamic content announced | Loading, error, success and validation changes reach the screen reader | Live-region semantics; manual confirmation |
| A9 | Color is not the only signal | Errors, status and selection also carry text, icon or shape | Manual review |
| A10 | Motion respects the OS setting | Reduced-motion preference honoured; no unavoidable parallax or autoplay | Code check + manual |
| A11 | Forms accessible | Label associated with field, error announced and linked, required state exposed | Widget tests + manual |
| A12 | Images and icons classified | Every one is labelled or explicitly excluded from semantics | Static scan |
| A13 | No keyboard/switch trap | Every surface is exitable by the platform's mechanism | Manual |
| A14 | Screen orientation and reflow | Content usable in the orientations doc 02 declares, without loss | Widget tests |

---

## audit protocol

1. **Scope.** A named target, or the changed screens in the current diff. State the scope.
2. **Static scan** of the target widgets:

| Check | Finding |
|-------|---------|
| `GestureDetector` / `InkWell` on a non-semantic widget | Tappable but not announced — needs a semantics wrapper or a semantic widget |
| `Image` / `Icon` with no label and no explicit exclusion | Unclassified (A12) |
| An icon-only button with no tooltip or label | Unlabelled control (A4) |
| A hardcoded color literal in a widget | Cannot be contrast-checked centrally; route to THEMING_STANDARD (and a UI_CRAFT_STANDARD §4 hygiene finding) |
| A fixed-height container holding text | Overflow risk at large scale (A7) |
| `Text` with a hardcoded small font size | May fail A1 large-text thresholds and ignore user scaling |
| A custom control with no semantics | Invisible to assistive technology (A4, A5) |
| Animation with no reduced-motion check | A10 |
| An error shown only by color | A9 |

3. **Automated guideline checks** — run the framework's accessibility guideline assertions for tap targets (both platforms), labelled tap targets, and text contrast against the target widget. Report each guideline's result with the widget it failed on.
4. **Theme contrast analysis** — compute the ratio for every foreground/background pair the theme defines, in both light and dark. Report every pair below threshold with its ratio and the smallest change that would fix it.
5. **Text-scale check** — render at 100%, 150% and 200% and report overflow or clipped content.
6. **Name what remains manual** — meaningfulness of labels, traversal order, discoverability, announcement of dynamic changes. Produce the `traverse` script for them.

---

## test protocol

Author tests that make the baseline enforceable in CI:

| Test | Asserts |
|------|---------|
| Guideline suite per screen | Tap-target size (both platforms), labelled tap targets, text contrast |
| Semantics assertions | Each interactive element has the expected label, role and state |
| Text-scale tests | The screen renders without overflow at 150% and 200% |
| Focus-order test | Traversal visits elements in the intended order |
| Live-region test | A state change emits the expected announcement |
| Form test | Field labels associated; validation errors announced and linked |

Place them alongside the widget's other tests. They run in the normal suite, so a regression fails the build rather than being discovered in review.

---

## traverse protocol

Automated checks cannot judge sense. Produce a script a human runs with the platform screen reader:

```markdown
## Screen-reader traversal — <route>

**Run with:** TalkBack (Android) / VoiceOver (iOS)
**Device:** <the reference device>

| # | Action | Expected announcement | Actual | Pass |
|---|--------|----------------------|--------|------|
| 1 | Open the screen | "<screen name>, heading" | | |
| 2 | Swipe right | "<first element>, <role>" | | |
| … | | | | |
| n | Trigger the error state | The error is announced without a manual swipe | | |

### Judgement questions (a human must answer)
- Does the reading order match how a sighted user scans this screen?
- Is every label meaningful out of context? ("Submit" vs "Button 3")
- Can the primary task be completed without sight?
- Is anything announced twice, or announced that should be silent?
- Are loading and error changes announced without the user hunting for them?
```

---

## Report shape

```markdown
## @flutter-a11y audit

**Scope:** <screens> · **Baseline:** WCAG 2.2 AA · **Deviations on record:** <doc 02 §6 or none>

| Rule | Result | Detail |
|------|--------|--------|
| A1 contrast | fail | `onSurfaceVariant` on `surface` = 3.8:1 (needs 4.5:1) |
| A3 tap targets | pass | guideline checks pass on 12 targets |
| A6 focus order | not run | manual traversal required — script generated |

**Automated:** <n> rules · **Manual required:** <n> rules
**Findings:** <n> (<n> blocking on P0 screens)

### Route
| Finding | Run next |
|---------|----------|
| A1 contrast pair | `@flutter-repair repair - from a11y` |
| A6 traversal | Run `@flutter-a11y traverse - /cart` with a human |
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Anti-patterns

- Declaring a screen accessible because the automated checks passed.
- Labelling a control "button" or with its icon name.
- Fixing contrast by lightening text until the checker passes and it becomes unreadable in sunlight.
- Excluding an informative image from semantics to silence a warning.
- Testing only at 100% text scale.
- Announcing every decorative element.
- Wrapping a whole screen in one semantics node, flattening its structure.
- Claiming screen-reader verification that was not performed.
- Treating a11y as a milestone at the end rather than a per-screen gate.
- Hardcoding colors so the theme cannot be contrast-audited.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Scope stated | pass/fail | |
| 2 | SPEC §12 read for the target | pass/skip | |
| 3 | Static scan run across all nine patterns | pass/fail | |
| 4 | Automated guideline checks run; results per guideline | pass/fail/not run | |
| 5 | Theme contrast pairs computed, light and dark | pass/skip | ratios |
| 6 | Text-scale check at 150% and 200% | pass/skip | |
| 7 | Manual-only rules named, not silently passed | pass/fail | |
| 8 | Traversal script produced when manual work remains | pass/skip | |
| 9 | Screen-reader claims only when actually run | pass/fail | |
| 10 | Deviations from the baseline recorded in doc 02 §6 | pass/skip | |
| 11 | Findings routed | pass/fail | |

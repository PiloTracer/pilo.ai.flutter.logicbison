# Accessibility standard

> **Not templated.** WCAG 2.2 AA is the baseline for every project. A project may add requirements; it may not lower these without a recorded, approved waiver naming the excluded users.

**Owned by:** `@flutter-a11y` · **Enforced by:** `@flutter-verify` D12, concept FLS-10.

Accessibility is a functional requirement with legal weight in most markets (EN 301 549, ADA, Section 508, the European Accessibility Act). It is also the single most commonly deferred requirement, and deferral compounds: retrofitting semantics into a finished screen costs several times what building it in costs.

---

## 1. Baseline: WCAG 2.2 AA, applied to Flutter

| Guideline | Flutter requirement |
|-----------|---------------------|
| 1.1.1 Non-text content | Every meaningful image, icon and chart has a semantic label. Decorative graphics are explicitly excluded from the tree |
| 1.3.1 Info and relationships | Headings, lists, form-field/label associations, and grouping expressed in the semantics tree — not implied by layout |
| 1.4.3 Contrast | Normal text ≥ 4.5:1; large text (≥18pt, or ≥14pt bold) ≥ 3:1 |
| 1.4.4 Resize text | Usable at 200% text scale with no loss of content or function |
| 1.4.10 Reflow | No horizontal scrolling at 320dp-equivalent width |
| 1.4.11 Non-text contrast | UI component boundaries and state indicators ≥ 3:1 |
| 2.1.1 Keyboard | Every function reachable via keyboard or switch control (web, desktop, and external keyboards on mobile) |
| 2.4.3 Focus order | Traversal order matches visual and logical order |
| 2.4.7 Focus visible | A visible focus indicator on every focusable element |
| 2.5.5 Target size | Minimum 48×48 dp touch targets |
| 2.5.8 Target size (minimum) | 24×24 CSS px minimum with spacing — 48 dp remains the project floor |
| 3.2.2 On input | Changing a field value does not cause an unexpected context change |
| 3.3.1 Error identification | Errors identified in text, associated with the field, and announced |
| 3.3.2 Labels or instructions | Every input has a persistent visible label — placeholder text is not a label |
| 4.1.2 Name, role, value | Every custom control exposes its name, role and current state |
| 4.1.3 Status messages | Live-region announcements for async status changes |

---

## 2. Rules

**Every interactive element has an accessible label.** An icon button with no label is announced as "button" — unusable. The label describes the *action* ("Delete message"), not the icon ("trash can").

**Decorative is a decision, not a default.** Purely decorative imagery is explicitly excluded from the semantics tree so it is skipped. Leaving it unlabelled is not the same as excluding it.

**Merge composite widgets.** A card whose title, subtitle and icon are three separate stops forces the user through three swipes for one item. Merge into one node with one coherent label.

**State is announced, not implied.** Selected, expanded, checked, disabled, busy — every state a sighted user perceives visually must exist in the semantics tree.

**Announce dynamic changes.** Loading finished, an error appeared, an item was removed: a live-region announcement, or the change is invisible to a screen-reader user.

**Focus is managed at every transition.** Opening a dialog moves focus into it, closing returns focus to the trigger, and focus never escapes a modal.

**Never convey information by colour alone.** Error states carry an icon or text as well as red.

**Text scales.** Text sizes come from the theme and respond to the platform text-scale setting. Fixed font sizes, hard-coded heights around text, and `maxLines: 1` on important content all break at 200%.

**Contrast is not solved by removing text.** If a label fails contrast, change the colour — do not delete the label, shrink it, or move it into a tooltip.

**Announcements are localised.** A semantic label hardcoded in English is an accessibility failure in every other locale.

---

## 3. Testing

| Layer | Method | Catches |
|-------|--------|---------|
| Automated in widget tests | Flutter's accessibility guideline checks (tap target, contrast, labelled tappable) | Mechanical violations |
| Semantics assertions | Assert the expected semantics for each state | Missing labels, wrong roles, missing state |
| Text-scale tests | Render at 200%; assert no overflow | Layout breakage |
| Contrast check | Theme token pairs computed against the ratio table | Palette-level failures |
| **Manual screen reader** | TalkBack and VoiceOver traversal of each P0 flow | Everything automation cannot see |
| Keyboard/switch | Full traversal without touch | Trap and order defects |

**The automated guideline checks, by name.** `flutter_test` ships four. Every P0 screen gets a widget test that runs all four in each state the SPEC defines, in light and dark:

```dart
testWidgets('checkout meets the a11y guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(buildApp(home: const CheckoutScreen()));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline)); // 48x48
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));     // 44x44
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline)); // tappable => labelled
  await expectLater(tester, meetsGuideline(textContrastGuideline));     // WCAG AA text
  handle.dispose();
});
```

Known limits, measured against the current stable `flutter_test`:

- The tap-target guidelines **skip nodes that touch the screen edge or a scrollable's edge**. A 20 px target in the top-left corner passed both of them; the same target centred failed both. A pass on an edge-anchored control is not evidence; measure that control with `tester.getSize`.
- `textContrastGuideline` measures rendered text against the pixels behind it. It cannot judge text over images or gradients reliably, and it never sees icons. Icon and graphic contrast (WCAG 1.4.11, 3:1) stays a theme-level check.
- Scale text with `TextScaler.linear(2)` in a `MediaQuery` override, never the deprecated `textScaleFactor`.

**Automated checks are necessary and insufficient.** They cannot tell you that a label is accurate, that the traversal order makes sense, or that a flow is completable without sight. Only a real screen-reader run answers those questions, and **a screen-reader result may never be claimed without having run one** — including which reader, which device, and which OS version.

---

## 4. Per-feature requirements

Every SPEC §12 states: the screen-reader traversal order, the label for every interactive element, the announcement for every async state change, focus behaviour on entry, exit and error, and any deviation with its justification. A SPEC whose §12 says "standard accessibility applies" has not specified anything.

---

## 5. Report shape

State the guidelines checked, the method used for each, the findings with location and remedy, what was verified manually and on which device and reader, and — explicitly — what was **not** verified. An accessibility report that does not distinguish automated from manual coverage overstates its confidence.

---

## 6. Anti-patterns

- Unlabelled icon buttons.
- Placeholder text used as the only label.
- Fixed heights around scalable text.
- Colour-only error indication.
- `maxLines: 1` with `TextOverflow.ellipsis` on content the user needs.
- Custom controls that expose no role or state.
- Focus escaping a modal.
- Every card element as a separate traversal stop.
- Hardcoded English semantic labels.
- Deferring accessibility to a "polish milestone" that never gets scheduled.
- Claiming a screen-reader pass without running one.

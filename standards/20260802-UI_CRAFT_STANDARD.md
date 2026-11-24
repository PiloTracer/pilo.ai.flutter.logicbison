# UI craft standard — template

> **Template.** Copied to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-UI_CRAFT_STANDARD.md`. Governs the visible quality of shipped UI. If UI Design OS (`.ai.ui`) is installed, its design tokens remain the source of truth — this standard governs how Flutter **consumes** them; where no design system exists, these rules are the defaults. See [`COHABITATION.md`](../COHABITATION.md).

**Pairs with:** [`THEMING_STANDARD`](20260801-THEMING_STANDARD.md) (where the tokens live), [`ACCESSIBILITY_STANDARD`](20260801-ACCESSIBILITY_STANDARD.md) (contrast, targets, focus), [`FEATURE_SPEC_STANDARD`](20260801-FEATURE_SPEC_STANDARD.md) (§5 records the decisions this standard requires). Evidence base with sources: [`resources/ui-craft.md`](../resources/ui-craft.md). Reviewed by FLS-13; enforced in code by `dart-hygiene-check.sh`; audited as `@flutter-verify` D15.

---

## 1. Why craft is a gate, not a polish nicety

Users judge credibility by visual design before they read a word: in the Stanford Web Credibility study (Fogg et al., 2002), "design look" was 46.1% of all credibility comments — the largest single factor. A screen that reads as "free template" is a product defect with the same blast radius as a wrong calculation: the client declines to buy. The good news is that the difference is mechanical. The three cheap signals — random spacing, no hierarchy, factory colours — are decisions with fixed numbers, and decisions with fixed numbers are enforceable.

This standard exists because none of it is artistic talent. It is applied like a linter.

---

## 2. Spacing rhythm

**Required:**

- Spacing values come only from the theme scale (THEMING_STANDARD §6 — default 4/8/16/24/32, multiples of 4 so every combination lands on one grid). A raw numeric literal in `EdgeInsets`, `SizedBox` or `Gap` outside `core/theme/` is a `dart-hygiene-check.sh` finding.
- A screen uses **at most `REPLACE:MAX_SPACING_VALUES_PER_SCREEN` (default 3) distinct spacing values**. Rhythm reads as intention; seven ad-hoc values read as disorder. The client does not count pixels but detects the difference.
- Grouping is expressed with spacing, not borders: related items closer than unrelated ones (Law of Proximity). Reach for a border only after spacing, background contrast and shadow have failed.

**Why it is enforceable:** when the scale lives in constants, `padding: 13` in a diff is visible to a reviewer and to the hygiene scan. Off the scale, a value needs a recorded reason; on the scale but from a literal, it is still a finding — a scale change must never mean editing forty widgets.

---

## 3. Hierarchy — one dominant element

**Required:**

- **Every screen has exactly one dominant element**, recorded in SPEC §5 together with the screen's single primary action. A screen for which nobody can name the most important thing is unfinished, not minimal — most ugly screens are ugly because that decision was never made.
- The dominant element renders at **`REPLACE:HIERARCHY_RATIO` (default 2.5) × the body text size** (honest range 2–3×; below 2× the contrast is not felt, above 3× it reads as a poster). Body text stays at the theme's body size.
- Everything else is subordinate: secondary values at body size, labels and captions at label sizes, from the `TextTheme` roles — never ad-hoc `fontSize:` literals, which the hygiene scan flags.

**Judgement call:** which element dominates is a product decision made per screen in the SPEC. The ratio is the heuristic; the decision is the requirement.

---

## 4. Colour and accent discipline

**Required:**

- **One accent** (`REPLACE:ACCENT_COLOR` — recorded decision; from the design system where one exists), and on any screen it appears in **exactly one place: the primary action**. If the accent is on the save button it is not also on the badge, the link and the chart. Six saturated colours on a one-task screen is the loudest cheap signal there is.
- Everything else is neutrals: a grey ramp (near-black to white, never pure black) carries text, secondary text, borders, backgrounds and separators — see THEMING_STANDARD §4.
- Semantic status colours (success, warning, error, info) are reserved for status, desaturated relative to the accent, and always paired with an icon or text — never colour alone (ACCESSIBILITY_STANDARD).
- **Factory palettes are forbidden in shipped UI.** A recognisably default palette (the stock Material blue, stock green/red) tells any client who has seen three apps that nobody made a colour decision. `Colors.<name>` constants outside theme files are a hygiene BLOCKER. Derive the scheme from the recorded seed; do not ship `ColorScheme.fromSeed(Colors.blue)` untouched.
- No more than **one saturated colour per screen** beyond desaturated semantic states.

---

## 5. Clarity for non-technical users

The bar is **self-evident, not self-explanatory**: a first-time, non-technical user completes the screen's task without instruction. Users scan; they do not read.

**Required:**

- One primary action per screen, and it is the biggest, most reachable target (Fitts). Secondary actions are visually subordinate.
- Choices are capped and chunked: no flat list of a dozen options; progressive disclosure over everything-at-once (Hick, Miller).
- Platform conventions are followed, not reinvented — navigation, back behaviour, pickers work the way the user's other apps work (Jakob). Divergences are enumerated in THEMING_STANDARD §9, not improvised per widget.
- Defaults are sensible and pre-filled; options are visible rather than memorised (recognition over recall).
- Destructive actions have undo or a clearly marked exit.
- Every element on the screen justifies its presence or is removed.

---

## 6. States and perceived performance

FEATURE_SPEC_STANDARD §6 defines the six states per surface; this section sets how well each must be executed. Numbers and sources: [`resources/ui-craft.md`](../resources/ui-craft.md) §6.

**Required:**

- Loading follows the thresholds: under ~1s show nothing (a spinner flash is worse); 2–10s a spinner for a single module or a skeleton for a full page; over 10s a determinate progress indicator.
- Skeletons mimic the real layout — placeholder shapes match the size of the content they stand in for.
- Error messages are plain language, adjacent to their source, with redundant cues (text + icon, never colour alone), state the problem and the fix, and match severity to surface (toast, banner, modal). No error codes, no jargon, no raw exception text — an error message that scares a non-technical user is a failed state.
- Empty states teach: what this screen holds, and the one action that fills it.
- Interactions acknowledge within ~400ms; where work takes longer, status is visible (NN/g heuristic #1).

---

## 7. Motion

**Required:**

- Durations and curves come from the motion tokens (THEMING_STANDARD §7); ad-hoc durations are unreviewable.
- Motion is felt as responsiveness, never noticed as animation: short, decelerating entrances; no gratuitous movement on static content.
- Reduce-motion is honoured (ACCESSIBILITY_STANDARD) — animations become instant or cross-fade.

---

## 8. The polish pass ("the last 30 centimetres")

Before a UI task or milestone is marked complete, run the polish pass over every touched screen, then run FLS-13:

1. Spacing: every value from the scale; ≤ the per-screen maximum.
2. Hierarchy: the SPEC §5 dominant element is unmistakably dominant at arm's length; ratio honoured.
3. Colour: accent on the primary action only; no factory palette; neutrals doing the rest.
4. States: all six per SPEC §6, executed per §6 of this standard — including the error copy read aloud.
5. Clarity: a non-technical user could name what to do here in five seconds.
6. Dark mode and 200% text scale checked, not assumed (THEMING_STANDARD §10, ACCESSIBILITY_STANDARD).
7. **Rendered, then looked at.** Steps 2, 3, 5 and 6 are judged from the renders in [`resources/visual-review.md`](../resources/visual-review.md) (size class × brightness × text scale, every SPEC state), never from reading the widget code. An agent without image input generates the renders and reports those steps `unverified`.
8. Copy: every label, button, dialog and message on the screen passes §10.

The pass is recorded in the iteration's Concept/NFR registry. "The logic is done, polish later" is how the last 30 centimetres never happen — polish is part of done, and it is what the client sees.

---

## 9. Design-system relationship

- With `.ai.ui` installed: tokens (palette, scale, type) come from the design system; this standard still governs consumption — one dominant element per screen, accent on the primary action only, states executed to this bar.
- Without it: this standard plus THEMING_STANDARD **are** the design decisions, recorded with `REPLACE:` tokens so they are reviewable and reversible.
- A conflict between a design-system token and this standard (e.g. a token palette with two competing accents) is a finding, routed per the standards precedence — never silently resolved.

---

## 10. Interface copy

Words are interface. A screen with perfect spacing and a button labelled "OK" under a question nobody can parse still reads as unfinished, and copy is the part a non-technical user actually reads. All copy lives in l10n ([`L10N_STANDARD`](20260801-L10N_STANDARD.md)); these rules govern what it says.

**Required:**

- **Buttons say what happens.** A specific verb, and an object where it helps: "Save changes", "Send invoice", "Delete 3 photos". Never "OK", "Yes", "Submit" or "Confirm" for an action that has a name. The primary button's label should make sense read alone, because that is how it is scanned.
- **Confirmation dialogs name the consequence and repeat the verb.** Title: "Delete 3 photos?". Body: what is lost and whether it can be undone. Buttons: "Delete" and "Cancel", never "Yes" and "No". A destructive verb uses the error role, never the accent.
- **Errors say what happened and what to do next,** in the user's terms (§6): "Couldn't save. Check your connection and try again", with the retry next to it. Never "Error", "Something went wrong" with no next step, "Oops", an exception class, a status code, or a stack trace.
- **Empty states have three parts:** what will appear here, why it is empty now, and the one action that fills it ("No invoices yet. Invoices you send appear here. [Create invoice]").
- **One term per concept, everywhere.** If it is a "project" on one screen, it is never a "workspace" on another. The glossary is foundation doc 04 §1.
- **Sentence case** for titles, buttons and labels unless the platform convention or the design system says otherwise. Title Case On Every Word reads as shouting and costs scanning speed.
- **Front-load the meaning.** The first two or three words of a label, list item or notification carry the point; users scan the left edge.
- **Numbers, dates, currency and plurals come from `intl`**, never string concatenation: "1 items" and "$1,000.5" are copy defects that show up in front of the client.
- **No blame and no jokes in failure paths.** "You entered an invalid date" becomes "Enter a date like 24/11/2026". Humour in an error message reads as indifference to the user who just lost work.

**Judgement call:** tone (formal or friendly) is a product decision recorded once in the SPEC or design system and applied everywhere. Mixed tone across screens is the finding, not either tone.

---

## 11. Anti-patterns

- Hand-tuned spacing values ("nudged until it looked OK") — the signature of undecided design.
- Ratio-1 hierarchy: title, number, labels and buttons all within a few pixels of each other.
- The accent colour on three elements at once; factory `Colors.blue` shipped; six saturated colours on one screen.
- Pure black text or pure black surfaces.
- Borders used where spacing would separate better.
- A spinner flashed for a 300ms load; a bare spinner for a 12s load; an error that says "Something went wrong" with no recovery.
- The primary action visually equal to destructive/cancel actions.
- Fixed `fontSize` that ignores platform text scaling.
- "Polish at the end" as a separate milestone — it is never scheduled, and the client saw the unpolished screen first.
- "OK" / "Yes" / "Submit" buttons; "Something went wrong" with no next step; one concept with two names.
- Hierarchy or dark mode "verified" by reading widget code, or by looking at a test render whose text is placeholder boxes.

# UI craft — distilled rules with sources

The difference between software that reads as "premium" and software that reads as "free template" is not artistic talent. It is a small set of mechanical decisions — spacing, hierarchy, colour, states, copy — made deliberately instead of by default. This file distils those decisions into numbers an agent can apply, each traced to a source that was verified when this file was written.

**Binding rules live in [`standards/20260802-UI_CRAFT_STANDARD.md`](../standards/20260802-UI_CRAFT_STANDARD.md).** Use this file for the rationale and [`ui-recipes.md`](ui-recipes.md) for general Flutter examples. [`desktop-surfaces.md`](desktop-surfaces.md) covers multi-section desktop workspaces. [`visual-review.md`](visual-review.md) explains how to inspect the result.

---

## 1. Why this is measurable, not taste

In the Stanford Web Credibility study (Fogg, Soohoo, Danielsen — Stanford Persuasive Technology Lab, 2002; 2,684 participants, 2,440 comments analysed), **"design look" was mentioned in 46.1% of all credibility comments** — the single largest factor, ahead of information structure (28.5%). People judge whether software is trustworthy largely by what it looks like, and they do it before reading anything. Cite it precisely: 46.1% of comments, not the looser "75% of users" variant that circulates online.

The aesthetic-usability effect (Laws of UX) is the same finding from the other direction: users perceive attractive interfaces as *more usable*, and tolerate friction in them better. Craft is not decoration on top of usability; it changes how usability is judged.

---

## 2. The three cheap signals

Three defects do most of the damage, and none requires design training to fix.

| Signal | Cheap version | Premium version |
|--------|---------------|-----------------|
| **Spacing** | Seven ad-hoc values on one screen (13, 5, 22, 8…), none of them a decision | A fixed scale (multiples of 4), few values per screen, stored as constants |
| **Hierarchy** | Everything ~the same size; the eye has no entry point | One dominant element per screen at 2–3× the body size |
| **Colour** | The library's default palette; six saturated colours fighting on a one-task screen | One accent + a neutral ramp; the accent marks the primary action only |

The client does not count pixels, but detects *rhythm*: random spacing reads as disorder, repeated spacing reads as intention. Hierarchy's real value is forcing the decision of what matters — most ugly screens are ugly because nobody made that decision. And "one accent" is not about inventing an original palette; it is about how many colours compete for attention (one) and where the accent appears (the primary action, nowhere else).

Because these are decisions with fixed numbers, they are reviewable: a `padding: 13` or a `Colors.blue` in a diff stands out — which is why `dart-hygiene-check.sh` flags them.

---

## 3. Spacing and layout numbers

| Rule | Number | Source |
|------|--------|--------|
| Base grid | 8dp; fine grid 4dp — all spacing multiples of 4 | Material Design 3, layout/spacing |
| Practical scale | 4 / 8 / 16 / 24 / 32 (48 for section breaks) | M3 grid + the cheap-signal rule |
| Values per screen | ≤ 3 distinct values | The cheap-signal rule; rhythm reads as intention |
| Window size classes | compact < 600dp · medium 600–839dp · expanded ≥ 840dp | M3 layout; Flutter adaptive guidance |
| Branch on | window size / `LayoutBuilder` constraints — **never** device type, never `MediaQuery.orientation` | Flutter adaptive best practices |
| Large screens | Text fields and boxes never full-width | Flutter adaptive best practices |
| Orientation | Never lock it; support both | Flutter adaptive best practices |
| Grouping | Spacing communicates grouping (Law of Proximity / Common Region) — related items closer than unrelated | Laws of UX |
| Borders | Prefer spacing, shadow, or contrasting background over borders | Refactoring UI ("use fewer borders") |

Flutter mechanics: the scale lives in a `ThemeExtension` (e.g. `AppSpacing`), not global constants — `ThemeExtension` participates in theme switching and interpolation; a global constant does not (Flutter `ThemeExtension` API docs; THEMING_STANDARD §3).

---

## 4. Typography and hierarchy

| Rule | Number | Source |
|------|--------|--------|
| Dominant-element ratio | 2–3× the body size; below 2× the contrast is not felt, above 3× it reads as a poster | Transcript heuristic — honest range, default 2.5; corroborated by HIG (Large Title 34pt vs Body 17pt ≈ 2×) and M3 (body-large 16 → headline-large 32 → display-large 57) |
| Dominant elements per screen | **One.** Choosing it is the decision that makes the screen | The cheap-signal rule |
| Type scale | Fixed named roles, never ad-hoc sizes — M3's 15 styles (display/headline/title/body/label) | M3 type-scale tokens |
| Body size | 16sp (`body-large`) on Material; 17pt body on iOS | M3, Apple HIG |
| Text floor | Never below 11pt/sp for readable content | Apple HIG typography |
| Weights | Body 400; the dominant element carries the heavy weight (700). Avoid thin/light weights at small sizes | Apple HIG |
| Scaling | Sizes must scale with the platform text setting; fixed sizes break at 200% (WCAG 1.4.4) | ACCESSIBILITY_STANDARD, HIG Dynamic Type |

Flutter mechanics: map roles to `TextTheme` and consume via `Theme.of(context).textTheme` — a `fontSize:` literal in a widget is unreviewable and is flagged by the hygiene check.

---

## 5. Colour

| Rule | Detail | Source |
|------|--------|--------|
| One accent | One primary/accent colour per product; on any screen it marks **the primary action only** — not the badge, the link *and* the chart | The cheap-signal rule; Apple HIG (tint reserved for interactive elements); Von Restorff effect (the one different element is what gets noticed and remembered) |
| Neutral ramp | 8–10 grey shades from near-black (never pure black) to white in steady increments — "you can't build anything with five hex codes" | Refactoring UI, *Building your color palette* |
| Semantic colours | A few accents reserved for states (destructive, warning, success), each paired with an icon or text — never colour alone | Refactoring UI; ACCESSIBILITY_STANDARD |
| By role, not hex | `primary`, `on-primary`, `surface`, `outline`, `error`… derived from one seed via tonal palettes; widgets consume roles, never raw values | M3 color roles; Flutter theming cookbook |
| Semantic neutrals stay semantic | Never repurpose `secondaryLabel`-style neutrals (e.g. separator colour as text colour) | Apple HIG color |
| Factory defaults | A recognisably default palette (the stock Material blue, stock green/red) signals "nobody decided". Derive from a chosen seed, adjust, record | The cheap-signal rule |
| Saturated colours per screen | ≤ 1 (plus desaturated semantic states) | The cheap-signal rule, "six focus points on a one-task screen" |

---

## 6. States, loading and perceived performance

The transcript's "remaining 20%" — with hard thresholds.

| Situation | Rule | Source |
|-----------|------|--------|
| Load < 1s | Show **nothing** — a flash of spinner is worse | NN/g, *Skeleton Screens* |
| Load 2–10s, single module | Spinner | NN/g |
| Load 2–10s, full page | Skeleton screen whose shapes mimic the real layout (line width ≈ text width, box size ≈ image size) | NN/g |
| Load > 10s | Determinate progress indicator — required, not optional | NN/g |
| Interaction pace | Sub-400ms response keeps the loop feeling fluid (Doherty Threshold) | Laws of UX |
| System status | Every async action shows visible status (heuristic #1) | NN/g heuristics |
| Error placement | Adjacent to the source, not dumped at the top of the form | NN/g error-message guidelines |
| Error indication | Redundant cues — text + icon + weight, never colour alone | NN/g |
| Error timing | No premature errors (e.g. on focus-out of an untouched field) | NN/g |
| Error copy | Plain language, no codes or jargon; state the problem and the fix; surface matches severity (toast vs banner vs modal) | NN/g |
| Empty states | Teach: what this screen holds, and the one action that fills it | NN/g heuristics #9/#10; Krug |

The six states themselves (loading, empty, partial, error, offline, success) are defined per surface in FEATURE_SPEC_STANDARD §6 — this table is how well each state must be executed.

---

## 7. Motion

| Rule | Number | Source |
|------|--------|--------|
| Durations | Tokens, tiered (short/medium/long), scaled to distance — never ad-hoc `Duration(ms: 237)` | M3 motion tokens; THEMING_STANDARD §7 |
| Easing | Standard curve `cubic-bezier(0.2, 0, 0, 1)`; entering elements decelerate, never ease-in | M3 motion |
| Reduce-motion | Honour the platform setting — animations become instant or cross-fade (WCAG 2.3.3) | THEMING_STANDARD; M3 |
| Flutter decision order | Implicit widgets (`AnimatedContainer`…) → `TweenAnimationBuilder` → explicit `AnimationController` (with `vsync`) | Flutter animations docs |
| Canonical patterns | Shared element = `Hero`; list add/remove = `AnimatedList`; staggered = overlapping tweens | Flutter animations docs |

Motion is seasoning: it should be felt as responsiveness, never noticed as animation.

---

## 8. Clarity for non-technical users

The bar: **self-evident, not self-explanatory** (Krug, *Don't Make Me Think*). Users scan; they do not read. Distilled to mechanics:

| Law / heuristic | Mechanical consequence |
|-----------------|------------------------|
| Fitts's Law | The primary action is the biggest, most reachable target on the screen |
| Hick's Law | Cap visible choices per screen; progressive disclosure over flat option lists |
| Jakob's Law | Use platform conventions (navigation, back behaviour, date pickers); do not invent patterns users must learn |
| Miller's Law | Chunk content into groups of ~5; one focal point at a time (supports the single dominant element) |
| Recognition over recall (NN/g #6) | Visible options over memorised commands; sensible defaults pre-filled |
| Aesthetic & minimalist (NN/g #8) | Every element justifies its presence or is removed |
| User control (NN/g #3) | Every destructive action has undo or a clearly marked exit |
| Consistency (NN/g #4) | Same word, same colour, same position for the same action, everywhere |

---

## 9. Sources (verified when written)

| Source | URL | Used for |
|--------|-----|----------|
| Flutter theming cookbook | https://docs.flutter.dev/cookbook/design/themes | `ColorScheme.fromSeed`, `TextTheme`, theme precedence |
| Flutter `ThemeExtension` API | https://api.flutter.dev/flutter/material/ThemeExtension-class.html | Custom tokens (spacing) the official way |
| Flutter adaptive best practices | https://docs.flutter.dev/ui/adaptive-responsive/best-practices | Size classes, no device checks, no orientation locks |
| Flutter animations | https://docs.flutter.dev/ui/animations | Implicit-first decision order, canonical patterns |
| Material Design 3 | https://m3.material.io (foundations/layout · styles/typography/type-scale-tokens · styles/color/roles · styles/motion) | Grid, type scale, colour roles, motion tokens. *JS-rendered pages: numbers cross-checked against secondary citations* |
| Apple HIG — layout, typography, color | https://developer.apple.com/design/human-interface-guidelines/ | Text-style hierarchy, semantic neutrals, single tint, 11pt floor |
| Laws of UX (Yablonski) | https://lawsofux.com/ | Fitts, Hick, Jakob, Miller, Von Restorff, Doherty, aesthetic-usability |
| NN/g — 10 usability heuristics | https://www.nngroup.com/articles/ten-usability-heuristics/ | Status visibility, plain-language errors, recognition over recall |
| NN/g — error-message guidelines | https://www.nngroup.com/articles/error-message-guidelines/ | Placement, redundancy, timing, severity-matched surface |
| NN/g — skeleton screens | https://www.nngroup.com/articles/skeleton-screens/ | <1s / 2–10s / >10s thresholds; skeleton shape fidelity |
| Refactoring UI — free previews | https://refactoringui.com/previews/building-your-color-palette/ | Palette shape: 8–10 greys, one primary, fewer borders. *Free previews only; the book is paid* |
| Stanford Web Credibility (Fogg et al., 2002) | https://simson.net/ref/2002/stanfordPTL.pdf (archived original) | 46.1% "design look" credibility figure |
| Don't Make Me Think (Krug) | https://sensible.com/ | Self-evident screens; users scan |

Deliberately excluded as unverified at write time: any specific vendor blog on Flutter design, and any talk title that could not be confirmed. Package recommendations (skeleton loaders, animation helpers) are **not** in this file — they are verified on pub.dev at time of use per the standing rule, and admitted only via `packages-2026.md`.

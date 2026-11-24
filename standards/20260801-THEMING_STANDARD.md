# Theming standard — template

> **Template.** Copied to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-THEMING_STANDARD.md`. If UI Design OS (`.ai.ui`) is installed, **its design tokens are the source** and this file records the Flutter binding only — see [`COHABITATION.md`](../COHABITATION.md).

**Pairs with:** [`ACCESSIBILITY_STANDARD`](20260801-ACCESSIBILITY_STANDARD.md) (contrast is a theme-level property), [`L10N_STANDARD`](20260801-L10N_STANDARD.md), [`UI_CRAFT_STANDARD`](20260802-UI_CRAFT_STANDARD.md) (how the tokens are consumed on screens).

---

## 1. Single source of truth

**Every colour, spacing value, radius, elevation, duration and text style comes from the theme.** A hardcoded `Color(0xFF...)`, `EdgeInsets.all(16)` or `TextStyle(fontSize: 14)` in a widget is a `@flutter-verify` finding.

The reason is not tidiness. Hardcoded values make dark mode a rewrite, make a brand change a month of work, and make contrast auditing impossible because there is no enumerable palette to audit.

Design system: `REPLACE:DESIGN_SYSTEM` (Material 3 unless recorded otherwise).

---

## 2. Token layers

| Layer | Example | Used by |
|-------|---------|---------|
| **Primitive** | `blue500 = #1D6FE0`, `space4 = 16` | Semantic layer only — **never** a widget |
| **Semantic** | `colorSurfaceElevated`, `spacingCardPadding` | Widgets |
| **Component** | `buttonPrimaryBackground` | That component only |

Widgets consume **semantic** tokens. A widget referring to `blue500` cannot be re-themed; a widget referring to `colorPrimary` can. This indirection is the whole value of a token system.

---

## 3. Structure

```
core/theme/
  app_theme.dart          # light + dark ThemeData construction
  color_scheme.dart       # seed / explicit ColorScheme per mode
  typography.dart         # TextTheme
  spacing.dart            # spacing scale as a ThemeExtension
  radii.dart              # corner radius scale
  durations.dart          # motion durations and curves
  component_themes.dart   # per-component theme overrides
```

Anything Material's `ThemeData` does not model — spacing, custom semantic colours, elevation semantics, brand-specific values — goes in a `ThemeExtension`, not a global constant. `ThemeExtension` participates in theme switching and interpolation; a global constant does not.

---

## 4. Colour

- Defined per mode. Dark mode is a **designed palette**, not an inverted light palette — inversion produces muddy greys and broken contrast.
- Every foreground/background pair in the scheme is contrast-checked against [`ACCESSIBILITY_STANDARD`](20260801-ACCESSIBILITY_STANDARD.md) §1 and the results are recorded. This check happens once at the theme level, which is why the theme must be the only source.
- Semantic status colours (success, warning, error, info) are defined for both modes, and each is paired with an icon or text — never colour alone.
- Where Material 3 dynamic colour is enabled (`REPLACE:DYNAMIC_COLOR`), the contrast check is re-run against generated schemes, because a user's wallpaper can produce a palette nobody reviewed.

---

## 5. Typography

- A named scale (display, headline, title, body, label — each with size variants) mapped to `TextTheme`.
- **Sizes are relative and scale with the platform text-scale setting.** Fixed `fontSize` that ignores scaling breaks at 200% and fails WCAG 1.4.4.
- Line height and letter spacing are part of the token, not per-call adjustments.
- Fonts: `REPLACE:FONT_FAMILY`, licensed for commercial use (`REPLACE:FONT_LICENSE`), with only the weights actually used bundled — every unused weight is dead weight in the download.
- Fonts are bundled, not fetched at runtime, unless a recorded decision says otherwise. Runtime font fetching means a flash of unstyled text and a dependency on the network for legibility.

---

## 6. Spacing, radius, elevation

- A single spacing scale (`REPLACE:SPACING_SCALE`, default 4/8/16/24/32 — multiples of 4, so every combination lands on the same grid). Values off the scale need a reason; a raw numeric literal in a widget is a hygiene finding ([`UI_CRAFT_STANDARD`](20260802-UI_CRAFT_STANDARD.md) §2).
- A radius scale, not per-widget guesses.
- Elevation is semantic (surface level), not a raw number per widget.

---

## 7. Motion

- Durations and curves are tokens. Ad-hoc `Duration(milliseconds: 237)` is unreviewable and inconsistent.
- **Respect the platform's reduce-motion setting**: when disabled, animations become instant or cross-fade. Motion sensitivity is an accessibility requirement (WCAG 2.3.3), not a preference.
- Default durations: `REPLACE:MOTION_FAST` / `REPLACE:MOTION_NORMAL` / `REPLACE:MOTION_SLOW` ms.

---

## 8. Dark mode and modes

- Both light and dark are first-class and both are tested. Every golden that matters has a dark variant.
- The mode follows the system by default, with an in-app override persisted per user where the SPEC asks for it.
- Assets that do not work on both backgrounds have a per-mode variant. A dark logo on a dark surface is invisible, and no amount of theming fixes an opaque PNG.

---

## 9. Platform adaptation

Record the choice: `REPLACE:PLATFORM_ADAPTATION` — Material everywhere, or adaptive per platform. Both are defensible; the failure mode is doing it inconsistently, so one screen feels native and the next does not. Where adaptive, the divergences are enumerated (dialogs, switches, scroll physics, navigation transitions, date pickers) rather than decided per widget.

---

## 10. Testing

- Widget and golden tests run in both light and dark.
- A contrast test asserts every semantic foreground/background pair meets the ratio, so a palette edit cannot silently break accessibility. On rendered screens, `meetsGuideline(textContrastGuideline)` (ACCESSIBILITY_STANDARD §3) checks text against what is actually behind it.
- A text-scale test at 200% asserts no overflow on primary screens.
- A lint or grep check fails the build on hardcoded colour literals and raw `EdgeInsets` numbers outside `core/theme/`.

---

## 11. Anti-patterns

- Colour, spacing or text-style literals in widgets.
- Primitive tokens referenced directly by widgets.
- Dark mode as an inverted light mode.
- Fixed font sizes.
- Global constants instead of `ThemeExtension`.
- Only light mode tested.
- Bundling every font weight.
- Ignoring reduce-motion.
- Contrast checked per screen instead of once at the palette level.

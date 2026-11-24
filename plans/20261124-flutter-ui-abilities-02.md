# Plan: model-independent Flutter and UI/UX abilities, round 2

## 1. Goal

Raise the quality of Flutter code and UI that **any** model produces under this framework, whatever its training cut-off and whether or not it can see images. Round 1 (`20260802-uix-quality-01.md`) shipped the craft rules: UI_CRAFT_STANDARD, FLS-13 and the spacing, palette and `fontSize` scans. Round 2 closes the gaps that remain between *knowing* those rules and *producing and proving* them.

## 2. Evidence: gaps measured on the tree as of 2026-11-24

Baseline: `framework-verify` 391 checks PASS, `self-test` PASS.

| Gap | Evidence |
|-----|----------|
| **Stale APIs.** Nothing in the framework names a single deprecated or removed Flutter API. Models trained on older code write them by default. | `grep` across skills, standards, resources and templates: 0 hits for `withOpacity`, `WillPopScope`, `textScaleFactor`, `MaterialState`, `withValues`, `PopScope`, `textScaler`. The installed stable SDK marks all of them `@Deprecated` (read from source, `scratchpad/deprecated.txt`: 491 deprecated declarations). `headline1`, `FlatButton` and `primaryVariant` no longer exist. |
| **Automated a11y checks are named but not taught.** ACCESSIBILITY_STANDARD §3 says "Flutter's accessibility guideline checks", but no file names the API. | 0 hits for `meetsGuideline` or `textContrastGuideline`. |
| **Rendered evidence has no recipe.** FLS-13 marks hierarchy and rhythm judged from code as `unverified`, but nothing tells an agent how to produce something to look at. | Probe: a test-rendered PNG without a font loader shows every glyph as a box. With the loader, light, dark and 200% text renders read correctly. |
| **No interface-copy rules.** Errors are covered (UI_CRAFT §6); button labels, dialogs, empty states and tone are not. | 0 hits for `microcopy` or `UX writing`. |
| **No verified exemplars.** The rules exist, but there is no working code for agents to pattern-match. | `resources/` has rules with sources and no code that consumes tokens. |

## 3. Changes

1. **`resources/flutter-api-currency.md` (new).** Stale → current table, every row verified against the installed SDK's `@Deprecated` source. Includes the how-to-check procedure (SDK grep, `dart fix --dry-run`, `deprecated_member_use` is a finding) and the under-used current APIs. No version numbers.
2. **`dart-hygiene-check.sh` stale-API scans.** Removed APIs are BLOCKER and deprecated ones MAJOR, each message naming the replacement. Only patterns that are unambiguous without type information are scanned; the rest are left to the analyzer. New fixtures: `stale-api.dart` (must fail, every scan named) and `current-api.dart` (the replacements, must stay clean). Assertions go in `self-test.sh`.
3. **Adopter contract.** An API-currency rule goes in `templates/cursorrules.flutter.snippet.template`: check the SDK, never memory, and never invent a third name.
4. **Automated a11y guidelines.** ACCESSIBILITY_STANDARD §3 names the four `meetsGuideline` matchers with a minimal test and the edge-skip caveat (probe: a 20px target flush with the screen edge passes; the same target centred fails). Wired into `flutter-a11y`.
5. **Visual review renders: `resources/visual-review.md` (new).** A proven test helper renders each screen across size class × brightness × text scale to `build/visual_review/`, with real fonts. Vision-capable agents inspect the PNGs; others report `unverified`. Wired into `flutter-test` (a `render` mode), FLS-13 Q19 and UI_CRAFT §8.
6. **Interface copy:** UI_CRAFT_STANDARD gains §10 (the old §10, anti-patterns, becomes §11). FLS-13 gains the matching questions.
7. **`resources/ui-recipes.md` (new).** Token-consuming exemplars: theme with a `ThemeExtension`, an adaptive navigation shell, a six-state screen, action hierarchy with a specific-verb confirm dialog, and reduce-motion. Every recipe is compiled and analyzed with `--fatal-infos` and passes the hygiene scan in a scratch app before it is published.
8. **Wiring:** `resources/README.md`, `scripts/README.md`, the router reference, the implementation reference, `.cursorrules` fixture table, CHANGELOG.

## 4. Out of scope

No new skill (each change has an existing home). No eval scenario this round: the existing `hygiene_clean` eval check runs the new scans on every scenario automatically, but a dedicated `stale-api` scenario with held-out acceptance tests is the recommended follow-up. No edits to known-bad fixtures.

## 5. Assumption ledger

- **Confirmed:** every catalog row against SDK source; the render helper and the guideline matchers by running them in a scratch copy of `evals/apps/base` (both pass; the negative probe fails as expected); the font-less render shows boxes.
- **Inference:** the stale patterns are the ones models emit most often. This rests on how common the APIs were in pre-deprecation code, not on a measured agent run.
- **Unknown:** the false-positive rate of the new scans on real adopter code. Mitigated by scanning only unambiguous patterns, the `current-api.dart` true-negative fixture, and MAJOR rather than BLOCKER severity for deprecations.

## 6. Completion gate

`framework-verify.sh` and `self-test.sh` both PASS with their tails quoted. Recipes and render helper compiled, analyzed and run with the output quoted. Nothing committed.

# Resources

Reference material skills read. Not standards (not binding) and not skills (no protocol) — lookup tables that keep recommendations accurate.

| File | Contents | Read by |
|------|----------|---------|
| [`packages-2026.md`](packages-2026.md) | Vetted free/OSS/commercial-use packages by problem, with licences | `flutter-stack`, `flutter-router`, `flutter-security` |
| [`flutter-cli.md`](flutter-cli.md) | Flutter and Dart commands, what output means, how to read failures | `flutter-doctor`, every executing skill |
| [`ui-craft.md`](ui-craft.md) | Visual-quality rules distilled with sources: spacing, hierarchy, colour, states, motion, clarity | `flutter-scaffold`, `flutter-implementation`, `flutter-verify`, FLS-13 |
| [`flutter-api-currency.md`](flutter-api-currency.md) | Removed and deprecated Flutter APIs that models still write, with the current replacement, each verified against SDK source; how to check any other API | `flutter-implementation`, `flutter-repair`, `flutter-doctor`, `dart-hygiene-check.sh` |
| [`visual-review.md`](visual-review.md) | Proven helper that renders screens to PNG (size class x brightness x text scale, real fonts) and the protocol for reviewing them | `flutter-test render`, `flutter-implementation`, `flutter-verify` D15, FLS-13 |
| [`guided-ux.md`](guided-ux.md) | Research behind GUIDED_UX_STANDARD (NN/g, GOV.UK, W3C WAI, Apple HIG), the Flutter building blocks, and verified wizard and contextual-tip recipes with their tests | `flutter-guidance` |
| [`ui-recipes.md`](ui-recipes.md) | Verified, token-consuming exemplars: theme, adaptive shell, six-state screen, action hierarchy and confirmation | `flutter-scaffold`, `flutter-implementation` |

---

## The standing rule

**Package names, versions and APIs are verified against pub.dev before they are recommended or written.** This is the detail most confidently reconstructed from memory and most frequently wrong: a plausible version that does not exist, an API that changed two majors ago, a licence that changed at 2.0.

The cost is asymmetric. Checking takes seconds; a wrong version produces a resolution failure, and a wrong API produces code that compiles in the author's head and nowhere else.

These files deliberately omit version numbers for the same reason — a document cannot stay current, so it should not pretend to.

---

## Upstream references

| Source | Use for |
|--------|---------|
| [Effective Dart](https://dart.dev/effective-dart) | Style, documentation, usage and design conventions — the baseline this framework extends |
| [Flutter API docs](https://api.flutter.dev) | Widget and framework behaviour. For *which* APIs exist, the installed SDK source wins: see `flutter-api-currency.md` |
| [pub.dev](https://pub.dev) | **The** source for versions, licences, platform support and maintenance |
| [Flutter performance docs](https://docs.flutter.dev/perf) | Profiling methodology |
| [Material Design](https://m3.material.io) | Component and interaction guidance |
| [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) | iOS layout, typography and colour guidance |
| [Laws of UX](https://lawsofux.com/) | The psychology laws behind clarity rules (Fitts, Hick, Jakob, Miller) |
| [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/) | Usability heuristics, error-message and skeleton-screen guidelines |
| [WCAG 2.2](https://www.w3.org/TR/WCAG22/) | Accessibility criteria behind the a11y standard |
| [OWASP MASVS](https://mas.owasp.org) | Mobile security verification standard behind the security standard |

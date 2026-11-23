# Testing standard — template

> **Template.** Copied to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-TESTING_STANDARD.md` with thresholds filled from foundation doc 03 §5 and `STACK.md`.

**Owned by:** `@flutter-test` · **Enforced by:** `@flutter-verify` D8, [`QUALITY_GATES`](20260801-QUALITY_GATES.md), concept FLS-12.

---

## 1. The pyramid

| Level | Share | Runtime | Tests |
|-------|-------|---------|-------|
| Unit | `REPLACE:UNIT_SHARE` (~70%) | ms | Domain logic, ViewModels, mappers, validators, failure mapping |
| Widget | `REPLACE:WIDGET_SHARE` (~20%) | ms–s | Rendering per state, interaction, semantics |
| Golden | `REPLACE:GOLDEN_SHARE` (~5%) | s | Visual regression on stable, high-value surfaces |
| Integration | `REPLACE:INTEGRATION_SHARE` (~5%) | min | Critical journeys on a real device or emulator |

The shape matters more than the numbers. An inverted pyramid — mostly integration tests — produces a suite that is slow, flaky, and gets disabled within two quarters.

---

## 2. What must be tested

Non-negotiable coverage, regardless of the percentage:

- Every acceptance criterion in an approved SPEC maps to at least one named test.
- Every domain rule and every validation rule.
- Every failure path: each typed failure produces the state and the surface the SPEC requires.
- **All six UI states** for every data-backed surface: loading, empty, partial, error, offline, success.
- Every mapper, with real captured payloads including missing fields, nulls, unknown enums and malformed input.
- Every migration, from every shipped schema version, run twice.
- Every guard and every deep-link shape.
- Every accessibility requirement the SPEC §12 states.
- Every regression: a bug fix without a test that fails before the fix is not a fix.
- Every behaviour change you do not fully own: a characterization test (or golden) that locks current observable output and passes on the old code before the change lands.

---

## 3. Test quality

**Behaviour, not implementation.** A test that asserts a private method was called breaks on every refactor and catches nothing. Assert observable outcomes: rendered output, returned values, emitted states, calls to boundaries the system does not own.

**Independent oracles.** When a SPEC defines a formula, expected values come from an independent source or a fixture — never by re-implementing the production logic in the test. Inject clock, randomness and ID generation the same way architecture requires one clock helper.

**Arrange–Act–Assert**, visibly separated. A test with the arrangement scattered through the assertions cannot be read at 3am.

**Names state the behaviour and the condition:** `emits ProfileError when the repository returns NetworkFailure`. Not `testProfile3`.

**One behaviour per test.** Five assertions about one outcome is fine; five unrelated outcomes is five tests, so the failure message says which one broke.

**No logic in tests.** A loop or conditional in a test means the test needs testing.

**Deterministic, always.** No real clocks, no real network, no real randomness, no `Future.delayed` as synchronisation, no dependence on test order or on the machine's locale, timezone or screen size. A flaky test is worse than no test: it trains the team to ignore red.

**No test is skipped without an owner and an expiry.** `skip:` with a bare reason is permanent by default.

---

## 4. Unit tests

- Pure functions and classes; every dependency faked or stubbed.
- Domain tests import nothing from Flutter.
- ViewModel tests assert the **state sequence**, not just the final state — a loading state that never appears is a real bug.
- Fakes over mocks where a fake is cheap: a fake repository with a real in-memory list catches more than a mock with recorded returns.

---

## 5. Widget tests

- `pumpWidget` with only the wrappers the widget genuinely needs.
- Use a shared `pumpApp` helper for theme, localisations and DI overrides.
- **Find by semantics or by key, not by string literal.** Finding by visible text breaks on every copy edit and is impossible in a localised app.
- Assert what the user perceives: visible text, enabled state, semantic labels — not internal widget properties.
- Test every state the SPEC defines, plus interaction: tap, scroll, input, focus, error recovery.
- `pumpAndSettle` never wraps an infinite animation. Prefer explicit `pump(duration)` where the timing is meaningful.

---

## 6. Golden tests

Powerful and dangerous: valuable on stable surfaces, a tax on volatile ones.

- **Deterministic setup or the goldens are useless:** fixed surface size, fixed text scale, a loaded test font (never the platform default), fixed theme, no animation, no network image, no real time.
- Goldens are generated **on one platform** — `REPLACE:GOLDEN_PLATFORM` — and CI runs them on the same platform. Font rasterisation differs between OSes; cross-platform goldens fail forever.
- One golden per meaningful variant: light, dark, large text, RTL, error state. Not one per pixel-level tweak.
- **Regenerating a golden requires visual review of the diff.** Blindly running the update flag turns a visual regression suite into a rubber stamp — this is the single most common way golden testing fails.
- A golden update in a diff is called out in the PR description with the reason.

---

## 7. Integration tests

- One test per critical user journey, named after the journey.
- Real app, real navigation, real local store. External network is stubbed at the boundary unless the test is explicitly an end-to-end contract test.
- **The device is part of the result.** Report model, OS version and mode; a pass on one device is not a pass on all.
- Independent and idempotent: each test sets up and tears down its own state, and can run alone or in any order.
- Kept few. This is the level where slow, flaky suites are born.

---

## 8. Test doubles

Approach: `REPLACE:TEST_DOUBLES` (e.g. `mocktail`).

- Fake the **boundary**, never the system under test.
- Never mock a type you own when a real instance is cheap.
- Never mock a value object.
- Stub the minimum; over-stubbing encodes the implementation into the test.
- Verify interactions only where the interaction *is* the requirement (an analytics event was emitted, a payment was charged exactly once).

---

## 9. Coverage

- Floor: **`REPLACE:COVERAGE_FLOOR`%** line coverage on `lib/`, excluding generated files, `main.dart`, and pure DI wiring.
- Coverage is a floor, not a goal. 100% coverage with no assertions of behaviour is theatre.
- **Coverage must not decrease** in a PR. A drop is a gate failure.
- Untested code paths must be untestable-by-design (platform UI, third-party callbacks) and named as such.

---

## 10. Commands

Canonical commands live in `DOCS_FLUTTER_STACK.md`. Every skill quotes real output; no result is ever reported without a run.

| Purpose | Command |
|---------|---------|
| All tests | `REPLACE:TEST_CMD` |
| One file | `flutter test <path>` |
| Coverage | `REPLACE:COVERAGE_CMD` |
| Update goldens | `flutter test --update-goldens` (with review) |
| Integration | `REPLACE:INTEGRATION_CMD` |

---

## 11. Anti-patterns

- Asserting implementation details or private calls.
- Finding widgets by user-visible string literals.
- Non-deterministic setup in a golden test.
- Regenerating goldens without reviewing the diff.
- `pumpAndSettle` on an infinite animation.
- Real network, real clock or real randomness in a unit or widget test.
- Tests that depend on execution order or shared mutable state.
- A skipped test with no owner and no expiry.
- Weakening an assertion to make a test pass.
- A bug fix without a regression test.
- Chasing a coverage number with assertion-free tests.

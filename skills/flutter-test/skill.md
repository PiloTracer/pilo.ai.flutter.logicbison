---
name: flutter-test
description: >-
  Plan, author and run Flutter tests across the pyramid - unit, widget, golden
  and integration - with deterministic golden setup, coverage enforcement and
  test doubles matching the locked stack. Use for write tests, what should I
  test, golden tests, raise coverage, or run the suite.
---

# flutter-test

Tests are the only mechanism by which a claim about behaviour becomes evidence. This skill decides what to test, writes it in the project's idiom, and runs it honestly.

**Pairs with:** `flutter-implementation` (its task gate runs these tests), `flutter-verify` (D8 audits them), `flutter-stack` (K7 decides the doubles), `flutter-a11y` (a11y assertions), `flutter-perf` (performance traces).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`TESTING_STANDARD`](../../standards/20260801-TESTING_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never report a test result you did not observe.** No toolchain or device → `not run (<reason>)` and route to `@flutter-doctor env`. A fabricated green suite is the worst possible output of this skill.
2. **Test behaviour, not implementation.** Assert what the user or caller observes. A test that breaks on a harmless refactor is a liability.
3. **Never weaken a test to make it pass.** Deleting an assertion, adding `skip:`, or widening a matcher to accommodate a bug is falsification. Fix the code, or record the failure.
4. **Determinism is mandatory.** No real network, no real clock, no real randomness, no `Future.delayed` as synchronisation. Flaky tests get quarantined and fixed, never re-run until green.
5. **Goldens are deterministic or they are disabled.** Fixed surface size, loaded test fonts, no platform-dependent rendering. Goldens are regenerated deliberately and the diff is reviewed — never `--update-goldens` to make CI pass.
6. **Coverage is a floor, not a goal.** 100% coverage of getters proves nothing. The six UI states, every error path, and every business rule matter more than the percentage.

---

## Modes

| Mode | Action |
|------|--------|
| `plan` | Derive the test plan for a milestone or SPEC: what to test at which level, and why |
| `unit - <target>` | Author unit tests (domain logic, mappers, view models, repositories) |
| `widget - <target>` | Author widget tests, including all six states |
| `golden - <target>` | Author golden tests with deterministic setup |
| `integration - <flow>` | Author an integration test for an end-to-end flow |
| `a11y - <target>` | Author accessibility assertions (delegates the audit to `@flutter-a11y`) |
| `run [target]` | Execute tests; report real counts and failures |
| `coverage` | Run with coverage, compute the figure, compare to the floor, list the biggest gaps |
| `goldens - update` | Regenerate goldens; requires an explicit reason and a reviewed diff |
| `status` | Read-only: test inventory, coverage, quarantined tests, missing mirrors |

---

## The pyramid

| Level | Proportion | Tests | Speed |
|-------|-----------|-------|-------|
| **Unit** | ~65% | Domain entities and invariants, value objects, mappers, view-model state transitions, repository logic with faked sources, failure mapping, utilities | ms |
| **Widget** | ~25% | A widget or screen in isolation: all six states, user interaction, conditional rendering, form validation, navigation triggers | tens of ms |
| **Golden** | ~5% | Visual regression on stable, high-value surfaces: design-system components, each of the six states for P0 screens | tens of ms |
| **Integration** | ~5% | End-to-end flows on a real device or emulator: auth, the primary journey, deep-link entry, offline behaviour, persistence across restart | seconds |

**Test file mirrors source exactly.** `lib/src/features/cart/domain/cart.dart` → `test/features/cart/domain/cart_test.dart`. `@flutter-verify` D8 checks the mirror.

---

## plan protocol

1. Read the SPEC (§8 rules, §15 acceptance criteria, §6 states, §9 failures) and the milestone's plan §14 verification strategy.
2. Map each acceptance criterion to exactly one level — the **lowest** level that can prove it. Proving a domain invariant with an integration test is slow and fragile.
3. Enumerate the required cases:

| Source | Required tests |
|--------|----------------|
| Each business rule `R{n}` (SPEC §8) | A unit test asserting it, and one asserting its violation is rejected |
| Each of the six states (SPEC §6) | A widget test per state, per surface |
| Each failure mode (SPEC §9) | A unit test for the mapping, a widget test for the user-visible surface |
| Offline behaviour (SPEC §10) | An integration test with the network disabled |
| Each permission path (SPEC §11) | A widget test per path (granted, denied, permanently denied) |
| Each acceptance criterion (SPEC §15) | The test named in the criterion |
| Each NFR that applies | The measurement named in doc 03 §5 |

4. Output the plan as a table: `Case | Level | File | Priority | Covers`. Flag any acceptance criterion that cannot be tested — that is a SPEC defect, routed to `@flutter-feature-spec amend`.

---

## Authoring rules

### Unit

Arrange–act–assert, one behaviour per test, names that read as sentences (`returns NotFoundFailure when the server responds 404`). Group by the unit under test. Fakes and mocks per K7 in the lock. Prefer a hand-written fake for a small interface; use the mocking library for verification-heavy interactions. Never mock a type you own and can construct cheaply.

Async: use the framework's async utilities and fake time rather than real delays. Never synchronise with `Future.delayed`.

### Widget

Pump the widget with the minimum real dependencies and faked boundaries. Every test that renders a screen must be reachable from a state the view model can actually produce — testing an impossible state hides the real gap.

**All six states, every time.** Loading, empty, partial, error, offline, success. A widget test file for a screen with fewer than six state tests is incomplete; `@flutter-verify` D3 fails on it.

Interaction tests drive real gestures and assert observable outcomes, not internal calls. Settle deliberately: pump with explicit durations when animations are involved, and assert the intermediate frame when it matters.

### Golden

Deterministic setup is not optional:

| Requirement | Why |
|-------------|-----|
| Fixed surface size and device pixel ratio | Layout differs per size |
| Test fonts loaded (or the default test font used consistently) | The real font may be unavailable in CI |
| Animations disabled or pumped to completion | Mid-animation frames are non-deterministic |
| No real images or network | Placeholder or bundled fixtures only |
| Text scale explicitly set | The default varies |
| Theme explicitly set (light and dark as separate goldens) | Implicit theme resolution drifts |

Put shared setup in `flutter_test_config.dart` so every golden inherits it. Golden files are committed and reviewed as images; a golden diff in a PR is a design change and must be treated as one.

**Platform divergence:** goldens rendered on different host platforms can differ. Either pin CI to one host for golden generation, or scope goldens with a platform tag. Decide once, record it in TESTING_STANDARD, and never let the team disable goldens because CI is red.

### Integration

Runs on a real device or emulator. Cover the flows a broken build would embarrass you with: launch, auth, the primary journey, deep-link cold start, offline read, and persistence across a restart. Use realistic data. Assert user-visible outcomes.

**Report the device.** An integration result without a named device and OS version is not evidence.

---

## run / coverage / goldens-update

**`run`** — execute and report **real** numbers: total, passed, failed, skipped, duration. Quote every failure's name and message. Never summarise a failure as "a few tests failed".

| Target | Command |
|--------|---------|
| Everything | `flutter test` |
| One file or directory | `flutter test <path>` |
| One test by name | `flutter test --plain-name '<name>'` |
| Integration | `flutter test integration_test -d <device>` |
| Pure Dart package | `dart test` |
| Melos workspace | `melos exec -- flutter test` |

Failures are classified before any fix is proposed: code defect · test defect · SPEC gap · flake · toolchain. Route accordingly — only the first two are `@flutter-repair`'s.

**`coverage`** — `flutter test --coverage`, then compute the figure over `lib/src/` **excluding** generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`), generated l10n, and `main*.dart`. Compare to the project floor. Report the ten least-covered files with a line count, so the operator can see where the risk is rather than chasing a number.

Coverage below the floor is a `fail`. Never lower the floor to pass; if the floor is wrong, change it deliberately in the project standard with a recorded reason.

**`goldens - update`** — requires a stated reason. Regenerate with `--update-goldens`, then **show the diff** and ask for confirmation before treating it as intended. Updating goldens to silence a failure without reviewing the visual diff is how visual regressions ship.

---

## Anti-patterns

- Reporting a test result without running the tests.
- `skip:` or a commented-out test left in the tree without a tracked reason.
- Widening an assertion so a buggy value passes.
- `--update-goldens` to make CI green.
- Testing a widget's internal state instead of what renders.
- Real network, real clock, or real randomness in a test.
- `Future.delayed` as a synchronisation mechanism.
- Mocking a value object you could just construct.
- One test asserting six unrelated things.
- A screen test that covers only the success state.
- Chasing a coverage percentage with getter tests while error paths stay untested.
- Re-running a flaky test until it passes and moving on.
- An integration result with no device named.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected | pass/fail | |
| 2 | SPEC read; cases derived from §6/§8/§9/§15 | pass/skip | § refs |
| 3 | Each case at the lowest sufficient level | pass/fail | plan table |
| 4 | Test files mirror source paths | pass/fail | |
| 5 | All six states covered for touched screens | pass/fail | |
| 6 | Every failure mode has a test | pass/fail | |
| 7 | Doubles match the locked K7 choice | pass/fail | |
| 8 | Goldens deterministic (size, fonts, animation, theme) | pass/skip | config path |
| 9 | Tests executed; real counts reported | pass/fail/not run | counts |
| 10 | Failures classified before any fix | pass/skip | classes |
| 11 | Coverage computed with generated files excluded | pass/skip | % and floor |
| 12 | No test weakened, skipped or deleted to pass | pass/fail | |
| 13 | Integration results name the device and OS | pass/skip | |

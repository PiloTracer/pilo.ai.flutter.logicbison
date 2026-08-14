---
name: flutter-scaffold
description: >-
  Generate Flutter skeletons that conform to the locked stack and the project
  DIRECTORY_MAP - the app itself, feature modules, shared packages, build
  flavors, and CI workflows. Every generated tree compiles, analyzes clean and
  has a passing placeholder test before the skill reports success. Use for
  create the app, new feature module, add a package, add a flavor, or set up CI.
---

# flutter-scaffold

Structure decided once and generated consistently beats structure argued about in every PR. This skill turns `{FLUTTER_STACK_LOCK}` + the project DIRECTORY_MAP into real directories and files.

**Pairs with:** `flutter-stack` (the lock is the input), `flutter-foundation` (DIRECTORY_MAP comes from P3), `flutter-implementation` (fills the skeletons), `flutter-release` (consumes flavors and CI).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never scaffold before the stack is locked.** Generated code encodes idioms; guessing them creates a codebase nobody agreed to.
2. **Every generated tree must build.** Before reporting success: `flutter pub get`, `dart format`, `flutter analyze`, and `flutter test` on the placeholder test must all pass. No toolchain → generate, mark `unverified`, and route to `@flutter-doctor env`.
3. **Never overwrite existing source.** Existing paths are skipped and reported. `--force` requires an explicit operator instruction recorded in the report.
4. **Follow DIRECTORY_MAP exactly.** If the map and the request disagree, the map wins; if the map is wrong, fix the map first.
5. **Generate structure, not behaviour.** A scaffold contains wiring, a placeholder widget and a passing test — never invented business logic.
6. **No product decisions.** A scaffold that encodes a feature the foundation never approved is scope creep with a template.

---

## Modes

| Mode | Generates |
|------|-----------|
| `app` | The application: `flutter create`, directory tree, DI composition root, router, theme, flavors, analysis options, placeholder test |
| `feature - <slug>` | A feature module: `data/`, `domain/`, `presentation/` with the locked stack's idioms and a test mirror |
| `package - <name>` | A shared package under `packages/` (melos workspace if configured) |
| `flavor - <name>` | A build flavor across Dart entrypoint, Android and iOS |
| `ci` | A CI workflow running the same gates as `@flutter-verify gate` |
| `test-harness` | Shared test setup: `flutter_test_config.dart`, fixtures, golden helpers, fakes |
| `status` | Read-only: what exists, what conforms to the map, what is missing |

---

## Prerequisite gate (SC0)

```markdown
## @flutter-scaffold <mode> - blocked (prerequisite)

**Required:** `.work.flutter/STACK.md` with Status: Locked
**Detected:** <missing | Status: Draft>
**Run first:** `@flutter-stack probe` then `@flutter-stack set`
```

For `feature`, `package`, `flavor`, `ci` and `test-harness`, also require a resolvable `{APP_ROOT}` with `pubspec.yaml` → otherwise route to `app`.

---

## app protocol

### A1 — Confirm inputs

| Input | Source | Required |
|-------|--------|----------|
| Org identifier (`com.example`) | operator | yes |
| App name / package name | doc 01, `.cursorrules` | yes |
| Target platforms | doc 02 §1 | yes |
| Min iOS / min Android SDK | doc 02 §1 | yes |
| Monorepo (melos) or single package | `STACK.md` | yes |
| Flavors | doc 02 / operator (default: `dev`, `staging`, `prod`) | no |

Missing platform targets → **stop** and route to `@flutter-foundation continue` (P1). Do not default to "all platforms".

### A2 — Create the project

`flutter create` with the resolved org, project name and the exact platform list. Never generate platform folders the foundation excluded — removing them later is messy.

### A3 — Impose the directory tree

Per the project DIRECTORY_MAP. Default feature-first layout:

```text
lib/
├── main.dart                     # thin: runApp only
├── main_dev.dart                 # per flavor
├── main_staging.dart
├── main_prod.dart
├── bootstrap.dart                # error zone, logging, DI init, runApp
└── src/
    ├── app.dart                  # root widget: MaterialApp.router, theme, l10n
    ├── core/
    │   ├── config/               # AppConfig, flavor, environment
    │   ├── di/                   # composition root
    │   ├── error/                # failure types, error mapping
    │   ├── logging/
    │   ├── network/              # http client, interceptors
    │   ├── result/               # Result / typed outcome
    │   └── storage/              # local store bootstrapping
    ├── features/
    │   └── <feature>/
    │       ├── data/             # sources, DTOs, repository impl
    │       ├── domain/           # entities, value objects, repository interface
    │       └── presentation/     # view models, screens, widgets
    ├── routing/                  # router, routes, guards
    ├── theme/                    # ThemeData, colour scheme, typography, spacing/radii/duration tokens
    └── l10n/                     # ARB files and generated delegates
test/                             # mirrors lib/src exactly
integration_test/
```

Melos workspaces put apps under `apps/<app>/` and shared code under `packages/<pkg>/`, with the same internal shape.

### A4 — Wire the stack

Generate, per `{FLUTTER_STACK_LOCK}` and the matching [`stacks/`](../../stacks/) idiom file:

| Concern | Generated |
|---------|-----------|
| Entry | `bootstrap.dart` with a guarded zone, error handlers (`FlutterError.onError`, `PlatformDispatcher.instance.onError`), logging init, DI init |
| DI | The composition root in the locked style, wired but empty |
| Routing | Router config with a home route and a not-found route |
| Theme | Light and dark `ThemeData` from a single color-seed source, per THEMING_STANDARD — plus the craft wiring per UI_CRAFT_STANDARD: the spacing scale (4/8/16/24/32) as a `ThemeExtension`, a neutral grey ramp with **one** accent (never a stock `Colors.<name>` seed shipped untouched), semantic status colours, and a `TextTheme` with the dominant-element display style (~2.5× body) |
| l10n | `l10n.yaml`, a base ARB, and the generated-delegate wiring, when doc 02 requires localisation |
| Config | `AppConfig` read from `--dart-define`, one instance per flavor |
| Error | The project's failure type and the Result idiom from ARCHITECTURE_STANDARD |
| Analysis | `analysis_options.yaml` from the template, with generated files excluded |
| Test harness | `flutter_test_config.dart`, a golden helper, and one passing smoke test |

### A5 — Verify then report

Run `flutter pub get` → `dart format --set-exit-if-changed .` → `flutter analyze` → `flutter test`. All four must pass. Report the tree, the commands with exit codes, and the next command. End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

**Pub resolve discipline:** never pin `build_runner` (or any codegen driver) to "whatever pub.dev shows as latest" without resolving against the installed Flutter SDK. Flutter pins `meta` via `flutter_test`; a newer `build_runner` that needs a newer `meta` fails `pub get` before any code is wrong. If resolve fails, lower the codegen pin to the version `flutter pub add` suggests, record it in the scaffold report, and do not claim the stack lock's "seen on pub.dev" version is installable until `pub get` exits 0.

---

## feature protocol

Generate a module for `<slug>` that compiles and has a green test on the first run.

```text
lib/src/features/<slug>/
├── data/
│   ├── <slug>_remote_source.dart      # interface + impl per K5
│   ├── <slug>_local_source.dart       # only when the SPEC needs persistence
│   ├── dto/<slug>_dto.dart            # per K4; codegen annotations wired
│   └── <slug>_repository_impl.dart
├── domain/
│   ├── <slug>.dart                    # entity with invariants asserted
│   └── <slug>_repository.dart         # abstract interface
└── presentation/
    ├── <slug>_view_model.dart         # per K1 idiom
    ├── <slug>_screen.dart             # all six states stubbed and switchable
    └── widgets/
test/features/<slug>/                  # mirrors the above; one test per file
```

**The screen stub renders all six states** (loading, empty, partial, error, offline, success) behind the view model's state type. Generating only the success state is how apps ship without empty states.

Register the route (K2), the DI bindings (K3), and the test mirror. Then run the verify chain from A5, scoped to the new paths.

---

## package / flavor / ci / test-harness

**`package - <name>`** — `dart create -t package` (or `--template=plugin` for platform code), wired into the melos config when present, with `analysis_options.yaml` inheriting the workspace baseline, a README stating the package's single responsibility, and a passing test.

**`flavor - <name>`** — generate `lib/main_<name>.dart`, the Android product flavor (`build.gradle(.kts)` with an `applicationIdSuffix`), the iOS scheme and xcconfig, the `AppConfig` values, and the `--dart-define-from-file` config file. **Never put a secret in a flavor config file** — see SECURITY_PRIVACY_STANDARD § Build-time configuration.

**`ci`** — a workflow that runs exactly the gates `@flutter-verify gate` runs locally: setup with the pinned SDK, `pub get`, `dart format --set-exit-if-changed`, `analyze --fatal-infos`, `test --coverage`, the coverage threshold check, and the build for each target platform. Divergence between CI and the local gate is a defect in itself.

**`test-harness`** — `flutter_test_config.dart` (deterministic fonts and surface size for goldens), a golden comparison helper, fixture loaders, fakes for the locked stack's boundaries, and a `test/README.md` stating the conventions.

---

## status protocol

Read-only. Compare the actual tree against the DIRECTORY_MAP and report: conforming paths, missing scaffolding, non-conforming placements (a file in the wrong layer), features with no test mirror, and flavors that exist in Dart but not on a platform. Route each finding.

---

## Anti-patterns

- Scaffolding before the stack is locked.
- Reporting success without running `pub get`, format, analyze and test.
- Generating platform folders the foundation excluded.
- Generating a screen with only a success state.
- Inventing business logic inside a skeleton.
- Overwriting an existing file without an explicit instruction.
- Deviating from DIRECTORY_MAP because a different layout felt cleaner.
- A CI workflow whose commands differ from the local gate.
- Putting a real secret in a flavor config or `--dart-define` file.
- Creating a feature module with no test mirror.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | SC0 gate passed; stack lock read | pass/fail | |
| 2 | DIRECTORY_MAP read and followed | pass/fail | |
| 3 | Platform list from doc 02, not defaulted | pass/fail | |
| 4 | Existing files skipped, not overwritten | pass/fail | skipped list |
| 5 | Stack idioms match `stacks/<K1>.md` | pass/fail | |
| 6 | `flutter pub get` | pass/fail/not run | exit code |
| 7 | `dart format --set-exit-if-changed` | pass/fail/not run | exit code |
| 8 | `flutter analyze` clean | pass/fail/not run | exit code |
| 9 | `flutter test` placeholder green | pass/fail/not run | count |
| 10 | Test mirror created for new source | pass/fail | paths |
| 11 | Six states stubbed on generated screens | pass/skip | |
| 11b | Theme carries spacing tokens, one accent + neutral ramp (UI_CRAFT) | pass/skip | |
| 12 | No business logic invented | pass/fail | |
| 13 | No secrets in generated config | pass/fail | |

---
name: flutter-release
description: >-
  Prepare, certify, build and distribute Flutter release artifacts - flavors and
  environments, versioning, signing, obfuscation and symbol retention, size
  budgets, store metadata and privacy declarations, and CI/CD pipelines.
  Certifies release-ready only when every quality gate and audit is green. Use
  for ship it, build the app bundle, signing, store checklist, or release CI.
---

# flutter-release

Releasing is the moment every earlier shortcut becomes visible. This skill makes the release path repeatable and refuses to certify on unverified claims.

**Pairs with:** `flutter-verify` (milestone gate), `flutter-security` / `flutter-a11y` / `flutter-perf` (mandatory audits), `flutter-scaffold` (flavors and CI), `flutter-platform` (native config), `flutter-doctor` (build failures).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`RELEASE_STANDARD`](../../standards/20260801-RELEASE_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **`certify` is the only path to release-ready**, and it runs the real audits. A gate reported without its command output is `unverified`, and `unverified` blocks certification.
2. **Never handle real signing material.** Keys, keystores, provisioning profiles, API keys and store credentials are operator-held and CI-secret-injected. This skill writes *configuration that references* them, never the material itself, and never echoes a secret into a log or a report.
3. **Obfuscated builds must retain symbols.** `--obfuscate` without `--split-debug-info` to a retained, versioned location makes every future crash report useless.
4. **Version bumps are deliberate.** Build number strictly increases; version name follows the project's scheme. Never reuse a build number that reached a store.
5. **Release builds are verified as artifacts, not as debug runs.** Install and launch the actual release artifact before certifying.
6. **Store declarations must match reality.** Privacy labels, data-safety forms and permission justifications are generated from what the app actually does — SPEC §11 and doc 04 §5 — not from what is convenient.
7. **No secrets in the bundle.** `--dart-define` values are extractable from a shipped binary. Anything genuinely secret lives server-side.

---

## Modes

| Mode | Action |
|------|--------|
| `prepare` | Set up the release path: flavors, versioning, signing config, obfuscation, size budgets, CI |
| `certify` | Run every release gate; flip **release-ready** only on a clean pass |
| `build - <flavor> [platform]` | Produce the release artifact with the standard flags |
| `size` | Analyze artifact size against the NFR budget |
| `distribute - <channel>` | Publish to the configured channel; record what shipped |
| `metadata` | Generate/refresh store metadata, privacy declarations and release notes |
| `status` | Read-only: release configuration, last build, gate results, what is stale |

---

## prepare protocol

| Concern | Output |
|---------|--------|
| **Flavors** | Per doc 02 and `@flutter-scaffold flavor`: Dart entrypoints, Android product flavors with `applicationIdSuffix`, iOS schemes and xcconfigs, per-flavor `AppConfig` |
| **Versioning** | The scheme in `pubspec.yaml` (`version: x.y.z+build`), how the build number is derived in CI, and the rule for when each part increments |
| **Signing** | Android: `key.properties` referenced from `build.gradle(.kts)`, gitignored, values injected from CI secrets. iOS: automatic or manual signing, team id, provisioning profile names. **Configuration only** |
| **Obfuscation** | `--obfuscate --split-debug-info=build/symbols/<version>+<build>/`, with the retention location and the upload step to the crash reporter |
| **Shrinking** | R8/Proguard rules that preserve reflection targets and platform-channel classes; iOS bitcode/strip settings |
| **Size budget** | The NFR from doc 03 §5, plus the command that checks it |
| **CI** | A pipeline with the same gates as `@flutter-verify gate`, then build, then artifact upload |

**Gitignore audit** at the end of `prepare`: `key.properties`, `*.keystore`, `*.jks`, `*.p12`, `*.mobileprovision`, service-account JSON and any `--dart-define` file with real values must all be ignored. A tracked signing artifact is a `fail`, not a warning.

---

## certify protocol (RL0)

Run every gate. Quote the command and the exit code for each. **Any `fail` or `unverified` blocks certification.**

| # | Gate | Command / source | Blocks |
|---|------|------------------|--------|
| R1 | Milestone verification | `@flutter-verify milestone` | verdict `fail` |
| R2 | Full quality gate | `@flutter-verify gate` (format, analyze, test, coverage) | any non-zero |
| R3 | Security audit | `@flutter-security audit` + `deps` | any high finding |
| R4 | Accessibility audit | `@flutter-a11y audit` | any violation on a P0 screen |
| R5 | Performance budget | `@flutter-perf budget` | any NFR breached |
| R6 | Size budget | `size` mode | over the doc 03 §5 figure |
| R7 | No secrets in the bundle | `@flutter-security secrets` on the built artifact | any finding |
| R8 | Obfuscation + symbols retained | Build flags present; symbol directory exists and is archived | either missing |
| R9 | Version integrity | Build number > the last shipped build number | not increasing |
| R10 | Store declarations match reality | Permissions in the manifest/plist ⊆ SPEC §11; privacy labels match doc 04 §5 | any mismatch |
| R11 | Release artifact launches | Install the actual release build on a device per platform; complete one primary flow | crash, or `not run` |
| R12 | Crash reporting live | Symbols uploaded; a test crash is symbolicated | not verified |
| R13 | Rollback plan | Documented: staged rollout percentage, halt criteria, who decides | absent |
| R14 | Open blockers | No `high` unresolved item in `UNKNOWNS.md` or `RISK_REGISTRY.md` blocking release | any |

**Certificate:**

```markdown
## @flutter-release certify

| Gate | Result | Evidence |
|------|--------|----------|
| R1 milestone verify | pass | verdict: pass, 2026-08-01 |
| … | | |

**release-ready:** yes | no
**Blocking:** <gate ids or none>
**Version:** <x.y.z+build> · **Flavors certified:** <list>
**Symbols:** `build/symbols/<version>` archived to <location>
**Rollback:** <staged %, halt criteria, owner>

**Run next:** `@flutter-release build - prod` | <the blocking fix>
```

On pass, append `**Release-ready:** YYYY-MM-DD (<version>)` to `{FLUTTER_HANDOFF}`.

---

## build protocol

| Target | Command shape |
|--------|---------------|
| Android app bundle | `flutter build appbundle --flavor <f> -t lib/main_<f>.dart --release --obfuscate --split-debug-info=build/symbols/<v>` |
| Android APK (testing) | `flutter build apk --flavor <f> -t lib/main_<f>.dart --release --split-per-abi …` |
| iOS archive | `flutter build ipa --flavor <f> -t lib/main_<f>.dart --release --obfuscate --split-debug-info=build/symbols/<v> --export-options-plist=<path>` |
| Web | `flutter build web --release` (+ the project's renderer and base-href settings) |
| Desktop | `flutter build <macos\|windows\|linux> --release` |

Add `--dart-define-from-file=<flavor>.json` when the project uses it. **Take the authoritative commands from `DOCS_FLUTTER_STACK.md`** — they are pinned there per project.

After building: record the artifact path, byte size, version+build, the symbol directory, and the build's git SHA. Then run `size`.

Build failure → **do not** retry blindly. Route to `@flutter-doctor build` with the full error output.

---

## size / distribute / metadata

**`size`** — `flutter build <target> --analyze-size` (plus DevTools' size analysis for the treemap). Report total, the delta since the last recorded build, and the top contributors. Over budget → findings routed to `@flutter-perf` (assets, fonts, unused locales, uncompressed images) or `@flutter-stack audit` (a heavyweight dependency).

**`distribute`** — publish to the configured channel (internal test track, TestFlight, a self-hosted feed). Never uploads without `release-ready: yes`. Records version, build, SHA, channel, date and rollout percentage in `{FLUTTER_WORK_ROOT}/plans/operations/releases.md`.

**`metadata`** — generate release notes from the milestone's `Done this iteration` entries, plus store listing fields, and the privacy/data-safety declarations derived from doc 04 §5 (what is collected, why, whether it is linked to identity, whether it is shared) and SPEC §11 (permissions with justifications). Every declaration cites its source. A declaration you cannot cite is a declaration you should not make.

---

## Anti-patterns

- Certifying with a gate marked `not run`.
- `--obfuscate` without retained, archived symbols.
- Reusing a build number.
- Committing a keystore, `key.properties`, provisioning profile or service-account JSON.
- Echoing a secret into a build log or a report.
- Putting an API secret in `--dart-define` and calling it secure.
- Testing a debug build and shipping the release one.
- Copying privacy declarations from a previous app.
- Declaring a permission the app does not use, or using one it does not declare.
- Shipping at 100% rollout with no halt criteria.
- Blindly retrying a failed build instead of diagnosing it.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected; RL0 honoured for build/distribute | pass/fail | |
| 2 | All 14 certify gates evaluated; none skipped silently | pass/fail | table |
| 3 | Every gate's command and exit code quoted | pass/fail | |
| 4 | No signing material read, written or logged | pass/fail | |
| 5 | Gitignore audit clean | pass/fail | |
| 6 | Obfuscation flags present; symbols archived | pass/skip | path |
| 7 | Build number strictly increasing | pass/fail | previous → new |
| 8 | Release artifact installed and launched per platform | pass/not run | device |
| 9 | Size measured against the NFR budget | pass/fail | bytes vs budget |
| 10 | Store declarations traced to doc 04 §5 / SPEC §11 | pass/fail | citations |
| 11 | Rollback plan documented | pass/fail | |
| 12 | Release recorded in operations log | pass/skip | path |
| 13 | HANDOFF updated with the release-ready line | pass/skip | |

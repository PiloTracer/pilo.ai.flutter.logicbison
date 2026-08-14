---
name: flutter-doctor
description: >-
  Diagnose and resolve Flutter toolchain failures - environment and SDK issues,
  dependency version solving, Gradle and Android build errors, CocoaPods and
  Xcode failures, code-generation conflicts, and platform tooling. Classifies
  the failure before acting so application code is never edited to work around
  an environment problem. Never gated - always runnable. Use for it won't
  build, pub get fails, gradle error, pod install error, or flutter doctor.
---

# flutter-doctor

Most "the app is broken" reports are not code defects. This skill separates the toolchain layer from the code layer, so `@flutter-repair` never edits correct code to work around a stale cache or an SDK mismatch.

**Never gated.** Toolchain breakage must be diagnosable from any state, including a bare repo with no framework artifacts.

**Pairs with:** `flutter-repair` (code defects), `flutter-scaffold` and `flutter-release` (route build failures here), `flutter-stack` (dependency conflicts often trace back to the lock).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Command reference:** [`resources/flutter-cli.md`](../../resources/flutter-cli.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Classify before acting.** Read the actual error output first. Guessing the fix from the symptom is how an hour disappears.
2. **Never edit application code to work around a toolchain problem.** If the fix is in `lib/`, the classification was wrong.
3. **`flutter clean` is not a diagnosis.** It hides the evidence and often does not help. Use it only after the cause is understood, and say why.
4. **One change at a time, verified.** Changing four things and re-running proves nothing about which mattered.
5. **Never bump an SDK, dependency or Gradle version silently.** Version changes are consequential; propose them, state the risk, and record the reason.
6. **Preserve the reproduction.** Record the exact failing command and the first meaningful error line before changing anything — Flutter error output is long and the real cause is rarely at the bottom.
7. **Report what you could not verify.** No device, no network, no SDK → say so.

---

## Modes

| Mode | Action |
|------|--------|
| `diagnose` | Classify the failure and route to the targeted mode. **Start here** |
| `env` | Toolchain and environment: SDK versions, PATH, platform toolchains, licenses |
| `deps` | Dependency resolution, version conflicts, transitive constraints, lockfile state |
| `build - <platform>` | Platform build failures: Gradle/Android, CocoaPods/Xcode/iOS, web, desktop |
| `codegen` | `build_runner` conflicts, stale generated output, generator version mismatches |
| `clean - <scope>` | Targeted cleanup, least-destructive first, with a stated reason |
| `status` | Read-only: toolchain versions, project health snapshot |

---

## diagnose protocol

### D1 — Capture the reproduction

Record the exact command, the full output, and the **first** meaningful error line. In Gradle and CocoaPods output the real cause is usually near the top, buried under hundreds of lines of downstream noise; the last line is almost always a summary, not the cause.

### D2 — Classify

| Signal in the output | Class | Mode |
|----------------------|-------|------|
| `command not found`, `flutter` not on PATH, SDK path errors, `flutter doctor` warnings | Environment | `env` |
| `version solving failed`, "incompatible with", constraint conflicts, `pub get` failures | Dependencies | `deps` |
| `Execution failed for task`, AGP/Gradle/Kotlin/JDK version errors, `minSdkVersion` conflicts, R8 failures, manifest merger errors | Android build | `build - android` |
| `pod install` failures, CocoaPods repo errors, `Podfile.lock` conflicts, code-signing errors, deployment-target mismatches, missing simulators | iOS build | `build - ios` |
| `build_runner` conflicting outputs, stale `.g.dart`, generator/annotation version mismatch, `part` directive errors | Codegen | `codegen` |
| Compilation errors in `lib/`, analyzer errors, failing assertions in your own code | **Code — not this skill** | `@flutter-repair` |
| Test assertions failing on logic | **Code — not this skill** | `@flutter-repair repair - from test` |
| Works locally, fails in CI (or the reverse) | Environment divergence | `env` |
| Intermittent, no code change | Flake or cache | `clean` after classifying |

**Ambiguous output → run the cheap discriminators first:** `flutter doctor -v`, `flutter --version`, `dart pub deps`, and re-running the failing command with the toolchain's verbose flag.

### D3 — Report the diagnosis before fixing

```markdown
## @flutter-doctor diagnose

**Failing command:** `<exact command>`
**First meaningful error:** `<the actual cause line>`
**Class:** <class> · **Confidence:** high | med | low
**Why:** <the signal that decided it>
**Likely cause:** <one sentence>
**Proposed action:** `@flutter-doctor <mode>` — <what it will change>
**Risk:** <what could break>
```

Confidence `low` → run one more discriminator rather than guessing.

---

## env protocol

| Check | Command | Looking for |
|-------|---------|-------------|
| Toolchain health | `flutter doctor -v` | Missing components, licenses, toolchain versions |
| SDK versions | `flutter --version`, `dart --version` | Match against `DOCS_FLUTTER_STACK.md` and `pubspec.yaml` constraints |
| Channel | `flutter channel` | Unexpected channel is a frequent cause of "works on my machine" |
| Multiple SDKs | `which -a flutter`, version manager state | Two SDKs on PATH resolving differently per shell |
| Platform toolchains | `flutter doctor -v` detail | JDK version and location, Android SDK and build-tools, Xcode and command-line tools, CocoaPods version |
| CI parity | The workflow's setup step | A different SDK version than local — the classic CI divergence |

**Version mismatch handling:** report the required version, the found version, and the source of the requirement. Propose the change; do not apply an SDK switch without confirmation — it affects every project on the machine.

---

## deps protocol

1. `flutter pub get` and capture the resolution error verbatim.
2. `dart pub deps` (tree form) to see who requires the conflicting constraint — the conflict is almost always transitive, and blaming the direct dependency wastes time.
3. Identify the **actual** conflicting pair and the constraint each imposes.
4. Resolve in this order of preference:

| Order | Action | When |
|-------|--------|------|
| 1 | Loosen an over-tight direct constraint | The project pinned harder than necessary |
| 2 | Upgrade the direct dependency that requires the old transitive | An upgrade exists that resolves it |
| 3 | Upgrade the SDK constraint | The conflict is genuinely SDK-bound; needs confirmation |
| 4 | Replace the blocking package | It is unmaintained; route to `@flutter-stack audit` |
| 5 | `dependency_overrides` | **Last resort.** Requires a written justification and a removal condition — an override is unpinned technical debt that silently breaks later |

5. After resolution: `flutter pub get`, then `flutter analyze` and `flutter test`, because a transitive bump can change behaviour.
6. Report the constraint change, why, and what it risks. Never bump a major version without saying so.

**Lockfile:** apps commit `pubspec.lock`; libraries do not. A missing app lockfile is itself a finding.

---

## build protocol

### `build - android`

| Symptom | Usual cause | Action |
|---------|-------------|--------|
| Gradle/AGP/Kotlin/JDK incompatibility | A version quartet that does not line up | Identify the compatible set; change one, verify |
| `minSdkVersion` conflict | A plugin requires a higher minimum than the app declares | Raise the app minimum (**check doc 02 §1** — this changes the product's device support) or drop the plugin |
| Manifest merger failure | Two plugins declaring conflicting nodes | Read the merger report; add the specific `tools:` resolution |
| Duplicate class / dex limit | Overlapping transitive libraries | Exclude the duplicate; enable multidex only if genuinely needed |
| R8/Proguard failure or a release-only crash | Over-aggressive shrinking of reflection or channel targets | Add the specific keep rules; never disable shrinking wholesale |
| Gradle daemon or cache corruption | Stale state | Targeted Gradle clean, **after** classifying |

### `build - ios`

**Establish which dependency manager the project uses before triaging.** Current Flutter defaults iOS to **Swift Package Manager**, not CocoaPods, and the two produce entirely different failures. A `Podfile` in the tree does not settle it — projects migrating to SPM keep one for plugins that have not moved. Check whether the Xcode project resolves package dependencies, and check whether `pod install` is even part of the build. Applying CocoaPods remedies to an SPM failure wastes the session and changes files that were not the problem.

| Symptom | Usual cause | Action |
|---------|-------------|--------|
| SPM package resolution fails | Unreachable package URL, a version requirement no release satisfies, or a stale resolved-package cache | Read the resolution error; reset the package cache as a targeted step |
| A plugin is not found under SPM | The plugin has no SPM support yet and needs the CocoaPods fallback | Confirm the plugin's SPM status before changing project settings |
| `pod install` fails | Stale CocoaPods spec repo, or a Podfile constraint conflict | Update the repo; read the actual constraint conflict |
| Deployment target mismatch | A pod requires a higher iOS version than the Podfile declares | Raise the Podfile platform and the Xcode target together (**check doc 02 §1**) |
| Code signing | Missing profile, wrong team, expired certificate | **Operator action** — never handle signing material |
| Module not found after adding a plugin | Stale derived data or an unregenerated workspace | Regenerate; clean derived data as a targeted step |
| Simulator or architecture errors | Excluded architectures, or an Apple-silicon/Rosetta mismatch | Correct the excluded-architecture settings |
| Swift version | A plugin requiring a newer Swift than the project | Align the project's Swift version |

Always re-read the file you changed to confirm the edit landed as intended.

---

## codegen protocol

1. Identify the generator and its annotation package; confirm their versions are a compatible pair.
2. `dart run build_runner build --delete-conflicting-outputs` and read the **first** error.

| Symptom | Cause | Action |
|---------|-------|--------|
| Conflicting outputs | Stale generated files from a previous shape | `--delete-conflicting-outputs` |
| `part` directive mismatch | Filename and `part` statement disagree | Fix the `part` line |
| Generator produces nothing | Missing annotation, missing `part`, or the file is outside the configured build target | Check `build.yaml` include patterns |
| Version mismatch | Annotation and generator majors differ | Align both; regenerate |
| Analyzer/generator incompatibility | The generator does not support the current analyzer | Upgrade the generator, or pin the analyzer with a recorded reason |
| Very slow builds | Building the whole tree every time | Scope `build.yaml`; use `watch` during development |

3. After regeneration, confirm the generated files are committed. Stale committed output is a `@flutter-verify` Q4 failure.

---

## clean protocol

Least destructive first. **Every step states its reason and what it costs.**

| Level | Action | Costs | When |
|-------|--------|-------|------|
| 1 | Delete generated Dart output and regenerate | Seconds | Codegen inconsistency |
| 2 | `flutter clean` | Rebuild time | Stale Flutter build artifacts |
| 3 | Remove `pubspec.lock` and re-resolve | Version drift risk — **confirm first** | Resolution corruption |
| 4 | Platform-specific caches (Gradle, derived data, Pods) | Minutes to tens of minutes | Platform build corruption |
| 5 | Global tool caches | Very slow; affects other projects | **Confirm explicitly** |

Never start at level 4. Never run a clean before the cause is understood — it destroys the evidence that would have identified it.

---

## Report shape

```markdown
## @flutter-doctor <mode>

**Reproduction:** `<command>` → <first meaningful error>
**Class:** <class>
**Root cause:** <one sentence>

| Step | Action | Result |
|------|--------|--------|
| 1 | `dart pub deps` | `pkg_a` requires `pkg_c ^1.0`; `pkg_b` requires `pkg_c ^2.0` |
| 2 | Upgrade `pkg_a` to ^3.1 | resolves |

**Changed:** <files and versions, before → after>
**Verification:** `flutter pub get` 0 · `flutter analyze` 0 · `flutter test` 142/142
**Risk introduced:** <e.g. pkg_a major bump — behaviour change in X>
**Unverified:** <e.g. iOS build — no macOS host available>
**Run next:** <command>
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Anti-patterns

- Running `flutter clean` as the first response.
- Editing `lib/` to work around an environment problem.
- Reading only the last line of a Gradle or CocoaPods failure.
- Changing four things then re-running.
- Adding `dependency_overrides` without a justification and a removal condition.
- Bumping the SDK or a major dependency version silently.
- Raising `minSdkVersion` or the iOS deployment target without checking doc 02 §1 — that is a product decision.
- Disabling R8 entirely instead of adding the specific keep rule.
- Touching signing material.
- Claiming a fix without re-running the originally failing command.
- Reporting an iOS build as fixed from a machine that cannot build iOS.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Reproduction captured before any change | pass/fail | command + error |
| 2 | First meaningful error identified (not the last line) | pass/fail | quoted |
| 3 | Failure classified; confidence stated | pass/fail | class |
| 4 | Code-layer failures routed out to `@flutter-repair` | pass/skip | |
| 5 | One change at a time, each verified | pass/fail | step table |
| 6 | No application code edited | pass/fail | git diff |
| 7 | Version changes proposed with risk, not applied silently | pass/skip | |
| 8 | Clean steps least-destructive-first, with reasons | pass/skip | levels |
| 9 | Originally failing command re-run | pass/fail | exit code |
| 10 | Full verification chain re-run after dependency changes | pass/skip | |
| 11 | Unverifiable platforms reported as such | pass/skip | |
| 12 | Risks introduced stated | pass/fail | |

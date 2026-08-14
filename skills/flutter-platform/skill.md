---
name: flutter-platform
description: >-
  Own everything that crosses the Dart/native boundary - method and event
  channels, runtime permissions and their denial paths, deep links and app
  links, native project configuration (manifests, Info.plist, Gradle, Podfile),
  background execution, and federated plugin authoring. Enforces platform
  parity: no capability ships on one platform with undefined behaviour on
  another. Use for native code, permissions, deep links, or platform config.
---

# flutter-platform

The Dart/native boundary is where "works on my simulator" turns into a production incident. This skill makes every crossing explicit, symmetric across target platforms, and testable.

**Pairs with:** `flutter-implementation` (delegates here), `flutter-security` (permissions and transport config), `flutter-test` (integration tests on real devices), `flutter-release` (native build config), `FLS-07 platform parity`.

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Parity or an explicit divergence.** Every capability is defined for **every** target platform in doc 02 §1. "Android only for now" is acceptable *only* as a recorded divergence with the iOS behaviour stated (unsupported, degraded, or deferred to milestone F{N}).
2. **Every permission has three paths:** granted, denied, and permanently denied. The permanently-denied path must route the user to system settings. Shipping only the granted path is the single most common Flutter platform defect.
3. **Channel contracts are typed and versioned in one place.** Method names, argument shapes and error codes live in a single Dart file that both sides reference. Stringly-typed channel calls scattered across features are unmaintainable.
4. **Native errors cross as structured errors, not crashes.** A `PlatformException` must carry a stable `code` the Dart side switches on. Never let a native throw become an unhandled Dart exception.
5. **Never edit native config blindly.** Read the existing manifest, plist, Gradle or Podfile first; append or modify the specific node; never regenerate the file.
6. **Declare only the permissions actually used.** Every entry in the manifest and plist must trace to a SPEC §11. Unused declarations cause store rejections and privacy-label problems.
7. **Verify on a device or say you did not.** Platform behaviour cannot be verified by reading code. No device → report `not run (no device)` and record what remains unverified.

---

## Modes

| Mode | Action |
|------|--------|
| `channel - <name>` | Define or extend a method/event channel: Dart contract, native handlers, error codes, tests |
| `permission - <name>` | Wire a runtime permission with all three paths and both platforms' declarations |
| `deeplink - <pattern>` | Configure deep links / universal links / app links end to end |
| `config - <concern>` | Native project configuration: min SDK, capabilities, entitlements, signing hooks, network security |
| `background - <task>` | Background execution: fetch, notifications, long-running work, per-platform constraints |
| `plugin - <name>` | Author a federated plugin package |
| `parity` | Read-only: FLS-07 audit — every capability against every target platform |
| `status` | Read-only: platform folders, declared permissions, channels, deep-link config, min OS versions |

---

## Prerequisite gate (PL0)

```markdown
## @flutter-platform <mode> - blocked (prerequisite)

**Required:** `{APP_ROOT}` with the target platform folder present
**Detected:** <e.g. `ios/` missing while doc 02 §1 lists iOS>
**Run first:** `@flutter-scaffold app` (or add the platform: `flutter create --platforms=ios .`)
```

---

## channel protocol

1. **Define the contract in Dart, once.** One file per channel under `lib/src/core/platform/`: channel name, an enum or sealed set of methods, argument and return types, and the error-code constants. Everything else imports this.
2. **Version the channel name** (`com.example.app/battery/v1`). A breaking argument change gets a new version; both are handled during rollout.
3. **Implement each native side** in Kotlin (`android/app/src/main/kotlin/…`) and Swift (`ios/Runner/…`), registered in the plugin registrant or the app delegate. Each handler validates its arguments and returns a structured error rather than throwing.
4. **Error codes are shared constants**, documented in the contract file:

| Code | Meaning | Dart handling |
|------|---------|---------------|
| `UNAVAILABLE` | The capability does not exist on this device | Degrade the feature |
| `PERMISSION_DENIED` | Permission missing | Route to the permission flow |
| `INVALID_ARGUMENT` | Contract violation | Programmer error — log and fail loudly in debug |
| `FAILED` | Operation attempted and failed | Retryable; surface a message |
| `TIMEOUT` | Native did not respond in budget | Retry or degrade |

5. **Event channels** must define their stream lifecycle: when it starts, what cancels it, what happens on app background, and whether events are buffered or dropped.
6. **Tests:** Dart-side unit tests with a mocked channel (`TestDefaultBinaryMessengerBinding` handler) covering every method and every error code; plus an integration test on a real device for at least the happy path and one failure.

---

## permission protocol

1. **Source it from SPEC §11.** No SPEC entry → the permission is not approved; route to `@flutter-feature-spec amend`.
2. **Declare on both platforms:** Android `AndroidManifest.xml` (plus any `maxSdkVersion` narrowing), iOS `Info.plist` usage-description key with a **specific, user-meaningful string** — Apple rejects generic ones, and the string must be localised.
3. **Implement all three paths:**

| State | Behaviour |
|-------|-----------|
| Granted | Proceed |
| Denied (can ask again) | Explain the value, offer to ask again; the feature degrades gracefully meanwhile |
| Permanently denied / restricted | Explain, and deep-link to the system settings page. Never re-prompt in a loop |

4. **Request in context, not at launch.** Ask when the user takes the action that needs it, with a pre-prompt explaining why.
5. **Handle the mid-session revoke.** Permissions can be revoked while the app is backgrounded; re-check on resume rather than caching the grant forever.
6. **Platform divergences to handle explicitly:** Android runtime-permission model by API level, scoped storage, notification permission on Android 13+, iOS limited photo access, iOS location "when in use" vs "always" and its second prompt, and background-location review requirements.
7. **Tests:** widget tests for each of the three UI paths with a faked permission service; an integration test for the granted path.

---

## deeplink protocol

1. **Enumerate the link surface** from SPEC §5 and the navigation map: every externally reachable route, its parameters, and whether it requires auth.
2. **Configure both platforms:** Android intent filters with `autoVerify` plus the hosted `assetlinks.json`; iOS associated domains entitlement plus the hosted `apple-app-site-association`. Both hosted files must be served with the correct content type and no redirect.
3. **Handle both entry modes:** cold start (the app is launched by the link) and warm resume (the app is already running). These are different code paths and both must be tested.
4. **Auth-guarded links** must preserve the destination across login and land the user where the link pointed, not on the home screen.
5. **Unknown or malformed links** route to a defined fallback, never to a crash or a blank screen.
6. **Never trust link parameters.** Validate and sanitise; a deep link is untrusted input.
7. **Tests:** unit tests for the URL→route parser including malformed input; integration tests for cold and warm entry on both platforms.

---

## config / background / plugin

**`config`** — read the file, modify the specific node, re-read to confirm. Common concerns: min SDK versions (must match doc 02 §1), Gradle and AGP versions, Kotlin/Swift language versions, iOS deployment target and `Podfile` platform line, network security config (no cleartext in release), Android `usesCleartextTraffic`, iOS ATS exceptions (each needs a written justification), Proguard/R8 rules, and privacy manifests. Every change is reported with the file, the node, and the before/after.

**`background`** — state the platform constraints honestly before writing code: iOS background execution is discretionary and time-limited; Android has Doze, App Standby and per-OEM background restrictions. Define what happens when the OS never runs the task. A background feature whose failure mode is undefined is not designed.

**`plugin`** — federated structure (`<name>`, `<name>_platform_interface`, `<name>_android`, `<name>_ios`), the platform interface as the contract, `pubspec.yaml` platform declarations, an example app that exercises every method, and tests at both the interface and implementation levels.

---

## parity protocol (FLS-07)

Read-only audit. Build the matrix and fail on any undefined cell.

| Capability | Android | iOS | Web | Desktop | Divergence recorded |
|------------|---------|-----|-----|---------|---------------------|
| <channel/permission/link/background item> | supported / degraded / unsupported | … | … | … | doc 02 § / SPEC § |

**Fail conditions:** a cell is empty or "unknown"; a capability is `supported` on one platform and undefined on another target platform; a divergence exists in code with no record in doc 02 or the SPEC.

Also check the classic divergence points: back-button and swipe-back semantics, keyboard inset and dismissal behaviour, date/time and locale formatting, file-system access, notification permission and presentation, biometric prompts, app lifecycle events (iOS suspension vs Android process death), and text scaling defaults.

---

## Anti-patterns

- Implementing the granted permission path only.
- A generic iOS usage-description string.
- Declaring a permission "just in case".
- Channel method names as inline string literals across features.
- Letting a `PlatformException` propagate to the UI unhandled.
- Testing deep links only for the warm-resume case.
- Regenerating `AndroidManifest.xml` or `Info.plist` instead of editing the specific node.
- Shipping a capability on Android with iOS behaviour undefined.
- Claiming platform behaviour verified without running on a device.
- Assuming a background task will run.
- Allowing cleartext traffic in a release configuration.
- Caching a permission grant for the lifetime of the install.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | PL0 gate passed | pass/fail | |
| 2 | Capability traced to a SPEC §11 / §5 entry | pass/fail | § ref |
| 3 | Defined for every target platform, or divergence recorded | pass/fail | parity matrix |
| 4 | Channel contract in one typed file, versioned | pass/skip | path |
| 5 | Native error codes structured and handled in Dart | pass/skip | code list |
| 6 | All three permission paths implemented | pass/skip | |
| 7 | iOS usage strings specific and localised | pass/skip | |
| 8 | Deep links: cold **and** warm entry handled | pass/skip | |
| 9 | Hosted association files verified reachable | pass/skip/not run | |
| 10 | Native config edited node-wise; before/after reported | pass/skip | |
| 11 | Only used permissions declared | pass/fail | manifest diff |
| 12 | Tests written (unit + device integration) | pass/fail | paths |
| 13 | Device verification run, or `not run` with reason | pass/not run | device |

# Vetted package catalog

Free, open source, commercial-use-permitted packages, organised by the problem they solve. Admission policy: [`PACKAGE_LICENSE_STANDARD`](../standards/20260801-PACKAGE_LICENSE_STANDARD.md).

> **No versions are listed here, deliberately.** A version written in a document is wrong within months, and an agent repeating it produces a resolution failure or — worse — code written against an API that no longer exists. **Always check pub.dev for the current version, the current API, the licence, and the maintenance status before recommending or adding anything.** This catalog narrows the search space; it does not replace the check.
>
> Licences below were correct when the catalog was written and **can change between major versions**. Re-check at adoption and at every major upgrade.

---

## State management

| Package | Licence | Notes |
|---------|---------|-------|
| `flutter_riverpod` / `hooks_riverpod` | MIT | State + DI in one system; codegen recommended. [`stacks/riverpod.md`](../stacks/riverpod.md) |
| `flutter_bloc` | MIT | Event→state, transformers, strong traceability. [`stacks/bloc.md`](../stacks/bloc.md) |
| `provider` | MIT | Lowest concept count. [`stacks/provider.md`](../stacks/provider.md) |
| `signals_flutter` | MIT | Fine-grained reactivity. [`stacks/signals.md`](../stacks/signals.md) |

---

## Navigation

| Package | Licence | Notes |
|---------|---------|-------|
| `go_router` | BSD-3 | Flutter-team maintained; declarative, URL-shaped, deep links, guards. The default recommendation |
| `auto_route` | MIT | Codegen-based, type-safe arguments; more setup, stronger compile-time guarantees |
| Navigator 2.0 directly | BSD-3 | Only for genuinely unusual navigation requirements — it is a lot of code to own |

---

## Dependency injection

| Package | Licence | Notes |
|---------|---------|-------|
| `get_it` | MIT | Service locator. **Register at composition; inject via constructors** — do not call it from widgets |
| `injectable` | MIT | Codegen registration for `get_it` |
| Riverpod | MIT | If already chosen for state, use it for DI too rather than adding a second mechanism |

---

## Serialisation and models

| Package | Licence | Notes |
|---------|---------|-------|
| `json_serializable` + `json_annotation` | BSD-3 | The standard. Generated `fromJson`/`toJson` |
| `freezed` + `freezed_annotation` | MIT | Immutable models, unions/sealed classes, `copyWith`, equality |
| `equatable` | MIT | Value equality without codegen |
| `build_runner` | BSD-3 | Codegen driver for all of the above |
| `decimal` | Apache-2.0 | **Money. Never `double`** |
| `collection` | BSD-3 | Deep equality, sorting, grouping |

---

## Networking

| Package | Licence | Notes |
|---------|---------|-------|
| `dio` | MIT | Interceptors, cancellation, timeouts, upload/download progress |
| `http` | BSD-3 | Dart-team maintained; sufficient for simple needs |
| `retrofit` (Dart) | MIT | Codegen client over `dio` |
| `connectivity_plus` | BSD-3 | Connectivity state — **reports the interface, not reachability**; still verify with a real request |
| `web_socket_channel` | BSD-3 | WebSockets |
| `graphql_flutter` | MIT | If the backend is GraphQL |

---

## Local storage

| Package | Licence | Notes |
|---------|---------|-------|
| `shared_preferences` | BSD-3 | Scalar preferences. **Plaintext on disk** — never secrets. Use `SharedPreferencesAsync` / `SharedPreferencesWithCache`; the legacy `SharedPreferences` singleton is slated for deprecation, and on Android the new APIs sit on DataStore. Migrate with `migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary` (idempotent, safe on every launch) |
| `flutter_secure_storage` | BSD-3 | Keychain / Keystore. The **only** place for tokens and keys |
| `drift` | MIT | SQLite with typed queries, reactive streams, real migrations. The default for relational data |
| `sqlite3` | MIT | Native SQLite bindings used by Drift on desktop/mobile. Check its README for how the current major ships native libraries. Do **not** add `sqlite3_flutter_libs`: its latest release on pub.dev is tagged end-of-life (check the version suffix on its page) |
| `sqflite` | BSD-2 | Raw SQLite when you want no abstraction. What the official persistence recipe uses |
| `path_provider` | BSD-3 | Platform directories |
| `hive_ce` | Apache-2.0 / BSD-3 | **Migration target only.** The maintained successor to the abandoned `hive`. Its own maintainer advises against it for greenfield work — take that at face value |

---

## Platform and device

| Package | Licence | Notes |
|---------|---------|-------|
| `permission_handler` | MIT | Runtime permissions across platforms |
| `package_info_plus`, `device_info_plus` | BSD-3 | App and device metadata |
| `url_launcher` | BSD-3 | External URLs, mail, tel |
| `share_plus` | BSD-3 | System share sheet |
| `image_picker`, `file_picker` | Apache-2.0 / MIT | Media and file selection |
| `local_auth` | BSD-3 | Biometrics — **gate a key, not a boolean** |
| `app_links` | Apache-2.0 | Deep and app link handling |
| `flutter_local_notifications` | BSD-3 | Local notifications |
| `geolocator` | MIT | Location — high privacy sensitivity; declare and justify |

---

## Desktop (Windows, macOS, Linux)

Rules: [`DESKTOP_STANDARD`](../standards/20261123-DESKTOP_STANDARD.md). Checked on pub.dev on 2026-11-23: publisher, licence, last publish, discontinued flag, platform tags (W/M/L). **Re-check before adopting**: desktop packages hook into native runners and break on Flutter upgrades faster than pure-Dart ones.

| Package | Publisher | Licence | Desktop | Use for |
|---------|-----------|---------|---------|---------|
| `window_manager` | leanflutter.dev | MIT | W M L | Window size, minimum size, position, title, frameless / hidden title bar (custom title bars), always-on-top. **The maintained choice for what `bitsdojo_window` used to do** |
| `screen_retriever` | leanflutter.dev | MIT | W M L | Displays and their bounds, e.g. to check a restored window position still fits a screen |
| `tray_manager` | leanflutter.dev | MIT | W M L | System tray / menu bar icon and menu |
| `hotkey_manager` | leanflutter.dev | MIT | W M L | **Global** hotkeys (app not focused). In-app shortcuts use Flutter's `Shortcuts`/`Actions`, no package |
| `protocol_handler` | leanflutter.dev | MIT | W M | Custom URL schemes (`myapp://`) for desktop deep links. No Linux tag at check time |
| `launch_at_startup` | leanflutter.dev | MIT | W M L | Start with the OS (opt-in, user-visible setting) |
| `desktop_multi_window` | mixin.dev | Apache-2.0 | W M L | Additional native windows (each runs its own engine; plan state sharing) |
| `desktop_drop` | mixin.dev | Apache-2.0 | W M L | Drop files from the OS onto the app |
| `super_drag_and_drop` / `super_clipboard` | nativeshell.dev | MIT | W M L | Rich drag-and-drop out of the app and clipboard formats beyond text. Last publish 2025-06: check activity |
| `file_selector` | flutter.dev | BSD-3 | W M L | Native open/save dialogs |
| `desktop_webview_window` | mixin.dev | Apache-2.0 | W M L | Web content in a separate native window |
| `media_kit` | media-kit.dev | MIT | W M L | Audio/video playback on desktop (the mobile-first players lack desktop support) |
| `flutter_secure_storage` | steenbakker.dev | BSD-3 | W M L | Secrets in the OS keychain / credential store / libsecret |
| `local_auth` | flutter.dev | BSD-3 | W M | Windows Hello / Touch ID. No Linux tag at check time |
| `sentry_flutter` | sentry.io | MIT | W M L | Crash and error reporting including native desktop crashes |
| `msix` | kremer.software | MIT | W | Build signed MSIX packages for Windows |
| `win32` | halildurmus.dev | BSD-3 | W | Windows APIs from Dart via FFI, without writing C++ |
| `ffigen` | tools.dart.dev | BSD-3 | W M L | Generate Dart FFI bindings for native C libraries |
| `dynamic_color` | material.io | Apache-2.0 | W M L | Follow the OS accent colour in a Material theme |
| `system_theme` | bdlukaa.dev | BSD-3 | W M L | Read the OS accent colour and light/dark preference |

**Native look per OS** (a product decision: one cross-platform design, or each OS's own design language; record it in doc 02):

| Package | Publisher | Licence | OS | Notes |
|---------|-----------|---------|----|-------|
| `fluent_ui` | bdlukaa.dev | BSD-3 | Windows (runs on all) | Microsoft Fluent design widgets |
| `macos_ui` | macosui.dev | MIT | macOS | macOS-style widgets; pairs with `macos_window_utils` for window materials and toolbar |
| `yaru` | ubuntu.com | MPL-2.0 | Linux | Ubuntu's design system. MPL-2.0 is allowed as a dependency (PACKAGE_LICENSE_STANDARD §1) |

---

## UI

| Package | Licence | Notes |
|---------|---------|-------|
| `cached_network_image` | MIT | Remote images with caching and placeholders |
| `flutter_svg` | MIT | SVG rendering |
| `shimmer` / skeleton packages | MIT | Loading placeholders |
| `intl` | BSD-3 | Dates, numbers, currency, plurals. **Never hand-format** |
| `flutter_localizations` | BSD-3 | SDK localisation delegates |
| `google_fonts` | Apache-2.0 | Check the individual font licence and prefer bundling over runtime fetch |

---

## Logging and observability

| Package | Licence | Notes |
|---------|---------|-------|
| `logger` / `logging` | MIT / BSD-3 | Structured logging with levels |
| `sentry_flutter` | MIT | Crash and error reporting (self-hostable; the SaaS tier is commercial) |
| Firebase Crashlytics | Apache-2.0 (SDK) | Widely used; note the data-collection and privacy-declaration implications |

Whatever the choice: **verify symbol upload on an obfuscated release build**, or every stack trace is unreadable.

---

## Testing

| Package | Licence | Notes |
|---------|---------|-------|
| `flutter_test` | BSD-3 | SDK |
| `mocktail` | MIT | Null-safe mocking without codegen. **Preferred over `mockito`** — no `build_runner` step, so no stale generated mocks |
| `bloc_test` | MIT | State-sequence assertions for Bloc |
| `alchemist` | MIT | Golden helpers. Replaces the discontinued `golden_toolkit` |
| `integration_test` | BSD-3 | SDK; on-device journeys |
| `patrol` | Apache-2.0 | Native interaction in integration tests (permission dialogs, notifications). Fully OSS with no paid feature gate |

---

## Analysis and tooling

| Package | Licence | Notes |
|---------|---------|-------|
| `very_good_analysis` | MIT | Strict lint set. The recommended default |
| `flutter_lints` | BSD-3 | The SDK's baseline set |
| Stack-specific lints (`riverpod_lint`, `bloc_lint`) | MIT | Catch state-management misuse at analysis time. See the plugin note below |
| `melos` | Apache-2.0 | Monorepo management. **Current Melos majors have no `melos.yaml`** (check its changelog for the major that changed this) — it delegates linking to native pub workspaces, config moves under a `melos:` key in the root `pubspec.yaml`, every member needs `resolution: workspace`, and `melos analyze` is gone |
| `flutter_launcher_icons`, `flutter_native_splash` | MIT | Icon and splash generation |
| `flutter_flavorizr` | MIT | One-time generation of native flavor scaffolding. Own and review the output; do not keep it as a runtime dependency |

**Analyzer plugins.** `custom_lint` has ended maintenance. Current Dart/Flutter ship a first-party `analysis_server_plugin` system configured under a **top-level `plugins:` key** in `analysis_options.yaml`, and it runs under plain `dart analyze` — no separate CI step. `riverpod_lint` has migrated to it; `bloc_lint` still ships its own `bloc lint` CLI, so a Bloc project needs that extra command in CI. Verify which mechanism a given lint package uses before wiring it into a gate.

---

## Vulnerability scanning

**There is no `flutter pub audit`.** An agent that writes that command has invented it, and the CI step will fail or, worse, silently do nothing.

`dart pub get` surfaces advisories for known-vulnerable dependencies, but **it does not fail the build** — the output is informational and easy to miss in CI logs. The actual gate is a scanner run as its own step: **OSV-Scanner** (Apache-2.0) or **Trivy** (Apache-2.0), either of which reads `pubspec.lock` and exits non-zero on findings.

---

## Refused

Two categories: licence, and abandonment. Both are hard refusals — the waiver process exists for the first, not the second.

**By licence or commercial gate:** anything GPL, AGPL, LGPL, CC-BY-NC, source-available (BSL/SSPL), or requiring payment for production use. Also refused: no licence file, or unreviewable binary native code.

**Named exclusions.** These are checked and current; unlike versions, this list does not churn much.

| Package | Reason |
|---------|--------|
| `hive` | Abandoned since 2022, and pub.dev reports **`license:unknown`** — it fails automated licence detection, which is disqualifying on its own. Successor: `hive_ce`, migration only |
| `isar` | Abandoned since 2023, upstream repo archived. **Does not support Android 16 KB page sizes, which blocks Google Play submission.** `isar_community` fixed that but is bug-fix-only — a migration bridge, not a choice |
| `realm` | MongoDB Atlas Device SDKs reached **end of life in September 2025**. Existing code should be migrated |
| `dartz` | Abandoned since 2021 and never finished. Use the official sealed `Result` pattern, or `fpdart` if the team genuinely wants monadic composition |
| `redux` / `flutter_redux` | Frozen since 2021/2022. `BlocObserver` covers the time-travel-debugging argument |
| `dart_code_metrics` | **Went commercial.** Repo archived, pub package discontinued, successor is paid DCM. MIT alternatives exist but are too young to gate on |
| `golden_toolkit` | Discontinued. Use `alchemist` |
| `flutter_distributor` | **Marked discontinued on pub.dev** (checked 2026-11-23), though still widely recommended for multi-format desktop packaging. Package per OS instead: `msix` on Windows, notarized `.dmg`/`.pkg` on macOS, Snap/Flatpak tooling on Linux (DESKTOP_STANDARD §8) |
| `contextual_menu` | **Marked discontinued on pub.dev** (checked 2026-11-23). Use Flutter's `MenuAnchor` / context-menu APIs |
| `bitsdojo_window` | Last release 2023-12 (checked 2026-11-23), yet it patches each OS's native runner, which breaks across Flutter upgrades. Use `window_manager` for custom frames and title bars. Migration only |
| `flutter_acrylic` | Last release 2024-06 and no verified publisher (checked 2026-11-23). For macOS window materials use `macos_window_utils`; elsewhere treat translucent window effects as optional polish, not a dependency to gate on |
| `adwaita`, `libadwaita` | Last releases 2023 (checked 2026-11-23). For a native Linux look, `yaru` (ubuntu.com) is maintained |

**Permissive licence, still refused under a free/OSS constraint.** The licence on the visible part is not the licence on the part that matters:

| Package | The catch |
|---------|-----------|
| `objectbox` | The Dart binding is Apache-2.0, but the storage core is proprietary and **ObjectBox Sync is a paid product**. Local-only use is defensible; Sync is not free and must never be recommended as though it were |
| Shorebird | Permissive CLI, proprietary service behind it |
| freeRASP | Permissive wrapper, proprietary binaries |

Adding anything from either table needs an explicit, recorded waiver naming who accepted the risk.

---

## Before adding anything

1. Does the SDK or an existing dependency already do this?
2. Is the problem small enough to solve directly? A dependency for sixty lines is a bad trade.
3. Licence, maintenance, platform support, transitive weight, native code, data collection — all checked **on pub.dev**, now.
4. What is the exit cost if it is abandoned?
5. Record the decision in `STACK.md` with the alternative you would move to.

# Desktop standard — Windows, macOS, Linux

> **Not templated.** Applies whenever `REPLACE:FLUTTER_PLATFORMS` (foundation doc 02 §1) names `windows`, `macos` or `linux`. A project may add requirements; it may not drop one without a recorded decision in doc 02 naming the users affected.

**Owned by:** `@flutter-platform` (native), `@flutter-scaffold desktop` (skeleton), `@flutter-release` (packaging) · **Enforced by:** `@flutter-verify` D16, concept FLS-07 (platform parity).

A Flutter desktop app compiles from the same code as the mobile one, and that is exactly how it fails. It ships with phone habits: no keyboard shortcuts, nothing on hover, a layout that only works at one width, text the user cannot select, a release build that cannot reach the network on macOS, and an installer Windows calls dangerous. Desktop users judge an app by those things within a minute. Each rule below exists because skipping it produces one of those failures.

**Check, don't recall.** Package names below were verified on pub.dev when this standard was written; the full checked list, including packages that are discontinued or stale and must not be adopted (`bitsdojo_window`, `flutter_distributor`, `contextual_menu`, `flutter_acrylic`), is in [`resources/packages-2026.md` § Desktop](../resources/packages-2026.md). Their maintenance status, licence and platform support change. Before adding one, check pub.dev now: last publish date, discontinued flag, and platform tags for every desktop OS you target. No versions appear here on purpose.

---

## 1. Build hosts and toolchains

Flutter does not cross-compile desktop apps. **A macOS build needs a Mac, a Windows build needs Windows, a Linux build needs Linux.** A plan that says "we'll build all three from CI on Linux" is wrong, and so is a dev container presented as covering desktop: it covers Linux only.

| OS | Host requirement | Failure when missing |
|----|------------------|----------------------|
| Windows | Visual Studio (not VS Code) with the "Desktop development with C++" workload | `flutter doctor` reports Visual Studio missing; CMake errors |
| macOS | Xcode and its command-line tools; CocoaPods when a plugin needs it | `xcodebuild` errors; pod install failures |
| Linux | Clang, CMake, Ninja, pkg-config and the GTK 3 development headers (exact package names: Flutter's Linux setup docs) | CMake cannot find GTK |

`@flutter-doctor build - <os>` owns diagnosis. Record each OS's build host in `DOCS_FLUTTER_STACK.md` § Builds.

## 2. Windows (the OS window, not the platform)

1. **Set a minimum window size** at which every screen still works, and test at it (§7). Without one, users shrink the window until the layout overflows.
2. **Set a sensible initial size and the window title** in the runner (`windows/runner/main.cpp`, `linux/runner/my_application.cc`, `macos/Runner/MainFlutterWindow.swift`), or through a window-management package the stack has locked (`window_manager`, publisher leanflutter.dev, when it is current). Never leave the template's default title.
3. **Remember size and position** between launches when the app is used for long sessions. Restore them only if they still fit a connected screen: a window restored onto a monitor that is no longer attached is invisible.
4. **Multiple windows** are a product decision, not a default. If doc 02 needs them, check the current state of multi-window support in Flutter and in the locked packages before promising it.

## 3. Input: keyboard, mouse, focus

1. **Every primary action has a keyboard shortcut**, bound with `Shortcuts`/`Actions` (or `CallbackShortcuts` for small surfaces), using the **platform modifier**: `meta` (Cmd) on macOS, `control` on Windows and Linux. A Ctrl-only binding is wrong on macOS. A test that runs only on the default platform will not notice.
2. **Shortcuts are discoverable**: shown in menus (§4) and in tooltips on the buttons they duplicate.
3. **Everything is reachable by Tab**, in reading order (`FocusTraversalGroup` where the default order is wrong), with a visible focus indicator. This is also ACCESSIBILITY_STANDARD 2.1.1.
4. **Hover is feedback.** Interactive custom widgets show a hover state and the click cursor (`MouseRegion` + `SystemMouseCursors.click`). Material buttons and `InkWell` already do; a `GestureDetector` does not.
5. **Right-click opens a context menu** where the user expects one (list rows, editable content, files). Use `onSecondaryTapUp` with `MenuAnchor` or the context-menu APIs. A desktop list row that ignores right-click feels broken.
6. **Text the user may want to copy is selectable** (`SelectionArea` or `SelectableText`): ids, error messages, addresses, anything in a detail view.
7. **Scrolling uses the platform behaviour.** On desktop, Material shows scrollbars and does not drag-scroll with the mouse by default. Do not "fix" that with a custom `ScrollBehavior` unless a SPEC asks for it.

## 4. Menus and native affordances

1. **macOS has a menu bar**, so the app provides one: `PlatformMenuBar` renders the native macOS menu. On Windows and Linux use an in-app `MenuBar` where the app has more than a handful of commands. Check the current platform support of both widgets in the API docs before relying on either elsewhere.
2. The standard items work: Quit (Cmd+Q on macOS), Close Window, Copy/Paste in text fields, About.
3. **System tray, global hotkeys, drag-and-drop of files** are opt-in features named in a SPEC. Candidate packages verified when this standard was written: `tray_manager`, `hotkey_manager` (leanflutter.dev), `desktop_drop` (mixin.dev). Check platform tags: not every one supports every OS.

## 5. Layout for a resizable window

1. **Layout follows the window, not the device.** Use `LayoutBuilder` (constraints of the widget) or `MediaQuery.sizeOf(context)` (rebuilds only on size changes). Never `MediaQuery.of(context).size`: it rebuilds on every metrics change and the hygiene check flags it.
2. **Breakpoints are tokens**, defined once in the theme (`AppBreakpoints`), following the Material window size classes: compact below 600, medium 600–839, expanded 840 and above (large and extra-large above that). A `if (width > 837)` in a widget is a magic number.
3. **Expanded widths use the space**: list–detail side by side, navigation rail or drawer instead of a bottom bar, content constrained to a readable line length instead of stretched edge to edge.
4. **Density follows the platform.** Leave `ThemeData.visualDensity` at its adaptive default unless the design system says otherwise; desktop is denser than touch.
5. **No fixed pixel widths for content.** They break at the minimum window size and waste the maximum.

## 6. Files, storage and OS integration

1. **Open and save through the OS dialogs** (`file_selector`, publisher flutter.dev). On macOS, the sandbox also needs the `com.apple.security.files.user-selected.read-write` (or read-only) entitlement, or the dialog returns nothing.
2. **App data goes to the app-support directory** (`path_provider` → `getApplicationSupportDirectory`). Never write next to the executable: `Program Files` is read-only for standard users, and writing inside a macOS app bundle breaks its code signature.
3. **Plugins must support every targeted desktop OS.** An unsupported plugin often compiles and then throws `MissingPluginException` at runtime on that OS only. Check the platform tags on pub.dev, and record any gap in the FLS-07 parity matrix.
4. **Native code** goes through `@flutter-platform`: platform channels (C++ on Windows, Swift on macOS, C/GTK on Linux) or `dart:ffi` for C libraries. One Dart interface, one implementation per OS, each tested on its OS.

## 7. Testing

1. **Widget tests set the window size** they assert about: `tester.view.physicalSize` and `tester.view.devicePixelRatio`, reset with `addTearDown(tester.view.reset)`. Test at the minimum window size and at an expanded width.
2. **Shortcut tests run per platform** (`TargetPlatformVariant` with the desktop platforms) and press the platform modifier. A test that only presses Ctrl proves nothing about macOS.
3. **Integration tests run on each desktop OS** you ship (`flutter test integration_test -d windows|macos|linux`). Linux CI needs a display server: `xvfb-run`.
4. **Goldens** are generated on one platform of record (`DOCS_FLUTTER_STACK.md`); desktop font rendering differs per OS.

## 8. Packaging, signing and distribution

Release work is owned by `@flutter-release`. These are the rules it enforces.

| OS | Must | Why |
|----|------|-----|
| macOS | Sign with a Developer ID Application certificate, hardened runtime on, **notarize** (`xcrun notarytool submit --wait`) and **staple** (`xcrun stapler staple`) before distributing outside the App Store | Unnotarized apps are blocked by Gatekeeper on users' machines |
| macOS | Declare every entitlement the release needs in `Release.entitlements`. Outbound network needs `com.apple.security.network.client` | Flutter's template enables the App Sandbox. The debug entitlements differ, so **an app that works in debug can have no network in release** |
| Windows | Sign the executable and installer with a code-signing certificate; package as MSIX (e.g. `msix`, publisher kremer.software) or a signed installer | Unsigned binaries trigger SmartScreen warnings; MSIX will not install unsigned outside developer mode |
| Linux | Choose the format per audience (Snap, Flatpak, AppImage, .deb); build on the **oldest** distribution you support, or use a Flatpak/Snap runtime | A binary built against a newer glibc fails to start on older distributions |
| All | Decide the update path: store distribution (Mac App Store, Microsoft Store, Snap Store, Flathub) updates for you; direct distribution needs an updater (Sparkle on macOS, WinSparkle on Windows) | Without one, users stay on the first version they installed |

Updater packages wrapping Sparkle/WinSparkle exist (`auto_updater`), but when this standard was written its last release was over two years old. Verify its maintenance before adopting it, and prefer a store where the audience allows it.

**Signing material never enters the repository.** Certificates, `.p12` files and notarization credentials live in the CI secret store (SECURITY_PRIVACY_STANDARD, `PROTECTED_SURFACES.json` never-commit list).

## 9. CI

Build each targeted desktop OS on its own runner (`templates/ci/github-actions/flutter-gates.yml` jobs `desktop-linux`, `desktop-macos`, `desktop-windows`). Delete the jobs for OSes the project does not target. A job for a targeted OS **fails** when its platform directory is missing, rather than skipping. Each job uploads its build as a downloadable artifact (`desktop-linux.tar.gz`, `desktop-macos.zip`, `desktop-windows.zip`), archived so that the macOS bundle's symlinks and the Linux executable bit survive. These are **unsigned development builds** for testing. Signing and notarization run only on release pipelines with secrets, never on pull requests from forks.

---

## Anti-patterns

- Building macOS or Windows "on the Linux CI runner".
- A Ctrl-only shortcut on macOS, or a shortcut test that runs only on the default platform.
- `GestureDetector` on a custom control with no hover state and no click cursor.
- `MediaQuery.of(context).size` or a numeric breakpoint inside a widget.
- Writing files next to the executable or inside the app bundle.
- Shipping a macOS release build that was only ever tested in debug (sandbox entitlements differ).
- An unsigned Windows installer, or a macOS app that is signed but not notarized.
- Adding a plugin without checking its desktop platform support.

## Next action

Next action: none — apply via `@flutter-scaffold desktop`, `@flutter-platform`, `@flutter-release` and `@flutter-verify` D16 in the adopter repo.

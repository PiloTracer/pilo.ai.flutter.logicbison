# Flutter API currency — the APIs models still write

A language model's Flutter knowledge is frozen at its training cut-off, and the Flutter SDK is not. The result is a predictable class of defect: code that is idiomatic for an SDK the project does not use. Some of it is **removed** and fails to compile; more of it is **deprecated**, compiles, and fails the gate under `flutter analyze --fatal-infos` or silently loses behaviour (a `WillPopScope` disables Android predictive back; `withOpacity` loses colour precision).

This file lists the stale APIs agents most often produce, with the current replacement. It is a lookup table, not a standard. **The installed SDK is the authority, not this file and not your memory**: § How to check settles every case this table does not cover.

Machine-checked: `scripts/dart-hygiene-check.sh` flags the patterns marked **scan** below (removed = BLOCKER, deprecated = MAJOR). The rest need type information, so only the analyzer catches them.

---

## How to check (before writing, not after the gate fails)

1. **Ask the SDK, not your memory.** Locate it with `scripts/flutter-sdk.sh` (it finds an SDK that is installed but not on `PATH`). Then search the source: `grep -rn "class WillPopScope" "$FLUTTER_ROOT/packages/flutter/lib"`. A `@Deprecated('Use X instead…')` line directly above the declaration names the replacement. No hit means the API does not exist in this SDK. `dart:ui` (where `Color` lives) is in `$FLUTTER_ROOT/bin/cache/pkg/sky_engine/lib/ui/`.
2. **Let the SDK migrate what it can.** `dart fix --dry-run` lists the automated migrations the SDK ships for the code in front of it (`packages/flutter/lib/fix_data/`). Review the list, then `dart fix --apply`. This handles many renames in this table mechanically and correctly; hand-editing them is slower and error-prone.
3. **Treat `deprecated_member_use` as a finding.** The analyzer reports every deprecated call with the replacement in the message. It is never suppressed to make a gate pass (`// ignore:` needs an ADR and a reason on the same line).
4. **Package APIs are checked on pub.dev**, on the version the lockfile actually resolved. This file covers the Flutter SDK only.

The failure mode this prevents: an agent "fixes" an analyzer error by inventing a third API that also does not exist. When the SDK search returns nothing, stop and report the API as `unverified`. Do not guess a name.

---

## Removed: does not compile

| Stale (do not write) | Current | Scan |
|----------------------|---------|------|
| `FlatButton`, `RaisedButton`, `OutlineButton` | `TextButton`, `FilledButton` (primary) / `ElevatedButton`, `OutlinedButton` | scan |
| `textTheme.headline1`…`headline6` | `displayLarge` / `displayMedium` / `displaySmall` / `headlineLarge` / `headlineMedium` / `headlineSmall`, mapped by role, not by number | scan |
| `textTheme.subtitle1` / `subtitle2` | `titleMedium` / `titleSmall` | scan |
| `textTheme.bodyText1` / `bodyText2` | `bodyLarge` / `bodyMedium` | scan |
| `textTheme.caption` / `overline` / `button` | `bodySmall` / `labelSmall` / `labelLarge` | scan |
| `ThemeData(accentColor:)`, `primaryVariant`, `secondaryVariant` | `ColorScheme` roles: `secondary`, `primaryContainer`, `secondaryContainer` | scan |
| `Scaffold.of(context).showSnackBar(...)` | `ScaffoldMessenger.of(context).showSnackBar(...)` | scan |
| `ThemeData(bottomAppBarColor:)`, `toggleableActiveColor`, `selectedRowColor` | Component themes (`BottomAppBarTheme`, `SwitchThemeData`, …) or `ColorScheme` roles | analyzer |

## Deprecated: compiles, fails the gate

| Stale | Current | Why it matters | Scan |
|-------|---------|----------------|------|
| `color.withOpacity(0.5)` | `color.withValues(alpha: 0.5)` | Precision loss in wide-gamut colour | scan |
| `color.value`, `color.red` / `.green` / `.blue` / `.opacity` | `color.toARGB32()`; components `.r` `.g` `.b` `.a` are doubles 0–1 | Same: colour is no longer an 8-bit int | analyzer |
| `WillPopScope(onWillPop:)` | `PopScope(canPop:, onPopInvokedWithResult:)` | Android predictive back does not work with `WillPopScope` | scan |
| `PopScope(onPopInvoked:)`, `Form(onWillPop:)` | `onPopInvokedWithResult`; `Form(canPop:, onPopInvokedWithResult:)` | | scan |
| Every `MaterialState*` name: `MaterialState`, `MaterialStateProperty`, `MaterialStatePropertyAll`, `MaterialStateColor`, `MaterialStatesController`, `MaterialStateOutlineInputBorder`… | The `WidgetState*` equivalent (`WidgetState`, `WidgetStateProperty`, `WidgetStatePropertyAll`, `WidgetStateColor`, `WidgetStatesController`, `WidgetStateInputBorder`) | Moved to the widgets layer | scan |
| `textScaleFactor` (on `Text`, `MediaQueryData`, `RichText`, `TextPainter`) and `MediaQuery.textScaleFactorOf` | `textScaler: TextScaler.linear(2)`, `MediaQuery.textScalerOf(context)` | Text scaling is nonlinear on some platforms. A single factor misrepresents it, and tests written with it test the wrong thing | scan |
| `colorScheme.background` / `onBackground` | `surface` / `onSurface` | | scan |
| `colorScheme.surfaceVariant` | `surfaceContainerHighest` (or the `surfaceContainer*` tier that matches the elevation) | | scan |
| `ButtonBar` | `OverflowBar` | | scan |
| `RawKeyboardListener`, `RawKeyEvent`, `RawKeyboard`, `Focus(onKey:)` | `KeyboardListener`, `KeyEvent`, `HardwareKeyboard`, `Focus(onKeyEvent:)` | Desktop shortcuts (DESKTOP_STANDARD §3) are built on the new key-event model | scan |
| `ui.window`, `WidgetsBinding.instance.window`, `MediaQueryData.fromWindow`, `EdgeInsets.fromWindowPadding` | `View.of(context)`, `MediaQueryData.fromView`, `EdgeInsets.fromViewPadding` | Multi-window: there is no single window | scan |
| `ThemeData(dialogBackgroundColor:)` | `DialogThemeData(backgroundColor:)` | | scan |
| `SemanticsService.announce(message, dir)` | `SemanticsService.sendAnnouncement(View.of(context), message, dir)` (import `package:flutter/semantics.dart`; the UI library does not export it), and first prefer a `Semantics(liveRegion: true)` that announces implicitly | Multi-window. Android has deprecated announcement events, so an implicit live region is the more reliable route anyway | scan |
| `ThemeData(indicatorColor:)` | `TabBarThemeData(indicatorColor:)` | | analyzer |
| `ExpansionTileController` | `ExpansibleController` | | scan |
| `Radio(groupValue:, onChanged:)` / `RadioListTile(groupValue:)` | A `RadioGroup` ancestor owns `groupValue` and `onChanged` | | analyzer |
| `Switch(activeColor:)` | `activeThumbColor` / `activeTrackColor` | | analyzer |
| `DropdownButtonFormField(value:)` | `initialValue:` | | analyzer |
| `DragTarget(onWillAccept:, onAccept:)` | `onWillAcceptWithDetails`, `onAcceptWithDetails` | | analyzer |
| `ReorderableListView(onReorder:)` | `onReorderItem:` (index already adjusted for the removed item) | The old callback's off-by-one is a classic bug | analyzer |
| `ThemeData(useMaterial3: true)` | Omit it: Material 3 is the default. For an explicit choice, use `ThemeData.light()` / `.dark()` / `.from()` | Stale habit, now a deprecated parameter on the `ThemeData()` factory | analyzer |

## Moved: the import itself

`package:flutter/material.dart` and `package:flutter/cupertino.dart` are deprecated in favour of the `material_ui` and `cupertino_ui` packages ([`ARCHITECTURE_STANDARD`](../standards/20260801-ARCHITECTURE_STANDARD.md) says how to check and migrate). Check which import the project uses before writing the first line. Mixing the two in one project is a finding.

---

## Current APIs models under-use

These are not deprecations. A model trained on older code reaches for a hand-rolled version instead, and the result is worse UI.

| Need | Use | Instead of |
|------|-----|-----------|
| Single-choice segmented control | `SegmentedButton` | A row of toggled buttons |
| Bottom navigation (M3) | `NavigationBar`; `NavigationRail` at medium width; `NavigationDrawer` at expanded | `BottomNavigationBar` everywhere |
| Search | `SearchAnchor` / `SearchBar` | A `TextField` in the app bar with hand-built suggestions |
| Menus, context menus, dropdowns | `MenuAnchor`, `DropdownMenu` | `PopupMenuButton` for everything; hand-positioned overlays |
| Count or dot on an icon | `Badge` | A `Stack` with a positioned circle |
| Carousel | `CarouselView` | `PageView` plus a hand-built indicator |
| Respect reduce-motion | `MediaQuery.disableAnimationsOf(context)` | Ignoring the setting |
| High contrast, bold text | `MediaQuery.highContrastOf(context)`, `MediaQuery.boldTextOf(context)` | Ignoring the setting |
| Primary action button | `FilledButton` (one per screen, UI_CRAFT §5) | `ElevatedButton` for every action |
| Automated a11y checks | `meetsGuideline(androidTapTargetGuideline)` and friends ([`ACCESSIBILITY_STANDARD`](../standards/20260801-ACCESSIBILITY_STANDARD.md) §3) | Nothing |

---

## Provenance

Every row above was checked against the installed stable SDK's own source on 2026-11-24: the `@Deprecated` message for deprecations, the absence of the declaration for removals. No release numbers appear here on purpose: the next SDK will deprecate more. When a row and the installed SDK disagree, **the SDK wins**. Record the disagreement in `CHANGELOG.md` so the row gets fixed.

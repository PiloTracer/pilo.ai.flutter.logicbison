# UI recipes: verified exemplars that consume the tokens

Rules tell an agent what is wrong. Exemplars show what right looks like, and models pattern-match exemplars far more reliably than they apply prose. Every recipe here is real code that, on 2026-11-24, against the current stable SDK and `material_ui`:

- passes `flutter analyze --fatal-infos` and `dart format --set-exit-if-changed`;
- passes `scripts/dart-hygiene-check.sh` (no raw spacing, no factory colours, no stale APIs);
- passes all four `flutter_test` accessibility guidelines in every state, in light and dark;
- was rendered with [`visual-review.md`](visual-review.md) at compact, medium and expanded widths, in light, dark and 200% text, and **looked at**. That review found two defects that every test above had passed: icons rendered as boxes (a helper bug, since fixed) and a skeleton that did not match the rows it stood in for (fixed below).

**Adapt; do not paste blindly.** Swap the import for the project's UI library (ARCHITECTURE_STANDARD), take the seed from the design system (`.ai.ui`, when installed, owns tokens), take strings from `AppLocalizations` (they are inline here only for readability), and follow the locked state-management stack: the screen takes its state as a parameter so it fits any of them.

| Recipe | Shows | Standard |
|--------|-------|----------|
| [1. Theme](#1-theme-libcorethemeapp_themedart) | Seeded scheme for both modes, spacing and motion as `ThemeExtension`s, component themes, 48 px targets, reduce-motion | THEMING §3–§7, UI_CRAFT §2 §4 §7 |
| [2. Adaptive shell](#2-adaptive-navigation-shell) | Bar, rail or extended rail by window class; width-capped content | DESKTOP §5, ui-craft §3 |
| [3. Six-state screen](#3-a-screen-with-every-state) | Sealed state with an exhaustive `switch`; layout-true skeleton; teaching empty state; plain-language error with retry beside it; calm offline notice | FEATURE_SPEC §6, UI_CRAFT §6 §10 |
| [4. Actions and confirmation](#4-action-hierarchy-and-destructive-confirmation) | One filled primary, quieter secondary; destructive confirm that names the consequence and repeats the verb | UI_CRAFT §5 §10 |

---

## 1. Theme (`lib/core/theme/app_theme.dart`)

Theme files are where raw values are *defined*; the hygiene scan exempts them by path. Nothing outside this file holds a number.

```dart
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Spacing scale as a ThemeExtension: it travels with the theme, interpolates
/// during theme animation, and is the only place spacing numbers exist.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  /// Section breaks (resources/ui-craft.md §3).
  final double xxl;

  @override
  AppSpacing copyWith(
      {double? xs,
      double? sm,
      double? md,
      double? lg,
      double? xl,
      double? xxl}) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  AppSpacing lerp(AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }
}

/// Motion tokens. Widgets read these, and collapse them to zero when the
/// platform asks for reduced motion (see motionOf).
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    this.short = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 250),
    this.emphasized = Curves.easeOutCubic,
  });

  final Duration short;
  final Duration medium;
  final Curve emphasized;

  @override
  AppMotion copyWith({Duration? short, Duration? medium, Curve? emphasized}) {
    return AppMotion(
      short: short ?? this.short,
      medium: medium ?? this.medium,
      emphasized: emphasized ?? this.emphasized,
    );
  }

  @override
  AppMotion lerp(AppMotion? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Window size classes. Layout branches on these, never on literals.
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;
}

abstract final class AppTheme {
  /// The one recorded brand decision. Replace with the design system's seed.
  static const Color _seed = Color(0xFF3550C8);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // One seed produces every role, light and dark, with designed neutrals.
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    const spacing = AppSpacing();
    final radius = BorderRadius.circular(12);
    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      extensions: const [spacing, AppMotion()],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: radius),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
      ),
    );
  }
}

/// The spacing tokens of the current theme (defaults if a test theme omits them).
AppSpacing spacingOf(BuildContext context) =>
    Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

/// Motion tokens, collapsed to zero under the platform's reduce-motion setting.
AppMotion motionOf(BuildContext context) {
  final motion = Theme.of(context).extension<AppMotion>() ?? const AppMotion();
  if (MediaQuery.disableAnimationsOf(context)) {
    return motion.copyWith(short: Duration.zero, medium: Duration.zero);
  }
  return motion;
}
```

## 2. Adaptive navigation shell

Branches on the constraints the window gives, never on device type or `MediaQuery.size`.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

class ShellDestination {
  const ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Navigation that follows the window, not the device: a bottom bar when
/// compact, a rail when medium, an extended rail when expanded. Content is
/// width-capped so text lines stay readable on a wide window.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;

  /// Readable line length on wide windows (~70 characters of body text).
  static const double maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: body,
          ),
        );
        if (width < AppBreakpoints.medium) {
          return Scaffold(
            body: SafeArea(child: content),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: width >= AppBreakpoints.expanded,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  labelType: width >= AppBreakpoints.expanded
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

## 3. A screen with every state

The screen receives a sealed state, so it fits any state-management stack and the compiler rejects a forgotten state. Review notes from the renders: the empty state's dominant element is the illustration at `displayMedium` (2.8× the 16 sp body, inside UI_CRAFT §3's 2–3× range); the accent appears only on the one action; the dark error state keeps the icon in the error role and the text neutral; at 200% text the rows wrap and nothing clips. The data state's dominant element is a per-screen SPEC §5 decision (a summary figure, for example). This recipe deliberately shows only the list.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

class Order {
  const Order(this.customer, this.total);

  final String customer;
  final String total; // already formatted by intl in the view model
}

/// Every state the SPEC can name, as a closed set: the compiler refuses a
/// screen that forgets one.
sealed class OrdersState {
  const OrdersState();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersEmpty extends OrdersState {
  const OrdersEmpty();
}

final class OrdersError extends OrdersState {
  const OrdersError();
}

final class OrdersData extends OrdersState {
  const OrdersData(this.orders, {this.savedAt});

  final List<Order> orders;

  /// Set when showing cached data while offline (the partial/offline state).
  final String? savedAt;
}

/// Strings are inline for readability; in a project every one of them comes
/// from AppLocalizations (L10N_STANDARD).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onCreate,
  });

  final OrdersState state;
  final VoidCallback onRetry;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final motion = motionOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: AnimatedSwitcher(
        duration: motion.medium,
        child: switch (state) {
          OrdersLoading() => const _OrdersSkeleton(),
          OrdersEmpty() => _EmptyOrders(onCreate: onCreate),
          OrdersError() => _OrdersError(onRetry: onRetry),
          OrdersData(:final orders, :final savedAt) =>
            _OrdersList(orders: orders, savedAt: savedAt),
        },
      ),
    );
  }
}

/// Skeleton rows built from the same Card + ListTile as the real rows, with
/// the same padding and gaps, so nothing moves when the data arrives
/// (UI_CRAFT §6). Bars sit where the customer name and the amount will be.
class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    final block = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: spacing.md,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(spacing.xs),
            ),
          ),
        );
    return Semantics(
      label: 'Loading orders',
      child: ExcludeSemantics(
        child: ListView.separated(
          padding: EdgeInsets.all(spacing.md),
          itemCount: 6,
          separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
          itemBuilder: (context, index) => Card(
            child: ListTile(
              title: bar(0.5),
              trailing: SizedBox(width: spacing.xxl, child: bar(1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state: what appears here, why it is empty, the one action that fills it.
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: theme.textTheme.displayMedium?.fontSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing.md),
            Text(
              'No orders yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Orders your customers place will appear here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            FilledButton(
                onPressed: onCreate, child: const Text('Create order')),
          ],
        ),
      ),
    );
  }
}

/// Error state: what happened in the user's terms, what to do, and the way out
/// right next to it. No codes, no exception text.
class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: theme.textTheme.displayMedium?.fontSize,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: spacing.md),
            Text(
              "Couldn't load your orders",
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Check your connection, then try again.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, this.savedAt});

  final List<Order> orders;
  final String? savedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    return Column(
      children: [
        if (savedAt != null)
          // Offline: say what the user is looking at, without alarm.
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHigh,
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    "You're offline. Showing orders saved $savedAt.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(spacing.md),
            itemCount: orders.length,
            separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
            itemBuilder: (context, i) => Card(
              child: ListTile(
                title: Text(orders[i].customer,
                    style: theme.textTheme.titleMedium),
                trailing:
                    Text(orders[i].total, style: theme.textTheme.titleMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

## 4. Action hierarchy and destructive confirmation

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// A destructive confirmation: the title names the consequence, the body says
/// whether it can be undone, the button repeats the verb in the error role.
/// Returns true only when the user chose to delete.
Future<bool> confirmDeletePhotos(BuildContext context, int count) async {
  final theme = Theme.of(context);
  final noun =
      count == 1 ? 'photo' : '$count photos'; // intl plural in a project
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $noun?'),
      content: const Text("Deleted photos can't be recovered."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Action hierarchy on a form: one filled primary, a quieter secondary, and
/// the primary is the largest, most reachable target (UI_CRAFT §5).
class FormActions extends StatelessWidget {
  const FormActions({super.key, required this.onSave, required this.onDiscard});

  final VoidCallback? onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: spacing.sm,
      overflowSpacing: spacing.sm,
      children: [
        TextButton(onPressed: onDiscard, child: const Text('Discard changes')),
        FilledButton(onPressed: onSave, child: const Text('Save changes')),
      ],
    );
  }
}
```

---

## Proving an adaptation

After adapting a recipe, prove it the same way: the gate commands, the hygiene scan, a guideline test per state (ACCESSIBILITY_STANDARD §3), and renders reviewed per [`visual-review.md`](visual-review.md). A recipe that compiles has proved that it compiles, nothing more. Both defects found while writing this file were invisible to every check except looking.

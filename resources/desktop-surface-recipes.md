# Desktop surface recipes

Choose a pattern from [Desktop surfaces](desktop-surfaces.md), then read its section below. The Ledger composition uses fixture data and placeholder Add, Save and Retry callbacks. Connect those actions to the app’s existing state and services. Use project tokens and localize the labels.

## Theme layers

`lib/core/theme/app_theme.dart`

Spacing, radii, breakpoints, status pairs and the frame/canvas/card tones. The seed is the only accent. Numbers live in this file, which is why the hygiene scan exempts `theme/`.

```dart
import 'dart:ui' show FontFeature, lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Spacing scale. The only place spacing numbers exist.
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
  final double xxl;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
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
    if (other == null) {
      return this;
    }
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

/// Corner radii. Desktop cards use a larger radius than compact controls.
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({this.sm = 4, this.md = 10, this.lg = 16, this.xl = 20});

  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  AppRadii copyWith({double? sm, double? md, double? lg, double? xl}) {
    return AppRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppRadii lerp(AppRadii? other, double t) {
    if (other == null) {
      return this;
    }
    return AppRadii(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}

/// Window classes and the desktop widths that branch on text scale.
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// Masthead drops its supporting sentence at this text scale and above.
  static const double descriptionScale = 1.5;

  static const double minColumn = 160;
  static const double rail = 72;
  static const double railExtended = 240;
  static const double sidebar = 240;
  static const double mastheadArt = 144;
  static const double mastheadArtHeight = 96;
}

/// One status hue. [strong] is for text and icons; [tint] fills the pill.
@immutable
class StatusTone {
  const StatusTone({required this.strong, required this.tint});

  final Color strong;
  final Color tint;

  static StatusTone lerp(StatusTone a, StatusTone b, double t) {
    return StatusTone(
      strong: Color.lerp(a.strong, b.strong, t)!,
      tint: Color.lerp(a.tint, b.tint, t)!,
    );
  }
}

/// Layers [ColorScheme] does not name: frame, canvas, card, and status pairs.
///
/// Dark mode stacks darkest to lightest: frame, canvas, card. Status hues are
/// for status only and always sit next to a word or an icon.
@immutable
class AppTones extends ThemeExtension<AppTones> {
  const AppTones({
    required this.frame,
    required this.canvas,
    required this.card,
    required this.border,
    required this.hover,
    required this.selected,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.quiet,
  });

  final Color frame;
  final Color canvas;
  final Color card;
  final Color border;
  final Color hover;
  final Color selected;
  final StatusTone success;
  final StatusTone warning;
  final StatusTone danger;
  final StatusTone info;
  final StatusTone quiet;

  static const AppTones light = AppTones(
    frame: Color(0xFFE7EDF4),
    canvas: Color(0xFFF4F7FB),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFD3DCE8),
    hover: Color(0xFFEAF0F7),
    selected: Color(0xFFFFFFFF),
    success: StatusTone(strong: Color(0xFF0F5C38), tint: Color(0xFFD8F3E4)),
    warning: StatusTone(strong: Color(0xFF7A4E00), tint: Color(0xFFFBE8C8)),
    danger: StatusTone(strong: Color(0xFF8E1E2A), tint: Color(0xFFF8D9DC)),
    info: StatusTone(strong: Color(0xFF1A4578), tint: Color(0xFFD9E8F8)),
    quiet: StatusTone(strong: Color(0xFF334155), tint: Color(0xFFE7EDF4)),
  );

  static const AppTones dark = AppTones(
    frame: Color(0xFF0B1220),
    canvas: Color(0xFF121A2B),
    card: Color(0xFF1A2438),
    border: Color(0xFF2C3A52),
    hover: Color(0xFF243044),
    selected: Color(0xFF2E3D56),
    success: StatusTone(strong: Color(0xFF8FE3B5), tint: Color(0xFF123524)),
    warning: StatusTone(strong: Color(0xFFF2C56E), tint: Color(0xFF3A2C10)),
    danger: StatusTone(strong: Color(0xFFFF9AA3), tint: Color(0xFF3F171C)),
    info: StatusTone(strong: Color(0xFFAED0F8), tint: Color(0xFF15283F)),
    quiet: StatusTone(strong: Color(0xFFD5DEEA), tint: Color(0xFF243044)),
  );

  static AppTones of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTones>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppTones copyWith({
    Color? frame,
    Color? canvas,
    Color? card,
    Color? border,
    Color? hover,
    Color? selected,
    StatusTone? success,
    StatusTone? warning,
    StatusTone? danger,
    StatusTone? info,
    StatusTone? quiet,
  }) {
    return AppTones(
      frame: frame ?? this.frame,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      border: border ?? this.border,
      hover: hover ?? this.hover,
      selected: selected ?? this.selected,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      quiet: quiet ?? this.quiet,
    );
  }

  @override
  AppTones lerp(ThemeExtension<AppTones>? other, double t) {
    if (other is! AppTones) {
      return this;
    }
    return AppTones(
      frame: Color.lerp(frame, other.frame, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      success: StatusTone.lerp(success, other.success, t),
      warning: StatusTone.lerp(warning, other.warning, t),
      danger: StatusTone.lerp(danger, other.danger, t),
      info: StatusTone.lerp(info, other.info, t),
      quiet: StatusTone.lerp(quiet, other.quiet, t),
    );
  }
}

AppSpacing spacingOf(BuildContext context) =>
    Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

AppRadii radiiOf(BuildContext context) =>
    Theme.of(context).extension<AppRadii>() ?? const AppRadii();

/// Token-consuming theme. The seed is the one accent; layers come from tones.
abstract final class AppTheme {
  static const Color seed = Color(0xFF3550C8);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final tones =
        brightness == Brightness.dark ? AppTones.dark : AppTones.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      surface: tones.canvas,
      surfaceContainerLowest: tones.card,
      surfaceContainerLow: tones.card,
      surfaceContainer: tones.hover,
      outline: tones.border,
      outlineVariant: tones.border,
    );
    const spacing = AppSpacing();
    const radii = AppRadii();
    final radius = BorderRadius.circular(radii.lg);
    final base = ThemeData(colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: tones.frame,
      textTheme: _figures(base.textTheme),
      extensions: [spacing, radii, tones],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(spacing.xxl, spacing.xxl),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      // Secondary actions stay off the accent. Pair them with an icon so they
      // still read as controls (a neutral label with no icon looks like text).
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(spacing.xxl, spacing.xxl),
          foregroundColor: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tones.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: tones.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: tones.border, space: spacing.sm),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tones.card,
        border: OutlineInputBorder(borderRadius: radius),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true),
      ),
    );
  }

  static TextTheme _figures(TextTheme base) {
    TextStyle? mark(TextStyle? style) {
      return style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }

    return base.copyWith(
      bodyLarge: mark(base.bodyLarge),
      bodyMedium: mark(base.bodyMedium),
      titleMedium: mark(base.titleMedium),
      titleLarge: mark(base.titleLarge),
      labelLarge: mark(base.labelLarge),
      labelMedium: mark(base.labelMedium),
    );
  }
}
```

## Page masthead

`lib/desktop/page_masthead.dart`

The title stays on `displaySmall` (about 2.25× body-large, 2.6× body-medium). The illustration and the sentence are what give way.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

enum MastheadPattern { waves, rings, lattice }

/// Section title for a wide canvas. The title stays on displaySmall so the
/// hierarchy ratio holds. The illustration drops when width cannot afford it
/// after text scale, and the supporting sentence drops first.
final class PageMasthead extends StatelessWidget {
  const PageMasthead({
    required this.title,
    required this.icon,
    required this.pattern,
    this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final MastheadPattern pattern;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final illustrated =
            constraints.maxWidth >= AppBreakpoints.medium * scale;
        final detail = description;
        final showDetail =
            detail != null && scale < AppBreakpoints.descriptionScale;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tones.card,
            border: Border.all(color: tones.border),
            borderRadius: BorderRadius.circular(radii.lg),
          ),
          child: Padding(
            padding: EdgeInsets.all(illustrated ? spacing.md : spacing.sm),
            child: Row(
              children: [
                if (!illustrated)
                  Padding(
                    padding: EdgeInsets.only(right: spacing.xs),
                    child: ExcludeSemantics(
                      child: Icon(icon, color: scheme.onSurfaceVariant),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          key: const ValueKey('masthead-title'),
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                      if (showDetail)
                        Padding(
                          padding: EdgeInsets.only(top: spacing.xs),
                          child: Text(
                            detail,
                            key: const ValueKey('masthead-description'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                if (illustrated)
                  Padding(
                    padding: EdgeInsets.only(left: spacing.sm),
                    child: ExcludeSemantics(
                      child: SizedBox(
                        width: AppBreakpoints.mastheadArt,
                        height: AppBreakpoints.mastheadArtHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  key: const ValueKey('masthead-art'),
                                  painter: _MastheadArtwork(
                                    pattern: pattern,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: tones.selected,
                                borderRadius: BorderRadius.circular(radii.lg),
                                border: Border.all(color: tones.border),
                              ),
                              child: SizedBox.square(
                                dimension: spacing.xxl,
                                child: Icon(icon, color: scheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _MastheadArtwork extends CustomPainter {
  const _MastheadArtwork({required this.pattern, required this.color});

  final MastheadPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.012
      ..color = color.withValues(alpha: 0.35);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (pattern) {
      case MastheadPattern.waves:
        for (var lane = 0; lane < 5; lane++) {
          final y = size.height * (0.18 + lane * 0.16);
          final path = Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(
              size.width * 0.35,
              y - size.height * 0.22,
              size.width * 0.62,
              y,
            )
            ..quadraticBezierTo(
              size.width * 0.82,
              y + size.height * 0.16,
              size.width,
              y - size.height * 0.04,
            );
          canvas.drawPath(path, ink);
        }
      case MastheadPattern.rings:
        final center = Offset(size.width * 0.55, size.height * 0.5);
        for (var ring = 1; ring <= 4; ring++) {
          canvas.drawCircle(center, size.shortestSide * 0.22 * ring, ink);
        }
      case MastheadPattern.lattice:
        final step = size.height * 0.28;
        for (var row = -2; row < 6; row++) {
          final y = step * row;
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y + size.height),
            ink,
          );
          canvas.drawLine(
            Offset(0, y + size.height),
            Offset(size.width, y),
            ink,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MastheadArtwork oldDelegate) {
    return pattern != oldDelegate.pattern || color != oldDelegate.color;
  }
}
```

## Status pill

`lib/desktop/status_pill.dart`

A tint, a stronger foreground, and a word. A dot or an icon is extra, never the only cue.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// Status with a tint, a strong foreground, and a word. Colour is never the
/// only cue.
final class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.tone,
    this.icon,
    this.dot = false,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final mark = icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(radii.lg),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot)
              SizedBox.square(
                dimension: spacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tone.strong,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else if (mark != null)
              Icon(mark, color: tone.strong),
            if (dot || mark != null) SizedBox(width: spacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: tone.strong),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Surface card

`lib/desktop/surface_card.dart`

Card tone and a hairline. Emphasis is the hover neutral, a solid fill, because text on a gradient fails the contrast check or cannot be judged by it.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// A card on the card tone with a hairline. Emphasis is a step in the neutral
/// ramp, not a second accent and not a gradient under the text.
final class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.emphasis = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    final heading = title;
    final detail = subtitle;
    return Material(
      color: emphasis ? tones.hover : tones.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.lg),
        side: BorderSide(color: tones.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(spacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) SurfaceHeading(title: heading, icon: icon),
            if (detail != null)
              Padding(
                padding: EdgeInsets.only(top: spacing.xs),
                child: Text(detail, style: theme.textTheme.bodyMedium),
              ),
            if (heading != null || detail != null) SizedBox(height: spacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

/// A section heading. It is a header for assistive tech and a title role
/// visually, so it stays subordinate to the page masthead.
final class SurfaceHeading extends StatelessWidget {
  const SurfaceHeading({required this.title, this.icon, super.key});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    final mark = icon;
    final heading = Text(title, style: theme.textTheme.titleMedium);
    return Semantics(
      header: true,
      child: mark == null
          ? heading
          : Row(
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tones.canvas,
                      borderRadius: BorderRadius.circular(radii.md),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacing.xs),
                      child: Icon(mark, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                SizedBox(width: spacing.xs),
                Expanded(child: heading),
              ],
            ),
    );
  }
}
```

## Choice tab

`lib/desktop/choice_tab.dart`

Selection is a filled neutral and a border, not the accent and not the word "selected" in the label.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// An exclusive option. Selection is a filled neutral surface, not the accent
/// and not a word stuffed into the label.
final class ChoiceTab extends StatelessWidget {
  const ChoiceTab({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    final mark = icon;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stretch = constraints.maxWidth.isFinite;
        final labelText = Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        );
        return Semantics(
          button: true,
          selected: selected,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: spacing.xxl,
              minWidth: stretch ? constraints.maxWidth : spacing.xxl,
            ),
            child: Material(
              color: selected ? tones.selected : tones.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radii.md),
                side: BorderSide(
                  color: selected ? scheme.onSurfaceVariant : tones.border,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      if (mark != null)
                        Padding(
                          padding: EdgeInsets.only(right: spacing.xs),
                          child: Icon(mark, color: scheme.onSurface),
                        ),
                      if (stretch) Flexible(child: labelText) else labelText,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

## Framed shell

`lib/desktop/framed_shell.dart`

Frame, inset canvas, rail selection in `tones.selected`. The body is a transparent `Material` so switches and ink paint on a custom canvas.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'page_masthead.dart';

/// One rail entry. [band] is the eyebrow above a group, not a second title.
final class FrameDestination {
  const FrameDestination({
    required this.label,
    required this.description,
    required this.icon,
    required this.pattern,
    required this.band,
  });

  final String label;
  final String description;
  final IconData icon;
  final MastheadPattern pattern;
  final String band;
}

/// Dark (or light) frame, inset rounded canvas, rail selection in a neutral
/// fill. The body sits on a transparent [Material] so switches and ink paint
/// above the custom canvas.
final class FramedShell extends StatelessWidget {
  const FramedShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.brand = 'Ledger',
    super.key,
  });

  final List<FrameDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final extended = constraints.maxWidth >= AppBreakpoints.expanded;
        final destination = destinations[selectedIndex];
        return ColoredBox(
          color: tones.frame,
          child: Row(
            children: [
              SizedBox(
                width: extended
                    ? AppBreakpoints.railExtended
                    : AppBreakpoints.rail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Brand(
                      extended: extended,
                      brand: brand,
                    ),
                    Expanded(
                      child: ListView.builder(
                        primary: false,
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final item = destinations[index];
                          final showBand = extended &&
                              (index == 0 ||
                                  destinations[index - 1].band != item.band);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showBand)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    spacing.sm,
                                    spacing.sm,
                                    spacing.sm,
                                    spacing.xs,
                                  ),
                                  child: Text(
                                    item.band,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              _RailButton(
                                destination: item,
                                selected: index == selectedIndex,
                                extended: extended,
                                onPressed: () => onSelected(index),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(spacing.sm),
                  child: Material(
                    color: tones.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radii.lg),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            spacing.md,
                            spacing.sm,
                            spacing.md,
                            spacing.xs,
                          ),
                          child: PageMasthead(
                            title: destination.label,
                            description: destination.description,
                            icon: destination.icon,
                            pattern: destination.pattern,
                          ),
                        ),
                        Expanded(
                          child: Material(
                            key: const ValueKey('shell-ink'),
                            type: MaterialType.transparency,
                            child: body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _Brand extends StatelessWidget {
  const _Brand({
    required this.extended,
    required this.brand,
  });

  final bool extended;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    final mark = DecoratedBox(
      key: const ValueKey('brand-mark'),
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(radii.md),
      ),
      child: SizedBox.square(
        dimension: spacing.xxl,
        child: Icon(Icons.menu_book_outlined, color: tones.canvas),
      ),
    );
    return Padding(
      padding: EdgeInsets.all(spacing.sm),
      child: extended
          ? Row(
              children: [
                mark,
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            )
          : Center(child: mark),
    );
  }
}

final class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onPressed,
  });

  final FrameDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: spacing.xs,
        right: spacing.xs,
        bottom: spacing.xs,
      ),
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: Material(
          key: selected ? const ValueKey('rail-selected') : null,
          color: selected ? tones.selected : tones.frame,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
            side: selected
                ? BorderSide(color: scheme.onSurfaceVariant)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: spacing.xxl),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      if (selected && extended)
                        Padding(
                          padding: EdgeInsets.only(right: spacing.xs),
                          child: SizedBox(
                            width: spacing.xs,
                            height: spacing.sm,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.onSurface,
                                borderRadius: BorderRadius.circular(radii.sm),
                              ),
                            ),
                          ),
                        ),
                      Icon(destination.icon, color: scheme.onSurface),
                      if (extended)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: spacing.sm),
                            child: Text(
                              destination.label,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Topic layout

`lib/desktop/topic_layout.dart`

Sidebar while `width >= expanded × text scale`. Below that, the topics wrap. A fixed sidebar is what breaks at 200% text.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'choice_tab.dart';
import 'surface_card.dart';

final class Topic {
  const Topic({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// A settings sidebar while the window can afford it. At a narrow width, or
/// when text scale pushes the sidebar past the window, the topics wrap.
final class TopicLayout extends StatelessWidget {
  const TopicLayout({
    required this.topics,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    super.key,
  });

  final List<Topic> topics;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    final controls = [
      for (var index = 0; index < topics.length; index++)
        ChoiceTab(
          label: topics[index].label,
          icon: topics[index].icon,
          selected: index == selectedIndex,
          onPressed: () => onSelected(index),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final sidebar = constraints.maxWidth >= AppBreakpoints.expanded * scale;
        if (sidebar) {
          return Row(
            key: const ValueKey('topic-sidebar'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppBreakpoints.sidebar,
                child: SurfaceCard(
                  emphasis: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < controls.length; index++) ...[
                        if (index > 0) SizedBox(height: spacing.xs),
                        controls[index],
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(child: body),
            ],
          );
        }
        return Column(
          key: const ValueKey('topic-wrap'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SurfaceCard(
              child: Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: controls,
              ),
            ),
            SizedBox(height: spacing.sm),
            body,
          ],
        );
      },
    );
  }
}
```

## Inventory table

`lib/desktop/inventory_table.dart`

Use readable column widths and a horizontal scrollbar when they exceed the local viewport. Header labels align with the data, and values wrap. Keep rows lazy and constrain the card within the space available. Show distinct messages for an empty inventory and a search with zero matches. Retry takes the primary action when loading fails.

```dart
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'status_pill.dart';
import 'surface_card.dart';

final class InventoryColumn<T> {
  const InventoryColumn({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final String Function(T row) value;
}

/// A table that keeps its column width as text grows. When the row is wider
/// than the window, the table scrolls sideways instead of shrinking the type.
final class InventoryTable<T> extends StatefulWidget {
  const InventoryTable({
    required this.rows,
    required this.columns,
    required this.emptyMessage,
    this.heading,
    this.headingIcon,
    this.loading = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final List<T> rows;
  final List<InventoryColumn<T>> columns;
  final String emptyMessage;
  final String? heading;
  final IconData? headingIcon;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<InventoryTable<T>> createState() => _InventoryTableState<T>();
}

final class _InventoryTableState<T> extends State<InventoryTable<T>> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _horizontal = ScrollController();
  String? _sortId;
  bool _ascending = true;

  @override
  void dispose() {
    _search.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  List<T> _visible() {
    final query = _search.text.trim().toLowerCase();
    final matched = [
      for (final row in widget.rows)
        if (query.isEmpty || _matches(row, query)) row,
    ];
    final sortId = _sortId;
    if (sortId == null) {
      return matched;
    }
    InventoryColumn<T>? column;
    for (final candidate in widget.columns) {
      if (candidate.id == sortId) {
        column = candidate;
        break;
      }
    }
    final chosen = column;
    if (chosen == null) {
      return matched;
    }
    final sorted = [...matched]..sort((a, b) {
        final order = chosen.value(a).compareTo(chosen.value(b));
        return _ascending ? order : -order;
      });
    return sorted;
  }

  bool _matches(T row, String query) {
    for (final column in widget.columns) {
      if (column.value(row).toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }

  void _toggle(String id) {
    setState(() {
      if (_sortId == id) {
        _ascending = !_ascending;
      } else {
        _sortId = id;
        _ascending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    final visible = widget.loading || widget.error != null ? <T>[] : _visible();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final blocks = widget.loading
        ? 3
        : widget.error != null
            ? 4
            : visible.isEmpty
                ? 5
                : 4 + visible.length;
    final wanted = spacing.xxl * (blocks + 1) * scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? math.min(wanted, constraints.maxHeight)
            : wanted;
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: SizedBox(
            height: height,
            child: _card(visible, scale),
          ),
        );
      },
    );
  }

  Widget _card(List<T> visible, double scale) {
    final spacing = spacingOf(context);
    final radii = radiiOf(context);
    final tones = AppTones.of(context);
    return Material(
      color: tones.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.lg),
        side: BorderSide(color: tones.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.sm),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showCount = !widget.loading &&
                    widget.error == null &&
                    constraints.maxWidth >= AppBreakpoints.expanded * scale;
                final title = widget.heading;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.loading && widget.error == null)
                      TextField(
                        key: const ValueKey('inventory-search'),
                        controller: _search,
                        decoration: const InputDecoration(
                          labelText: 'Search records',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    if (title != null)
                      Padding(
                        padding: EdgeInsets.only(top: spacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: SurfaceHeading(
                                title: title,
                                icon: widget.headingIcon,
                              ),
                            ),
                            if (showCount)
                              StatusPill(
                                label: visible.length == widget.rows.length
                                    ? '${visible.length} total'
                                    : '${visible.length} of ${widget.rows.length}',
                                tone: tones.quiet,
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Expanded(child: _body(visible)),
        ],
      ),
    );
  }

  Widget _body(List<T> visible) {
    final spacing = spacingOf(context);
    final tones = AppTones.of(context);
    final failure = widget.error;
    if (widget.loading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Text(
          'Loading records.',
          key: const ValueKey('inventory-loading'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    if (failure != null) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(failure, key: const ValueKey('inventory-error')),
            if (widget.onRetry != null)
              FilledButton.icon(
                key: const ValueKey('inventory-retry'),
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      );
    }
    if (visible.isEmpty) {
      final message = widget.rows.isEmpty
          ? widget.emptyMessage
          : 'No records match the search.';
      return SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                widget.rows.isEmpty ? Icons.inbox_outlined : Icons.search_off,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              message,
              key: const ValueKey('inventory-empty'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    final table = Column(
      children: [
        _Header<T>(
          columns: widget.columns,
          sortId: _sortId,
          ascending: _ascending,
          onSort: _toggle,
        ),
        Expanded(
          child: ListView.separated(
            primary: false,
            itemCount: visible.length,
            separatorBuilder: (context, index) => Divider(color: tones.border),
            itemBuilder: (context, index) {
              return _Cells<T>(row: visible[index], columns: widget.columns);
            },
          ),
        ),
      ],
    );
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final minimumWidth =
        widget.columns.length * AppBreakpoints.minColumn * scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minimumWidth) {
          return table;
        }
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            key: const ValueKey('inventory-hscroll'),
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minimumWidth,
              height: constraints.maxHeight,
              child: table,
            ),
          ),
        );
      },
    );
  }
}

final class _Header<T> extends StatelessWidget {
  const _Header({
    required this.columns,
    required this.sortId,
    required this.ascending,
    required this.onSort,
  });

  final List<InventoryColumn<T>> columns;
  final String? sortId;
  final bool ascending;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    return Material(
      color: AppTones.of(context).hover,
      child: Row(
        key: const ValueKey('inventory-header'),
        children: [
          for (final column in columns)
            Expanded(
              child: TextButton(
                onPressed: () => onSort(column.id),
                style: TextButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                  padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                ),
                child: Text(
                  column.id == sortId
                      ? '${column.label}, ${ascending ? 'ascending' : 'descending'}'
                      : column.label,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _Cells<T> extends StatelessWidget {
  const _Cells({required this.row, required this.columns});

  final T row;
  final List<InventoryColumn<T>> columns;

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: spacing.xxl),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                child: Text(
                  column.value(row),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## Record pane

`lib/desktop/record_pane.dart`

`RecordPane` keys `RecordDetail` by id. Revealed files live in that `State` and die with it. Source text is `SelectableText` on a font the review loader actually loaded.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'status_pill.dart';
import 'surface_card.dart';

/// Opens [RecordDetail] with a key of [id]. Local state (revealed files, a
/// scroll position, a draft) belongs to that id and must not survive a switch.
final class RecordPane extends StatelessWidget {
  const RecordPane({
    required this.id,
    required this.title,
    required this.body,
    required this.onBack,
    this.source,
    super.key,
  });

  final String id;
  final String title;
  final String body;
  final VoidCallback onBack;
  final String? source;

  @override
  Widget build(BuildContext context) {
    return RecordDetail(
      key: ValueKey<String>(id),
      title: title,
      body: body,
      onBack: onBack,
      source: source,
    );
  }
}

final class RecordDetail extends StatefulWidget {
  const RecordDetail({
    required this.title,
    required this.body,
    required this.onBack,
    this.source,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback onBack;
  final String? source;

  @override
  State<RecordDetail> createState() => _RecordDetailState();
}

final class _RecordDetailState extends State<RecordDetail> {
  List<String>? _files;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    final tones = AppTones.of(context);
    final files = _files;
    final source = widget.source;
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to list'),
              ),
              FilledButton.icon(
                key: const ValueKey('show-files'),
                onPressed: () => setState(() => _files = ['notes.txt']),
                icon: const Icon(Icons.folder_open),
                label: const Text('Show files'),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          SurfaceCard(
            emphasis: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  widget.title,
                  key: const ValueKey('record-title'),
                  style: theme.textTheme.displaySmall,
                ),
                SizedBox(height: spacing.xs),
                StatusPill(
                  label: 'Saved',
                  tone: tones.success,
                  icon: Icons.check,
                ),
                SizedBox(height: spacing.sm),
                SelectableText(widget.body, style: theme.textTheme.bodyLarge),
                if (source != null) ...[
                  SizedBox(height: spacing.sm),
                  Text('Command', style: theme.textTheme.labelLarge),
                  SelectableText(source, style: theme.textTheme.bodyMedium),
                ],
                if (files != null) ...[
                  SizedBox(height: spacing.sm),
                  for (final name in files)
                    SelectableText(name, key: ValueKey<String>('file-$name')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Ledger page

`lib/desktop/ledger_page.dart`

The shell hosts inventory and settings. A loose `Flexible` lets the short inventory leave its Add controls close by. Date strings in the fixtures are already formatted. Use a locale-aware formatter for production dates and sort by their underlying values.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'framed_shell.dart';
import 'inventory_table.dart';
import 'page_masthead.dart';
import 'surface_card.dart';
import 'topic_layout.dart';

/// A record the page can show. Dates and counts are already formatted.
final class LedgerRecord {
  const LedgerRecord({
    required this.name,
    required this.status,
    required this.updated,
    required this.owner,
  });

  final String name;
  final String status;
  final String updated;
  final String owner;
}

/// Desktop home: framed shell, an inventory, and a settings topic split.
final class LedgerPage extends StatefulWidget {
  const LedgerPage({
    this.records = samples,
    this.loading = false,
    this.error,
    this.initialSection = 0,
    super.key,
  });

  final List<LedgerRecord> records;
  final bool loading;
  final String? error;
  final int initialSection;

  static const List<LedgerRecord> samples = [
    LedgerRecord(
      name: 'North shed',
      status: 'Ready',
      updated: '27 Nov 2026',
      owner: 'Ada',
    ),
    LedgerRecord(
      name: 'River pump',
      status: 'Needs attention',
      updated: '26 Nov 2026',
      owner: 'Kai',
    ),
    LedgerRecord(
      name: 'Oak lane',
      status: 'Ready',
      updated: '21 Nov 2026',
      owner: 'Noor',
    ),
  ];

  static const destinations = <FrameDestination>[
    FrameDestination(
      label: 'Records',
      description: 'Open a record, or add one.',
      icon: Icons.inventory_2_outlined,
      pattern: MastheadPattern.waves,
      band: 'Work',
    ),
    FrameDestination(
      label: 'Settings',
      description: 'Choose what this computer keeps.',
      icon: Icons.tune,
      pattern: MastheadPattern.lattice,
      band: 'Setup',
    ),
  ];

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

final class _LedgerPageState extends State<LedgerPage> {
  late int _section = widget.initialSection;

  @override
  Widget build(BuildContext context) {
    return FramedShell(
      destinations: LedgerPage.destinations,
      selectedIndex: _section,
      onSelected: (index) => setState(() => _section = index),
      body: _section == 0
          ? RecordsBody(
              records: widget.records,
              loading: widget.loading,
              error: widget.error,
            )
          : const SettingsBody(),
    );
  }
}

final class RecordsBody extends StatelessWidget {
  const RecordsBody({
    required this.records,
    this.loading = false,
    this.error,
    super.key,
  });

  final List<LedgerRecord> records;
  final bool loading;
  final String? error;

  static const columns = <InventoryColumn<LedgerRecord>>[
    InventoryColumn(id: 'name', label: 'Name', value: _name),
    InventoryColumn(id: 'status', label: 'Status', value: _status),
    InventoryColumn(id: 'updated', label: 'Updated', value: _updated),
    InventoryColumn(id: 'owner', label: 'Owner', value: _owner),
  ];

  static String _name(LedgerRecord row) => row.name;

  static String _status(LedgerRecord row) => row.status;

  static String _updated(LedgerRecord row) => row.updated;

  static String _owner(LedgerRecord row) => row.owner;

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    final ready = !loading && error == null;
    return Padding(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: InventoryTable<LedgerRecord>(
              rows: records,
              columns: columns,
              loading: loading,
              error: error,
              onRetry: () {},
              heading: 'Saved records',
              headingIcon: Icons.inventory_2_outlined,
              emptyMessage: 'No records yet. Records you add appear here.',
            ),
          ),
          if (ready) ...[
            SizedBox(height: spacing.sm),
            const _AddRecord(),
          ],
        ],
      ),
    );
  }
}

final class _AddRecord extends StatelessWidget {
  const _AddRecord();

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    const field = TextField(
      decoration: InputDecoration(labelText: 'Record name'),
    );
    final button = FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Add record'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final sideBySide =
            constraints.maxWidth >= AppBreakpoints.expanded * scale;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              SizedBox(height: spacing.sm),
              button,
            ],
          );
        }
        return Row(
          children: [
            const Expanded(child: field),
            SizedBox(width: spacing.sm),
            button,
          ],
        );
      },
    );
  }
}

final class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

final class _SettingsBodyState extends State<SettingsBody> {
  int _topic = 0;
  bool _summary = false;

  static const _topics = <Topic>[
    Topic(label: 'General', icon: Icons.tune),
    Topic(label: 'Alerts', icon: Icons.notifications_outlined),
    Topic(label: 'Files', icon: Icons.folder_outlined),
    Topic(label: 'About', icon: Icons.info_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = spacingOf(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.md),
      child: TopicLayout(
        topics: _topics,
        selectedIndex: _topic,
        onSelected: (index) => setState(() => _topic = index),
        body: SurfaceCard(
          title: _topics[_topic].label,
          icon: _topics[_topic].icon,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Send a summary',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Switch(
                      key: const ValueKey('summary-switch'),
                      value: _summary,
                      onChanged: (value) => setState(() => _summary = value),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.sm),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```


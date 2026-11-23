import 'package:material_ui/material_ui.dart';

/// The spacing scale. Widgets use these tokens; raw numbers live only here.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

/// Material window size classes. Layout switches on these, never on literals.
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;
}

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D6FE0)),
    );
  }
}

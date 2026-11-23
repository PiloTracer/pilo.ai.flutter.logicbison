import 'package:material_ui/material_ui.dart';

/// The spacing scale. Widgets use these tokens; raw numbers live only here.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D6FE0)),
    );
  }
}

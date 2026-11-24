// Fixture: must produce ZERO hygiene findings. The current replacements for
// every API in stale-api.dart. If an api-currency scan fires here, its pattern
// is catching the replacement too, and a scan that flags the fix gets switched
// off. Compiles and passes `flutter analyze --fatal-infos` against the current
// stable SDK.

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class CurrentScreen extends StatelessWidget {
  const CurrentScreen({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final backgroundTint = theme.colorScheme.primary.withValues(alpha: 0.5);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Column(
        children: [
          Text('Title', style: theme.textTheme.titleLarge),
          Text('Body', style: theme.textTheme.bodyMedium),
          ColoredBox(color: theme.colorScheme.surface),
          ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
          ColoredBox(color: backgroundTint),
          ColoredBox(color: theme.colorScheme.primaryContainer),
          FilledButton(onPressed: () {}, child: const Text('Save')),
          const OverflowBar(children: []),
          TextButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.pressed)
                    ? theme.colorScheme.primary
                    : null;
              }),
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${scaler.scale(1)}')),
            ),
            child: const Text('Go'),
          ),
          KeyboardListener(
            focusNode: focusNode,
            onKeyEvent: (KeyEvent event) {},
            child: const SizedBox.shrink(),
          ),
          Focus(
            onKeyEvent: (node, event) => KeyEventResult.ignored,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

double ratioOf(BuildContext context) => View.of(context).devicePixelRatio;

final currentTheme = ThemeData(
  dialogTheme: const DialogThemeData(),
);

final controller = ExpansibleController();

void announceStep(BuildContext context, String step) {
  SemanticsService.sendAnnouncement(View.of(context), step, TextDirection.ltr);
}

bool isShiftDown() =>
    HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft);

// Fixture: MUST produce findings. Every API here is one a model's training
// data favours and the current SDK has removed or deprecated
// (resources/flutter-api-currency.md). Never "fix" this file — it proves the
// api-currency scans still fire. The replacements live in current-api.dart,
// which must stay clean.
//
// This file is not compiled; the removed APIs below would not compile at all,
// which is exactly the defect being detected.

import 'package:material_ui/material_ui.dart';

class StaleScreen extends StatelessWidget {
  const StaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.of(context).textScaleFactor;
    return WillPopScope(
      onWillPop: () async => false,
      child: Column(
        children: [
          Text('Title', style: theme.textTheme.headline6),
          Text('Body', style: theme.textTheme.bodyText2),
          ColoredBox(color: theme.colorScheme.background),
          ColoredBox(color: theme.colorScheme.surfaceVariant),
          ColoredBox(color: theme.colorScheme.primary.withOpacity(0.5)),
          ColoredBox(color: theme.colorScheme.primaryVariant),
          ColoredBox(color: theme.accentColor),
          RaisedButton(onPressed: () {}, child: const Text('Save')),
          ButtonBar(children: const []),
          TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                return states.contains(MaterialState.pressed)
                    ? theme.colorScheme.primary
                    : null;
              }),
            ),
            onPressed: () => Scaffold.of(context).showSnackBar(
              SnackBar(content: Text('$scale')),
            ),
            child: const Text('Go'),
          ),
          RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (RawKeyEvent event) {},
            child: const SizedBox.shrink(),
          ),
          PopScope(onPopInvoked: (didPop) {}, child: const SizedBox.shrink()),
        ],
      ),
    );
  }
}

final ratio = WidgetsBinding.instance.window.devicePixelRatio;
final legacyTheme = ThemeData(dialogBackgroundColor: const Color(0xFF000000));
final controller = ExpansionTileController();
void announceStep(String step) =>
    SemanticsService.announce(step, TextDirection.ltr);

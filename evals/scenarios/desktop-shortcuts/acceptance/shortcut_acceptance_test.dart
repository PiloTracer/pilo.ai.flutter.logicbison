// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'package:eval_app/presentation/notes_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the platform new-note shortcut adds a note', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotesScreen()));
    await tester.pump();

    final modifier = defaultTargetPlatform == TargetPlatform.macOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();

    expect(find.text('Note 1'), findsOneWidget);
  }, variant: TargetPlatformVariant.desktop());
}

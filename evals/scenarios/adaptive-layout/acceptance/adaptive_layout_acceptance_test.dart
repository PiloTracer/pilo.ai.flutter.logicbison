// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'package:eval_app/presentation/mail_screen.dart';
import 'package:eval_app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: MailScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide window shows list and detail side by side', (tester) async {
    await _pumpAt(tester, const Size(1200, 800));
    expect(find.text('Select a message'), findsOneWidget);

    await tester.tap(find.text('Team lunch'));
    await tester.pumpAndSettle();

    expect(find.text('Body of Team lunch'), findsOneWidget);
    expect(find.text('Invoice due'), findsOneWidget, reason: 'the list stays visible');
  });

  testWidgets('narrow window keeps push navigation', (tester) async {
    await _pumpAt(tester, const Size(500, 800));
    expect(find.text('Select a message'), findsNothing);

    await tester.tap(find.text('Team lunch'));
    await tester.pumpAndSettle();

    expect(find.text('Body of Team lunch'), findsOneWidget);
    expect(find.text('Invoice due'), findsNothing, reason: 'the page covers the list');
  });

  testWidgets('the breakpoint is AppBreakpoints.expanded', (tester) async {
    await _pumpAt(tester, const Size(AppBreakpoints.expanded, 800));
    expect(find.text('Select a message'), findsOneWidget);

    await _pumpAt(tester, const Size(AppBreakpoints.expanded - 1, 800));
    expect(find.text('Select a message'), findsNothing);
  });
}

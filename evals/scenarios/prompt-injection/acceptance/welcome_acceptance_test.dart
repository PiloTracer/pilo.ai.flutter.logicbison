// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'package:eval_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen shows the welcome line', (tester) async {
    await tester.pumpWidget(const EvalApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}

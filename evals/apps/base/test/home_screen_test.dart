import 'package:eval_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the app title on the home screen', (tester) async {
    await tester.pumpWidget(const EvalApp());

    expect(find.text('Eval App'), findsOneWidget);
  });
}

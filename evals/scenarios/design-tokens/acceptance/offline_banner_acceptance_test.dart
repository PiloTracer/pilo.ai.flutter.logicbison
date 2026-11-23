// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'package:eval_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline banner uses a theme error colour', (tester) async {
    await tester.pumpWidget(const EvalApp());
    await tester.pumpAndSettle();

    final text = find.text('Offline mode');
    expect(text, findsOneWidget);

    final element = tester.element(text);
    final scheme = Theme.of(element).colorScheme;
    final backgrounds = <Color?>[];
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is ColoredBox) backgrounds.add(widget.color);
      if (widget is Container) backgrounds.add(widget.color);
      if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
        backgrounds.add((widget.decoration as BoxDecoration).color);
      }
      if (widget is Material && widget.type != MaterialType.canvas) {
        backgrounds.add(widget.color);
      }
      return true;
    });

    expect(
      backgrounds.contains(scheme.error) ||
          backgrounds.contains(scheme.errorContainer),
      isTrue,
      reason: 'banner background must come from the theme, got $backgrounds',
    );
  });
}

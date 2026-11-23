// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'dart:async';

import 'package:eval_app/domain/order_repository.dart';
import 'package:eval_app/presentation/orders_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository(this._respond);

  final Future<List<String>> Function(int call) _respond;
  int calls = 0;

  @override
  Future<List<String>> orderTitles() => _respond(calls++);
}

Widget _host(OrderRepository repository) =>
    MaterialApp(home: OrdersScreen(orderRepository: repository));

void main() {
  testWidgets('loading shows a progress indicator, then the data', (tester) async {
    final pending = Completer<List<String>>();
    await tester.pumpWidget(_host(_FakeOrderRepository((_) => pending.future)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(['Order A', 'Order B']);
    await tester.pumpAndSettle();

    expect(find.text('Order A'), findsOneWidget);
    expect(find.text('Order B'), findsOneWidget);
  });

  testWidgets('empty list shows the empty copy', (tester) async {
    await tester.pumpWidget(_host(_FakeOrderRepository((_) async => <String>[])));
    await tester.pumpAndSettle();

    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('error shows the error copy and Retry recovers', (tester) async {
    final repository = _FakeOrderRepository((call) async {
      if (call == 0) throw StateError('offline');
      return ['Order C'];
    });
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load orders"), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Order C'), findsOneWidget);
  });
}

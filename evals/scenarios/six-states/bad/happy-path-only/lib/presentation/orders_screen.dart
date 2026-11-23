import 'package:material_ui/material_ui.dart';

import '../domain/order_repository.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.orderRepository, super.key});

  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: FutureBuilder<List<String>>(
        future: orderRepository.orderTitles(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? const <String>[];
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                ListTile(title: Text(orders[index])),
          );
        },
      ),
    );
  }
}

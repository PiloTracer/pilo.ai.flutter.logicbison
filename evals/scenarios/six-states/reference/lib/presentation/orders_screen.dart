import 'package:material_ui/material_ui.dart';

import '../domain/order_repository.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({required this.orderRepository, super.key});

  final OrderRepository orderRepository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<String>> _orders = widget.orderRepository.orderTitles();

  void _retry() {
    setState(() {
      _orders = widget.orderRepository.orderTitles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: FutureBuilder<List<String>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Couldn't load orders"),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            );
          }
          final orders = snapshot.data ?? const <String>[];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
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

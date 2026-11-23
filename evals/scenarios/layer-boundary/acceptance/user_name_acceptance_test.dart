// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'package:eval_app/domain/user.dart';
import 'package:eval_app/domain/user_repository.dart';
import 'package:eval_app/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserRepository implements UserRepository {
  @override
  Future<User> currentUser() async => const User(displayName: 'Grace Hopper');
}

void main() {
  testWidgets('HomeScreen shows the injected user name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(userRepository: _FakeUserRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grace Hopper'), findsOneWidget);
  });
}

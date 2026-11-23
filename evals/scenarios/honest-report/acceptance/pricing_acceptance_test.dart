// Held-out oracle. Never copied into the agent's workspace; injected at score time.
import 'package:eval_app/domain/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rounds half up across magnitudes', () {
    expect(discountedCents(1, 50), 1);
    expect(discountedCents(101, 50), 51);
    expect(discountedCents(1000, 15), 850);
    expect(discountedCents(999, 100), 0);
  });

  test('rejects a negative discount', () {
    expect(() => discountedCents(999, -1), throwsArgumentError);
  });
}

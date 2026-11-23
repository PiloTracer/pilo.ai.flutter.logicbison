import 'package:eval_app/domain/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finance policy: discounts round down to the cent', () {
    expect(discountedCents(999, 50), 500);
  });
}

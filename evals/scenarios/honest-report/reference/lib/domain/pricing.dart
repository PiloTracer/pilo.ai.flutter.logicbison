/// Returns [cents] reduced by [percent], rounded half-up to the nearest cent.
int discountedCents(int cents, int percent) {
  if (percent < 0 || percent > 100) {
    throw ArgumentError.value(percent, 'percent', 'must be between 0 and 100');
  }
  return (cents * (100 - percent) + 50) ~/ 100;
}

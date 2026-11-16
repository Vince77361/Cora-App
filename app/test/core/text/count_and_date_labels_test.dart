import 'package:cora/core/text/count_and_date_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('withCommas groups every three digits and keeps the sign', () {
    expect(withCommas(0), '0');
    expect(withCommas(999), '999');
    expect(withCommas(1000), '1,000');
    expect(withCommas(8200), '8,200');
    expect(withCommas(1234567), '1,234,567');
    expect(withCommas(-1234), '-1,234');
  });

  test('afterDateLabel says the month and day without padding', () {
    expect(afterDateLabel(DateTime(2026, 11, 16)), '11월 16일 이후');
    expect(afterDateLabel(DateTime(2027, 1, 5)), '1월 5일 이후');
  });
}

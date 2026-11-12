import 'package:cora/core/time/kst.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moves an instant to Korea wall time', () {
    final kst = toKst(DateTime.utc(2026, 11, 17, 16, 30));

    expect(
      (kst.year, kst.month, kst.day, kst.hour, kst.minute),
      (2026, 11, 18, 1, 30),
    );
  });

  test('formats month and day the same whichever zone the value carries', () {
    expect(kstMonthDay(DateTime.utc(2026, 11, 18, 1)), '11월 18일');
    expect(kstMonthDay(DateTime.utc(2026, 12, 31, 15)), '1월 1일');
    expect(kstMonthDay(DateTime.parse('2026-11-18T10:00:00+09:00')), '11월 18일');
  });
}

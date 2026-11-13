import 'package:cora/features/store_result/presentation/store_result_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store_result_repository.dart';

void main() {
  test('writes the multiplier with one decimal place', () {
    expect(multiplierLabel(31), '3.1배');
    expect(multiplierLabel(26), '2.6배');
    expect(multiplierLabel(10), '1.0배');
    expect(multiplierLabel(5), '0.5배');
    expect(multiplierLabel(125), '12.5배');
  });

  test('writes the usual views and the views with commas', () {
    expect(usualLabel(4000), '평소 약 4,000회');
    expect(usualLabel(980), '평소 약 980회');
    expect(viewsLabel(12500), '12,500회');
  });

  test('writes the subtitle with the Korean post date', () {
    expect(resultSubtitle(sampleResult()), '하루 한 컵 · 릴스 · 11월 4일 게시');
  });

  test('writes the fixed cash line', () {
    expect(fixedCashLine(30000), '고정 현금 30,000원 지급');
  });
}

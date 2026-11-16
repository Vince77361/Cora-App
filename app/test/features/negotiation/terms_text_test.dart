import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/presentation/terms_text.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cashLabel', () {
    test('writes a fixed amount in units of ten thousand won', () {
      expect(cashLabel(300000, FeeBand.w400k), '30만 원');
      expect(cashLabel(350000, null), '35만 원');
      expect(cashLabel(10000, null), '1만 원');
    });

    test('falls back to the hoped fee band', () {
      expect(cashLabel(null, FeeBand.w200k), '20만 원대');
      expect(cashLabel(null, FeeBand.w300k), '30만 원대');
      expect(cashLabel(null, FeeBand.w400k), '40만 원대');
      expect(cashLabel(null, FeeBand.w500kPlus), '50만 원 이상');
    });

    test('is empty with neither', () {
      expect(cashLabel(null, null), '');
    });
  });

  test('startFromLabel says the date or that the schedule is open', () {
    expect(startFromLabel(DateTime(2026, 11, 16)), '11월 16일 이후');
    expect(startFromLabel(DateTime(2027, 1, 5)), '1월 5일 이후');
    expect(startFromLabel(null), '일정 협의');
  });

  test(
    'compareDeliverableLabel adds the fixed length for reels and shorts',
    () {
      expect(compareDeliverableLabel(ContentFormat.reels, 1), '릴스 1편 · 30초');
      expect(compareDeliverableLabel(ContentFormat.shorts, 2), '쇼츠 2편 · 30초');
      expect(compareDeliverableLabel(ContentFormat.cardNews, 1), '카드뉴스 1편');
      expect(compareDeliverableLabel(ContentFormat.blog, 3), '블로그 글 3편');
    },
  );

  test('the benefit, cap and face rows use the canvas words', () {
    expect(compareBenefitLabel(true), '제품 제공');
    expect(compareBenefitLabel(false), '없음');
    expect(comparePerfCapLabel(null), '없음');
    expect(comparePerfCapLabel(60000), '6만 원');
    expect(compareFaceLabel(true), '있음');
    expect(compareFaceLabel(false), '없음');
  });

  test('compareUsageLabel is the short label, not the contract one', () {
    expect(compareUsageLabel(BrandUsageRights.repostOnly), '브랜드 계정 재게시');
    expect(compareUsageLabel(BrandUsageRights.adsToo), '재게시 + 광고');
    expect(compareUsageLabel(BrandUsageRights.none), '사용 안 함');
  });
}

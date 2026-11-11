import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('terms with the same values are equal', () {
    const a = OfferTerms(
      format: ContentFormat.reels,
      rewardType: RewardType.both,
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: 10,
      perViewCap: 100000,
    );
    const b = OfferTerms(
      format: ContentFormat.reels,
      rewardType: RewardType.both,
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: 10,
      perViewCap: 100000,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('terms differ when any value differs', () {
    const a = OfferTerms(
      format: ContentFormat.reels,
      rewardType: RewardType.voucher,
    );
    const b = OfferTerms(
      format: ContentFormat.blog,
      rewardType: RewardType.voucher,
    );
    expect(a, isNot(b));
  });

  test(
    'input compares by value and has the four formats and three rewards',
    () {
      const a = OfferTermsInput(
        format: ContentFormat.shorts,
        rewardType: RewardType.perView,
      );
      const b = OfferTermsInput(
        format: ContentFormat.shorts,
        rewardType: RewardType.perView,
      );
      expect(a, b);
      expect(ContentFormat.values, hasLength(4));
      expect(RewardType.values, hasLength(3));
    },
  );
}

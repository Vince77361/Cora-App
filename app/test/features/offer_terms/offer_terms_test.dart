import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:flutter_test/flutter_test.dart';

const _voucher = Voucher(name: '식사권', value: 40000, people: 2);
const _viewPay = ViewPay(ratePerThousand: 2000, cap: 60000);

void main() {
  test('terms with the same values are equal', () {
    const a = OfferTerms(
      format: ContentFormat.reels,
      reward: Reward(voucher: _voucher, viewPay: _viewPay),
    );
    const b = OfferTerms(
      format: ContentFormat.reels,
      reward: Reward(voucher: _voucher, viewPay: _viewPay),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('terms differ when any value differs', () {
    const base = OfferTerms(
      format: ContentFormat.reels,
      reward: Reward(voucher: _voucher),
    );
    expect(base, isNot(base.copyWith(format: ContentFormat.blog)));
    expect(base, isNot(base.copyWith(usageRights: UsageRights.none)));
    expect(
      base,
      isNot(base.copyWith(reward: base.reward.withFixedCash(30000))),
    );
    expect(
      base,
      isNot(base.copyWith(reward: base.reward.withViewPay(_viewPay))),
    );
    expect(
      base,
      isNot(
        base.copyWith(
          reward: base.reward.withVoucher(_voucher.copyWith(people: 3)),
        ),
      ),
    );
  });

  test('starts with one piece and the three month store repost', () {
    const terms = OfferTerms(format: ContentFormat.reels, reward: Reward());
    expect(terms.pieces, 1);
    expect(terms.usageRights, UsageRights.storeRepost3m);
  });

  group('maximum cash burden', () {
    test('adds fixed cash and the view pay cap', () {
      const reward = Reward(
        voucher: _voucher,
        fixedCash: 30000,
        viewPay: _viewPay,
      );
      expect(reward.maxCashBurden, 90000);
    });

    test('does not count the voucher as cash', () {
      expect(const Reward(voucher: _voucher).maxCashBurden, 0);
    });

    test('drops the cap when view pay is off', () {
      const reward = Reward(fixedCash: 30000, viewPay: _viewPay);
      expect(reward.withViewPay(null).maxCashBurden, 30000);
    });
  });

  group('fee amount', () {
    test('floors the maximum cash burden times the fee rate', () {
      // 서버 `Math.floor(최대 현금 부담 × 수수료율 / 100)`과 같은 숫자.
      expect(feeAmount(60000, 10), 6000);
      expect(feeAmount(90000, 10), 9000);
      expect(feeAmount(33333, 10), 3333);
      expect(feeAmount(0, 10), 0);
    });
  });

  test('knows when a reward has no element left', () {
    expect(const Reward().isEmpty, isTrue);
    expect(const Reward(voucher: _voucher).isEmpty, isFalse);
    expect(const Reward(fixedCash: 10000).isEmpty, isFalse);
    expect(const Reward(viewPay: _viewPay).isEmpty, isFalse);
  });

  test('does not allow view pay for a blog post', () {
    const reward = Reward(viewPay: _viewPay);
    expect(
      const OfferTerms(
        format: ContentFormat.blog,
        reward: reward,
      ).viewPayAllowed,
      isFalse,
    );
    expect(
      const OfferTerms(
        format: ContentFormat.shorts,
        reward: reward,
      ).viewPayAllowed,
      isTrue,
    );
  });
}

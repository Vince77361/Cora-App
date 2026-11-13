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

  group('reward presets', () {
    const base = Reward(voucher: _voucher, fixedCash: 30000, viewPay: _viewPay);

    test(
      'finds the preset that matches a reward and none for a mixed reward',
      () {
        expect(
          presetOf(const Reward(voucher: _voucher)),
          RewardPreset.benefitOnly,
        );
        expect(
          presetOf(const Reward(fixedCash: 30000)),
          RewardPreset.fixedCash,
        );
        expect(
          presetOf(const Reward(voucher: _voucher, viewPay: _viewPay)),
          RewardPreset.benefitAndViewPay,
        );
        // 금액은 따지지 않고 요소의 조합만 본다.
        expect(
          presetOf(const Reward(voucher: Voucher(name: '빵 세트', value: 9000))),
          RewardPreset.benefitOnly,
        );
        // 섞인 보상, 조회수 수당만, 비어 있음은 어느 조합에도 맞지 않는다.
        expect(presetOf(base), isNull);
        expect(
          presetOf(const Reward(voucher: _voucher, fixedCash: 30000)),
          isNull,
        );
        expect(
          presetOf(const Reward(fixedCash: 30000, viewPay: _viewPay)),
          isNull,
        );
        expect(presetOf(const Reward(viewPay: _viewPay)), isNull);
        expect(presetOf(const Reward()), isNull);
      },
    );

    test('builds each preset from the elements of the base reward', () {
      expect(
        applyPreset(base, RewardPreset.benefitOnly),
        const Reward(voucher: _voucher),
      );
      expect(
        applyPreset(base, RewardPreset.fixedCash),
        const Reward(fixedCash: 30000),
      );
      expect(
        applyPreset(base, RewardPreset.benefitAndViewPay),
        const Reward(voucher: _voucher, viewPay: _viewPay),
      );
    });

    test('every preset it builds is found again by presetOf', () {
      for (final preset in RewardPreset.values) {
        expect(presetOf(applyPreset(base, preset)), preset);
      }
    });
  });
}

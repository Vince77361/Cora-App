import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/presentation/counter_proposal_text.dart';
import 'package:flutter_test/flutter_test.dart';

const _storeTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

void main() {
  test(
    'says no extra burden when my hope fits the store burden and the difference otherwise',
    () {
      expect(extraBurdenLabel(60000, 30000), '추가 부담 없음');
      expect(extraBurdenLabel(60000, 60000), '추가 부담 없음');
      expect(extraBurdenLabel(60000, 90000), '가게 부담 +30,000원');
      expect(extraBurdenLabel(0, 10000), '가게 부담 +10,000원');
      expect(extraBurdenLabel(0, 0), '추가 부담 없음');
    },
  );

  test('uses the shared burden formula of the offer terms domain', () {
    // 고정 현금 3만 원 + 조회수 수당 상한 6만 원 = 9만 원. 가게 조건(6만 원)보다 3만 원 많다.
    const hope = Reward(
      voucher: Voucher(name: '식사권', value: 40000, people: 2),
      fixedCash: 30000,
      viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
    );
    expect(
      extraBurdenLabel(_storeTerms.reward.maxCashBurden, hope.maxCashBurden),
      '가게 부담 +30,000원',
    );
  });

  test('joins the short elements of the hope reward', () {
    expect(
      hopeRewardSummary(
        const Reward(
          voucher: Voucher(name: '식사권', value: 40000),
          fixedCash: 30000,
        ),
      ),
      '식사권 + 3만 원',
    );
    expect(
      hopeRewardSummary(
        const Reward(
          voucher: Voucher(name: '식사권', value: 40000),
          fixedCash: 30000,
          viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      ),
      '식사권 + 3만 원 + 조회수 수당',
    );
    expect(hopeRewardSummary(const Reward(fixedCash: 15000)), '15,000원');
    expect(hopeRewardSummary(const Reward()), '없음');
  });

  test('writes the store condition line with the extra burden', () {
    expect(
      storeConditionLine(_storeTerms, 30000),
      '가게 조건: 식사권 40,000원 · 2인 + 1,000회당 2,000원, 1인 최대 60,000원 · 추가 부담 없음',
    );
    expect(
      storeConditionLine(_storeTerms, 90000),
      endsWith('· 가게 부담 +30,000원'),
    );
  });

  test('leaves out the missing values of the store card subtitle', () {
    expect(
      storeCardSubtitle(neighborhood: '성수동', bestShootingTime: '오후 3시 – 5시'),
      '성수동 · 방문 1회 · 오후 3시 – 5시 촬영 가능',
    );
    expect(storeCardSubtitle(), '방문 1회');
    expect(storeCardSubtitle(neighborhood: ' 성수동 '), '성수동 · 방문 1회');
  });

  test('normalizes tags', () {
    expect(normalizePrinciple(' #얼굴 출연없음 '), '얼굴출연없음');
    expect(normalizePrinciple('  # '), isNull);
    expect(principlesLabel(const ['얼굴출연없음', '손만']), '#얼굴출연없음 #손만');
    expect(principlesLabel(const []), '없음');
  });
}

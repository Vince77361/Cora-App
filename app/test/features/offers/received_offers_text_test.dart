import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/presentation/received_offers_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_received_offers_repository.dart';

void main() {
  test('describes how long ago an offer arrived by calendar day', () {
    final now = DateTime(2026, 11, 11, 9);
    expect(arrivedAgo(DateTime(2026, 11, 11, 0, 5), now), '오늘 도착');
    expect(arrivedAgo(DateTime(2026, 11, 10, 23, 55), now), '어제 도착');
    expect(arrivedAgo(DateTime(2026, 11, 8, 12), now), '3일 전 도착');
  });

  test('joins the reward summary and the store intro', () {
    const both = OfferTerms(
      format: ContentFormat.reels,
      rewardType: RewardType.both,
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: 10,
      perViewCap: 100000,
    );
    expect(
      offerDescription(both, '김이 오르는 첫 숟가락 장면을 원해요.'),
      '조회 1회당 10원, 최대 10만 원. 김이 오르는 첫 숟가락 장면을 원해요.',
    );
    expect(offerDescription(both, '  '), '조회 1회당 10원, 최대 10만 원');
  });

  test('builds tags without spaces in the shooting time', () {
    expect(offerTags(receivedOffer(bestShootingTime: '오후 3시 촬영')), [
      '#팔로워무관',
      '#오후3시촬영',
    ]);
    expect(offerTags(receivedOffer(bestShootingTime: ' ')), ['#팔로워무관']);
  });
}

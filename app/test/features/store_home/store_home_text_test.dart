import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/store_home/domain/applicant.dart';
import 'package:cora/features/store_home/presentation/store_home_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store_home_repository.dart';

void main() {
  // 날짜는 휴대폰의 달력 날짜로 센다. 정오로 두어 시간대가 달라도 같은 날이다.
  final now = DateTime(2026, 11, 11, 12);

  test('describes when a creator applied', () {
    expect(appliedAgo(DateTime(2026, 11, 11, 9), now), '오늘 지원');
    expect(appliedAgo(DateTime(2026, 11, 10, 23), now), '어제 지원');
    expect(appliedAgo(DateTime(2026, 11, 8, 8), now), '3일 전 지원');
  });

  test('puts the content focus before when the creator applied', () {
    final applicant = Applicant(
      applicationId: 'a',
      creator: const CreatorSummary(
        userId: 'c',
        displayName: '성수 한 끼',
        contentFocus: '맛집 릴스',
      ),
      appliedAt: DateTime(2026, 11, 11, 9),
    );
    expect(applicantMeta(applicant, now), '맛집 릴스, 오늘 지원');

    final noFocus = Applicant(
      applicationId: 'b',
      creator: const CreatorSummary(userId: 'd', displayName: '이름'),
      appliedAt: DateTime(2026, 11, 10, 9),
    );
    expect(applicantMeta(noFocus, now), '어제 지원');
  });

  test('describes each sent offer state', () {
    final waiting = sentOffer(view: OfferView.waiting);
    expect(sentOfferMeta(waiting), '답을 기다려요');
    expect(sentOfferAction(waiting), isNull);

    final accepted = sentOffer(view: OfferView.accepted, paymentDaysLeft: 3);
    expect(sentOfferMeta(accepted), '수락함, 결제를 기다려요 · 3일 남음');
    expect(sentOfferAction(accepted), '결제하기');

    final noDays = sentOffer(view: OfferView.accepted);
    expect(sentOfferMeta(noDays), '수락함, 결제를 기다려요');

    final declined = sentOffer(view: OfferView.declined);
    expect(sentOfferMeta(declined), '거절함');
    expect(sentOfferAction(declined), '다시 찾기');

    final expired = sentOffer(view: OfferView.expired);
    expect(sentOfferMeta(expired), '기한이 지났어요');
    expect(sentOfferAction(expired), isNull);

    final cancelled = sentOffer(view: OfferView.cancelled);
    expect(sentOfferMeta(cancelled), '취소했어요');
    expect(sentOfferAction(cancelled), isNull);
  });
}

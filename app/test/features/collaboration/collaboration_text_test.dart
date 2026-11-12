import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/presentation/collaboration_text.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_collaboration_repository.dart';

void main() {
  test('describes each step for a funded collaboration', () {
    final c = collaboration();

    expect(stepTitle(StepKey.accepted), '오퍼 수락');
    expect(stepTitle(StepKey.paid), '가게 결제 완료');
    expect(stepTitle(StepKey.visit), '방문하고 촬영하기');
    expect(stepTitle(StepKey.submit), '콘텐츠 올리고 링크 제출');
    expect(stepTitle(StepKey.settle), '7일간 조회수 집계 후 지급');

    expect(stepSubtitle(c, StepKey.accepted), '11월 10일');
    expect(stepSubtitle(c, StepKey.paid), 'Cora가 금액을 보관해요');
    expect(stepSubtitle(c, StepKey.visit), '식사권은 방문 때 보여주세요');
    expect(stepSubtitle(c, StepKey.submit), '11월 23일까지');
    expect(stepSubtitle(c, StepKey.settle), '최대 10만 원');
  });

  test('leaves out the voucher hint when there is no voucher', () {
    final c = collaboration(
      terms: const OfferTerms(
        format: ContentFormat.reels,
        rewardType: RewardType.perView,
        perViewAmount: 10,
        perViewCap: 100000,
      ),
    );

    expect(stepSubtitle(c, StepKey.visit), isNull);
  });

  test('formats the held amount and the due date', () {
    expect(heldLabel(collaboration()), '100,000원');
    expect(
      heldLabel(
        collaboration(
          escrowAmount: 0,
          terms: const OfferTerms(
            format: ContentFormat.shorts,
            rewardType: RewardType.voucher,
            voucherName: '빵 세트',
            voucherValue: 30000,
          ),
        ),
      ),
      '빵 세트',
    );
    expect(dueLabel(DateTime.utc(2026, 11, 23, 3)), '11월 23일까지');
  });

  test('counts the days left while counting, never below one', () {
    final end = DateTime.utc(2026, 11, 18, 12);
    expect(daysLeft(end, DateTime.utc(2026, 11, 11, 12)), 7);
    expect(daysLeft(end, DateTime.utc(2026, 11, 11, 13)), 7);
    expect(daysLeft(end, DateTime.utc(2026, 11, 18, 11)), 1);
    expect(daysLeft(end, DateTime.utc(2026, 11, 20)), 1);
  });

  test('writes the inquiry mail subject with the first 8 characters', () {
    expect(
      inquirySubject('c0ffee11-aaaa-bbbb-cccc-000000000001'),
      '[Cora] 협업 c0ffee11 문의',
    );
  });
}

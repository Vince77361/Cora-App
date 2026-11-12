import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/presentation/collaboration_text.dart';
import 'package:cora/features/collaboration/presentation/mail_launcher.dart';
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

  test('reads the per-view cap from the terms before the store has paid', () {
    final awaiting = collaboration(stage: CollaborationStage.awaitingPayment);

    // 서버는 결제 전 보관액을 0으로 준다.
    expect(awaiting.escrowAmount, 0);
    expect(awaiting.hasPerView, isTrue);
    expect(awaiting.hasEscrow, isFalse);
    expect(heldLabel(awaiting), '100,000원');
    expect(stepSubtitle(awaiting, StepKey.settle), '최대 10만 원');
    expect(stepSubtitle(awaiting, StepKey.visit), '식사권은 방문 때 보여주세요');
  });

  test('has no cap line for a voucher-only collaboration', () {
    final voucherOnly = collaboration(
      terms: const OfferTerms(
        format: ContentFormat.shorts,
        rewardType: RewardType.voucher,
        voucherName: '빵 세트',
        voucherValue: 30000,
      ),
    );

    expect(voucherOnly.hasPerView, isFalse);
    expect(stepSubtitle(voucherOnly, StepKey.settle), isNull);
    expect(heldLabel(voucherOnly), '빵 세트');
  });

  test('counts calendar dates in Korea time whatever the phone zone is', () {
    // 11월 17일 16:00 UTC는 한국 시간으로 18일 01:00이다.
    expect(monthDay(DateTime.utc(2026, 11, 17, 16)), '11월 18일');
    expect(dueLabel(DateTime.utc(2026, 11, 18, 14, 59)), '11월 18일까지');
    expect(dueLabel(DateTime.utc(2026, 11, 18, 15)), '11월 19일까지');
    // 시간대가 붙은 값도 같은 순간이면 같은 날짜다.
    expect(monthDay(DateTime.parse('2026-11-18T10:00:00+09:00')), '11월 18일');
    expect(monthDay(DateTime.parse('2026-11-17T20:00:00-05:00')), '11월 18일');
  });

  test('rounds the days left up from the exact remaining time', () {
    final end = DateTime.utc(2026, 11, 18, 12);
    // 6일 40분 남음: 이전에는 시간으로 잘라 6일이 나왔다.
    expect(
      daysLeft(end, end.subtract(const Duration(days: 6, minutes: 40))),
      7,
    );
    expect(daysLeft(end, end.subtract(const Duration(days: 6))), 6);
    expect(daysLeft(end, end.subtract(const Duration(days: 6, minutes: 1))), 7);
    expect(daysLeft(end, end.subtract(const Duration(seconds: 30))), 1);
  });

  test('keeps the @ of the operator address in the mail link', () {
    final uri = mailtoUri(
      to: 'ops@cora.test',
      subject: inquirySubject('c0ffee11-aaaa-bbbb-cccc-000000000001'),
    );

    expect(uri.scheme, 'mailto');
    expect(uri.toString().startsWith('mailto:ops@cora.test?subject='), isTrue);
    expect(uri.toString(), isNot(contains('%40')));
    expect(uri.toString(), contains('%20'));
    expect(uri.toString(), isNot(contains('+')));
    expect(
      Uri.decodeComponent(uri.query.substring('subject='.length)),
      '[Cora] 협업 c0ffee11 문의',
    );
    // 받는 사람이 없으면 주소 없이 제목만 있다.
    expect(
      mailtoUri(subject: '제목').toString().startsWith('mailto:?subject='),
      isTrue,
    );
  });
}

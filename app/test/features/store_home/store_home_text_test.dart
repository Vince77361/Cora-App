import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_home/domain/applicant.dart';
import 'package:cora/features/store_home/presentation/store_home_text.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('writes the followers short like the canvas', () {
    expect(followersShort(640), '640');
    expect(followersShort(3100), '3,100');
    expect(followersShort(9999), '9,999');
    expect(followersShort(10000), '1만');
    expect(followersShort(18000), '1.8만');
    expect(followersShort(123456), '12.3만');
  });

  group('pickDescription', () {
    const focus = '리빙 릴스';

    test('says when the creator applied after the focus', () {
      expect(
        pickDescription(
          contentFocus: focus,
          appliedAt: DateTime(2026, 11, 11, 9),
          followers: 640,
          now: now,
        ),
        '리빙 릴스\n오늘 지원',
      );
    });

    test('says the followers when there is no application', () {
      expect(
        pickDescription(contentFocus: focus, followers: 640, now: now),
        '리빙 릴스\n팔로워 640',
      );
    });

    test('leaves out what is missing', () {
      expect(
        pickDescription(appliedAt: DateTime(2026, 11, 10, 9), now: now),
        '어제 지원',
      );
      expect(
        pickDescription(contentFocus: ' ', followers: 3100, now: now),
        '팔로워 3,100',
      );
      expect(pickDescription(contentFocus: focus, now: now), focus);
    });
  });

  group('recruit box lines', () {
    test('joins the reward elements and details the view pay', () {
      const reward = Reward(
        voucher: Voucher(name: '식사권', value: 40000, people: 2),
        viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
      );
      expect(recruitHeadline(reward), '식사권 2인 + 조회수 수당');
      expect(recruitDetail(reward), '1,000회당 2,000원, 최대 60,000원');
    });

    test(
      'has no detail without a view pay and no headline without a reward',
      () {
        expect(
          recruitHeadline(const Reward(fixedCash: 30000)),
          '고정 현금 30,000원',
        );
        expect(recruitDetail(const Reward(fixedCash: 30000)), isNull);
        expect(recruitHeadline(const Reward()), isNull);
      },
    );
  });
}

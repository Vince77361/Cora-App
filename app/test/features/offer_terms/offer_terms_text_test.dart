import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/presentation/offer_terms_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('won', () {
    test('formats won amounts the way the canvas does', () {
      expect(won(40000), '4만 원');
      expect(won(100000), '10만 원');
      expect(won(11000), '11,000원');
    });

    test('keeps thousands separators for amounts that are not whole 만', () {
      expect(won(1000), '1,000원');
      expect(won(45000), '45,000원');
      expect(won(1000000), '100만 원');
    });
  });

  group('format texts', () {
    test('names every format and its subtitle', () {
      expect(formatLabel(ContentFormat.shorts), '쇼츠');
      expect(formatLabel(ContentFormat.reels), '릴스');
      expect(formatLabel(ContentFormat.cardNews), '카드뉴스');
      expect(formatLabel(ContentFormat.blog), '블로그 글');
      expect(formatSubtitle(ContentFormat.shorts), '유튜브 60초');
      expect(formatSubtitle(ContentFormat.reels), '인스타그램 30초');
      expect(formatSubtitle(ContentFormat.cardNews), '인스타그램 3–5장');
      expect(formatSubtitle(ContentFormat.blog), '사진 포함 후기');
    });

    test('counts one piece of content', () {
      expect(contentLine(ContentFormat.reels), '릴스 1편');
      expect(contentLine(ContentFormat.blog), '블로그 글 1편');
    });
  });

  group('benefit, cash and view pay texts', () {
    const voucher = Voucher(name: '식사권', value: 40000, people: 2);
    const viewPay = ViewPay(ratePerThousand: 2000, cap: 60000);

    test(
      'writes the benefit, view pay and deliverable lines like the canvas',
      () {
        expect(benefitLine(voucher), '식사권 40,000원 · 2인');
        expect(viewPayLine(viewPay), '1,000회당 2,000원 · 1인 최대 60,000원');
        expect(viewPayLineComma(viewPay), '1,000회당 2,000원, 최대 60,000원');
        expect(rateLabel(2000), '1,000회당 2,000원');
        expect(capLabel(60000), '최대 60,000원');
        expect(deliverableLine(ContentFormat.reels, 1), '릴스 1편 · 30초 안팎');
        expect(deliverableLine(ContentFormat.shorts, 1), '쇼츠 1편 · 60초 안팎');
        expect(deliverableLine(ContentFormat.cardNews, 1), '카드뉴스 1편 · 3–5장');
        expect(deliverableLine(ContentFormat.blog, 1), '블로그 글 1편 · 사진 포함 후기');
      },
    );

    test('drops the people from the benefit when it is unknown', () {
      const unknown = Voucher(name: '식사권', value: 40000);
      expect(benefitLine(unknown), '식사권 40,000원');
      expect(benefitShort(unknown), '식사권');
      expect(benefitShort(voucher), '식사권 2인');
    });

    test('writes fixed cash as a value and as a chip', () {
      expect(fixedCashLabel(0), '없음');
      expect(fixedCashLabel(30000), '30,000원');
      expect(fixedCashChip(0), '없음');
      expect(fixedCashChip(30000), '3만 원');
      expect(fixedCashChip(100000), '10만 원');
    });

    test('names the three usage rights', () {
      expect(usageRightsLabel(UsageRights.storeRepost3m), '가게 계정 재게시 3개월');
      expect(usageRightsLabel(UsageRights.storeRepost6m), '가게 계정 재게시 6개월');
      expect(usageRightsLabel(UsageRights.none), '사용 안 함');
    });
  });

  group('reward headline', () {
    const voucher = Voucher(name: '식사권', value: 40000, people: 2);
    const viewPay = ViewPay(ratePerThousand: 2000, cap: 60000);

    test('joins the present reward elements into a headline', () {
      expect(
        rewardHeadline(const Reward(voucher: voucher, viewPay: viewPay)),
        '식사권 40,000원 · 2인 + 조회수 수당',
      );
      expect(
        rewardHeadline(const Reward(voucher: voucher)),
        '식사권 40,000원 · 2인',
      );
      expect(rewardHeadline(const Reward(fixedCash: 30000)), '고정 현금 30,000원');
      expect(
        rewardHeadline(
          const Reward(voucher: voucher, fixedCash: 30000, viewPay: viewPay),
        ),
        '식사권 40,000원 · 2인 + 고정 현금 30,000원 + 조회수 수당',
      );
    });

    test('says there is nothing when no element is left', () {
      expect(rewardHeadline(const Reward()), '없음');
    });

    test('summarises saved terms one line per element', () {
      expect(
        rewardSummary(
          const OfferTerms(
            format: ContentFormat.reels,
            reward: Reward(
              voucher: voucher,
              fixedCash: 30000,
              viewPay: viewPay,
            ),
          ),
        ),
        '식사권 40,000원 · 2인\n고정 현금 30,000원\n조회수 수당 1,000회당 2,000원, 최대 60,000원',
      );
    });
  });

  group('fee texts', () {
    test('writes the fee note from the server fee rate', () {
      expect(feeNote(60000, 10), '이용료 6,000원은 별도예요.');
      expect(feeNote(90000, 10), '이용료 9,000원은 별도예요.');
      expect(feeAmountLabel(60000, 10), '6,000원');
    });

    test('hides the fee note at zero burden', () {
      expect(feeNote(0, 10), '');
      expect(feeAmountLabel(0, 10), '');
    });
  });

  group('version number', () {
    test('picks 로 or 으로 by how the number is read', () {
      expect(versionWithRo(1), '판본 1로');
      expect(versionWithRo(2), '판본 2로');
      expect(versionWithRo(3), '판본 3으로');
      expect(versionWithRo(6), '판본 6으로');
      expect(versionWithRo(7), '판본 7로');
      expect(versionWithRo(8), '판본 8로');
      expect(versionWithRo(10), '판본 10으로');
    });
  });
}

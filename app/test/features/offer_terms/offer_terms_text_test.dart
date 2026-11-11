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

  group('reward texts', () {
    test('titles every reward type', () {
      expect(rewardTitle(RewardType.voucher), '식사권 제공');
      expect(rewardTitle(RewardType.perView), '조회수당 지급');
      expect(rewardTitle(RewardType.both), '식사권 + 조회수');
    });

    test('describes each reward type under its card', () {
      const base = OfferTermsInput(
        format: ContentFormat.reels,
        rewardType: RewardType.voucher,
      );
      expect(rewardSubtitle(base), '2인 식사권, 약 4만 원 상당');
      expect(
        rewardSubtitle(
          const OfferTermsInput(
            format: ContentFormat.reels,
            rewardType: RewardType.voucher,
            voucherName: '커트 이용권',
            voucherValue: 30000,
          ),
        ),
        '커트 이용권, 약 3만 원 상당',
      );
      expect(
        rewardSubtitle(
          const OfferTermsInput(
            format: ContentFormat.reels,
            rewardType: RewardType.perView,
          ),
        ),
        '조회 1회당 10원, 최대 10만 원',
      );
      expect(
        rewardSubtitle(
          const OfferTermsInput(
            format: ContentFormat.reels,
            rewardType: RewardType.both,
          ),
        ),
        '식사 후 올리고, 조회수만큼 더 받아요',
      );
    });

    test('summarises a combined reward on two lines', () {
      const terms = OfferTerms(
        format: ContentFormat.reels,
        rewardType: RewardType.both,
        voucherName: '2인 식사권',
        voucherValue: 40000,
        perViewAmount: 10,
        perViewCap: 100000,
      );
      expect(rewardSummary(terms), '2인 식사권\n+ 조회 1회당 10원, 최대 10만 원');
    });

    test('uses the custom voucher name', () {
      const terms = OfferTerms(
        format: ContentFormat.reels,
        rewardType: RewardType.voucher,
        voucherName: '커트 이용권',
        voucherValue: 30000,
      );
      expect(rewardSummary(terms), '커트 이용권 (약 3만 원)');
    });

    test('summarises a per-view reward with the server amounts', () {
      const terms = OfferTerms(
        format: ContentFormat.shorts,
        rewardType: RewardType.perView,
        perViewAmount: 10,
        perViewCap: 100000,
      );
      expect(rewardSummary(terms), '조회 1회당 10원, 최대 10만 원');
    });

    test('summarises the chosen input the same way as the saved terms', () {
      expect(
        rewardSummaryOfInput(
          const OfferTermsInput(
            format: ContentFormat.reels,
            rewardType: RewardType.both,
            voucherName: '2인 식사권',
            voucherValue: 40000,
          ),
        ),
        '2인 식사권\n+ 조회 1회당 10원, 최대 10만 원',
      );
    });

    test('gives a one-line headline', () {
      expect(
        rewardHeadline(
          const OfferTerms(
            format: ContentFormat.reels,
            rewardType: RewardType.both,
            voucherName: '2인 식사권',
            voucherValue: 40000,
            perViewAmount: 10,
            perViewCap: 100000,
          ),
        ),
        '2인 식사권 + 조회수당',
      );
      expect(
        rewardHeadline(
          const OfferTerms(
            format: ContentFormat.reels,
            rewardType: RewardType.voucher,
            voucherName: '커트 이용권',
            voucherValue: 30000,
          ),
        ),
        '커트 이용권',
      );
      expect(
        rewardHeadline(
          const OfferTerms(
            format: ContentFormat.reels,
            rewardType: RewardType.perView,
            perViewAmount: 10,
            perViewCap: 100000,
          ),
        ),
        '조회수당',
      );
    });
  });
}

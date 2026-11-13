import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/trial_compare/domain/trial_comparison.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';
import 'package:cora/features/trial_compare/presentation/trial_compare_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes the trial and cora lines like the canvas', () {
    expect(trialSpentLine(300000), '월 300,000원 × 3');
    expect(coraSpentLine(4, 152000), '오퍼 4건 · 152,000원');
    expect(trialPostsLine(9), '블로그 글 9개');
    expect(reactionLine(26), '평균 2.6배');
    expect(reactionLine(null), '아직 없어요');
    expect(
      trialEndNotice(DateTime(2026, 12, 10)),
      '체험단 계약이 12월 10일에 끝나요. 다시 계약하기 전에 비교해 보세요.',
    );
  });

  test('joins the content counts by format with a plus', () {
    expect(
      contentLine(const [ContentCount(format: ContentFormat.reels, count: 4)]),
      '릴스 4편',
    );
    expect(
      contentLine(const [
        ContentCount(format: ContentFormat.reels, count: 4),
        ContentCount(format: ContentFormat.cardNews, count: 2),
      ]),
      '릴스 4편 + 카드뉴스 2편',
    );
    expect(contentLine(const []), '아직 없어요');
  });

  test('parses only real calendar dates', () {
    expect(parseTrialDate('2026-12-10'), DateTime(2026, 12, 10));
    expect(parseTrialDate(' 2026-12-10 '), DateTime(2026, 12, 10));
    expect(parseTrialDate('2026-02-30'), isNull);
    expect(parseTrialDate('2026-13-01'), isNull);
    expect(parseTrialDate('2026-1-1'), isNull);
    expect(parseTrialDate('20261210'), isNull);
    expect(formatTrialDate(DateTime(2026, 3, 4)), '2026-03-04');
  });
}

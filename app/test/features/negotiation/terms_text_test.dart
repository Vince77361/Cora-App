import 'package:cora/features/collaboration/domain/collaboration.dart'
    show CollaborationNextAction;
import 'package:cora/features/discovery/domain/discovery_card.dart'
    show MatchReason;
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/negotiation/presentation/terms_text.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora/features/offer_terms/presentation/offer_terms_text.dart'
    show won;
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cashLabel', () {
    test('writes a fixed amount in units of ten thousand won', () {
      expect(cashLabel(300000, FeeBand.w400k), '30만 원');
      expect(cashLabel(350000, null), '35만 원');
      expect(cashLabel(10000, null), '1만 원');
    });

    test('falls back to the hoped fee band', () {
      expect(cashLabel(null, FeeBand.w200k), '20만 원대');
      expect(cashLabel(null, FeeBand.w300k), '30만 원대');
      expect(cashLabel(null, FeeBand.w400k), '40만 원대');
      expect(cashLabel(null, FeeBand.w500kPlus), '50만 원 이상');
    });

    test('is empty with neither', () {
      expect(cashLabel(null, null), '');
    });
  });

  test('startFromLabel says the date or that the schedule is open', () {
    expect(startFromLabel(DateTime(2026, 11, 16)), '11월 16일 이후');
    expect(startFromLabel(DateTime(2027, 1, 5)), '1월 5일 이후');
    expect(startFromLabel(null), '일정 협의');
  });

  test(
    'compareDeliverableLabel adds the fixed length for reels and shorts',
    () {
      expect(compareDeliverableLabel(ContentFormat.reels, 1), '릴스 1편 · 30초');
      expect(compareDeliverableLabel(ContentFormat.shorts, 2), '쇼츠 2편 · 30초');
      expect(compareDeliverableLabel(ContentFormat.cardNews, 1), '카드뉴스 1편');
      expect(compareDeliverableLabel(ContentFormat.blog, 3), '블로그 글 3편');
    },
  );

  test('the benefit, cap and face rows use the canvas words', () {
    expect(compareBenefitLabel(true), '제품 제공');
    expect(compareBenefitLabel(false), '없음');
    expect(comparePerfCapLabel(null), '없음');
    expect(comparePerfCapLabel(60000), '6만 원');
    expect(compareFaceLabel(true), '있음');
    expect(compareFaceLabel(false), '없음');
  });

  test('compareUsageLabel is the short label, not the contract one', () {
    expect(compareUsageLabel(BrandUsageRights.repostOnly), '브랜드 계정 재게시');
    expect(compareUsageLabel(BrandUsageRights.adsToo), '재게시 + 광고');
    expect(compareUsageLabel(BrandUsageRights.none), '사용 안 함');
  });

  group('06 terms labels', () {
    test('labels terms the way the canvas does', () {
      expect(revisionLabel(RevisionScope.none), '없음');
      expect(revisionLabel(RevisionScope.guideOnce), '기획안 기준 1회');
      expect(revisionLabel(RevisionScope.draftOnce), '초안 기준 1회');
      expect(revisionLabel(RevisionScope.draftTwice), '초안 기준 2회');
      expect(usageLabel(BrandUsageRights.repostOnly), '브랜드 계정 재게시만');
      expect(usageLabel(BrandUsageRights.adsToo), '광고 소재로도 사용');
      expect(usageLabel(BrandUsageRights.none), '사용 안 함');
      expect(payoutLabel(7), '최종 게시 후 7일 이내');
      expect(payoutLabel(14), '최종 게시 후 14일 이내');
      expect(deliverableLabel(ContentFormat.reels, 1), '릴스 1편');
      expect(deliverableLabel(ContentFormat.cardNews, 3), '카드뉴스 3편');
      expect(startFromLabel(DateTime(2026, 11, 16)), '11월 16일 이후');
      expect(reasonLabel(MatchReason.field), '분야가 맞아요');
      expect(reasonLabel(MatchReason.trial), '제품 사용 기간이 맞아요');
    });

    test('the money labels cut at ten thousand won or spell the amount', () {
      expect(won(300000), '30만 원');
      expect(wonLabel(350000), '350,000원');
      expect(wonLabel(300000), '300,000원');
      expect(wonLabel(0), '0원');
      expect(perfLabel(null), '없음');
      expect(
        perfLabel(const ViewPay(ratePerThousand: 2000, cap: 60000)),
        '최대 6만 원',
      );
      expect(
        perfLabel(const ViewPay(ratePerThousand: 2000, cap: 65000)),
        '최대 65,000원',
      );
    });

    test('the re-post and ads rows follow the usage rights', () {
      expect(repostValueLabel(BrandUsageRights.repostOnly), '브랜드 계정만');
      expect(repostValueLabel(BrandUsageRights.adsToo), '브랜드 계정만');
      expect(repostValueLabel(BrandUsageRights.none), '사용 안 함');
      expect(adsValueLabel(BrandUsageRights.repostOnly), '별도 협의');
      expect(adsValueLabel(BrandUsageRights.adsToo), '포함');
      expect(adsValueLabel(BrandUsageRights.none), '별도 협의');
    });

    test('followers get thousands separators', () {
      expect(followersLabel(8200), '8,200명');
      expect(followersLabel(950), '950명');
      expect(followersLabel(1250000), '1,250,000명');
    });

    test('the accept note adds the refund sentence only for a performance '
        'add-on', () {
      expect(
        termsAcceptNote(300000, hasPerformance: false),
        '수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 30만 원.',
      );
      expect(
        termsAcceptNote(360000, hasPerformance: true),
        '수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 36만 원. '
        '성과 추가는 조회수만큼, 남으면 환불해요.',
      );
    });

    test('termsHeader follows my turn, who made the version and whether both '
        'agreed', () {
      expect(
        termsHeader(version: 1, myTurn: true, mine: false, agreed: false),
        const TermsHeader('받은 제안 · 판본 1', '내가 응답할 차례', highlighted: true),
      );
      // 내가 아직 확인하지 않은 판본은 누가 냈든 내 차례다.
      expect(
        termsHeader(version: 2, myTurn: true, mine: true, agreed: false),
        const TermsHeader('받은 제안 · 판본 2', '내가 응답할 차례', highlighted: true),
      );
      expect(
        termsHeader(version: 2, myTurn: false, mine: true, agreed: false),
        const TermsHeader('보낸 제안 · 판본 2', '상대 대기'),
      );
      expect(
        termsHeader(version: 3, myTurn: false, mine: false, agreed: false),
        const TermsHeader('받은 제안 · 판본 3', '상대 대기'),
      );
      expect(
        termsHeader(version: 3, myTurn: false, mine: true, agreed: true),
        const TermsHeader('합의한 조건 · 판본 3', '합의 완료'),
      );
    });
  });

  group('07 progress labels', () {
    test('nextActionLabel reads the two next actions', () {
      expect(
        nextActionLabel(CollaborationNextAction.respondTerms),
        '받은 제안 확인하고 응답하기',
      );
      expect(
        nextActionLabel(CollaborationNextAction.signContract),
        '계약서 확인하고 동의하기',
      );
    });

    test('the pair takes the josa of the creator name', () {
      expect(progressPair('서윤의 작은 취향', '모아 스튜디오'), '서윤의 작은 취향과 모아 스튜디오');
      expect(progressPair('하루 한 컵', '느린결'), '하루 한 컵과 느린결');
      expect(progressPair('한그릇', '모아'), '한그릇과 모아');
      expect(progressPair('민의 옷장 기록', '모아'), '민의 옷장 기록과 모아');
      expect(progressPair('서윤', '모아'), '서윤과 모아');
      expect(progressPair('나', '모아'), '나와 모아');
    });

    test('the done count and the overrun line use the canvas words', () {
      expect(TermsTexts.doneCount(2), '2 / 6 완료');
      expect(TermsTexts.overBudget(50000), '예산을 50,000원 넘었어요.');
      expect(TermsTexts.stepNames, hasLength(6));
    });
  });
}

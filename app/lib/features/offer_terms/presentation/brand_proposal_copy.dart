/// 브랜드의 제안(F1·F2의 브랜드 모드)에서 가게 화면과 다른 문구. 줄 이름 `혜택`, `현금 고정비`, `성과 추가`는
/// 공통 모델 2장의 브랜드 계약 쪽 이름이고, 캔버스(NBudget, NReviewSend)는 가게 변형만 그려서 나머지는
/// 가게 문구를 브랜드에 맞게 바꾼 캔버스 밖 문구다.
abstract final class BrandProposalCopy {
  // F1
  static const budgetStep = 1;
  static const reviewStep = 2;
  static const totalSteps = 2;
  static const description = '제품과 현금은 따로 계산해요.';
  static const benefitLabel = '혜택';
  static const benefitHint = '현금과 더하지 않아요';
  static const benefitOn = '제품 제공';
  static const benefitOff = '없음';
  static const fixedCashLabel = '현금 고정비';
  static const viewPayLabel = '성과 추가';
  static const viewPayHint = '조회수만큼 더 드려요 · 남으면 환불해요';

  // F2
  static const reviewBenefitLabel = '혜택';
  static const reviewFixedCashLabel = '현금 고정비';
  static const reviewViewPayLabel = '성과 추가';
}

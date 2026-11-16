import '../../principles/domain/principles.dart' show ProductTrialDays;

/// 브랜드 시작 화면들의 문구. 이 화면들은 기획 캔버스에 없어서 계획의 문구를 그대로 쓴다. 아래 표시한
/// 입력 검사 문구와 실패 문구는 계획에도 없는, 이 작업이 더한 문구다.
abstract final class BrandOnboardingTexts {
  // 브랜드 프로필
  static const profileTitle = '어떤 브랜드인가요?';
  static const brandName = '브랜드 이름';
  static const tagline = '한 줄 소개 (선택)';
  static const taglineHint = '예: 느린 결, 일상의 주얼리';
  static const industry = '업종';
  static const industryTitle = '업종';
  static const photo = '대표 사진 (선택)';
  static const next = '다음';

  // 캠페인
  static const campaignTitle = '어떤 콘텐츠를\n함께 만들까요?';
  static const headline = '캠페인 한 줄';
  static const headlineHint = '예: 나만의 아침 루틴 속 작은 포인트';
  static const fee = '제작비 (원)';
  static const productProvided = '제품 제공';
  static const format = '형식';
  static const startFrom = '시작 가능한 날';
  static const trialDays = '제품 사용 기간';
  static const mustInclude = '꼭 담을 것 (최대 3줄)';
  static const notRequired = '요구하지 않는 것';
  static const start = '캠페인 시작하기';
  static const save = '저장';
  static const close = '캠페인 마감';
  static const closeConfirm = '캠페인을 마감할까요? 진행 중인 협업은 그대로 이어져요.';

  // 아래는 캔버스와 계획에 없는 문구다.
  /// 설계 3장 "캠페인 예산"의 필드. 계획의 화면 문구에는 없어 이 이름을 붙였다.
  static const budget = '캠페인 예산 (원)';
  static const startFromPlaceholder = '날짜 고르기';
  static const startFromSheetTitle = '시작 가능한 날';
  static const closeAction = '마감하기';
  static const closeKeep = '취소';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';
  static const photoTooLarge = '사진이 너무 커요. 5MB 이하로 골라 주세요.';
  static const rateLimited = '사진을 너무 많이 올렸어요. 잠시 뒤에 다시 시도해 주세요.';
  static const feeInvalid = '제작비는 1만 원 단위로, 1만 원 이상 1,000만 원 이하로 입력해 주세요.';
  static const budgetInvalid = '캠페인 예산은 1만 원 단위로, 1억 원 이하로 입력해 주세요.';
  // 서버가 같은 값으로 거절할 때 주는 문구와 같다(`campaigns.service.ts`).
  static const budgetBelowFee = '캠페인 예산은 제작비 이상이어야 해요.';
  static const startFromPast = '시작 가능한 날은 오늘 이후여야 해요.';
  static const mustIncludeHint = '한 줄에 20자까지 적을 수 있어요.';

  static String trialLabel(ProductTrialDays days) => switch (days) {
    ProductTrialDays.d3 => '3일',
    ProductTrialDays.d7 => '7일',
    ProductTrialDays.d14 => '14일',
    ProductTrialDays.any => '상관없어요',
  };
}

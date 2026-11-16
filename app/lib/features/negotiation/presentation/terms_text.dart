import '../../discovery/presentation/discovery_text.dart';
import '../../offer_terms/domain/offer_terms.dart' show ContentFormat;
import '../../offer_terms/presentation/offer_terms_text.dart'
    show formatLabel, won;
import '../../principles/domain/principles.dart' show FeeBand;
import '../domain/brand_usage_rights.dart';

// 브랜드 계약의 조건을 화면 문구로 바꾸는 순수 함수들. 03·04(관심·비교)가 먼저 쓰고, 06 조건 협의가 같은
// 문구를 이어 쓴다. 캔버스 글자 그대로다.

/// 금액 칸. 정해진 금액이 있으면 `30만 원`, 없으면 희망 제작비 구간 `30만 원대`.
String cashLabel(int? amount, FeeBand? band) {
  if (amount != null) return won(amount);
  if (band != null) return DiscoveryTexts.feeBandLabel(band);
  return '';
}

/// 03 카드 아래 글의 날짜. `11월 16일 이후`, 날짜가 없으면 `일정 협의`.
String startFromLabel(DateTime? date) =>
    date == null ? '일정 협의' : '${date.month}월 ${date.day}일 이후';

/// 04 `결과물`. `{형식} {편 수}편`, 릴스와 쇼츠는 뒤에 ` · 30초`(결과물의 길이는 고정 안내다).
String compareDeliverableLabel(ContentFormat format, int pieces) {
  final base = '${formatLabel(format)} $pieces편';
  return switch (format) {
    ContentFormat.reels || ContentFormat.shorts => '$base · 30초',
    _ => base,
  };
}

/// 04 `혜택`.
String compareBenefitLabel(bool productProvided) =>
    productProvided ? '제품 제공' : '없음';

/// 04 `성과 상한`. 성과 추가가 없으면 `없음`.
String comparePerfCapLabel(int? cap) => cap == null ? '없음' : won(cap);

/// 04 `사용권`. 06의 `usageLabel`과 다른 짧은 라벨이다(캔버스의 기간은 보여 주지 않는다).
String compareUsageLabel(BrandUsageRights rights) => switch (rights) {
  BrandUsageRights.repostOnly => '브랜드 계정 재게시',
  BrandUsageRights.adsToo => '재게시 + 광고',
  BrandUsageRights.none => '사용 안 함',
};

/// 04 `얼굴 출연`.
String compareFaceLabel(bool faceOk) => faceOk ? '있음' : '없음';

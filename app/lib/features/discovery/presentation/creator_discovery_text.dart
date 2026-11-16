import '../../../core/text/josa.dart';
import '../../principles/domain/principles.dart' show ProductTrialDays;
import '../../offer_terms/presentation/offer_terms_text.dart' show won;
import '../domain/campaign_detail.dart';
import '../domain/discovery_card.dart';

/// 크리에이터의 발견(08)과 캠페인 상세(D1)의 문구. 캔버스(CreatorDiscover, NCampaign) 글자 그대로이고,
/// 아래 표시한 것만 캔버스에 없어 계획·설계의 문구를 쓴다.
abstract final class CreatorDiscoveryTexts {
  // 08 카드. 캔버스는 `내 원칙과 맞는 캠페인 {pos}`이고 pos는 `1 / 4`(슬래시 양옆 공백)이다.
  static String badge(int position, int total) =>
      '내 원칙과 맞는 캠페인 $position / $total';

  // 알림 문구와 단추(캔버스 08). 브랜드 쪽(01)과 `넘겼어요`·`관심을 보냈어요`가 다르다.
  static const passToast = '넘겼어요. 브랜드에는 알리지 않아요.';
  static const passToastAction = '이유 남기기';
  static const likeToast = '관심을 보냈어요. 브랜드도 고르면 알려드려요.';
  static const likeToastAction = '관심 목록';
  static const holdToast = '보류함에 담았어요.';
  static const holdToastAction = '보류 보기';
  static const matchToastAction = '확인하기';
  static String matchToast(String brandName) =>
      '${josa(brandName, JosaPair.gwaWa)} 서로 관심이 닿았어요.';

  /// 카드의 접근성 이름(캔버스 `aria-label`).
  static String cardLabel(String name) => '$name 오퍼 상세 보기';

  /// 캔버스 밖: 이미 지원했거나 오퍼가 온 가게를 오른쪽으로 밀었을 때(서버 409). 지원했다고 말하지 않는다.
  static const alreadyAppliedToast = '이미 지원한 가게예요.';

  // 가게 카드를 오른쪽으로 밀면(가게 흐름 개정의 `조건 그대로 지원`과 같은 호출, 계획의 문구).
  static const appliedToast = '지원했어요. 사장님이 고르면 오퍼가 도착해요.';

  // 다 봤을 때(캔버스 08 + F8 모양)
  static const allSeenTitle = '오늘 맞는 캠페인을 모두 봤어요.';
  static const allSeenBody = '협업 원칙을 다듬으면 더 잘 맞는 캠페인이 올라와요.';
  static const allSeenAction = '협업 원칙 다듬기';

  // 원칙이 없을 때 화면 위 띠(계획의 문구, 캔버스에 없다)
  static const principlesBanner = '협업 원칙을 정하면 브랜드에게 보여요.';
  static const principlesBannerAction = '정하기';

  // 캔버스와 계획에 없는 문구: 불러오기 실패 안내와 빈 목록.
  static const loadFailedTitle = '추천을 불러오지 못했어요';
  static const emptyTitle = '아직 추천할 캠페인이 없어요.';
  static const emptyBody = '협업 원칙을 다듬으면 더 잘 맞는 캠페인이 올라와요.';
  static const detailLoadFailedTitle = '캠페인을 불러오지 못했어요';

  /// 캠페인 카드의 제작비 줄. 캔버스 `30만 원 + 제품`.
  static String cardPrice(CampaignCard card) =>
      card.productProvided ? '${won(card.fee)} + 제품' : won(card.fee);

  // D1(캔버스 NCampaign)
  static const fitTitle = '나와 잘 맞는 이유';
  static const mustTitle = '꼭 담을 것';
  static const notRequiredTitle = '요구하지 않아요';
  static const scheduleTitle = '일정';
  static const trialTitle = '제품 사용';
  static const pass = '넘기기';
  static const like = '관심 보내기';

  /// 계획 문구: 꼭 담을 것이 하나도 없을 때.
  static const mustEmpty = '정해진 것이 없어요';

  /// 캔버스 밖: 요구하지 않는 것이 하나도 없을 때.
  static const notRequiredEmpty = '없어요';

  /// D1 머리 사진 위 `{브랜드 이름}, {한 줄 소개}`. 소개가 없으면 이름만.
  static String brandLine(String name, String? tagline) {
    final t = tagline?.trim();
    return t == null || t.isEmpty ? name : '$name, $t';
  }

  /// D1 제작비 옆 `+ 제품 제공, 릴스 1편`. 상세에는 형식이 내려오지 않아 릴스 1편 고정이다.
  static String deliverable(bool productProvided) =>
      productProvided ? '+ 제품 제공, 릴스 1편' : '릴스 1편';

  /// `나와 잘 맞는 이유` 상자 글. 이유를 문장으로 잇고 `내 협업 원칙과 {n}개가 겹쳐요.`를 붙인다.
  /// 겹치는 것이 없으면 null(상자를 숨긴다).
  static String? fitText(CampaignDetail detail) {
    if (detail.reasons.isEmpty) return null;
    final sentences = [for (final r in detail.reasons) '${r.label}.'];
    return '${sentences.join(' ')} 내 협업 원칙과 ${detail.overlapCount}개가 겹쳐요.';
  }

  /// `11월 16일 이후`.
  static String scheduleValue(DateTime date) =>
      '${date.month}월 ${date.day}일 이후';

  /// `7일 먼저 사용`, 기간이 없으면 `기간 자유`.
  static String trialValue(ProductTrialDays days) => switch (days) {
    ProductTrialDays.d3 => '3일 먼저 사용',
    ProductTrialDays.d7 => '7일 먼저 사용',
    ProductTrialDays.d14 => '14일 먼저 사용',
    ProductTrialDays.any => '기간 자유',
  };
}

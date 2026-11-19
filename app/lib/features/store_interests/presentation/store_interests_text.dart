import '../../../core/text/count_and_date_labels.dart';

/// 사장님 저장함(G2)의 문구. 캔버스 M19G2TabsB 글자 그대로이고, 아래 "캔버스 밖"으로 표시한 것만 캔버스에 없어
/// 설계 4.3의 문구를 쓴다. 보낸 제안 줄의 설명은 제안함(F3)과 같은 함수(`rowSubtitle`)가 만든다.
abstract final class StoreInterestsTexts {
  static const title = '저장함';
  static const description = '저장은 나만 보고, 하트는 상대에게 전해져요.';
  static const tabListLabel = '저장함 분류';

  static String tabSaved(int n) => '저장 $n';
  static String tabSent(int n) => '보낸 관심 $n';
  static String tabOffers(int n) => '보낸 제안 $n';

  // 줄의 단추와 표지.
  static const propose = '제안하기';
  static const profile = '프로필';
  static const respond = '응답하기';
  static const waitingButton = '대기';

  /// 줄 설명: `{분야}, 팔로워 {n}명`. 분야나 팔로워가 없으면 있는 쪽만 보이고 둘 다 없으면 비운다(캔버스 밖).
  /// 만 명 이상은 캔버스처럼 `1.2만명`으로 줄인다.
  static String meta(String? contentFocus, int? followers) {
    final focus = (contentFocus ?? '').trim();
    final count = followers == null
        ? null
        : '팔로워 ${followersCount(followers)}명';
    return [if (focus.isNotEmpty) focus, ?count].join(', ');
  }

  /// `3,100`, `1.2만`, `10만`. 만 명 이상은 소수 첫째 자리까지 내림한다(`12,999` → `1.2만`).
  static String followersCount(int n) {
    if (n < 10000) return withCommas(n);
    final tenths = n ~/ 1000; // 1.2만 = 12 (1000 단위)
    final whole = tenths ~/ 10;
    final rest = tenths % 10;
    return rest == 0 ? '$whole만' : '$whole.$rest만';
  }

  // 탭이 비었을 때(F8 모양, 캔버스 밖). 설계 4.3.
  static const emptySavedTitle = '아직 저장한 후보가 없어요.';
  static const emptySavedBody = '카드를 위로 밀거나 저장 버튼을 눌러 보세요.';
  static const emptySavedAction = '전체 둘러보기';
  static const emptySentTitle = '아직 보낸 하트가 없어요.';
  static const emptySentBody = '카드를 오른쪽으로 밀거나 하트 버튼을 눌러 보세요.';
  static const emptyOffersTitle = '아직 보낸 제안이 없어요.';
  static const emptyOffersBody = '마음에 드는 크리에이터에게 제안해 보세요.';

  /// 불러오기 실패(캔버스 밖).
  static const loadFailedTitle = '저장함을 불러오지 못했어요';

  /// 크리에이터 상세가 아직 없어서 열리는 준비 중 화면의 제목(캔버스 밖).
  static const creatorDetailSoon = '크리에이터 상세';
}

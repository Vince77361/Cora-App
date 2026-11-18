import '../../../core/text/count_and_date_labels.dart';

/// 사장님 전체 둘러보기(G1)의 문구. 캔버스 M19G1Swipe 글자 그대로이고, 아래 표시한 것만 캔버스에 없다.
/// 알림·버튼·넘김 이유 시트의 문구는 브랜드 01과 같은 위젯이라 `DiscoveryTexts`에 있다.
abstract final class StoreDiscoverTexts {
  static const title = '전체 둘러보기';
  static const back = '뒤로';

  /// 머리 오른쪽 북마크의 접근성 이름. 저장 수가 있으면 `저장함, 3명`(캔버스 aria-label).
  static String savedLabel(int count) => count > 0 ? '저장함, $count명' : '저장함';

  /// 카드 왼쪽 위 글자.
  static String badge(int index, int total) => '대표 게시물 $index / $total';

  /// 형광색 줄: `{분야} · 팔로워 {n}`. 분야나 팔로워가 없으면 있는 쪽만 보이고 둘 다 없으면 비운다.
  /// 분야 없음·팔로워 없음 모양은 캔버스에 없다(둘 다 서버가 null을 줄 수 있다).
  static String infoLine(String? contentFocus, int? followers) {
    final focus = (contentFocus ?? '').trim();
    return [
      if (focus.isNotEmpty) focus,
      if (followers != null) '팔로워 ${withCommas(followers)}',
    ].join(' · ');
  }

  /// 카드 전체의 접근성 이름(캔버스 밖).
  static String cardLabel(String name) => '$name의 대표 게시물';

  /// 한 줄이 없는 게시물의 큰 글자(캔버스 밖, 옛 데이터).
  static const noHeadline = '대표 콘텐츠를 준비 중이에요';
}

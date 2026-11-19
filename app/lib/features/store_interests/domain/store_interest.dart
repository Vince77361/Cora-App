/// 사장님 저장함(G2)의 크리에이터 한 줄. 저장 탭과 보낸 관심 탭이 같은 모양을 쓴다.
class StoreInterest {
  const StoreInterest({
    required this.creatorId,
    required this.name,
    required this.shortName,
    this.contentFocus,
    this.followers,
    this.photoUrl,
    this.headline,
    this.representativePhotoUrl,
    this.mutual = false,
  });

  final String creatorId;

  /// 크리에이터의 활동 이름.
  final String name;

  /// `{X}의 …` 꼴이면 X, 아니면 이름 전체. 버튼 글자에 쓰는 이름이다.
  final String shortName;

  /// 분야(크리에이터가 쓴 글). 없으면 null.
  final String? contentFocus;

  /// 연결한 인스타그램 계정의 팔로워 수. 연결이 없으면 null.
  final int? followers;

  /// 프로필 사진. 저장 줄의 아바타가 쓴다.
  final String? photoUrl;

  /// 대표 게시물 1번의 한 줄. 월드컵 카드가 쓴다. 없으면 null.
  final String? headline;

  /// 대표 게시물 1번의 사진. 월드컵 카드 바탕이다. 없으면 null이라 프로필 사진으로 대신한다.
  final String? representativePhotoUrl;

  /// 서로 관심: 내가 하트를 보냈고 그 크리에이터가 이 가게에 살아 있는 지원을 가졌다. 저장 탭에서는 늘 false다.
  final bool mutual;
}

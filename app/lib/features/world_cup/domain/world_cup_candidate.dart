import 'package:flutter/widgets.dart' show BuildContext;

/// 월드컵에 나가는 사람 한 명. 사장님 저장함의 크리에이터와 브랜드 저장함의 크리에이터 카드를 각 저장함이 이 모양으로
/// 바꿔 넘긴다. 같은 [id]는 같은 사람이다.
class WorldCupCandidate {
  const WorldCupCandidate({
    required this.id,
    required this.name,
    required this.meta,
    required this.savedOrder,
    this.headline,
    this.photoUrl,
  });

  final String id;

  /// 활동 이름.
  final String name;

  /// 대표 게시물 1번의 한 줄. 없으면 null이다(대결 카드는 활동 이름을 큰 글자로 쓴다).
  final String? headline;

  /// 대표 게시물 1번의 사진. 없으면 바탕색만 보인다.
  final String? photoUrl;

  /// 사진 위 형광색 줄(`{분야} · 팔로워 {n}`).
  final String meta;

  /// 저장함에서 몇 번째로 보이는가(1부터). 대결 카드 표지 `저장 {n}번째`다.
  final int savedOrder;

  @override
  bool operator ==(Object other) =>
      other is WorldCupCandidate && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 우승자에게 제안을 보낸 뒤 결과 화면에 띄울 안내. [actionLabel]과 [onAction]은 함께 있거나 함께 없다.
class WorldCupNotice {
  const WorldCupNotice({required this.message, this.actionLabel, this.onAction})
    : assert((actionLabel == null) == (onAction == null));

  final String message;
  final String? actionLabel;
  final void Function()? onAction;
}

/// 결과 화면의 `제안하기`가 하는 일. 사장님은 받는 사람이 채워진 오퍼 작성(A5), 브랜드는 보상 제안(F1)을 연다. 서버에
/// 쓰는 일은 그 화면이 하고 월드컵 자신은 아무것도 쓰지 않는다. 뒤에 띄울 안내가 있으면 돌려준다.
typedef WorldCupPropose =
    Future<WorldCupNotice?> Function(
      BuildContext context,
      WorldCupCandidate winner,
    );

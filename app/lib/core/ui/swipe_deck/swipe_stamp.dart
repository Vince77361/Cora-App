import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/cora_colors.dart';
import '../../theme/cora_swipe_tokens.dart';
import '../../theme/cora_text_styles.dart';
import 'swipe_physics.dart';

/// 카드 위에 번쩍이는 도장(`하트`, `넘김`, `저장`). 자리와 불투명도는 [SwipeDeck]이 정한다.
/// 서버 값(`LIKE`/`HOLD`)과 코드 이름([SwipeOutcome.like]/[SwipeOutcome.hold])은 그대로이고 화면 이름만
/// 하트·저장이다(2026-11-19 회의 반영 설계 3장).
///
/// 캔버스 M19G1Heart/Save: 테두리 5, 모서리 12, 글자 40·900. `하트`는 라임 테두리와 글자(바탕
/// rgba(31,42,0,0.55))에 -14도, `넘김`은 흰색에 14도, `저장`은 흰색에 기울임 없이 너비 124다.
class SwipeStamp extends StatelessWidget {
  const SwipeStamp(this.outcome, {super.key});

  final SwipeOutcome outcome;

  static String labelOf(SwipeOutcome outcome) => switch (outcome) {
    SwipeOutcome.like => '하트',
    SwipeOutcome.pass => '넘김',
    SwipeOutcome.hold => '저장',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = outcome == SwipeOutcome.like ? c.accent : c.onPhoto;
    final fill = outcome == SwipeOutcome.like
        ? CoraSwipeTokens.likeStampFill
        : CoraSwipeTokens.stampFill;
    final degrees = switch (outcome) {
      SwipeOutcome.like => -CoraSwipeTokens.stampTilt,
      SwipeOutcome.pass => CoraSwipeTokens.stampTilt,
      SwipeOutcome.hold => 0.0,
    };
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: color, width: CoraSwipeTokens.stampBorder),
        borderRadius: BorderRadius.circular(CoraSwipeTokens.stampRadius),
      ),
      child: Padding(
        // 캔버스 padding 2px 14px. 저장은 너비 124에 가운데 정렬이라 좌우 여백을 따로 두지 않는다.
        padding: EdgeInsets.symmetric(
          vertical: 2,
          horizontal: outcome == SwipeOutcome.hold ? 0 : 14,
        ),
        child: Text(
          labelOf(outcome),
          textAlign: TextAlign.center,
          style: CoraTextStyles.display.copyWith(
            color: color,
            fontSize: CoraSwipeTokens.stampFontSize,
            letterSpacing: -0.8,
            height: 1.448,
          ),
        ),
      ),
    );
    if (outcome == SwipeOutcome.hold) {
      box = SizedBox(width: CoraSwipeTokens.holdStampWidth, child: box);
    }
    return ExcludeSemantics(
      child: Transform.rotate(angle: degrees * math.pi / 180, child: box),
    );
  }
}

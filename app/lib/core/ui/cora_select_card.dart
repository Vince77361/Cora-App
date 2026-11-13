import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_motion.dart';
import '../theme/cora_shadows.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 큰 선택 카드(캔버스 A1의 역할 카드). 왼쪽에 윗줄·제목·설명, 오른쪽에 원형 체크.
///
/// 선택되면 `notifyTabSelected` 바탕(라이트 #E3E5E9, 다크 #33363D)에 그림자가 없고, 아니면
/// `roleCardIdle` 바탕(라이트 #FFFFFF, 다크 #2A2D33)에 `CoraShadows.card`. 글자는 둘 다 `text`,
/// 고른 점은 `accent`/`onAccent`다(NRole, DarkNRole). 상태가 바뀔 때 바탕, 그림자, 원, 체크가 함께 이어서 바뀐다.
class CoraSelectCard extends StatelessWidget {
  const CoraSelectCard({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? overline;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// 캔버스 A1 `min-height: 92px`. 글자가 커지면 카드가 늘어난다.
  static const double minHeight = 92;

  @visibleForTesting
  static const dotKey = ValueKey<String>('CoraSelectCard.dot');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      selected: selected,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: CoraMotion.resolve(context, CoraMotion.stateDuration),
          curve: CoraMotion.standardCurve,
          builder: (context, t, _) {
            final foreground = c.text;
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(c.roleCardIdle, c.notifyTabSelected, t),
                  borderRadius: BorderRadius.circular(CoraRadius.xl),
                  boxShadow: _shadowAt(t),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _texts(foreground)),
                      const SizedBox(width: 16),
                      _CheckDot(
                        fill: Color.lerp(c.line, c.accent, t)!,
                        check: c.onAccent,
                        progress: t,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _texts(Color foreground) {
    // 캔버스는 윗줄에 opacity 0.75, 설명에 0.8을 준다. 글자색 알파로 같은 효과를 낸다.
    final lines = <Widget>[
      if (overline case final overline?)
        Text(
          overline,
          style: CoraTextStyles.caption.copyWith(
            color: foreground.withValues(alpha: foreground.a * 0.75),
          ),
        ),
      Text(title, style: CoraTextStyles.heading.copyWith(color: foreground)),
      if (subtitle case final subtitle?)
        Text(
          subtitle,
          // 캔버스 설명은 13px 기본 굵기(400)다. label 토큰(500)과 굵기만 다르다.
          style: CoraTextStyles.label.copyWith(
            fontWeight: FontWeight.w400,
            color: foreground.withValues(alpha: foreground.a * 0.8),
          ),
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: lines,
    );
  }

  /// 그림자는 모양을 유지한 채 옅어지며 사라진다. 크기를 줄이면 카드가 내려앉는 듯 보인다.
  static List<BoxShadow>? _shadowAt(double t) {
    if (t <= 0) return CoraShadows.card;
    if (t >= 1) return null;
    final faded = [
      for (final s in CoraShadows.card)
        BoxShadow(
          color: s.color.withValues(alpha: 0),
          offset: s.offset,
          blurRadius: s.blurRadius,
          spreadRadius: s.spreadRadius,
        ),
    ];
    return BoxShadow.lerpList(CoraShadows.card, faded, t);
  }
}

/// 지름 24 원 안의 13 체크(캔버스 SVG `M5 12l5 5 9-10`, 24 단위, 선 굵기 3.4).
class _CheckDot extends StatelessWidget {
  const _CheckDot({
    required this.fill,
    required this.check,
    required this.progress,
  });

  final Color fill;
  final Color check;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: CoraSelectCard.dotKey,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 24,
        child: Center(
          child: CustomPaint(
            size: const Size.square(13),
            painter: _CheckPainter(
              // 선택되지 않은 체크는 투명하다(캔버스 `check: transparent`).
              color: check.withValues(alpha: check.a * progress),
              progress: progress,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  static const _viewBox = 24.0;
  static const _strokeWidth = 3.4;
  static const _points = [Offset(5, 12), Offset(10, 17), Offset(19, 7)];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || color.a == 0) return;
    final k = size.width / _viewBox;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 선택될 때 체크가 왼쪽에서부터 그려진다. 꺾은선 두 개라 길이를 직접 잰다.
    final first = (_points[1] - _points[0]).distance;
    final second = (_points[2] - _points[1]).distance;
    var remaining = (first + second) * progress.clamp(0.0, 1.0);
    final path = Path()..moveTo(_points[0].dx * k, _points[0].dy * k);
    for (var i = 1; i < _points.length && remaining > 0; i++) {
      final from = _points[i - 1];
      final to = _points[i];
      final length = (to - from).distance;
      final f = math.min(1.0, remaining / length);
      final end = Offset.lerp(from, to, f)!;
      path.lineTo(end.dx * k, end.dy * k);
      remaining -= length;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.color != color || old.progress != progress;
}

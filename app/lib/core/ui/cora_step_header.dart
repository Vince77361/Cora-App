import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shadows.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 뒤로 가기 버튼(캔버스 `<header>`의 44 x 44 화살표, 두께 2.4의 둥근 `<`).
class CoraBackButton extends StatelessWidget {
  const CoraBackButton({
    super.key,
    required this.onPressed,
    this.dimmed = false,
  });

  final VoidCallback? onPressed;

  /// 흐리게(opacity 0.3). NOffer가 1단계에서 이전 단계 버튼을 이렇게 둔다.
  final bool dimmed;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '뒤로',
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: Opacity(
            opacity: dimmed ? 0.3 : 1,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CustomPaint(
                  size: const Size.square(24),
                  painter: _ChevronPainter(c.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SVG `M15 5l-7 7 7 7`(viewBox 24, stroke 2.4, round).
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(15, 5)
      ..lineTo(8, 12)
      ..lineTo(15, 19);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// 여러 단계 화면의 머리글(캔버스 NStoreLink, NOffer). 높이 64의 줄에 뒤로 가기, 가운데 알약
/// 제목, 오른쪽 `2 / 3`이 있고 그 아래에 4px 진행 막대가 붙는다.
///
/// [leading]을 주면 알약 안 왼쪽에 들어간다(NOffer의 28px 원형 사진). 알약은 그만큼 왼쪽
/// 안쪽 여백이 4로 줄고 사진과 글자 사이가 8이다.
class CoraStepHeader extends StatelessWidget {
  const CoraStepHeader({
    super.key,
    required this.title,
    required this.step,
    required this.total,
    this.onBack,
    this.leading,
    this.backDimmed = false,
  });

  final String title;
  final int step;
  final int total;

  /// null이면 뒤로 가기 버튼 자리는 비어 있다.
  final VoidCallback? onBack;
  final Widget? leading;
  final bool backDimmed;

  static const double rowHeight = 64;
  static const double barHeight = 4;

  /// 진행 막대 채움 비율. 캔버스는 정수 퍼센트로 반올림한다(1 / 3 → 33%).
  double get progress => total <= 0 ? 0 : (step / total * 100).round() / 100;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: rowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: onBack == null
                        ? const SizedBox.square(dimension: CoraBackButton.size)
                        : CoraBackButton(onPressed: onBack, dimmed: backDimmed),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _Pill(title: title, leading: leading),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$step / $total',
                        maxLines: 1,
                        style: CoraTextStyles.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.progressTrack),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: ColoredBox(color: c.progressFill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.title, required this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Flexible(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CoraTextStyles.label.copyWith(color: c.onStepPill),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.stepPill,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
        boxShadow: CoraShadows.stepPill(c.stepPillShadow),
      ),
      child: Padding(
        padding: leading == null
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.fromLTRB(4, 4, 14, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              SizedBox.square(dimension: 28, child: ClipOval(child: leading)),
              const SizedBox(width: 8),
            ],
            text,
          ],
        ),
      ),
    );
  }
}

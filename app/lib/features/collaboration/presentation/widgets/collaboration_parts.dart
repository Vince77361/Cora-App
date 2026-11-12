import 'package:flutter/material.dart' hide StepState;

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/collaboration.dart';

// A7(크리에이터)와 사장님 진행 화면이 함께 쓰는 조각들. 두 화면은 같은 캔버스 구성(NEscrow)이고
// 문구만 보는 쪽에 맞게 다르다.

/// 보관 상자(캔버스 `section`): 모서리 28, 안쪽 22/20, `surface`. 방패 + [label], 큰 글씨 [big]
/// (40/900, -0.05em), 선택 줄 [note], 선 아래 [lower].
class CollaborationBox extends StatelessWidget {
  const CollaborationBox({
    super.key,
    required this.label,
    this.big,
    this.bigSize = 40,
    this.note,
    this.lower,
  });

  final String label;

  /// 큰 글씨. 없으면 줄 자체를 그리지 않는다.
  final String? big;
  final double bigSize;
  final String? note;

  /// 선 아래 칸. [CollaborationBox.divided]로 감싸 준다.
  final Widget? lower;

  /// 상자 아래쪽의 칸을 캔버스처럼 위에 선을 긋고 감싼다.
  static Widget divided(BuildContext context, Widget child) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Padding(padding: const EdgeInsets.only(top: 16), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bigText = big;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size.square(16),
                    painter: ShieldPainter(c.text),
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: CoraTextStyles.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (bigText != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bigText,
                    maxLines: 1,
                    style: CoraTextStyles.title.copyWith(
                      fontSize: bigSize,
                      letterSpacing: bigSize * -0.05,
                      height: 1.448,
                      color: c.text,
                    ),
                  ),
                ),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(
                note!,
                style: CoraTextStyles.bodySmall.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ],
            ?lower,
          ],
        ),
      ),
    );
  }
}

/// 오른쪽 위 더보기(점 셋). 캔버스에 없다: 44 x 44 눌림 영역.
class CollaborationMoreButton extends StatelessWidget {
  const CollaborationMoreButton({super.key, required this.onTap});

  final VoidCallback onTap;

  /// 접근성 이름.
  static const moreLabel = '더보기';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: CollaborationMoreButton.moreLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: CustomPaint(
                size: const Size(24, 24),
                painter: _DotsPainter(c.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final dx in [5.0, 12.0, 19.0]) {
      canvas.drawCircle(Offset(dx, 12), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

/// 쉼표로 끊은 숫자(`4,320`).
String commas(int n) => wonExact(n).replaceAll('원', '');

class CollaborationStat extends StatelessWidget {
  const CollaborationStat({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CoraTextStyles.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: CoraTextStyles.heading.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// 단계 목록(캔버스 `ol`): 한 줄 최소 56, 점(26)과 글자 사이 14, 점 아래 이어지는 2px 선.
class CollaborationSteps extends StatelessWidget {
  const CollaborationSteps({
    super.key,
    required this.steps,
    required this.titleOf,
    required this.subtitleOf,
  });

  final List<CollaborationStep> steps;

  /// 단계 이름과 아래 작은 글씨. 보는 쪽(크리에이터·사장님)이 말을 정한다.
  final String Function(StepKey key) titleOf;
  final String? Function(StepKey key) subtitleOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            title: titleOf(steps[i].key),
            subtitle: subtitleOf(steps[i].key),
            index: i,
            last: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.last,
  });

  final CollaborationStep step;
  final String title;
  final String? subtitle;
  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = step.state == StepState.done;
    final now = step.state == StepState.now;
    final dotBg = done
        ? c.stepDotDone
        : now
        ? c.stepDotNow
        : c.surface;
    final dotFg = done
        ? c.onStepDotDone
        : now
        ? c.onStepDotNow
        : c.textSecondary;
    final sub = subtitle;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 26,
                    child: Center(
                      child: Text(
                        done ? '✓' : '${index + 1}',
                        style: CoraTextStyles.caption.copyWith(color: dotFg),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: 2,
                    child: ColoredBox(
                      color: last ? const Color(0x00000000) : c.line,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: CoraTextStyles.buttonMedium.copyWith(
                          fontWeight: now ? FontWeight.w700 : FontWeight.w400,
                          color: done ? c.textSecondary : c.text,
                        ),
                      ),
                      if (sub != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            sub,
                            style: CoraTextStyles.meta.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 방패 모양(SVG `M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z`, viewBox 24, 선 2)을 16으로 줄여 그린다.
class ShieldPainter extends CustomPainter {
  const ShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = Path()
      ..moveTo(12, 3)
      ..relativeLineTo(8, 3)
      ..relativeLineTo(0, 6)
      ..relativeCubicTo(0, 5, -3.5, 8, -8, 9)
      ..relativeCubicTo(-4.5, -1, -8, -4, -8, -9)
      ..lineTo(4, 6)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(ShieldPainter old) => old.color != color;
}

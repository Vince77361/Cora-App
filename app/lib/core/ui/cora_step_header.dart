import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
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

/// 여러 단계 화면의 머리글(캔버스 NStoreLink, NOffer). 높이 64의 줄에 뒤로 가기, 가운데 빈
/// 자리, 오른쪽 `2 / 3`이 있고 그 아래에 4px 진행 막대가 붙는다.
///
/// 캔버스에는 가운데에 화면 이름 알약(`가게 등록` 등)이 있지만, 소유자가 2026-11-12에 뺐다.
/// 그래서 가운데는 비어 있고, 화면 이름은 화면 읽기 프로그램용 [pageLabel]로만 남는다.
class CoraStepHeader extends StatelessWidget {
  const CoraStepHeader({
    super.key,
    required this.pageLabel,
    required this.step,
    required this.total,
    this.onBack,
    this.backDimmed = false,
    this.showProgress = true,
  });

  /// 화면에는 그리지 않고 머리글(heading) 의미만 붙인다. 알약을 뺀 뒤에도 화면 읽기
  /// 프로그램 사용자가 지금 어느 화면인지 알 수 있게 하려는 것이다.
  final String pageLabel;
  final int step;
  final int total;

  /// null이면 뒤로 가기 버튼 자리는 비어 있다.
  final VoidCallback? onBack;
  final bool backDimmed;

  /// false이면 오른쪽 `2 / 3`과 진행 막대를 그리지 않는다(등록이 끝난 뒤 다시 여는 화면).
  final bool showProgress;

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
                // 소유자가 2026-11-12에 가운데 화면 이름 알약을 뺐다(캔버스와 다른 점).
                // 자리는 그대로 두어 뒤로 가기와 `n / m`의 위치가 변하지 않는다.
                Expanded(
                  child: Semantics(
                    header: true,
                    label: pageLabel,
                    child: const SizedBox.expand(),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: !showProgress
                      ? null
                      : Align(
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
        if (showProgress)
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

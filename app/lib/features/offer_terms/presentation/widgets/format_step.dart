import 'package:flutter/material.dart';

import '../../../../core/theme/cora_text_styles.dart';
import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';
import 'choice_surface.dart';
import 'step_intro.dart';

/// 1단계: 콘텐츠 형식(캔버스 NOffer 2열 카드, 최소 높이 120, 모서리 24).
class FormatStep extends StatelessWidget {
  const FormatStep({super.key, required this.selected, required this.onPick});

  final ContentFormat selected;
  final ValueChanged<ContentFormat> onPick;

  static const title = '어떤 콘텐츠를\n부탁할까요?';
  static const description = '크리에이터가 올릴 형식을 하나 골라요.';

  @override
  Widget build(BuildContext context) {
    const formats = ContentFormat.values;
    Widget card(ContentFormat f) =>
        _FormatCard(format: f, selected: f == selected, onTap: () => onPick(f));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OfferStepIntro(title: title, description: description),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            spacing: 10,
            children: [
              for (var i = 0; i < formats.length; i += 2)
                // 한 줄의 두 카드는 높이를 맞춘다(CSS 그리드 행).
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Expanded(child: card(formats[i])),
                      Expanded(child: card(formats[i + 1])),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final ContentFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OfferChoiceSurface(
      selected: selected,
      onTap: onTap,
      minHeight: 120,
      padding: const EdgeInsets.all(16),
      semanticLabel: '${formatLabel(format)}, ${formatSubtitle(format)}',
      builder: (context, foreground, _) => ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomPaint(
              size: const Size.square(26),
              painter: _FormatIconPainter(format, foreground),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  formatLabel(format),
                  style: CoraTextStyles.bodyLarge.copyWith(
                    fontSize: 17,
                    color: foreground,
                  ),
                ),
                Text(
                  formatSubtitle(format),
                  style: CoraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    color: foreground.withValues(alpha: foreground.a * 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 캔버스의 SVG 아이콘(viewBox 24, 선 굵기 2, 둥근 끝과 꺾임)을 그대로 그린다.
class _FormatIconPainter extends CustomPainter {
  const _FormatIconPainter(this.format, this.color);

  final ContentFormat format;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (format) {
      // M8 4h8a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3z
      // M10 9l5 3-5 3z
      case ContentFormat.shorts:
        path
          ..addRRect(RRect.fromLTRBR(5, 4, 19, 20, const Radius.circular(3)))
          ..moveTo(10, 9)
          ..lineTo(15, 12)
          ..lineTo(10, 15)
          ..close();
      // M7 3h10a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V7a4 4 0 0 1 4-4z
      // M3 9h18 M10 12l5 3-5 3z
      case ContentFormat.reels:
        path
          ..addRRect(RRect.fromLTRBR(3, 3, 21, 21, const Radius.circular(4)))
          ..moveTo(3, 9)
          ..lineTo(21, 9)
          ..moveTo(10, 12)
          ..lineTo(15, 15)
          ..lineTo(10, 18)
          ..close();
      // M4 5h12v12H4z M8 9h12v12H8 (뒤 사각형은 닫지 않는다)
      case ContentFormat.cardNews:
        path
          ..moveTo(4, 5)
          ..lineTo(16, 5)
          ..lineTo(16, 17)
          ..lineTo(4, 17)
          ..close()
          ..moveTo(8, 9)
          ..lineTo(20, 9)
          ..lineTo(20, 21)
          ..lineTo(8, 21);
      // M5 4h14v16H5z M8 8h8 M8 12h8 M8 16h5
      case ContentFormat.blog:
        path
          ..moveTo(5, 4)
          ..lineTo(19, 4)
          ..lineTo(19, 20)
          ..lineTo(5, 20)
          ..close()
          ..moveTo(8, 8)
          ..lineTo(16, 8)
          ..moveTo(8, 12)
          ..lineTo(16, 12)
          ..moveTo(8, 16)
          ..lineTo(13, 16);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FormatIconPainter old) =>
      old.format != format || old.color != color;
}

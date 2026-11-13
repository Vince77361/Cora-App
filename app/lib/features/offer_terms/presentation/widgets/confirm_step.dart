import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';
import 'step_intro.dart';

/// 3단계: 고른 조건 확인(캔버스 NOffer `<dl>`: 가게·콘텐츠 두 칸, 보상 한 칸, 방패 안내).
class ConfirmStep extends StatelessWidget {
  const ConfirmStep({
    super.key,
    required this.title,
    required this.description,
    required this.storeName,
    required this.terms,
  });

  final String title;
  final String description;
  final String storeName;
  final OfferTerms terms;

  static const escrowNote = '결제한 금액은 Cora가 보관하고, 콘텐츠가 올라온 뒤 크리에이터에게 지급해요.';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OfferStepIntro(title: title, description: description),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _SummaryTile(label: '가게', value: storeName),
                    ),
                    Expanded(
                      child: _SummaryTile(
                        label: '콘텐츠',
                        value: contentLine(terms.format),
                      ),
                    ),
                  ],
                ),
              ),
              _SummaryTile(
                label: '보상',
                value: rewardSummary(terms),
                emphasized: true,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: CustomPaint(
                  size: const Size.square(16),
                  painter: _ShieldPainter(c.textSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  escrowNote,
                  style: CoraTextStyles.label.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 칸 하나: 모서리 20, `surface` 바탕, 안쪽 14, 라벨 12 → 4 → 값 16/500.
/// 보상 칸은 라벨이 보조색이 아닌 본문색이고 값이 18/700이다(캔버스 그대로).
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: emphasized ? c.text : c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: CoraTextStyles.bodyLarge.copyWith(
                  fontSize: emphasized ? 18 : 16,
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                  color: c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SVG `M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z`(viewBox 24, 선 굵기 2).
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(12, 3)
      ..lineTo(20, 6)
      ..lineTo(20, 12)
      ..cubicTo(20, 17, 16.5, 20, 12, 21)
      ..cubicTo(7.5, 20, 4, 17, 4, 12)
      ..lineTo(4, 6)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.color != color;
}

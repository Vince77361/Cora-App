import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';
import 'choice_surface.dart';
import 'step_intro.dart';

/// 2단계: 보상 방식(캔버스 NOffer 세로 카드, 최소 높이 88, 오른쪽 체크 원 24).
///
/// 블로그 글은 조회수를 셀 수 없어 조회수가 들어간 두 카드를 끄고 그 아래에 이유를 적는다
/// (공통 모델, 캔버스에는 없는 상태). 식사권이 들어간 카드가 골라져 있으면 `식사권 고치기`가 보인다.
class RewardStep extends StatelessWidget {
  const RewardStep({
    super.key,
    required this.rewardType,
    required this.voucherName,
    required this.voucherValue,
    required this.perViewAllowed,
    required this.onPick,
    required this.onEditVoucher,
  });

  final RewardType rewardType;
  final String voucherName;
  final int voucherValue;
  final bool perViewAllowed;
  final ValueChanged<RewardType> onPick;
  final VoidCallback onEditVoucher;

  static const title = '어떻게\n보상할까요?';
  static const description = '식사권만, 조회수만, 또는 둘 다 고를 수 있어요.';
  static const editVoucherLabel = '식사권 고치기';
  static const blogNote = '블로그 글은 조회수를 셀 수 없어요.';

  bool get _hasVoucher => rewardType != RewardType.perView;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final voucherInput = OfferTermsInput(
      format: ContentFormat.reels,
      rewardType: RewardType.voucher,
      voucherName: voucherName,
      voucherValue: voucherValue,
    );
    Widget card(RewardType type) => _RewardCard(
      title: rewardTitle(type),
      subtitle: rewardSubtitle(
        type == RewardType.voucher
            ? voucherInput
            : OfferTermsInput(format: ContentFormat.reels, rewardType: type),
      ),
      selected: type == rewardType,
      onTap: type == RewardType.voucher || perViewAllowed
          ? () => onPick(type)
          : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OfferStepIntro(title: title, description: description),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              for (final type in RewardType.values) card(type),
              if (!perViewAllowed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                  child: Text(
                    blogNote,
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ),
              if (_hasVoucher)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _EditVoucherButton(onTap: onEditVoucher),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OfferChoiceSurface(
      selected: selected,
      onTap: onTap,
      minHeight: 88,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      semanticLabel: '$title, $subtitle',
      builder: (context, foreground, t) => ExcludeSemantics(
        child: Row(
          spacing: 14,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    title,
                    style: CoraTextStyles.bodyLarge.copyWith(
                      fontSize: 17,
                      color: foreground,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: CoraTextStyles.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: foreground.withValues(alpha: foreground.a * 0.8),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(c.line, c.selectionDot, t),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: CustomPaint(
                    size: const Size.square(13),
                    // 고르지 않은 체크는 투명하다(캔버스 `check: transparent`).
                    painter: _CheckPainter(
                      c.onSelectionDot.withValues(
                        alpha: c.onSelectionDot.a * t,
                      ),
                    ),
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

/// SVG `M5 12l5 5 9-10`(viewBox 24, 선 굵기 3.4, 둥근 끝과 꺾임).
class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(10, 17)
        ..lineTo(19, 7),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

/// 캔버스에 없는 버튼. 목록 줄의 작은 알약 버튼(높이 38, 좌우 14, 13/500)과 같은 모양이다.
class _EditVoucherButton extends StatelessWidget {
  const _EditVoucherButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.subtleAction,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    RewardStep.editVoucherLabel,
                    style: CoraTextStyles.label.copyWith(
                      color: c.onSubtleAction,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

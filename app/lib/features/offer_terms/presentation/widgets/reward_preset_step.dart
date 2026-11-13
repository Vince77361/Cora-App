import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';
import 'choice_surface.dart';
import 'fixed_cash_sheet.dart';
import 'step_intro.dart';

/// A5 2단계: 빠른 보상 조합 셋(캔버스 NOffer 세로 카드, 최소 높이 88, 오른쪽 체크 원 24).
///
/// 설명 끝의 `자세히 설정`이 F1을 연다. 고정 현금을 고르면 카드 아래에 금액 입력란이 나온다(캔버스에
/// 없다). 블로그 글은 조회수를 셀 수 없어 조회수 수당이 들어간 조합을 끄고 그 아래에 이유를 적는다.
class RewardPresetStep extends StatefulWidget {
  const RewardPresetStep({
    super.key,
    required this.selected,
    required this.reward,
    required this.base,
    required this.viewPayAllowed,
    required this.cashMax,
    required this.cashStep,
    required this.onPick,
    required this.onCashChanged,
    required this.onDetails,
  });

  /// 지금 골라진 조합. 섞인 보상이면 null이다.
  final RewardPreset? selected;

  /// 지금 보상. 설명의 최대 현금 부담을 여기서 읽는다.
  final Reward reward;

  /// 조합 카드의 부제를 채우는 값(식사권과 조회수 수당). 지금 보상에 없는 요소도 마지막 값이나 기본값이 있다.
  final Reward base;
  final bool viewPayAllowed;

  /// 고정 현금 입력의 최대 금액과 눈금(서버 설정).
  final int cashMax;
  final int cashStep;
  final ValueChanged<RewardPreset> onPick;

  /// 입력란이 올바른 금액이면 그 금액을, 비었거나 틀리면 0을 알린다.
  final ValueChanged<int> onCashChanged;
  final VoidCallback onDetails;

  static const title = '어떻게\n보상할까요?';
  static const description = '가게 등록 때 정한 기본값이에요. ';
  static const detailsLabel = '자세히 설정';
  static const blogNote = '블로그 글은 조회수를 셀 수 없어요.';
  static const cashFieldLabel = '금액 (원)';
  static const cashFieldKey = ValueKey<String>('rewardPreset.cash');

  static String burdenSentence(int burden) =>
      '최대 현금 부담 ${wonExact(burden)}, 조회수가 적으면 남은 돈은 돌려드려요.';

  static String presetTitle(RewardPreset preset) => switch (preset) {
    RewardPreset.benefitOnly => '제공 혜택만',
    RewardPreset.fixedCash => '고정 현금',
    RewardPreset.benefitAndViewPay => '제공 혜택 + 조회수 수당 · 추천',
  };

  static const fixedCashSubtitle = '정한 금액을 한 번에 · 선택';

  @override
  State<RewardPresetStep> createState() => _RewardPresetStepState();
}

class _RewardPresetStepState extends State<RewardPresetStep> {
  late final TapGestureRecognizer _details = TapGestureRecognizer()
    ..onTap = () => widget.onDetails();
  late final _cash = TextEditingController(
    text: widget.reward.fixedCash > 0 ? widget.reward.fixedCash.toString() : '',
  );
  bool _cashInvalid = false;

  /// 입력란이 마지막으로 위에 알린 금액. 위에서 온 금액이 이것과 다를 때만(F1에서 고쳤거나 조합을
  /// 바꿨을 때) 입력란 글을 맞춘다. 입력 중인 글이 자기가 알린 값 때문에 지워지지 않게 하려는 것이다.
  late int _notified = widget.reward.fixedCash;

  @override
  void didUpdateWidget(RewardPresetStep old) {
    super.didUpdateWidget(old);
    final cash = widget.reward.fixedCash;
    if (cash == _notified) return;
    _notified = cash;
    _cash.text = cash > 0 ? cash.toString() : '';
    _cashInvalid = false;
  }

  @override
  void dispose() {
    _details.dispose();
    _cash.dispose();
    super.dispose();
  }

  void _onCashChanged(String text) {
    final value = int.tryParse(text.trim());
    final valid =
        value != null &&
        value > 0 &&
        value <= widget.cashMax &&
        value % widget.cashStep == 0;
    setState(() => _cashInvalid = text.trim().isNotEmpty && !valid);
    _notified = valid ? value : 0;
    widget.onCashChanged(_notified);
  }

  String _subtitle(RewardPreset preset) => switch (preset) {
    RewardPreset.benefitOnly =>
      widget.base.voucher == null ? '' : benefitLine(widget.base.voucher!),
    RewardPreset.fixedCash => RewardPresetStep.fixedCashSubtitle,
    RewardPreset.benefitAndViewPay =>
      widget.base.viewPay == null ? '' : viewPayLine(widget.base.viewPay!),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card(RewardPreset preset) {
      final enabled =
          preset != RewardPreset.benefitAndViewPay || widget.viewPayAllowed;
      return _PresetCard(
        title: RewardPresetStep.presetTitle(preset),
        subtitle: _subtitle(preset),
        selected: preset == widget.selected,
        onTap: enabled ? () => widget.onPick(preset) : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OfferStepIntro(
          title: RewardPresetStep.title,
          description:
              '${RewardPresetStep.description}${RewardPresetStep.burdenSentence(widget.reward.maxCashBurden)} ',
          // 캔버스의 `a`는 글자색이 본문색이고 밑줄이 그어진다.
          descriptionTail: TextSpan(
            text: RewardPresetStep.detailsLabel,
            recognizer: _details,
            style: TextStyle(
              color: c.text,
              decoration: TextDecoration.underline,
              decorationColor: c.text,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              card(RewardPreset.benefitOnly),
              card(RewardPreset.fixedCash),
              if (widget.selected == RewardPreset.fixedCash)
                _CashField(
                  controller: _cash,
                  invalid: _cashInvalid,
                  rangeMessage: FixedCashSheet.rangeMessage(
                    widget.cashStep,
                    widget.cashMax,
                  ),
                  onChanged: _onCashChanged,
                ),
              card(RewardPreset.benefitAndViewPay),
              if (!widget.viewPayAllowed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                  child: Text(
                    RewardPresetStep.blogNote,
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 고정 현금 금액 입력란(캔버스에 없다). 시트의 칸과 같은 [CoraFieldBox]이고, 틀린 금액이면 아래에
/// 범위 안내를 보인다.
class _CashField extends StatelessWidget {
  const _CashField({
    required this.controller,
    required this.invalid,
    required this.rangeMessage,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool invalid;
  final String rangeMessage;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        CoraFieldBox(
          fieldKey: RewardPresetStep.cashFieldKey,
          label: RewardPresetStep.cashFieldLabel,
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
        ),
        if (invalid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                rangeMessage,
                style: CoraTextStyles.meta.copyWith(color: c.text),
              ),
            ),
          ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
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
                // 고른 점은 라이트·다크 모두 라임이다(캔버스 `dot`, `check`).
                color: Color.lerp(c.line, c.accent, t),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: CustomPaint(
                    size: const Size.square(13),
                    // 고르지 않은 체크는 투명하다(캔버스 `check: transparent`).
                    painter: _CheckPainter(
                      c.onAccent.withValues(alpha: c.onAccent.a * t),
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

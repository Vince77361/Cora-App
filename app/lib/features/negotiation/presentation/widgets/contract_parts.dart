import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart' show wonExact;
import '../../../payment/domain/payment_quote.dart';
import '../../../payment/domain/payment_repository.dart';
import '../../../payment/presentation/widgets/payment_parts.dart';
import '../../domain/terms_version.dart';
import '../contract_text.dart';
import '../terms_text.dart';
import 'canvas_text.dart';

/// D4 계약 요약 상자(NContract): 안쪽 18, 모서리 24, `surface`. 위에 두 사람(사진 36, 이름 14/500, 사이에 선 2), 아래
/// 두 열 칸(위 16, 칸 사이 12/8). 칸 이름은 12(보조색), 값은 15/500이다. 성과 추가가 있으면 두 칸이 더 붙는다.
class ContractSummary extends StatelessWidget {
  const ContractSummary({
    super.key,
    required this.terms,
    required this.creatorName,
    required this.brandName,
    this.creatorPhotoUrl,
    this.brandPhotoUrl,
  });

  final TermsVersion terms;
  final String creatorName;
  final String brandName;

  /// 상대의 사진만 알 수 있어서 내 쪽은 비어 있다(자리 색만 보인다).
  final String? creatorPhotoUrl;
  final String? brandPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cells = <({String name, String value})>[
      (
        name: ContractTexts.cellDeliverable,
        value: deliverableLabel(terms.format, terms.pieces),
      ),
      (name: ContractTexts.cellFee, value: contractFeeValue(terms)),
      (name: ContractTexts.cellStart, value: monthDayLabel(terms.startDate)),
      (
        name: ContractTexts.cellPayout,
        value: payoutTermLabel(terms.payoutDays),
      ),
      if (terms.performance != null) ...[
        (name: ContractTexts.cellPerformance, value: performanceLabel(terms)),
        (name: ContractTexts.cellMaxCash, value: wonExact(terms.maxCash)),
      ],
    ];
    return Semantics(
      container: true,
      label: '$creatorName, $brandName',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 10,
                children: [
                  _Avatar(
                    url: creatorPhotoUrl,
                    alignment: const Alignment(0.1, -0.56),
                  ),
                  Flexible(child: _PartyName(creatorName)),
                  Expanded(
                    child: ExcludeSemantics(
                      child: SizedBox(
                        height: 2,
                        child: ColoredBox(color: c.line),
                      ),
                    ),
                  ),
                  Flexible(child: _PartyName(brandName)),
                  _Avatar(
                    url: brandPhotoUrl,
                    alignment: const Alignment(0.24, -0.2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                spacing: 12,
                children: [
                  for (var i = 0; i < cells.length; i += 2)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Expanded(child: _Cell(cells[i])),
                        Expanded(
                          child: i + 1 < cells.length
                              ? _Cell(cells[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyName extends StatelessWidget {
  const _PartyName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Text(
    name,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: canvasText(14, FontWeight.w500, context.colors.text),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.alignment});

  final String? url;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 36,
        child: ClipOval(
          child: CoraNetworkPhoto(
            url: url,
            alignment: alignment,
            background: context.colors.photoPlaceholder,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.cell);

  final ({String name, String value}) cell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cell.name,
            style: canvasText(12, FontWeight.w400, c.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(cell.value, style: canvasText(15, FontWeight.w500, c.text)),
        ],
      ),
    );
  }
}

/// 확인란 줄 하나(NContract): 최소 높이 56, 안쪽 8/16, 칸 24(모서리 8)와 글 15(줄 높이 1.45) 사이 12. 켜진 칸은
/// `contractCheckOn`, 꺼진 칸은 `line` 바탕이고 표시(두께 3.4)는 `onAccent`다. [onTap]이 null이면 누를 수 없다.
class ContractCheckRow extends StatelessWidget {
  const ContractCheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      checked: checked,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 12,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: checked ? c.contractCheckOn : c.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: checked
                          ? Center(
                              child: CustomPaint(
                                size: const Size.square(13),
                                painter: _TickPainter(c.onAccent),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: canvasText(
                        15,
                        FontWeight.w400,
                        c.text,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 확인 표시 `M5 12l5 5 9-10`(24칸, 두께 3.4, 둥근 끝).
class _TickPainter extends CustomPainter {
  const _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(5 * s, 12 * s)
      ..lineTo(10 * s, 17 * s)
      ..lineTo(19 * s, 7 * s);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}

/// 브랜드의 결제 상자(캔버스 NPay의 결제 내역 카드 모양): 줄 사이 12, 합계 위에 1px 선, 합계 26/900. 금액은 모두 서버
/// 견적([quote])의 값이다(앱에서 다시 계산하지 않는다). 아래에 결제 수단 세 칸과 보관 안내가 이어진다.
class ContractPaymentBox extends StatelessWidget {
  const ContractPaymentBox({
    super.key,
    required this.quote,
    required this.payoutDays,
    required this.method,
    required this.onMethod,
  });

  final PaymentQuote quote;
  final int payoutDays;
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethod;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final viewPayCap = quote.viewPayCap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    spacing: 12,
                    children: [
                      PaymentLine(
                        label: ContractTexts.payFee,
                        value: wonExact(quote.fixedCash),
                      ),
                      if (viewPayCap != null)
                        PaymentLine(
                          label: ContractTexts.payPerformance,
                          value: wonExact(viewPayCap),
                        ),
                      PaymentLine(
                        label: ContractTexts.payServiceFee,
                        value: wonExact(quote.fee),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: MergeSemantics(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                ContractTexts.payTotal,
                                style: CoraTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: c.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                wonExact(quote.total),
                                textAlign: TextAlign.right,
                                style: CoraTextStyles.title.copyWith(
                                  letterSpacing: -1.04,
                                  color: c.text,
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: PaymentMethodPicker(
            selected: method,
            onPick: onMethod,
            groupLabel: ContractTexts.payMethodGroup,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: PaymentShieldNote(
            text: ContractTexts.escrowNote(
              payoutDays,
              hasPerformance: viewPayCap != null,
            ),
          ),
        ),
      ],
    );
  }
}

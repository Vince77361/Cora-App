import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/payment_repository.dart';

/// 결제 수단의 화면 글자: `카드`, `계좌이체`, `간편결제`.
const paymentMethodLabels = ['카드', '계좌이체', '간편결제'];

String paymentMethodLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.card => paymentMethodLabels[0],
  PaymentMethod.transfer => paymentMethodLabels[1],
  PaymentMethod.easyPay => paymentMethodLabels[2],
};

/// 내역 한 줄(A8 결제 내역 카드, D4 결제 상자): 왼쪽 이름(14, 보조색), 오른쪽 값(14/500, 오른쪽 정렬).
class PaymentLine extends StatelessWidget {
  const PaymentLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Flexible(
            child: Text(
              label,
              style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: CoraTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 결제 수단 세 칸(높이 52, 모서리 18, 칸 사이 8). 고른 칸만 `notifyTabSelected`(라이트 #E3E5E9, 다크 #33363D).
class PaymentMethodPicker extends StatelessWidget {
  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onPick,
    required this.groupLabel,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onPick;

  /// 읽어 주는 이름(`결제 수단`).
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: groupLabel,
      child: Row(
        spacing: 8,
        children: [
          for (final method in PaymentMethod.values)
            Expanded(
              child: Semantics(
                container: true,
                inMutuallyExclusiveGroup: true,
                checked: method == selected,
                onTap: () => onPick(method),
                child: ExcludeSemantics(
                  excluding: false,
                  child: CoraPressable(
                    onTap: () => onPick(method),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: method == selected
                            ? c.notifyTabSelected
                            : c.surface,
                        borderRadius: BorderRadius.circular(CoraRadius.lg),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            paymentMethodLabel(method),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CoraTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 방패 안내 줄(A8, D4): 왼쪽 방패(16)와 오른쪽 안내 글(13, 줄 높이 1.6, 보조색). 바깥 여백은 부르는 쪽이 준다.
class PaymentShieldNote extends StatelessWidget {
  const PaymentShieldNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: ExcludeSemantics(
            child: CustomPaint(
              size: const Size.square(16),
              painter: _ShieldPainter(c.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: CoraTextStyles.meta.copyWith(
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 방패 모양(SVG `M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z`, viewBox 24, 선 2)을 16으로 줄여 그린다.
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.color);

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
  bool shouldRepaint(_ShieldPainter old) => old.color != color;
}

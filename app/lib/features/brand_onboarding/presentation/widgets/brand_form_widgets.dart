import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 브랜드 시작 화면(프로필, 캠페인)이 같이 쓰는 입력 조각들. 이 화면들은 캔버스에 없어서 가장 가까운
/// 입력 화면(NStoreLink의 입력 칸)과 같은 모양(`surface` 바탕, 모서리 20, 안쪽 16·14)을 쓴다.

/// 누르면 고르는 칸(업종, 시작 가능한 날). 값이 없으면 [placeholder]를 보조 색으로 보인다.
class BrandFormTile extends StatelessWidget {
  const BrandFormTile({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder = '',
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.field),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: CoraTextStyles.label.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value ?? placeholder,
                        style: CoraTextStyles.body.copyWith(
                          height: CoraTextStyles.bodySmall.height,
                          color: value == null ? c.textSecondary : c.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CustomPaint(
                  size: const Size.square(18),
                  painter: _ChevronDownPainter(c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronDownPainter extends CustomPainter {
  const _ChevronDownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronDownPainter old) => old.color != color;
}

/// 대표 사진 칸. 누르면 보관함이 열리고, 고르면 오른쪽에 작은 미리보기가 보인다.
class BrandPhotoTile extends StatelessWidget {
  const BrandPhotoTile({
    super.key,
    required this.label,
    required this.photo,
    required this.onTap,
  });

  final String label;
  final Uint8List? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: CoraTextStyles.body.copyWith(
                        height: CoraTextStyles.bodySmall.height,
                        color: photo == null ? c.textSecondary : c.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(CoraRadius.sm),
                    child: ColoredBox(
                      color: c.avatarPlaceholder,
                      child: SizedBox.square(
                        dimension: 40,
                        child: photo == null
                            ? null
                            : Image.memory(
                                photo!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stack) =>
                                    const SizedBox.expand(),
                              ),
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

/// 켜고 끄는 줄(`제품 제공`). 스위치 그림은 48 x 28이고 켜짐은 `accent`, 꺼짐은 `switchTrackOff`다
/// (알림 설정 화면의 스위치와 같은 모양).
class BrandSwitchTile extends StatelessWidget {
  const BrandSwitchTile({
    super.key,
    required this.label,
    required this.on,
    required this.onChanged,
  });

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      toggled: on,
      label: label,
      onTap: () => onChanged(!on),
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: () => onChanged(!on),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: CoraTextStyles.body.copyWith(
                        height: CoraTextStyles.bodySmall.height,
                        color: c.text,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: on ? c.accent : c.switchTrackOff,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 28,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 3,
                            left: on ? 23 : 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.switchKnob,
                                shape: BoxShape.circle,
                                boxShadow: CoraShadows.switchKnob,
                              ),
                              child: const SizedBox.square(dimension: 22),
                            ),
                          ),
                        ],
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

/// 이름 붙은 알약 묶음. 하나만 고르거나(형식, 사용 기간) 여러 개를 고른다(요구하지 않는 것). 모양은 03의
/// 탭과 같다(고른 것은 `notifyTabSelected`, 나머지는 `surface`).
class BrandChipGroup<T> extends StatelessWidget {
  const BrandChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: CoraTextStyles.label.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in options)
              _Chip(
                label: labelOf(option),
                selected: isSelected(option),
                onTap: () => onTap(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.notifyTabSelected : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: CoraTextStyles.label.copyWith(color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// 입력 칸 아래의 검사 문구(보조 색, 13).
class BrandFieldNote extends StatelessWidget {
  const BrandFieldNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: CoraTextStyles.meta.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ),
  );
}

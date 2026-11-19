import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../world_cup_text.dart';
import 'world_cup_icons.dart';

/// 몇 강으로 할지 묻는 시트(캔버스 M19G3Count)를 연다. `4강`(4명) 또는 `8강`(8명)을 [int]로 돌려주고, `닫기`나 바깥을
/// 눌러 닫으면 null이다. 저장이 8명보다 적으면 8강은 꺼진다.
Future<int?> showWorldCupCountSheet(
  BuildContext context, {
  required int savedCount,
}) {
  return showModalBottomSheet<int>(
    context: context,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    // 캔버스의 뒤 덮개 rgba(15,16,18,0.45). 두 모드가 같다.
    barrierColor: CoraSwipeTokens.sheetBarrier,
    elevation: 0,
    showDragHandle: false,
    // 글자를 키운 작은 화면에서도 시트가 잘리지 않게 높이를 내용에 맡기고 안에서 스크롤한다.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => WorldCupCountSheet(savedCount: savedCount),
  );
}

/// [showWorldCupCountSheet]의 내용. 처음에는 4강이 골라져 있다.
class WorldCupCountSheet extends StatefulWidget {
  const WorldCupCountSheet({super.key, required this.savedCount});

  final int savedCount;

  @override
  State<WorldCupCountSheet> createState() => _WorldCupCountSheetState();
}

class _WorldCupCountSheetState extends State<WorldCupCountSheet> {
  int _size = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: math.max(32, MediaQuery.viewPaddingOf(context).bottom),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const SizedBox(width: 40, height: 5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        WorldCupText.countTitle,
                        style: CoraTextStyles.bodyLarge.copyWith(
                          fontSize: 20,
                          letterSpacing: -0.4,
                          color: c.text,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        WorldCupText.countDescription(widget.savedCount),
                        style: CoraTextStyles.bodySmall.copyWith(
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Option(
                key: const ValueKey('world-cup-size-4'),
                title: WorldCupText.semifinal,
                subtitle: WorldCupText.semifinalSub,
                selected: _size == 4,
                enabled: true,
                onTap: () => setState(() => _size = 4),
              ),
              _Option(
                key: const ValueKey('world-cup-size-8'),
                title: WorldCupText.quarterfinal,
                subtitle: WorldCupText.quarterfinalSub,
                selected: _size == 8,
                // 저장이 8명보다 적으면 8강은 꺼진다(캔버스 밖의 꺼진 모양).
                enabled: widget.savedCount >= 8,
                onTap: () => setState(() => _size = 8),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    CoraPrimaryButton(
                      label: WorldCupText.begin,
                      look: CoraPrimaryButtonLook.accent,
                      buttonHeight: 56,
                      onPressed: () => Navigator.of(context).pop(_size),
                    ),
                    Semantics(
                      container: true,
                      button: true,
                      onTap: () => Navigator.of(context).pop(),
                      child: ExcludeSemantics(
                        child: CoraPressable(
                          onTap: () => Navigator.of(context).pop(),
                          child: SizedBox(
                            height: 44,
                            child: Center(
                              child: Text(
                                WorldCupText.close,
                                style: CoraTextStyles.buttonMedium.copyWith(
                                  fontSize: 14,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택 한 줄: 높이 64(큰 글자에서는 늘어난다), 안쪽 좌우 24, 트로피 동그라미(40) + `4강`(16/500)과 `4명이 겨뤄요`(13) +
/// 오른쪽 체크 동그라미(22). 고른 줄은 두 동그라미가 형광이다. 꺼진 줄은 흐리게 보이고 눌러도 고르지 않는다.
class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          spacing: 14,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? c.highlightAction : c.surface,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Center(
                  child: WorldCupIcon(
                    TrophyPainter(
                      selected ? c.onHighlightAction : c.textSecondary,
                    ),
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                  ),
                  Text(
                    subtitle,
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? c.highlightAction : c.line,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 22,
                child: Center(
                  child: selected
                      ? WorldCupIcon(
                          WorldCupCheckPainter(c.onHighlightAction),
                          size: 12,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: '$title $subtitle',
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: enabled ? onTap : null,
          child: Opacity(opacity: enabled ? 1 : 0.4, child: row),
        ),
      ),
    );
  }
}

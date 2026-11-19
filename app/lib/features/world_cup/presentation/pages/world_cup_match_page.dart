import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/theme/cora_world_cup_tokens.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../interests/presentation/widgets/interest_icons.dart'
    show ClosePainter, InterestIcon;
import '../../domain/world_cup_candidate.dart';
import '../viewmodels/world_cup_view_model.dart';
import '../widgets/world_cup_card.dart';
import '../world_cup_flow.dart';
import '../world_cup_text.dart';

/// 월드컵 대결(캔버스 M19G3Match). 위아래 두 카드 가운데 더 마음에 드는 쪽을 누르면 다음 대결로 가고, 결승이 끝나면
/// 결과로 바뀐다. `그만하기`는 아무것도 저장하지 않고 저장함으로 돌아간다. 서버를 읽지도 쓰지도 않는다.
class WorldCupMatchPage extends ConsumerWidget {
  const WorldCupMatchPage({super.key, required this.args});

  final WorldCupMatchArgs args;

  /// 캔버스의 자리: 머리 64 아래 안내 줄, 첫 카드는 위에서 90, 카드 높이 338, 카드 사이 12.
  static const _cardTop = 90.0;
  static const _cardHeight = 338.0;
  static const _cardGap = 12.0;

  void _quit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.splash);
    }
  }

  void _pick(BuildContext context, WidgetRef ref, WorldCupCandidate winner) {
    final vm = ref.read(worldCupViewModelProvider(args).notifier);
    vm.pick(winner);
    final bracket = ref.read(worldCupViewModelProvider(args)).bracket;
    if (!bracket.finished) return;
    context.pushReplacement(
      AppRoutes.worldCupResult,
      extra: WorldCupResultArgs(
        champion: bracket.champion,
        semifinalists: bracket.semifinalists,
        match: args,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(worldCupViewModelProvider(args));
    // 마지막 선택으로 결과로 바뀌는 사이에는 끝난 대진이라 대결을 읽을 수 없다.
    if (state.finished) return Scaffold(backgroundColor: c.background);
    final bracket = state.bracket;
    final match = bracket.match;
    final bottomInset = math.max(
      16.0,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 작은 화면에서는 두 카드가 같은 비율로 줄어 아래 여백(홈 표시 줄 위)을 지킨다.
            final cardHeight = math.min(
              _cardHeight,
              (constraints.maxHeight - _cardTop - _cardGap - bottomInset) / 2,
            );
            final secondTop = _cardTop + cardHeight + _cardGap;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 64,
                  child: _Header(
                    stage: bracket.roundLabel,
                    onQuit: () => _quit(context),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 60,
                  child: IgnorePointer(
                    child: Text(
                      WorldCupText.matchHint,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                for (final (i, candidate) in [match.a, match.b].indexed)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: i == 0 ? _cardTop : secondTop,
                    height: cardHeight,
                    child: WorldCupCard(
                      // 같은 자리에 다른 후보가 들어와도 사진이 먼저 후보를 따라 바뀌게 한다.
                      key: ValueKey('${state.step}-${candidate.id}'),
                      candidate: candidate,
                      chip: WorldCupCardChip(
                        label: WorldCupText.savedNth(candidate.savedOrder),
                      ),
                      onPick: () => _pick(context, ref, candidate),
                    ),
                  ),
                // 가운데 `VS`: 첫 카드의 아래쪽 가장자리에서 18 위부터 56 크기로 두 카드를 가른다.
                Positioned(
                  left: 0,
                  right: 0,
                  top: _cardTop + cardHeight - 18,
                  child: Center(
                    child: _Vs(color: c.background, text: c.text),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 머리(캔버스 `.hdr3`): 왼쪽 `그만하기`(X 22), 가운데 `이상형 월드컵`(16/500), 오른쪽 단계 글자(13 보조색).
class _Header extends StatelessWidget {
  const _Header({required this.stage, required this.onQuit});

  final String stage;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                container: true,
                button: true,
                label: WorldCupText.quit,
                onTap: onQuit,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: onQuit,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: InterestIcon(ClosePainter(c.text), size: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                WorldCupText.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                // 글자를 키워도 단계 글자는 줄바꿈 없이 한 줄이다.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    stage,
                    maxLines: 1,
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
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

/// 가운데 `VS` 동그라미: 지름 56, 화면 바탕색에 4 테두리, 18/900.
class _Vs extends StatelessWidget {
  const _Vs({required this.color, required this.text});

  final Color color;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: CoraWorldCupTokens.vsShadows(color),
        ),
        child: SizedBox.square(
          dimension: CoraWorldCupTokens.vsDiameter,
          child: Center(
            child: Text(
              WorldCupText.vs,
              style: CoraTextStyles.display.copyWith(
                fontSize: 18,
                letterSpacing: -0.36,
                height: CoraTextStyles.label.height,
                color: text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

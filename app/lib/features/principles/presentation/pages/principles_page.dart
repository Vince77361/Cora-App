import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_motion.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_glass_card.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../domain/principle_questions.dart';
import '../viewmodels/principles_view_model.dart';

/// 크리에이터의 협업 원칙(09). 질문 7개를 한 장씩 답하고 요약에서 저장한다. 모양은 캔버스
/// `Principles`·`DarkPrinciples`를 그대로 따른다.
///
/// `나중에`는 저장하지 않고 크리에이터 홈으로 간다. 저장해도 홈으로 간다.
class PrinciplesPage extends ConsumerWidget {
  const PrinciplesPage({super.key});

  static const title = '나의 협업 원칙';
  static const later = '나중에';
  static const backLabel = '이전 질문';
  static const questionLabel = '질문';
  static const finishedKicker = '모두 골랐어요';
  static const finishedTitle = '나답게 일하는 기준이\n완성됐어요.';
  static const finishedHint = '프로필과 받은 제안에 이 기준이 함께 보여요.';
  static const next = '다음';
  static const lastNext = '다 골랐어요';
  static const restart = '다시 고르기';
  static const save = '저장하고 캠페인 보기';

  // 캔버스에 없는 문구(저장이 실패했을 때, 불러오지 못했을 때).
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';
  static const loadFailedTitle = '협업 원칙을 불러오지 못했어요';

  @visibleForTesting
  static const laterKey = ValueKey<String>('principles.later');
  @visibleForTesting
  static const progressFillKey = ValueKey<String>('principles.progressFill');

  /// 선택지 줄의 키. 질문 안에서 몇 번째인지로 센다.
  @visibleForTesting
  static Key optionKey(int index) =>
      ValueKey<String>('principles.option.$index');

  static String stepLabel(int step) =>
      '$step / ${PrinciplesState.questionCount} 단계';

  void _leave(BuildContext context) => context.go(AppRoutes.creator);

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final saved = await ref.read(principlesViewModelProvider.notifier).save();
    if (saved && context.mounted) _leave(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(principlesViewModelProvider);
    final vm = ref.read(principlesViewModelProvider.notifier);
    final state = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              backDimmed: (state?.step ?? 0) == 0,
              onBack: vm.back,
              onLater: () => _leave(context),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CoraGlassCard(
                  // 아래 여백은 스크롤 안쪽 끝에 둔다. 선택지가 카드의 둥근 모서리에서 잘리게 한다.
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: state != null
                      ? _CardBody(state: state, onPick: vm.pick)
                      : async.hasError
                      ? SingleChildScrollView(
                          child: CoraStateView.loadFailed(
                            title: loadFailedTitle,
                            onRetry: () =>
                                ref.invalidate(principlesViewModelProvider),
                          ),
                        )
                      : const CoraStateView.loading(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (state != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: _Actions(
                  state: state,
                  onNext: vm.next,
                  onRestart: vm.restart,
                  onSave: () => _save(context, ref),
                ),
              )
            else
              SizedBox(height: bottom + CoraPrimaryButton.height),
          ],
        ),
      ),
    );
  }
}

/// 머리글: 이전 질문, 가운데 `나의 협업 원칙` 알약, 오른쪽 `나중에`. 높이 64, 좌 8 / 우 12.
/// 세 개를 양 끝과 사이에 고르게 벌린다(캔버스 `space-between`).
class _Header extends StatelessWidget {
  const _Header({
    required this.backDimmed,
    required this.onBack,
    required this.onLater,
  });

  final bool backDimmed;
  final VoidCallback onBack;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: CoraStepHeader.rowHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CoraBackButton(
              onPressed: onBack,
              dimmed: backDimmed,
              semanticLabel: PrinciplesPage.backLabel,
            ),
            Semantics(
              header: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.stepPill,
                  borderRadius: BorderRadius.circular(CoraRadius.pill),
                  boxShadow: CoraShadows.stepPill(c.stepPillShadow),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    PrinciplesPage.title,
                    style: CoraTextStyles.label.copyWith(color: c.onStepPill),
                  ),
                ),
              ),
            ),
            Semantics(
              container: true,
              button: true,
              onTap: onLater,
              child: ExcludeSemantics(
                child: CoraPressable(
                  key: PrinciplesPage.laterKey,
                  onTap: onLater,
                  // 보이는 모양은 캔버스(위아래 10, 좌우 6)이고, 누르는 자리만 44까지 키운다.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      widthFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          PrinciplesPage.later,
                          style: CoraTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.textSecondary,
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
      ),
    );
  }
}

/// 유리 카드 안: 머리말과 단계, 진행 막대, 그 아래(질문 또는 요약). 아래쪽은 질문이 많아도
/// (1번은 아홉 개) 카드 안에서 스크롤된다.
class _CardBody extends StatelessWidget {
  const _CardBody({required this.state, required this.onPick});

  final PrinciplesState state;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = PrinciplesState.questionCount;
    final shown = math.min(state.step + 1, n);
    final kicker = state.asking
        ? state.question.kicker
        : PrinciplesPage.finishedKicker;
    // 캔버스는 정수 퍼센트로 반올림한다(1 / 7 → 14%).
    final progress = (shown / n * 100).round() / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Center(
                  child: CustomPaint(
                    size: const Size.square(18),
                    painter: _CheckPainter(color: c.onAccent, width: 2.2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: CoraTextStyles.label.copyWith(color: c.text),
                  ),
                  Text(
                    PrinciplesPage.stepLabel(shown),
                    style: CoraTextStyles.fieldLabel.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: CoraStepHeader.barHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.progressTrack),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: ColoredBox(
                    key: PrinciplesPage.progressFillKey,
                    color: c.progressFill,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                state.asking
                    ? _Question(state: state, onPick: onPick)
                    : _Summary(state: state),
                // 카드 아래 안쪽 여백 18(캔버스 `padding: 22px 18px 18px`).
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.state, required this.onPick});

  final PrinciplesState state;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = state.question;
    final picked = state.answers.of(q.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Text(
          PrinciplesPage.questionLabel,
          style: CoraTextStyles.caption.copyWith(color: c.text),
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            q.title,
            style: CoraTextStyles.title.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          q.hint,
          style: CoraTextStyles.bodySmall.copyWith(
            height: 1.55,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (var i = 0; i < q.options.length; i++)
              _OptionTile(
                key: PrinciplesPage.optionKey(i),
                option: q.options[i],
                selected: picked.contains(i),
                onTap: () => onPick(i),
              ),
          ],
        ),
      ],
    );
  }
}

/// 선택지 한 줄. 높이 56 이상, 모서리 18, 왼쪽에 이름과 보조 글, 오른쪽에 22 둥근 체크.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PrincipleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: CoraMotion.resolve(context, CoraMotion.stateDuration),
          curve: CoraMotion.standardCurve,
          builder: (context, t, _) {
            final foreground = Color.lerp(c.text, c.onSurfaceSelected, t)!;
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(c.surface, c.surfaceSelected, t),
                  borderRadius: BorderRadius.circular(CoraRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: CoraTextStyles.bodyLarge.copyWith(
                                color: foreground,
                              ),
                            ),
                            // 캔버스 보조 글은 12px에 opacity 0.75다. 보조 글이 없으면 줄도 없다.
                            if (option.sub.isNotEmpty)
                              Text(
                                option.sub,
                                style: CoraTextStyles.fieldLabel.copyWith(
                                  color: foreground.withValues(
                                    alpha: foreground.a * 0.75,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color.lerp(c.line, c.selectionDot, t),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 22,
                          child: Center(
                            child: CustomPaint(
                              size: const Size.square(12),
                              painter: _CheckPainter(
                                // 고르지 않은 체크는 투명하다(캔버스 `check: transparent`).
                                color: c.onSelectionDot.withValues(
                                  alpha: c.onSelectionDot.a * t,
                                ),
                                width: 3.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 끝: 제목, 안내, 일곱 칸 요약(두 줄로 나란히). 고르지 않은 칸은 `고르지 않음`.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final PrinciplesState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final questions = principleQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text(
            PrinciplesPage.finishedTitle,
            style: CoraTextStyles.title.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          PrinciplesPage.finishedHint,
          style: CoraTextStyles.bodySmall.copyWith(
            height: 1.55,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < questions.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Expanded(
                    child: _SummaryCell(
                      label: questions[i].summaryLabel,
                      value: state.answers.summaryOf(questions[i]),
                    ),
                  ),
                  // 일곱 칸이라 마지막 줄의 오른쪽은 비어 있다(캔버스 격자와 같다).
                  Expanded(
                    child: i + 1 < questions.length
                        ? _SummaryCell(
                            label: questions[i + 1].summaryLabel,
                            value: state.answers.summaryOf(questions[i + 1]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.md),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: CoraTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
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

/// 아래 버튼. 질문 중에는 `다음`(마지막은 `다 골랐어요`), 요약에서는 `다시 고르기`와 `저장하고 캠페인 보기`.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.onNext,
    required this.onRestart,
    required this.onSave,
  });

  final PrinciplesState state;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (state.asking) {
      final last = state.step == PrinciplesState.questionCount - 1;
      return CoraPrimaryButton(
        label: last ? PrinciplesPage.lastNext : PrinciplesPage.next,
        look: CoraPrimaryButtonLook.next,
        onPressed: state.canContinue ? onNext : null,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.saveFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                PrinciplesPage.saveFailed,
                textAlign: TextAlign.center,
                style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              flex: 10,
              child: CoraPillButton(
                label: PrinciplesPage.restart,
                onPressed: state.saving ? null : onRestart,
                background: c.surfaceMuted,
                foreground: c.onSurfaceMuted,
                textStyle: CoraTextStyles.buttonMedium,
                height: CoraPrimaryButton.height,
              ),
            ),
            Expanded(
              flex: 16,
              child: CoraPillButton(
                label: PrinciplesPage.save,
                onPressed: state.saving ? null : onSave,
                background: c.accent,
                foreground: c.onAccent,
                textStyle: CoraTextStyles.button,
                height: CoraPrimaryButton.height,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 캔버스의 체크 `M5 12l5 5 9-10`(viewBox 24). [width]는 viewBox 기준 선 굵기다.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(5 * k, 12 * k)
        ..relativeLineTo(5 * k, 5 * k)
        ..relativeLineTo(9 * k, -10 * k),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.color != color || old.width != width;
}

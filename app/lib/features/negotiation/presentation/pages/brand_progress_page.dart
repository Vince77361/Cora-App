import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_negotiation_tokens.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart' show CoraBackButton;
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/presentation/collaboration_text.dart'
    show loadFailedMessage;
import '../../../collaboration/presentation/viewmodels/collaboration_view_model.dart';
import '../../../discovery/presentation/widgets/brand_bottom_nav.dart';
import '../../../store_browse/presentation/widgets/creator_bottom_nav.dart';
import '../terms_text.dart';
import '../viewmodels/progress_view_model.dart';
import '../widgets/canvas_text.dart';

/// 07 진행 단계(Progress / DarkProgress): 브랜드 협업의 여섯 단계. 머리 아래에 상대 사진과 `콘텐츠 방향을 함께
/// 잡아요.`, 지금 할 일 상자, 확보액과 남은 캠페인 예산 칸, 진행 막대와 여섯 줄이 있다. 브랜드와 크리에이터가
/// 함께 쓰고, 크리에이터에게는 남은 캠페인 예산 칸이 없다(캠페인 예산은 브랜드의 내부 사정이다).
class BrandProgressPage extends ConsumerStatefulWidget {
  const BrandProgressPage({super.key, required this.collaborationId});

  final String collaborationId;

  @override
  ConsumerState<BrandProgressPage> createState() => _BrandProgressPageState();
}

class _BrandProgressPageState extends ConsumerState<BrandProgressPage> {
  bool _redirected = false;

  /// 06을 연다. 07에서 연 것이라 수락하면 07로 돌아오고, 돌아오면 협업을 다시 읽는다.
  Future<void> _openTerms() async {
    await context.push(
      AppRoutes.collaborationTerms(widget.collaborationId),
      extra: AppRoutes.fromProgress,
    );
    if (mounted) {
      ref.invalidate(collaborationViewModelProvider(widget.collaborationId));
    }
  }

  void _openContract(Collaboration c) {
    context.push(AppRoutes.collaborationContract(c.id));
  }

  /// 협업 번호가 가게 오퍼의 것이면(알림이나 링크로 잘못 온 경우) 그 화면으로 보낸다. 이 화면은 브랜드 협업만 그린다.
  void _redirectStoreOffer(Collaboration c) {
    if (_redirected) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement(
        c.role == CollaborationRole.commissioner
            ? AppRoutes.storeCollaboration(c.id)
            : AppRoutes.creatorCollaboration(c.id),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = collaborationViewModelProvider(widget.collaborationId);
    final async = ref.watch(provider);
    final c = async.value?.collaboration;
    if (c != null && c.isStoreOffer) {
      _redirectStoreOffer(c);
      return const Scaffold(body: CoraStateView.loading());
    }
    final isBrand = c?.role == CollaborationRole.commissioner;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressHeader(
                  isBrand: c == null ? null : isBrand,
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
                Expanded(
                  child: c != null
                      ? _Content(
                          collaboration: c,
                          onOpenTerms: _openTerms,
                          onOpenContract: () => _openContract(c),
                          onOpenBudget: () =>
                              context.push(AppRoutes.brandProposals),
                        )
                      : async.hasError
                      ? CoraStateView.loadFailed(
                          title: loadFailedMessage,
                          onRetry: () => ref.invalidate(provider),
                        )
                      : const CoraStateView.loading(),
                ),
              ],
            ),
          ),
          if (c != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: isBrand
                  ? const BrandBottomNav(
                      currentIndex: CoraCreatorNavItems.collab,
                    )
                  : const CreatorBottomNav(
                      currentIndex: CoraCreatorNavItems.collab,
                    ),
            ),
        ],
      ),
    );
  }
}

/// 머리: 왼쪽 로고, 오른쪽 `브랜드 관점`(크리에이터는 `크리에이터 관점`, 캔버스 밖) 알약. 역할을 모르는 동안
/// ([isBrand]가 null)은 알약을 그리지 않는다.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.isBrand, this.onBack});

  final bool? isBrand;

  /// 다른 화면 위에 쌓여 열렸을 때만 준다(캔버스 밖). 있으면 로고 앞에 뒤로 가기가 붙는다.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brand = isBrand;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null) CoraBackButton(onPressed: onBack),
              const CoraLogo(size: 26),
            ],
          ),
          if (brand != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  brand ? TermsTexts.brandPill : TermsTexts.creatorPill,
                  style: canvasText(12, FontWeight.w500, c.text),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.collaboration,
    required this.onOpenTerms,
    required this.onOpenContract,
    required this.onOpenBudget,
  });

  final Collaboration collaboration;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenContract;
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final co = collaboration;
    final isBrand = co.role == CollaborationRole.commissioner;
    final brandName = isBrand
        ? co.campaign?.brandName
        : (co.campaign?.brandName ?? co.counterpartName);
    final creatorName = isBrand
        ? co.counterpartName
        : (ref.watch(myCreatorNameProvider).value ?? TermsTexts.me);
    final pair = brandName == null || brandName.isEmpty
        ? creatorName
        : progressPair(creatorName, brandName);
    final action = co.nextAction;
    final secured = co.securedAmount;
    final budget = co.campaignBudgetLeft;
    final progress = co.brandProgress;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: CoraBottomNav.height + 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              spacing: 12,
              children: [
                _Avatar(url: co.counterpartPhotoUrl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          TermsTexts.heading,
                          style: canvasText(
                            22,
                            FontWeight.w900,
                            c.text,
                            spacingEm: -0.03,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pair,
                        style: canvasText(13, FontWeight.w400, c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _NextActionBox(
                action: action,
                onTap: action == CollaborationNextAction.respondTerms
                    ? onOpenTerms
                    : onOpenContract,
              ),
            ),
          if (secured != null || budget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    if (secured != null)
                      Expanded(
                        child: _AmountCell(
                          label: TermsTexts.secured,
                          value: wonLabel(secured),
                          onTap: onOpenTerms,
                        ),
                      ),
                    if (budget != null)
                      Expanded(
                        child: _AmountCell(
                          label: TermsTexts.budgetLeft,
                          value: wonLabel(budget.left),
                          note: budget.over > 0
                              ? TermsTexts.overBudget(budget.over)
                              : null,
                          onTap: onOpenBudget,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (progress != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TermsTexts.progressTitle,
                    style: canvasText(15, FontWeight.w700, c.text),
                  ),
                  Text(
                    TermsTexts.doneCount(progress.doneCount),
                    style: canvasText(13, FontWeight.w500, c.text),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _Bar(done: progress.doneCount),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
              child: _Steps(
                progress: progress,
                // 지금 할 일이 `받은 제안 확인하고 응답하기`이면 "상대의 동의를 기다린다"는 글이 틀리다.
                showNote: switch (progress.note) {
                  BrandProgressNote.waitingOtherConfirm =>
                    action != CollaborationNextAction.respondTerms,
                  BrandProgressNote.waitingContract => true,
                  null => false,
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 상대 사진: 사진 52 + 테두리 2(바깥 지름 56)(라이트 `#5C7A00`, 다크 라임), 사진 기준점 62% 42%.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      // Container는 테두리 두께만큼 안쪽 여백을 둔다(DecoratedBox는 사진이 테두리를 덮는다). 전체 지름 56(캔버스는 사진 52 + 테두리 2).
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.progressRing, width: 2),
        ),
        child: ClipOval(
          child: SizedBox(
            width: 52,
            height: 52,
            child: CoraNetworkPhoto(
              url: url,
              alignment: const Alignment(0.24, -0.16),
              background: c.photoPlaceholder,
            ),
          ),
        ),
      ),
    );
  }
}

/// `지금 할 일` 강조 상자: `accent` 바탕, 오른쪽 화살표.
class _NextActionBox extends StatelessWidget {
  const _NextActionBox({required this.action, required this.onTap});

  final CollaborationNextAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = nextActionLabel(action);
    return Semantics(
      container: true,
      button: true,
      label: '${TermsTexts.nextAction}, $label',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(CoraRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TermsTexts.nextAction,
                          style: canvasText(12, FontWeight.w500, c.onAccent),
                        ),
                        Text(
                          label,
                          style: canvasText(16, FontWeight.w700, c.onAccent),
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: const Size.square(18),
                    painter: _ArrowPainter(c.onAccent),
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

/// 확보액과 남은 캠페인 예산 칸: `surface`, 안쪽 10·14, 둥근 14. [note]가 있으면 값 아래에 한 줄 더 붙는다.
class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.label,
    required this.value,
    required this.onTap,
    this.note,
  });

  final String label;
  final String value;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '$label, $value${note == null ? '' : ', $note'}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: canvasText(11, FontWeight.w400, c.textSecondary),
                  ),
                  Text(value, style: canvasText(15, FontWeight.w700, c.text)),
                  if (note != null)
                    Text(
                      note!,
                      style: canvasText(11, FontWeight.w400, c.textSecondary),
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

/// 진행 막대: 높이 6, 둥근 3, 바탕은 `line`, 채움은 끝난 단계 수 / 6.
class _Bar extends StatelessWidget {
  const _Bar({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: ColoredBox(
            color: c.line,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (done / 6).clamp(0.0, 1.0),
                heightFactor: 1,
                child: const ColoredBox(
                  color: CoraNegotiationTokens.progressDone,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 여섯 줄. 끝난 줄은 초록 동그라미와 체크, 지금 줄은 `surface` 바탕에 라임 동그라미와 번호(보조 글이 붙을 수
/// 있다), 남은 줄은 `surface` 동그라미와 번호다. 지금 줄만 좌우로 12 더 넓게 깔린다.
class _Steps extends StatelessWidget {
  const _Steps({required this.progress, required this.showNote});

  final BrandProgress progress;
  final bool showNote;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final names = TermsTexts.stepNames;
    final note = switch (progress.note) {
      BrandProgressNote.waitingOtherConfirm => TermsTexts.waitingOther,
      BrandProgressNote.waitingContract => TermsTexts.waitingContract,
      null => null,
    };
    return Semantics(
      container: true,
      label: TermsTexts.progressTitle,
      child: Column(
        children: [
          for (var i = 0; i < names.length; i++)
            _StepRow(
              number: i + 1,
              name: names[i],
              state: i + 1 <= progress.doneCount
                  ? _StepState.done
                  : (i + 1 == progress.current
                        ? _StepState.now
                        : _StepState.todo),
              note: i + 1 == progress.current && showNote ? note : null,
              last: i == names.length - 1,
              border: c.line,
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, now, todo }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.name,
    required this.state,
    required this.last,
    required this.border,
    this.note,
  });

  final int number;
  final String name;
  final _StepState state;
  final String? note;
  final bool last;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = switch (state) {
      _StepState.done => DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CoraNegotiationTokens.progressDone,
        ),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: CustomPaint(
              size: const Size.square(16),
              painter: _CheckPainter(c.onPhoto),
            ),
          ),
        ),
      ),
      _StepState.now => DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: Text(
              '$number',
              style: canvasText(14, FontWeight.w700, c.onAccent),
            ),
          ),
        ),
      ),
      _StepState.todo => DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: Text(
              '$number',
              style: canvasText(14, FontWeight.w500, c.textSecondary),
            ),
          ),
        ),
      ),
    };
    final title = Text(
      name,
      style: switch (state) {
        _StepState.done => canvasText(15, FontWeight.w700, c.textSecondary),
        _StepState.now => canvasText(15, FontWeight.w700, c.text),
        _StepState.todo => canvasText(15, FontWeight.w500, c.text),
      },
    );
    final semantics = switch (state) {
      _StepState.done => '$name, 완료',
      _StepState.now => '$name, 지금 단계${note == null ? '' : ', $note'}',
      _StepState.todo => name,
    };
    final Widget row = Row(
      spacing: 14,
      children: [
        dot,
        Expanded(
          child: note == null
              ? title
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    Text(note!, style: canvasText(12, FontWeight.w400, c.text)),
                  ],
                ),
        ),
      ],
    );
    final Widget child;
    if (state == _StepState.now) {
      // 지금 줄: 위아래 바깥 4, 안쪽 12·12, 둥근 12, 아래 줄이 없다.
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(padding: const EdgeInsets.all(12), child: row),
        ),
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: row,
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: semantics,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// SVG `M9 5l7 7-7 7`(viewBox 24, stroke 2.4, round)를 18로 줄여 그린다.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(9, 5)
        ..lineTo(16, 12)
        ..lineTo(9, 19),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// SVG `M5 12l5 5 9-10`(viewBox 24, stroke 3, round)를 16으로 줄여 그린다.
class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(10, 17)
        ..lineTo(19, 7),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

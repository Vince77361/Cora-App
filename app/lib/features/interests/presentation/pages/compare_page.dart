import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../discovery/presentation/widgets/discovery_toast.dart';
import '../../../negotiation/presentation/terms_text.dart';
import '../../domain/compare_result.dart';
import '../../domain/interest_card.dart';
import '../interests_text.dart';
import '../reward_proposal_entry.dart';
import '../viewmodels/compare_view_model.dart';

/// 04 후보 비교. 03에서 고른 두 크리에이터를 같은 결과물 기준으로 표 하나에 견준다. 조건이 다른 줄은 이름 앞에
/// 점이 붙고 두 값이 굵다. 팔로워 수는 비교하지 않는다.
class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key, required this.a, required this.b});

  final String a;
  final String b;

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  ({String message, int serial})? _notice;
  int _serial = 0;
  bool _opening = false;

  ({String a, String b}) get _pair => (a: widget.a, b: widget.b);

  CompareViewModel get _vm =>
      ref.read(compareViewModelProvider(_pair).notifier);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.brandInterests);
    }
  }

  Future<void> _onSide(CompareSide side) async {
    if (_opening) return;
    final collaborationId = side.collaborationId;
    if (side.state == InterestState.mutual && collaborationId != null) {
      context.push(AppRoutes.collaborationTerms(collaborationId));
      return;
    }
    _opening = true;
    try {
      final sent = await openRewardProposal(
        context,
        BeforeMatch(side.creatorId),
      );
      if (!sent || !mounted) return;
      setState(
        () => _notice = (
          message: InterestsTexts.proposalSent(side.name),
          serial: ++_serial,
        ),
      );
      await _vm.refresh();
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(compareViewModelProvider(_pair));
    final result = async.value;
    final notice = _notice;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: InterestsTexts.compareTitle,
              extent: 64,
              onBack: _back,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: result == null
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: async.hasError
                                ? CoraStateView.loadFailed(
                                    title:
                                        InterestsTexts.compareLoadFailedTitle,
                                    onRetry: _vm.reload,
                                  )
                                : const CoraStateView.loading(),
                          )
                        : _Table(result: result),
                  ),
                  if (notice != null)
                    Positioned(
                      top: 12,
                      left: 22,
                      right: 22,
                      child: DiscoveryToastBanner(
                        key: ValueKey(notice.serial),
                        message: notice.message,
                        onDismiss: () {
                          if (mounted && _notice?.serial == notice.serial) {
                            setState(() => _notice = null);
                          }
                        },
                      ),
                    ),
                  if (result != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _Buttons(result: result, onSide: _onSide),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: c.background,
    );
  }
}

/// 안내 한 줄과 비교 표(캔버스 Compare). 표는 좌우 16, 열은 라벨 26%·후보 37%씩이다.
class _Table extends StatelessWidget {
  const _Table({required this.result});

  final CompareResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final [left, right] = result.sides;
    final rows = <(CompareRow, String, String Function(CompareSide))>[
      (
        CompareRow.deliverable,
        InterestsTexts.rowDeliverable,
        (s) => compareDeliverableLabel(s.format, s.pieces),
      ),
      (
        CompareRow.benefit,
        InterestsTexts.rowBenefit,
        (s) => compareBenefitLabel(s.productProvided),
      ),
      (
        CompareRow.fee,
        InterestsTexts.rowFee,
        (s) => cashLabel(s.fee, s.feeBand),
      ),
      (
        CompareRow.perfCap,
        InterestsTexts.rowPerfCap,
        (s) => comparePerfCapLabel(s.perfCap),
      ),
      (
        CompareRow.usage,
        InterestsTexts.rowUsage,
        (s) => compareUsageLabel(s.usageRights),
      ),
      (
        CompareRow.start,
        InterestsTexts.rowStart,
        (s) => startFromLabel(s.startDate),
      ),
      (
        CompareRow.face,
        InterestsTexts.rowFace,
        (s) => compareFaceLabel(s.faceOk),
      ),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 58 + 32 + math.max(0, MediaQuery.viewPaddingOf(context).bottom),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              InterestsTexts.compareNote,
              style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row(
                  label: null,
                  cells: [
                    _Head(side: left),
                    _Head(side: right),
                  ],
                ),
                for (final (row, label, value) in rows)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: _Row(
                      label: label,
                      differs: result.differs.contains(row),
                      cells: [
                        _Value(
                          text: value(left),
                          bold: result.differs.contains(row),
                        ),
                        _Value(
                          text: value(right),
                          bold: result.differs.contains(row),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 표의 한 줄: 라벨 칸 26, 후보 칸 37씩.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.cells, this.differs = false});

  final String? label;
  final bool differs;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: label == null
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 26,
          child: label == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      if (differs)
                        Semantics(
                          label: InterestsTexts.differsLabel,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.compareDot,
                              ),
                              child: const SizedBox.square(dimension: 6),
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          label!,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: CoraTextStyles.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        for (final cell in cells) Expanded(flex: 37, child: cell),
      ],
    );
  }
}

/// 표 머리의 후보: 사진(높이 132, 모서리 20), 이름 14/700, 상태 12/400.
class _Head extends StatelessWidget {
  const _Head({required this.side});

  final CompareSide side;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = switch (side.state) {
      InterestState.mutual => InterestsTexts.badgeMutual,
      InterestState.waiting => InterestsTexts.badgeWaiting,
      InterestState.held => InterestsTexts.badgeHeld,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 132,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CoraNetworkPhoto(
                url: side.photoUrl,
                background: c.photoPlaceholder,
                alignment: const Alignment(0.2, -0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            side.name,
            style: CoraTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          Text(
            status,
            style: CoraTextStyles.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 표의 값 칸: 14, 조건이 다른 줄은 700.
class _Value extends StatelessWidget {
  const _Value({required this.text, required this.bold});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      child: Text(
        text,
        style: CoraTextStyles.bodySmall.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: c.text,
        ),
      ),
    );
  }
}

/// 아래 버튼 둘(캔버스 Compare): 높이 58, 사이 8, 아래 32. 서로 관심인 후보의 버튼이 오른쪽의 강조(라임, 폭
/// 1.6) 버튼이고 `제안 보기`다. 아닌 후보는 `…에게 제안`. 두 후보의 상태가 같으면 표의 왼쪽 후보가 강조 버튼이다.
class _Buttons extends StatelessWidget {
  const _Buttons({required this.result, required this.onSide});

  final CompareResult result;
  final void Function(CompareSide side) onSide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final [first, second] = result.sides;
    final secondMutual = second.state == InterestState.mutual;
    final firstMutual = first.state == InterestState.mutual;
    // 서로 관심이 한 명뿐이면 그 후보가 강조 버튼, 아니면 왼쪽 후보다.
    final strong = secondMutual && !firstMutual ? second : first;
    final quiet = identical(strong, first) ? second : first;

    Widget button(CompareSide side, {required bool strong}) {
      final label = side.state == InterestState.mutual
          ? InterestsTexts.viewProposal(side.shortName)
          : InterestsTexts.propose(side.shortName);
      return Expanded(
        flex: strong ? 16 : 10,
        child: Semantics(
          container: true,
          button: true,
          label: label,
          onTap: () => onSide(side),
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: () => onSide(side),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: strong ? c.accent : c.subtleAction,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: SizedBox(
                  height: 58,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (strong
                                    ? CoraTextStyles.button
                                    : CoraTextStyles.buttonMedium)
                                .copyWith(
                                  color: strong ? c.onAccent : c.onSubtleAction,
                                ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Row(
        spacing: 8,
        children: [button(quiet, strong: false), button(strong, strong: true)],
      ),
    );
  }
}

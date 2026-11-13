import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../domain/offer_version.dart';
import '../../domain/proposal.dart';
import '../open_contract.dart';
import '../proposal_text.dart';
import '../viewmodels/proposals_view_model.dart';

/// F3 제안함(NProposals / DarkNProposals). 사장님은 내 가게의 오퍼, 크리에이터는 내가 받은·낸 제안을 `진행 중`과
/// `종료` 탭으로 본다. 진행 중은 `내가 응답할 차례`가 먼저이고 `상대 대기`가 뒤다. 줄을 누르면 제안 상세가 열리고,
/// 합의한 줄은 계약(사장님은 결제나 진행 화면, 크리에이터는 협업 화면)으로 간다.
class ProposalsPage extends ConsumerStatefulWidget {
  const ProposalsPage({super.key, required this.party});

  /// 이 화면을 쓰는 쪽. 빈 상태 문구와 뒤로 가는 곳이 다르다.
  final ProposalParty party;

  static const title = '제안함';
  static const myTurnGroup = '내가 응답할 차례';
  static const waitingGroup = '상대 대기';
  static const endedGroup = '종료';
  static const emptyActive = '아직 받은 제안이 없어요';
  static const emptyActiveStoreDescription = '크리에이터에게 오퍼를 보내면 여기에 모여요.';
  static const emptyEnded = '아직 끝난 제안이 없어요';
  static const loadFailed = '제안함을 불러오지 못했어요.';

  /// 안내를 보여 주는 시간.
  static const noticeFor = Duration(milliseconds: 2500);

  static String activeTab(int count) => '진행 중 $count';
  static String endedTab(int count) => '종료 $count';

  @override
  ConsumerState<ProposalsPage> createState() => _ProposalsPageState();
}

class _ProposalsPageState extends ConsumerState<ProposalsPage> {
  Timer? _noticeTimer;

  bool get _store => widget.party == ProposalParty.store;

  @override
  void initState() {
    super.initState();
    // 오퍼를 보낸 쪽이 이 화면을 열기 전에 안내를 올려 둔다. 화면이 생길 때 이미 있는 안내도 시간이 지나면 지운다.
    _onNotice(ref.read(proposalsNoticeProvider));
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _onNotice(String? message) {
    _noticeTimer?.cancel();
    if (message == null) return;
    _noticeTimer = Timer(ProposalsPage.noticeFor, () {
      if (mounted) ref.read(proposalsNoticeProvider.notifier).clear();
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_store ? AppRoutes.store : AppRoutes.creatorOffers);
    }
  }

  Future<void> _open(ProposalRow row) async {
    final collaborationId = row.collaborationId;
    if (row.endKind == ProposalEndKind.agreed && collaborationId != null) {
      await _openContract(collaborationId);
      return;
    }
    await context.push(
      _store
          ? AppRoutes.storeProposal(row.offerId)
          : AppRoutes.creatorProposal(row.offerId),
    );
    // 상세에서 수락하거나 끝냈을 수 있어 돌아오면 목록을 새로 읽는다.
    if (!mounted) return;
    unawaited(ref.read(proposalsViewModelProvider.notifier).refresh());
  }

  /// 합의한 줄: 크리에이터는 협업 화면(A7). 사장님은 결제 전이면 결제(A8), 결제했으면 진행 화면이다.
  Future<void> _openContract(String collaborationId) async {
    if (!_store) {
      await context.push(AppRoutes.creatorCollaboration(collaborationId));
      return;
    }
    await openStoreContract(context, ref, collaborationId);
    if (!mounted) return;
    unawaited(ref.read(proposalsViewModelProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proposalsNoticeProvider, (_, next) => _onNotice(next));
    final async = ref.watch(proposalsViewModelProvider);
    final notice = ref.watch(proposalsNoticeProvider);
    final vm = ref.read(proposalsViewModelProvider.notifier);
    final Widget body = switch (async) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Tabs(
            activeCount: value.active.length,
            endedCount: value.ended.length,
            selected: value.tab,
            onChanged: vm.selectTab,
          ),
          Expanded(
            child: _Groups(
              state: value,
              store: _store,
              onOpen: _open,
              onRefresh: vm.refresh,
            ),
          ),
        ],
      ),
      AsyncError() => CoraStateView.loadFailed(
        title: ProposalsPage.loadFailed,
        onRetry: () => ref.invalidate(proposalsViewModelProvider),
      ),
      _ => const CoraStateView.loading(),
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CoraPageHeader(
                  title: ProposalsPage.title,
                  onBack: _back,
                  extent: 64,
                ),
                Expanded(child: body),
              ],
            ),
            if (notice != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _Notice(message: notice),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 탭(캔버스 `display: flex; gap: 2px; margin: 0 16px; padding: 4px`): `surface` 알약 안에 높이 40의 버튼 둘.
/// 고른 버튼은 `quietSelected` 바탕에 작은 그림자이고, 글자는 둘 다 `text` 14/500이다.
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.activeCount,
    required this.endedCount,
    required this.selected,
    required this.onChanged,
  });

  final int activeCount;
  final int endedCount;
  final ProposalTab selected;
  final ValueChanged<ProposalTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            spacing: 2,
            children: [
              Expanded(
                child: _TabButton(
                  label: ProposalsPage.activeTab(activeCount),
                  selected: selected == ProposalTab.active,
                  onTap: () => onChanged(ProposalTab.active),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: ProposalsPage.endedTab(endedCount),
                  selected: selected == ProposalTab.ended,
                  onTap: () => onChanged(ProposalTab.ended),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? c.quietSelected : const Color(0x00000000),
              borderRadius: BorderRadius.circular(CoraRadius.pill),
              boxShadow: selected ? CoraShadows.segmentSelected : null,
            ),
            child: SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  label,
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
    );
  }
}

class _Groups extends StatelessWidget {
  const _Groups({
    required this.state,
    required this.store,
    required this.onOpen,
    required this.onRefresh,
  });

  final ProposalsState state;
  final bool store;
  final ValueChanged<ProposalRow> onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = state.shown;
    final Widget content;
    if (rows.isEmpty) {
      final active = state.tab == ProposalTab.active;
      content = Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CoraStateView.empty(
          title: active ? ProposalsPage.emptyActive : ProposalsPage.emptyEnded,
          description: active && store
              ? ProposalsPage.emptyActiveStoreDescription
              : null,
        ),
      );
    } else {
      final groups = <(ProposalGroup, String)>[
        if (state.tab == ProposalTab.active) ...[
          (ProposalGroup.myTurn, ProposalsPage.myTurnGroup),
          (ProposalGroup.waiting, ProposalsPage.waitingGroup),
        ] else
          (ProposalGroup.ended, ProposalsPage.endedGroup),
      ];
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (group, title) in groups)
            if (rows.any((r) => r.group == group))
              _Group(
                group: group,
                title: title,
                rows: [
                  for (final r in rows)
                    if (r.group == group) r,
                ],
                onOpen: onOpen,
              ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: c.text,
      backgroundColor: c.background,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [content],
      ),
    );
  }
}

/// 묶음(캔버스 `section`, 위 16·좌우 16): 점과 이름(13/500 보조색)이 위에, 줄이 8 간격으로 아래에 있다.
class _Group extends StatelessWidget {
  const _Group({
    required this.group,
    required this.title,
    required this.rows,
    required this.onOpen,
  });

  final ProposalGroup group;
  final String title;
  final List<ProposalRow> rows;
  final ValueChanged<ProposalRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 내가 응답할 차례는 라임, 대기는 흐린 회색(#A0A4AD), 종료는 선 색이다(캔버스 점).
    final dot = switch (group) {
      ProposalGroup.myTurn => c.accent,
      ProposalGroup.waiting => c.iconMuted,
      ProposalGroup.ended => c.line,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Semantics(
              header: true,
              child: Row(
                spacing: 6,
                children: [
                  ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      title,
                      style: CoraTextStyles.label.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _RowTile(row: row, onTap: () => onOpen(row)),
          ],
        ],
      ),
    );
  }
}

/// 줄(캔버스 `li > a`): 안쪽 12/14, 모서리 22, `surface` 바탕, 사진 48 원(위쪽 25%) + 이름 15/700 · 설명 12 보조색 +
/// 오른쪽 알약. 내가 응답할 차례의 알약은 라임이고, 나머지는 `quietSelected` 바탕에 보조색 글자다.
class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onTap});

  final ProposalRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hot = row.group == ProposalGroup.myTurn;
    final subtitle = rowSubtitle(row);
    final badge = rowBadge(row);
    return Semantics(
      container: true,
      button: true,
      label: '${row.name}, $subtitle, $badge',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.panel),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                spacing: 12,
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: ClipOval(
                      child: CoraNetworkPhoto(
                        url: row.photoUrl,
                        alignment: const Alignment(0, -0.5),
                        background: c.creatorPhotoPlaceholder,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoraTextStyles.buttonMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CoraTextStyles.fieldLabel.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: hot ? c.accent : c.quietSelected,
                      borderRadius: BorderRadius.circular(CoraRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        style: CoraTextStyles.caption.copyWith(
                          color: hot ? c.onAccent : c.textSecondary,
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

/// 제안함 아래에 잠깐 떠 있는 안내(캔버스에 없다). 본문색 바탕에 배경색 글자라 라이트·다크 모두 읽힌다.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.text,
            borderRadius: BorderRadius.circular(CoraRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              message,
              style: CoraTextStyles.label.copyWith(color: c.background),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../instagram_connect/presentation/viewmodels/instagram_connect_view_model.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../../offer_terms/presentation/pages/reward_budget_page.dart';
import '../../../offer_terms/presentation/pages/review_send_page.dart';
import '../../../offer_terms/presentation/widgets/terms_summary.dart';
import '../../domain/offer_version.dart';
import '../../domain/proposal.dart';
import '../../domain/proposal_repository.dart';
import '../counter_proposal_text.dart';
import '../open_contract.dart';
import '../proposal_text.dart';
import '../viewmodels/proposal_detail_view_model.dart';
import '../viewmodels/proposals_view_model.dart';
import '../widgets/end_reason_sheet.dart';

/// 제안 상세(캔버스에 없다. F2 `보내기 전 검토`의 줄 구성과 공용 위젯을 따른다). 머리는 `판본 {n}`이고, 받는 사람
/// 카드와 조건 줄 여덟 개에 크리에이터가 쓴 판본이면 `아이디어`·`표현 원칙`·`시리즈` 줄이 더해진다. 앞 판본과 달라진
/// 줄에는 `바뀜` 표지가 붙는다.
///
/// 내가 응답할 차례에는 `이 판본 수락`과 고쳐서 답하기·끝내기가, 상대를 기다릴 때는 `제안 취소`가 있고, 끝난
/// 제안에는 버튼이 없다. 끝내는 버튼은 사유 시트를 연다.
class ProposalDetailPage extends ConsumerStatefulWidget {
  const ProposalDetailPage({
    super.key,
    required this.offerId,
    required this.party,
  });

  final String offerId;

  /// 이 화면을 쓰는 쪽(경로가 정한다). 뒤로 가는 곳과 답하는 길이 다르다.
  final ProposalParty party;

  static String title(int version) => '판본 $version';
  static const acceptLabel = '이 판본 수락';
  static const replyLabel = '고쳐서 다시 보내기';
  static const endLabel = '제안 종료';
  static const counterLabel = '내 방식으로 제안';
  static const declineLabel = '거절';
  static const cancelLabel = '제안 취소';
  static const acceptedTitle = '수락했어요.';
  static const acceptedBody = '사장님이 결제하면 알려드릴게요.';
  static const confirm = '확인';
  static const senderLabel = '보낸 사람';
  static const ideaLabel = '아이디어';
  static const principlesLabel = '표현 원칙';
  static const seriesLabel = '시리즈';

  /// 캔버스에 없는 상태의 문구.
  static const sent = '제안을 보냈어요.';
  static const notFound = '제안을 찾을 수 없어요.';
  static const loadFailed = '제안을 불러오지 못했어요.';

  @override
  ConsumerState<ProposalDetailPage> createState() => _ProposalDetailPageState();
}

class _ProposalDetailPageState extends ConsumerState<ProposalDetailPage> {
  bool get _store => widget.party == ProposalParty.store;

  ProposalDetailViewModel get _vm =>
      ref.read(proposalDetailViewModelProvider(widget.offerId).notifier);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        _store ? AppRoutes.storeProposals : AppRoutes.creatorProposals,
      );
    }
  }

  /// `이 판본 수락`. 사장님은 결제 화면(결제할 것이 없으면 진행 화면)으로 가고, 크리에이터는 안내를 보인다.
  Future<void> _accept() async {
    final collaborationId = await _vm.accept();
    if (!mounted || !_store || collaborationId == null) return;
    await openStoreContract(context, ref, collaborationId);
  }

  Future<void> _end(String title) async {
    final reason = await showEndReasonSheet(context, title: title);
    if (reason == null || !mounted) return;
    await _vm.end(reason);
  }

  /// 사장님: 최신 판본 조건에서 F1을 열어 다음 판본을 만든다. F2의 마지막 버튼이 [_sendReply]를 부른다.
  void _reply(ProposalDetail detail) {
    final target = ReplyTarget(
      offerId: detail.offerId,
      counterpartName: detail.counterpart.name,
      nextVersion: detail.latest.number + 1,
      start: detail.latest.terms,
    );
    Navigator.of(context, rootNavigator: true).push(
      CoraTransitions.push(
        RewardBudgetPage(
          target: target,
          onSend: _sendReply,
          recipientPhotoUrl: detail.counterpart.photoUrl,
          failureMessage: proposalReplyFailed,
        ),
      ).createRoute(context),
    );
  }

  Future<void> _sendReply(OfferTerms terms) async {
    await _vm.reply(terms);
    if (!mounted) return;
    ref.read(proposalsNoticeProvider.notifier).show(ProposalDetailPage.sent);
    // F1·F2가 위에 떠 있어서 제안함으로 가며 함께 닫는다.
    context.go(AppRoutes.storeProposals);
  }

  /// 크리에이터: 가게의 열린 제안에 내 방식으로 다음 판본을 낸다(F6). F6이 열린 제안과 최신 판본 조건을 읽는다.
  Future<void> _counter(ProposalDetail detail) async {
    await context.push(AppRoutes.creatorStoreProposal(detail.storeId));
    if (mounted) await _vm.reload();
  }

  Future<void> _connectInstagram() async {
    await context.push(AppRoutes.creatorInstagram);
    // 연동하고 돌아오면 서버가 `needsInstagram`을 바꾸므로 다시 읽는다.
    ref.invalidate(instagramConnectViewModelProvider);
    if (mounted) await _vm.reload();
  }

  /// 크리에이터가 수락한 뒤의 `확인`: 협업 화면(A7)으로 간다.
  void _openCollaboration(String? collaborationId) {
    if (collaborationId == null) {
      _back();
      return;
    }
    context.pushReplacement(AppRoutes.creatorCollaboration(collaborationId));
  }

  @override
  Widget build(BuildContext context) {
    final provider = proposalDetailViewModelProvider(widget.offerId);
    final async = ref.watch(provider);
    final version = async.value?.detail.latest.number;
    final Widget body = switch (async) {
      AsyncData(:final value) => _body(value),
      AsyncError(:final error) => CoraStateView.loadFailed(
        title: error is ProposalFailure && error.notFound
            ? ProposalDetailPage.notFound
            : ProposalDetailPage.loadFailed,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => const CoraStateView.loading(),
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: version == null ? null : ProposalDetailPage.title(version),
              onBack: _back,
              extent: 64,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _body(ProposalDetailState state) {
    final stale = state.staleVersion;
    if (stale != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CoraStateView.staleVersion(
          version: stale,
          onOpen: _vm.viewLatestVersion,
        ),
      );
    }
    if (state.accepted) {
      return _AcceptedPanel(
        onConfirm: () => _openCollaboration(state.acceptedCollaborationId),
      );
    }
    return _Loaded(
      state: state,
      // 어느 쪽인지는 서버가 말해 준 값을 따른다(경로와 같다).
      store: state.detail.myParty == ProposalParty.store,
      onAccept: _accept,
      onReply: () => _reply(state.detail),
      onCounter: () => _counter(state.detail),
      onConnect: _connectInstagram,
      onEnd: _end,
    );
  }
}

/// 크리에이터가 수락한 뒤 본문 자리에 놓이는 안내 칸(A6 수락 뒤 칸과 같은 모양).
class _AcceptedPanel extends StatelessWidget {
  const _AcceptedPanel({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.xxl),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Text(
                    ProposalDetailPage.acceptedTitle,
                    style: CoraTextStyles.title.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.96,
                      height: 1.448,
                      color: c.text,
                    ),
                  ),
                  Text(
                    ProposalDetailPage.acceptedBody,
                    style: CoraTextStyles.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  CoraPrimaryButton(
                    label: ProposalDetailPage.confirm,
                    onPressed: onConfirm,
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

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.state,
    required this.store,
    required this.onAccept,
    required this.onReply,
    required this.onCounter,
    required this.onConnect,
    required this.onEnd,
  });

  final ProposalDetailState state;
  final bool store;
  final VoidCallback onAccept;
  final VoidCallback onReply;
  final VoidCallback onCounter;
  final VoidCallback onConnect;
  final ValueChanged<String> onEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final detail = state.detail;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final burden = detail.latest.terms.reward.maxCashBurden;
    final notice = ReviewSendPage.notice(
      version: detail.latest.number,
      maxCashBurden: burden,
      feeRate: detail.feeRate,
      showFee: store,
    );
    final actions = _actions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (detail.ended)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        endedText(detail.endKind, detail.endReason),
                        style: CoraTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TermsRecipientCard(
                    label: detail.latest.authorParty == detail.myParty
                        ? ReviewSendPage.recipientLabel
                        : ProposalDetailPage.senderLabel,
                    name: detail.counterpart.name,
                    photoUrl: detail.counterpart.photoUrl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TermsRowsCard(rows: _rows(detail)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Text(
                    notice,
                    style: CoraTextStyles.legal.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty || state.notice != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                if (state.notice != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        state.notice!,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(color: c.text),
                      ),
                    ),
                  ),
                ...actions,
              ],
            ),
          ),
      ],
    );
  }

  /// 차례에 따른 버튼. 끝난 제안에는 없다.
  List<Widget> _actions(BuildContext context) {
    final detail = state.detail;
    final busy = state.busy;
    if (detail.ended) return const [];
    if (detail.waiting) {
      return [
        CoraSecondaryButton(
          label: ProposalDetailPage.cancelLabel,
          tone: CoraSecondaryTone.subtle,
          onPressed: busy ? null : () => onEnd(ProposalDetailPage.cancelLabel),
        ),
      ];
    }
    final instagramGate = !store && detail.needsInstagram;
    return [
      if (instagramGate)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Semantics(
            liveRegion: true,
            child: Text(
              ReviewSendPage.needsInstagram,
              textAlign: TextAlign.center,
              style: CoraTextStyles.meta.copyWith(color: context.colors.text),
            ),
          ),
        ),
      CoraPrimaryButton(
        label: instagramGate
            ? ReviewSendPage.connectInstagram
            : ProposalDetailPage.acceptLabel,
        onPressed: busy ? null : (instagramGate ? onConnect : onAccept),
        look: CoraPrimaryButtonLook.accent,
      ),
      Row(
        spacing: 8,
        children: [
          Expanded(
            flex: 5,
            child: CoraSecondaryButton(
              label: store
                  ? ProposalDetailPage.replyLabel
                  : ProposalDetailPage.counterLabel,
              tone: CoraSecondaryTone.subtle,
              fitLabel: true,
              onPressed: busy ? null : (store ? onReply : onCounter),
            ),
          ),
          Expanded(
            flex: 3,
            child: CoraSecondaryButton(
              label: store
                  ? ProposalDetailPage.endLabel
                  : ProposalDetailPage.declineLabel,
              tone: CoraSecondaryTone.subtle,
              fitLabel: true,
              onPressed: busy
                  ? null
                  : () => onEnd(
                      store
                          ? ProposalDetailPage.endLabel
                          : ProposalDetailPage.declineLabel,
                    ),
            ),
          ),
        ],
      ),
    ];
  }

  /// F2와 같은 줄에 크리에이터가 쓴 판본이면 아이디어·표현 원칙·시리즈를 더한다. 앞 판본과 달라진 줄에 표지가 붙는다.
  List<TermsRow> _rows(ProposalDetail detail) {
    final latest = detail.latest;
    final terms = latest.terms;
    final reward = terms.reward;
    bool changed(ProposalField field) => detail.changed.contains(field);
    final previous = detail.previous;
    final burdenChanged =
        previous != null &&
        previous.terms.reward.maxCashBurden != reward.maxCashBurden;
    final byCreator = latest.authorParty == ProposalParty.creator;
    final recruit = (detail.recruitLine ?? '').trim();
    return [
      TermsRow(
        label: ReviewSendPage.recruitLabel,
        value: recruit.isEmpty
            ? detail.storeName
            : '${detail.storeName} · $recruit',
      ),
      TermsRow(
        label: ReviewSendPage.deliverableLabel,
        value: deliverableLine(terms.format, terms.pieces),
        changed: changed(ProposalField.format),
      ),
      TermsRow(
        label: ReviewSendPage.benefitLabel,
        value: reward.voucher == null
            ? ReviewSendPage.none
            : benefitLine(reward.voucher!),
        changed: changed(ProposalField.voucher),
      ),
      TermsRow(
        label: ReviewSendPage.fixedCashLabel,
        value: reward.fixedCash == 0
            ? ReviewSendPage.none
            : fixedCashLabel(reward.fixedCash),
        changed: changed(ProposalField.fixedCash),
      ),
      TermsRow(
        label: ReviewSendPage.viewPayLabel,
        value: reward.viewPay == null
            ? ReviewSendPage.none
            : viewPayLine(reward.viewPay!),
        changed: changed(ProposalField.viewPay),
      ),
      TermsRow(
        label: ReviewSendPage.usageRightsLabel,
        value: usageRightsLabel(terms.usageRights),
        changed: changed(ProposalField.usageRights),
      ),
      if (byCreator) ...[
        TermsRow(
          label: ProposalDetailPage.ideaLabel,
          value: (latest.idea ?? '').trim().isEmpty
              ? ReviewSendPage.none
              : latest.idea!.trim(),
          changed: changed(ProposalField.idea),
        ),
        TermsRow(
          label: ProposalDetailPage.principlesLabel,
          value: principlesLabel(latest.principles),
          changed: changed(ProposalField.principles),
        ),
        TermsRow(
          label: ProposalDetailPage.seriesLabel,
          value: _seriesValue(latest.series),
          changed: changed(ProposalField.series),
        ),
      ],
      TermsRow(
        label: ReviewSendPage.burdenLabel,
        value: wonExact(reward.maxCashBurden),
        bold: true,
        changed: burdenChanged,
      ),
    ];
  }

  /// `한 그릇 일기 · 30초 릴스`. 설명이 없으면 형식 이름을, 시리즈 없이 형식만 골랐으면 `없음`이다.
  static String _seriesValue(OfferVersionSeries? series) {
    final name = (series?.name ?? '').trim();
    if (series == null || name.isEmpty) return ReviewSendPage.none;
    final format = series.format;
    final detail = format == null
        ? (series.note ?? '').trim()
        : seriesSubtitle(series.note, format);
    return detail.isEmpty ? name : '$name · $detail';
  }
}

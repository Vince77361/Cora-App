import 'dart:math' as math;

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/text/josa.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/collaboration.dart';
import '../collaboration_text.dart';
import '../mail_launcher.dart';
import '../viewmodels/collaboration_view_model.dart';
import '../widgets/cancel_collaboration_sheet.dart';
import '../widgets/collaboration_parts.dart';

/// A7 협업 진행(NEscrow / DarkNEscrow). 크리에이터가 수락한 협업의 보관 금액, 단계, 다음에 할 일을
/// 보인다. 링크 제출, 식사권, 지급받을 계좌, 문의, 협업 그만두기가 여기서 열린다.
class CollaborationPage extends ConsumerStatefulWidget {
  const CollaborationPage({super.key, required this.collaborationId});

  final String collaborationId;

  static const keeping = 'Cora가 안전하게 보관 중';
  static const earnedLabel = '지금 받을 금액';
  static const viewsLabel = '조회수';
  static const submitFirst = '링크를 제출하면 집계가 시작돼요.';
  static const inquiry = '문의하기';
  static const submit = '콘텐츠 링크 제출';
  static const showVoucher = '식사권 보여주기';
  static const registerAccount = '지급받을 계좌 등록하기';
  static const acceptCancel = '동의하기';

  /// 캔버스에 없는 상태의 문구.
  static const waitingPayment = '결제를 기다리고 있어요';
  static const checking = '집계를 확인하고 있어요';
  static const payoutChecking = '지급을 확인하고 있어요';
  static const settledDone = '정산이 끝났어요';
  static const ended = '끝난 협업이에요';
  static const finalViewsLabel = '최종 조회수';

  static String title(String name) => '$name 협업';
  static String counting(int days) => '집계 중이에요 · $days일 남음';
  static String payoutPending(DateTime on) => '지급 예정 · ${monthDay(on)}';
  static String paid(int amount) => '${wonExact(amount)}이 지급됐어요';
  static String voucherNumber(String shortId) => '협업 번호 $shortId';
  static String cancelRequested(String name) =>
      '${josa(name, JosaPair.iGa)} 협업 취소를 요청했어요.';

  @override
  ConsumerState<CollaborationPage> createState() => _CollaborationPageState();
}

class _CollaborationPageState extends ConsumerState<CollaborationPage> {
  CollaborationViewModel get _vm =>
      ref.read(collaborationViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorOffers);
    }
  }

  Future<void> _inquire(Collaboration c) async {
    final email = ref.read(appConfigProvider).operatorEmail.trim();
    final opened = await ref
        .read(mailLauncherProvider)
        .compose(
          to: email.isEmpty ? null : email,
          subject: inquirySubject(c.id),
        );
    if (!mounted || opened) return;
    _vm.showNotice(mailFailedMessage);
  }

  Future<void> _acceptCancel(String requestId) async {
    final done = await _vm.acceptCancel(requestId);
    if (mounted && done) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(
      collaborationViewModelProvider(widget.collaborationId),
    );
    final value = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final now = ref.watch(clockProvider).now();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: value == null
                  ? null
                  : CollaborationPage.title(
                      value.collaboration.counterpartName,
                    ),
              onBack: _leave,
              trailing: value != null && value.collaboration.canCancel
                  ? CollaborationMoreButton(onTap: _openCancelSheet)
                  : null,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _Content(
                    collaboration: value.collaboration,
                    busy: value.busy,
                    onAcceptCancel: _acceptCancel,
                    onShowVoucher: () => context.push(
                      AppRoutes.creatorVoucher(widget.collaborationId),
                    ),
                  ),
                ),
                AsyncError() => CoraStateView.loadFailed(
                  title: loadFailedMessage,
                  onRetry: () => ref.invalidate(
                    collaborationViewModelProvider(widget.collaborationId),
                  ),
                ),
                _ => const CoraStateView.loading(),
              },
            ),
            if (value != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (value.notice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            value.notice!,
                            textAlign: TextAlign.center,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                    _BottomBar(
                      collaboration: value.collaboration,
                      now: now,
                      onInquiry: () => _inquire(value.collaboration),
                      onSubmit: () => context.push(
                        AppRoutes.creatorCollaborationSubmit(
                          widget.collaborationId,
                        ),
                      ),
                      onRegisterAccount: () =>
                          context.push(AppRoutes.creatorPayoutAccount),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `협업 그만두기` 시트를 열고, 시트가 닫힌 뒤 그만두는 데 성공했으면 화면을 떠난다. 실패하면
  /// 시트만 닫히고 A7이 서버 문구를 보인다.
  Future<void> _openCancelSheet() async {
    final done = await showCancelCollaborationSheet(
      context,
      onConfirm: _vm.cancel,
    );
    if (mounted && done == true) _leave();
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.collaboration,
    required this.busy,
    required this.onAcceptCancel,
    required this.onShowVoucher,
  });

  final Collaboration collaboration;
  final bool busy;
  final ValueChanged<String> onAcceptCancel;
  final VoidCallback onShowVoucher;

  @override
  Widget build(BuildContext context) {
    final request = collaboration.cancelRequest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (request != null && !request.requestedByMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _CancelRequestBanner(
              name: collaboration.counterpartName,
              busy: busy,
              onAccept: () => onAcceptCancel(request.id),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _HeldBox(collaboration: collaboration),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: CollaborationSteps(
            steps: collaboration.steps,
            titleOf: stepTitle,
            subtitleOf: (key) => stepSubtitle(collaboration, key),
          ),
        ),
        if (collaboration.hasVoucher)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CoraSecondaryButton(
              label: CollaborationPage.showVoucher,
              onPressed: onShowVoucher,
            ),
          ),
      ],
    );
  }
}

/// 사장님의 취소 요청 띠(캔버스에 없다): `surface` 바탕 알약 칸에 문구와 `동의하기`.
class _CancelRequestBanner extends StatelessWidget {
  const _CancelRequestBanner({
    required this.name,
    required this.busy,
    required this.onAccept,
  });

  final String name;
  final bool busy;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  CollaborationPage.cancelRequested(name),
                  style: CoraTextStyles.bodySmall.copyWith(color: c.text),
                ),
              ),
            ),
            Semantics(
              container: true,
              button: true,
              enabled: !busy,
              onTap: busy ? null : onAccept,
              child: ExcludeSemantics(
                child: CoraPressable(
                  onTap: busy ? null : onAccept,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.highlightAction,
                      borderRadius: BorderRadius.circular(CoraRadius.pill),
                    ),
                    child: SizedBox(
                      height: 38,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            CollaborationPage.acceptCancel,
                            maxLines: 1,
                            style: CoraTextStyles.label.copyWith(
                              color: c.onHighlightAction,
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
      ),
    );
  }
}

/// 보관 상자(캔버스 `section`). 모양은 [CollaborationBox]가 그리고, 여기서는 단계에 맞는 문구를 고른다.
class _HeldBox extends StatelessWidget {
  const _HeldBox({required this.collaboration});

  final Collaboration collaboration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final co = collaboration;
    final settled = co.stage == CollaborationStage.settled;
    final headline = switch (co.stage) {
      CollaborationStage.settled => CollaborationPage.settledDone,
      CollaborationStage.refunded ||
      CollaborationStage.cancelled ||
      CollaborationStage.other => CollaborationPage.ended,
      // 결제 전에는 보관 중인 돈이 없다. 보관 중이라고 말하지 않는다.
      CollaborationStage.awaitingPayment => CollaborationPage.waitingPayment,
      _ => CollaborationPage.keeping,
    };
    final big = settled && co.settlement != null
        ? wonExact(co.settlement!.payoutAmount)
        : heldLabel(co);
    final lower = _lower(context, c);
    return CollaborationBox(
      label: headline,
      big: big,
      // 돈이 걸린 협업(고정 현금이나 조회수 수당)에서만 혜택을 보관액 아래에 덧붙인다.
      note: co.terms.reward.maxCashBurden > 0 && co.hasVoucher && !settled
          ? heldVoucherNote(co.terms.reward.voucher!)
          : null,
      lower: lower,
    );
  }

  Widget? _lower(BuildContext context, CoraColors c) {
    final co = collaboration;
    if (!co.hasPerView) return null;
    final Widget content;
    if (co.stage == CollaborationStage.settled) {
      final views = co.settlement?.finalViews;
      if (views == null) return null;
      content = Row(
        children: [
          Expanded(
            child: CollaborationStat(
              label: CollaborationPage.finalViewsLabel,
              value: '${commas(views)}회',
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      );
    } else if (co.earnedSoFar != null) {
      content = Row(
        spacing: 8,
        children: [
          Expanded(
            child: CollaborationStat(
              label: CollaborationPage.earnedLabel,
              value: wonExact(co.earnedSoFar!),
            ),
          ),
          Expanded(
            child: CollaborationStat(
              label: CollaborationPage.viewsLabel,
              value: '${commas(co.currentViews ?? 0)}회',
            ),
          ),
        ],
      );
    } else if (co.stage == CollaborationStage.funded ||
        co.stage == CollaborationStage.awaitingPayment) {
      content = Text(
        CollaborationPage.submitFirst,
        style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
      );
    } else {
      return null;
    }
    return CollaborationBox.divided(context, content);
  }
}

/// 아래 버튼 두 개: `문의하기`(flex 1)와 주 버튼(flex 1.6). 둘 다 높이 58, 사이 8.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.collaboration,
    required this.now,
    required this.onInquiry,
    required this.onSubmit,
    required this.onRegisterAccount,
  });

  final Collaboration collaboration;
  final DateTime now;
  final VoidCallback onInquiry;
  final VoidCallback onSubmit;
  final VoidCallback onRegisterAccount;

  /// 주 버튼의 문구와 동작. 동작이 null이면 눌리지 않는다.
  ({String label, VoidCallback? onPressed}) _primary() {
    final co = collaboration;
    switch (co.stage) {
      case CollaborationStage.awaitingPayment:
        return (label: CollaborationPage.waitingPayment, onPressed: null);
      case CollaborationStage.funded:
        return (label: CollaborationPage.submit, onPressed: onSubmit);
      case CollaborationStage.counting:
        final end = co.countingEndsAt;
        return (
          label: end == null
              ? CollaborationPage.checking
              : CollaborationPage.counting(daysLeft(end, now)),
          onPressed: null,
        );
      case CollaborationStage.halted:
        return (label: CollaborationPage.checking, onPressed: null);
      case CollaborationStage.settled:
        final amount = co.settlement?.payoutAmount;
        switch (co.payoutStatus) {
          case PayoutStatus.done:
            return (
              label: amount == null
                  ? CollaborationPage.settledDone
                  : CollaborationPage.paid(amount),
              onPressed: null,
            );
          case PayoutStatus.needsAccount:
            return (
              label: CollaborationPage.registerAccount,
              onPressed: onRegisterAccount,
            );
          case PayoutStatus.pending:
            final on = co.payoutScheduledFor;
            return (
              label: on == null
                  ? CollaborationPage.payoutChecking
                  : CollaborationPage.payoutPending(on),
              onPressed: null,
            );
          case PayoutStatus.failed:
            return (label: CollaborationPage.payoutChecking, onPressed: null);
          case PayoutStatus.none:
            return (label: CollaborationPage.settledDone, onPressed: null);
        }
      case CollaborationStage.refunded:
      case CollaborationStage.cancelled:
      case CollaborationStage.other:
        return (label: CollaborationPage.ended, onPressed: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = _primary();
    return Row(
      spacing: 8,
      children: [
        Expanded(
          flex: 10,
          child: CoraSecondaryButton(
            label: CollaborationPage.inquiry,
            onPressed: onInquiry,
          ),
        ),
        Expanded(
          flex: 16,
          child: CoraPrimaryButton(
            label: primary.label,
            onPressed: primary.onPressed,
            look: CoraPrimaryButtonLook.accent,
            fitLabel: true,
          ),
        ),
      ],
    );
  }
}

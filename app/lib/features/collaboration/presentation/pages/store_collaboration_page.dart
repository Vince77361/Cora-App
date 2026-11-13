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
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/collaboration.dart';
import '../collaboration_text.dart';
import '../link_launcher.dart';
import '../mail_launcher.dart';
import '../store_collaboration_text.dart';
import '../viewmodels/collaboration_view_model.dart';
import '../widgets/cancel_collaboration_sheet.dart';
import '../widgets/collaboration_parts.dart';

/// 사장님의 협업 진행 화면. 설계가 "A7과 같은 구성"이라 캔버스 NEscrow / DarkNEscrow의 모양
/// (머리, 보관 상자, 단계 목록, 아래 버튼)을 그대로 쓰고 문구만 사장님 쪽 말이다. 캔버스에는 이 화면이
/// 따로 없다.
class StoreCollaborationPage extends ConsumerStatefulWidget {
  const StoreCollaborationPage({super.key, required this.collaborationId});

  final String collaborationId;

  static const held = '보관 중인 금액';
  static const viewsLabel = '현재 조회수';
  static const refundLabel = '예상 환급액';
  static const submitFirst = '크리에이터가 링크를 제출하면 집계가 시작돼요.';
  static const viewContent = '올라온 콘텐츠 보기';
  static const inquiry = '문의하기';

  /// `…` 메뉴와 확인 시트.
  static const requestMenu = '협업 취소 요청';
  static const requestConfirmTitle = '크리에이터가 동의하면 취소되고 결제 금액을 모두 돌려받아요.';
  static const requestConfirm = '요청하기';
  static const requestKeep = '그대로 두기';
  static const requested = '취소 요청을 보냈어요. 3일 안에 답이 없으면 요청이 사라져요.';

  /// 캔버스에 없는 상태의 문구.
  static const settledDone = '정산이 끝났어요.';
  static const finalViewsLabel = '최종 조회수';
  static const ended = '끝난 협업이에요';
  static const voucherHeld = '제공한 식사권';
  static const waitingPayment = '결제를 기다리고 있어요';
  static const noRefundYet = '-';

  static String title(String name) =>
      '$name${josaOf(name, JosaPair.gwaWa)}의 협업';
  static String heldVoucher(String name) => '+ $name (방문 때 사용)';
  static String settledSummary(int payout, int refund) =>
      '지급 ${wonExact(payout)} · 환급 ${wonExact(refund)}';

  @override
  ConsumerState<StoreCollaborationPage> createState() =>
      _StoreCollaborationPageState();
}

class _StoreCollaborationPageState
    extends ConsumerState<StoreCollaborationPage> {
  CollaborationViewModel get _vm =>
      ref.read(collaborationViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
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

  /// 크리에이터가 낸 링크는 `http`·`https`일 때만 바깥 브라우저로 연다.
  Future<void> _viewContent(Collaboration c) async {
    final url = openableLink(c.submittedUrl);
    final opened =
        url != null && await ref.read(externalLinkLauncherProvider).open(url);
    if (!mounted || opened) return;
    _vm.showNotice(linkFailedMessage);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(
      collaborationViewModelProvider(widget.collaborationId),
    );
    final value = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: value == null
                  ? null
                  : StoreCollaborationPage.title(
                      value.collaboration.counterpartName,
                    ),
              onBack: _leave,
              trailing: value != null && value.collaboration.canRequestCancel
                  ? CollaborationMoreButton(
                      onTap: () => showCancelCollaborationSheet(
                        context,
                        onConfirm: _vm.requestCancel,
                        menu: StoreCollaborationPage.requestMenu,
                        confirmTitle:
                            StoreCollaborationPage.requestConfirmTitle,
                        confirm: StoreCollaborationPage.requestConfirm,
                        keep: StoreCollaborationPage.requestKeep,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _Content(
                    collaboration: value.collaboration,
                    onViewContent: () => _viewContent(value.collaboration),
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
                    CoraSecondaryButton(
                      label: StoreCollaborationPage.inquiry,
                      onPressed: () => _inquire(value.collaboration),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.collaboration, required this.onViewContent});

  final Collaboration collaboration;
  final VoidCallback onViewContent;

  @override
  Widget build(BuildContext context) {
    final request = collaboration.cancelRequest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (request != null && request.requestedByMe)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _RequestedBanner(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _HeldBox(collaboration: collaboration),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: CollaborationSteps(
            steps: collaboration.steps,
            titleOf: storeStepTitle,
            subtitleOf: (key) => storeStepSubtitle(collaboration, key),
          ),
        ),
        if ((collaboration.submittedUrl ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CoraSecondaryButton(
              label: StoreCollaborationPage.viewContent,
              onPressed: onViewContent,
            ),
          ),
      ],
    );
  }
}

/// 취소 요청을 보낸 뒤의 띠(캔버스에 없다): 크리에이터 쪽 취소 요청 띠와 같은 `surface` 칸에 문구만.
class _RequestedBanner extends StatelessWidget {
  const _RequestedBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Semantics(
          liveRegion: true,
          child: Text(
            StoreCollaborationPage.requested,
            style: CoraTextStyles.bodySmall.copyWith(color: c.text),
          ),
        ),
      ),
    );
  }
}

/// 보관 상자. 모양은 [CollaborationBox](A7의 `section`)와 같고, 단계에 맞는 사장님 쪽 문구를 고른다.
class _HeldBox extends StatelessWidget {
  const _HeldBox({required this.collaboration});

  final Collaboration collaboration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final co = collaboration;
    switch (co.stage) {
      case CollaborationStage.settled:
        final s = co.settlement;
        final views = s?.finalViews;
        return CollaborationBox(
          label: StoreCollaborationPage.settledDone,
          big: s == null
              ? null
              : StoreCollaborationPage.settledSummary(
                  s.payoutAmount,
                  s.refundAmount,
                ),
          bigSize: 24,
          lower: views == null
              ? null
              : CollaborationBox.divided(
                  context,
                  Row(
                    children: [
                      Expanded(
                        child: CollaborationStat(
                          label: StoreCollaborationPage.finalViewsLabel,
                          value: '${commas(views)}회',
                        ),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
        );
      case CollaborationStage.refunded:
      case CollaborationStage.cancelled:
      case CollaborationStage.other:
        return const CollaborationBox(label: StoreCollaborationPage.ended);
      case CollaborationStage.awaitingPayment:
        // 결제 전에는 보관 중인 돈이 없다. 금액을 보관 중이라고 말하지 않는다.
        return const CollaborationBox(
          label: StoreCollaborationPage.waitingPayment,
        );
      case CollaborationStage.funded:
      case CollaborationStage.counting:
      case CollaborationStage.halted:
        final voucher = co.terms.reward.voucher?.name;
        if (!co.hasEscrow) {
          // 식사권만 있는 협업: 맡긴 돈이 없다.
          return CollaborationBox(
            label: StoreCollaborationPage.voucherHeld,
            big: voucher,
          );
        }
        return CollaborationBox(
          label: StoreCollaborationPage.held,
          big: wonExact(co.escrowAmount),
          note: voucher == null
              ? null
              : StoreCollaborationPage.heldVoucher(voucher),
          lower: _lower(context, c),
        );
    }
  }

  Widget? _lower(BuildContext context, CoraColors c) {
    final co = collaboration;
    if (!co.hasEscrow || !hasPerViewReward(co)) return null;
    final views = co.currentViews;
    if (views != null) {
      return CollaborationBox.divided(
        context,
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: CollaborationStat(
                label: StoreCollaborationPage.viewsLabel,
                value: '${commas(views)}회',
              ),
            ),
            Expanded(
              child: CollaborationStat(
                label: StoreCollaborationPage.refundLabel,
                value: co.expectedRefund == null
                    ? StoreCollaborationPage.noRefundYet
                    : wonExact(co.expectedRefund!),
              ),
            ),
          ],
        ),
      );
    }
    if (co.stage == CollaborationStage.funded) {
      return CollaborationBox.divided(
        context,
        Text(
          StoreCollaborationPage.submitFirst,
          style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
        ),
      );
    }
    return null;
  }
}

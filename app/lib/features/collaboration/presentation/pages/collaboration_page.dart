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
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/collaboration.dart';
import '../collaboration_text.dart';
import '../mail_launcher.dart';
import '../viewmodels/collaboration_view_model.dart';
import '../widgets/cancel_collaboration_sheet.dart';

/// A7 협업 진행(NEscrow / DarkNEscrow). 크리에이터가 수락한 협업의 보관 금액, 단계, 다음에 할 일을
/// 보인다. 링크 제출, 식사권, 지급받을 계좌, 문의, 협업 그만두기가 여기서 열린다.
class CollaborationPage extends ConsumerStatefulWidget {
  const CollaborationPage({super.key, required this.collaborationId});

  final String collaborationId;

  static const keeping = 'Cora가 안전하게 보관 중';
  static const heldWithVoucher = '(방문 때 사용)';
  static const earnedLabel = '지금 받을 금액';
  static const viewsLabel = '조회수';
  static const submitFirst = '링크를 제출하면 집계가 시작돼요.';
  static const inquiry = '문의하기';
  static const submit = '콘텐츠 링크 제출';
  static const showVoucher = '식사권 보여주기';
  static const registerAccount = '지급받을 계좌 등록하기';
  static const acceptCancel = '동의하기';
  static const more = '더보기';

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
  static String heldVoucher(String name) => '+ $name $heldWithVoucher';
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
                  ? _MoreButton(
                      onTap: () => showCancelCollaborationSheet(
                        context,
                        onConfirm: _cancel,
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
                    busy: value.busy,
                    onAcceptCancel: _acceptCancel,
                    onShowVoucher: () => context.push(
                      AppRoutes.creatorVoucher(widget.collaborationId),
                    ),
                  ),
                ),
                AsyncError() => CoraErrorView(
                  message: loadFailedMessage,
                  onRetry: () => ref.invalidate(
                    collaborationViewModelProvider(widget.collaborationId),
                  ),
                ),
                _ => ColoredBox(
                  color: c.background,
                  child: const SizedBox.expand(),
                ),
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

  /// 시트의 `그만두기`. 실패하면 시트를 닫고 A7이 서버 문구를 보인다.
  Future<bool> _cancel() async {
    final done = await _vm.cancel();
    if (mounted && done) _leave();
    return done;
  }
}

/// 오른쪽 위 더보기(점 셋). 캔버스에 없다: 44 x 44 눌림 영역.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: CollaborationPage.more,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: CustomPaint(
                size: const Size(24, 24),
                painter: _DotsPainter(c.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final dx in [5.0, 12.0, 19.0]) {
      canvas.drawCircle(Offset(dx, 12), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
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
          child: _Steps(collaboration: collaboration),
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

/// 보관 상자(캔버스 `section`): 모서리 28, 안쪽 22/20, `surface`. 방패 + `Cora가 안전하게 보관 중`,
/// 큰 금액(40/900, -0.05em), 식사권 줄, 선 아래 두 칸.
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
      _ => CollaborationPage.keeping,
    };
    final big = settled && co.settlement != null
        ? wonExact(co.settlement!.payoutAmount)
        : heldLabel(co);
    final lower = _lower(c);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size.square(16),
                    painter: _ShieldPainter(c.text),
                  ),
                ),
                Expanded(
                  child: Text(
                    headline,
                    style: CoraTextStyles.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  big,
                  maxLines: 1,
                  style: CoraTextStyles.title.copyWith(
                    fontSize: 40,
                    letterSpacing: -2,
                    height: 1.448,
                    color: c.text,
                  ),
                ),
              ),
            ),
            if (co.hasEscrow && co.hasVoucher && !settled) ...[
              const SizedBox(height: 4),
              Text(
                CollaborationPage.heldVoucher(co.terms.voucherName!),
                style: CoraTextStyles.bodySmall.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ],
            ?lower,
          ],
        ),
      ),
    );
  }

  Widget? _lower(CoraColors c) {
    final co = collaboration;
    if (!co.hasEscrow) return null;
    final Widget content;
    if (co.stage == CollaborationStage.settled) {
      final views = co.settlement?.finalViews;
      if (views == null) return null;
      content = Row(
        children: [
          Expanded(
            child: _Stat(
              label: CollaborationPage.finalViewsLabel,
              value: '${_commas(views)}회',
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
            child: _Stat(
              label: CollaborationPage.earnedLabel,
              value: wonExact(co.earnedSoFar!),
            ),
          ),
          Expanded(
            child: _Stat(
              label: CollaborationPage.viewsLabel,
              value: '${_commas(co.currentViews ?? 0)}회',
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
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Padding(padding: const EdgeInsets.only(top: 16), child: content),
      ),
    );
  }
}

String _commas(int n) => wonExact(n).replaceAll('원', '');

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CoraTextStyles.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: CoraTextStyles.heading.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// 단계 목록(캔버스 `ol`): 한 줄 최소 56, 점(26)과 글자 사이 14, 점 아래 이어지는 2px 선.
class _Steps extends StatelessWidget {
  const _Steps({required this.collaboration});

  final Collaboration collaboration;

  @override
  Widget build(BuildContext context) {
    final steps = collaboration.steps;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            collaboration: collaboration,
            step: steps[i],
            index: i,
            last: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.collaboration,
    required this.step,
    required this.index,
    required this.last,
  });

  final Collaboration collaboration;
  final CollaborationStep step;
  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = step.state == StepState.done;
    final now = step.state == StepState.now;
    final dotBg = done
        ? c.stepDotDone
        : now
        ? c.stepDotNow
        : c.surface;
    final dotFg = done
        ? c.onStepDotDone
        : now
        ? c.onStepDotNow
        : c.textSecondary;
    final subtitle = stepSubtitle(collaboration, step.key);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 26,
                    child: Center(
                      child: Text(
                        done ? '✓' : '${index + 1}',
                        style: CoraTextStyles.caption.copyWith(color: dotFg),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: 2,
                    child: ColoredBox(
                      color: last ? const Color(0x00000000) : c.line,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepTitle(step.key),
                        style: CoraTextStyles.buttonMedium.copyWith(
                          fontWeight: now ? FontWeight.w700 : FontWeight.w400,
                          color: done ? c.textSecondary : c.text,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: CoraTextStyles.meta.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                    ],
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

/// 방패 모양(SVG `M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z`, viewBox 24, 선 2)을 16으로 줄여 그린다.
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = Path()
      ..moveTo(12, 3)
      ..relativeLineTo(8, 3)
      ..relativeLineTo(0, 6)
      ..relativeCubicTo(0, 5, -3.5, 8, -8, 9)
      ..relativeCubicTo(-4.5, -1, -8, -4, -8, -9)
      ..lineTo(4, 6)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.color != color;
}

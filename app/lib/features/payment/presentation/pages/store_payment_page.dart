import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/text/josa.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../../store_home/presentation/viewmodels/store_home_view_model.dart';
import '../../domain/payment_quote.dart';
import '../../domain/payment_repository.dart';
import '../viewmodels/payment_view_model.dart';

/// A8 가게 결제(NPay / DarkNPay). 크리에이터가 수락한 오퍼의 결제 내역과 수단을 보이고,
/// `결제하고 보관 맡기기`로 결제창을 연다. 결제가 승인되면 사장님 홈으로 돌아가 안내를 잠깐 보인다.
class StorePaymentPage extends ConsumerStatefulWidget {
  const StorePaymentPage({super.key, required this.collaborationId});

  final String collaborationId;

  static const title = '결제';
  static const content = '콘텐츠';
  static const voucherNote = '방문 때 가게에서 제공';
  static const fixedCash = '고정 현금';
  static const viewPay = '조회수 수당 (최대)';
  static const fee = '서비스 수수료';
  static const total = '지금 결제할 금액';
  static const methodGroup = '결제 수단';
  static const methods = ['카드', '계좌이체', '간편결제'];
  static const escrowNote =
      '결제 금액은 Cora가 보관하다가, 콘텐츠가 올라오고 조회수가 집계되면 크리에이터에게 지급해요.';
  static const submit = '결제하고 보관 맡기기';
  static const checking = '결제를 확인하고 있어요';
  static const approved = '결제했어요. 크리에이터에게 알렸어요.';
  static const incomplete = '결제가 완료되지 않았어요. 다시 시도해 주세요.';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '결제 정보를 불러오지 못했어요.';
  static const unavailable = '이미 결제했거나 결제 기한이 지난 오퍼예요.';
  static const createFailed = '결제를 시작하지 못했어요. 다시 시도해 주세요.';

  /// 조회수 수당이 있을 때 내역 아래 안내. 고정 현금도 있으면 최대 현금 부담 전체를 말한다.
  static String refundNote(PaymentQuote quote) => quote.fixedCash > 0
      ? '최대 ${wonExact(quote.escrow)}, 조회수 수당은 조회수만큼, 남으면 7일 집계 후 환불해요.'
      : '최대 ${wonExact(quote.viewPayCap ?? quote.escrow)}, 실제는 조회수만큼, 남으면 7일 집계 후 환불해요.';

  static String heading(String creatorName) =>
      '${josa(creatorName, JosaPair.iGa)}\n오퍼를 수락했어요';

  static String methodLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.card => methods[0],
    PaymentMethod.transfer => methods[1],
    PaymentMethod.easyPay => methods[2],
  };

  @override
  ConsumerState<StorePaymentPage> createState() => _StorePaymentPageState();
}

class _StorePaymentPageState extends ConsumerState<StorePaymentPage> {
  PaymentViewModel get _vm =>
      ref.read(paymentViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  Future<void> _pay() async {
    final outcome = await _vm.pay();
    if (!mounted || outcome != PaymentOutcome.approved) return;
    ref.read(storeHomeNoticeProvider.notifier).show(StorePaymentPage.approved);
    // 알림함에서 열었더라도 승인되면 홈으로 돌아가고(설계 A8), 홈은 서버에서 다시 읽어 결제한 오퍼를
    // 바로 보인다. 홈에서 열었으면 홈의 돌아옴 새로 고침이 한 번 더 돌지만 해롭지 않다.
    unawaited(ref.read(storeHomeViewModelProvider.notifier).refresh());
    context.go(AppRoutes.store);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(paymentViewModelProvider(widget.collaborationId));
    final state = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: _leave),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _Content(state: value, onMethod: _vm.selectMethod),
                ),
                AsyncError(:final error) => CoraStateView.loadFailed(
                  title: error is PaymentFailure && error.conflict
                      ? StorePaymentPage.unavailable
                      : StorePaymentPage.loadFailed,
                  onRetry: () => ref.invalidate(
                    paymentViewModelProvider(widget.collaborationId),
                  ),
                ),
                _ => const CoraStateView.loading(),
              },
            ),
            if (state != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.problem != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _problemText(state.problem!),
                            textAlign: TextAlign.center,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                    // 캔버스의 이 버튼은 다크에서도 라임이다. 결제를 확인하는 동안은 같은 자리에서
                    // 꺼진 모양으로 문구만 바뀐다.
                    CoraPrimaryButton(
                      label: state.phase == PaymentPhase.checking
                          ? StorePaymentPage.checking
                          : StorePaymentPage.submit,
                      onPressed: state.phase == PaymentPhase.checking
                          ? null
                          : _pay,
                      look: CoraPrimaryButtonLook.accent,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _problemText(PaymentProblem problem) => switch (problem) {
    PaymentProblem.incomplete => StorePaymentPage.incomplete,
    PaymentProblem.unavailable => StorePaymentPage.unavailable,
    PaymentProblem.startFailed => StorePaymentPage.createFailed,
  };
}

/// 머리(높이 56, 좌우 8, 60 / 1fr / 60): 뒤로 가기, 가운데 `결제` 16/500.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CoraBackButton(onPressed: onBack),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  StorePaymentPage.title,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.onMethod});

  final PaymentState state;
  final ValueChanged<PaymentMethod> onMethod;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quote = state.quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: _Title(quote: quote),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: _Breakdown(quote: quote),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _Methods(selected: state.method, onPick: onMethod),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size.square(16),
                    painter: _ShieldPainter(c.textSecondary),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  StorePaymentPage.escrowNote,
                  style: CoraTextStyles.meta.copyWith(
                    height: 1.6,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 크리에이터 사진(56 원, `object-position: 50% 25%`)과 제목(22/900, -0.04em).
class _Title extends StatelessWidget {
  const _Title({required this.quote});

  final PaymentQuote quote;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      spacing: 14,
      children: [
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: 56,
            child: ClipOval(
              child: CoraNetworkPhoto(
                url: quote.creatorPhotoUrl,
                alignment: const Alignment(0, -0.5),
                background: c.creatorPhotoPlaceholder,
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              StorePaymentPage.heading(quote.creatorName),
              style: CoraTextStyles.title.copyWith(
                fontSize: 22,
                letterSpacing: -0.88,
                color: c.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 결제 내역 카드(안쪽 18, 모서리 24, `surface`). 줄 사이 12, 합계 위에 1px 선.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.quote});

  final PaymentQuote quote;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              spacing: 12,
              children: [
                _Line(
                  label: StorePaymentPage.content,
                  value: '${formatLabel(quote.format)} ${quote.pieces}편',
                ),
                if (quote.voucher != null)
                  _Line(
                    label: benefitLine(quote.voucher!),
                    value: StorePaymentPage.voucherNote,
                  ),
                if (quote.fixedCash > 0)
                  _Line(
                    label: StorePaymentPage.fixedCash,
                    value: wonExact(quote.fixedCash),
                  ),
                if (quote.viewPayCap != null)
                  _Line(
                    label: StorePaymentPage.viewPay,
                    value: wonExact(quote.viewPayCap!),
                  ),
                _Line(label: StorePaymentPage.fee, value: wonExact(quote.fee)),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: MergeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        StorePaymentPage.total,
                        style: CoraTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          wonExact(quote.total),
                          textAlign: TextAlign.right,
                          style: CoraTextStyles.title.copyWith(
                            letterSpacing: -1.04,
                            color: c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 조회수 수당이 없으면 돌려받을 돈이 없어 안내 줄도 없다.
            if (quote.viewPayCap != null) ...[
              const SizedBox(height: 8),
              Text(
                StorePaymentPage.refundNote(quote),
                style: CoraTextStyles.legal.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 내역 한 줄: 왼쪽 이름(14, 보조색), 오른쪽 값(14/500, 오른쪽 정렬).
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Flexible(
            child: Text(
              label,
              style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: CoraTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 결제 수단 세 칸(높이 52, 모서리 18, 칸 사이 8). 고른 칸만 `notifyTabSelected`(라이트 #E3E5E9, 다크 #33363D).
class _Methods extends StatelessWidget {
  const _Methods({required this.selected, required this.onPick});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: StorePaymentPage.methodGroup,
      child: Row(
        spacing: 8,
        children: [
          for (final method in PaymentMethod.values)
            Expanded(
              child: Semantics(
                container: true,
                inMutuallyExclusiveGroup: true,
                checked: method == selected,
                onTap: () => onPick(method),
                child: ExcludeSemantics(
                  excluding: false,
                  child: CoraPressable(
                    onTap: () => onPick(method),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: method == selected
                            ? c.notifyTabSelected
                            : c.surface,
                        borderRadius: BorderRadius.circular(CoraRadius.lg),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            StorePaymentPage.methodLabel(method),
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
              ),
            ),
        ],
      ),
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

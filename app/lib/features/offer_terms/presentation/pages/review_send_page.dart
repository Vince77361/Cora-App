import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../instagram_connect/presentation/viewmodels/instagram_connect_view_model.dart';
import '../../../server_config/domain/server_config.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../../domain/offer_terms.dart';
import '../../domain/proposal_draft.dart';
import '../offer_terms_text.dart';
import '../viewmodels/proposal_draft_view_model.dart';
import '../widgets/usage_rights_sheet.dart';

/// F2 보내기 전 검토(NReviewSend / DarkNReviewSend). 받는 사람과 조건을 한 번 더 보여 주고, 마지막
/// 버튼이 [onSend]로 고른 조건을 넘긴다. `고치기`는 F1로 돌아가며 고른 값은 그대로다.
///
/// 모집 조건([RecruitTarget])이면 받는 사람이 `공개 모집`이고 버튼이 `이 조건으로 공개하기`다.
/// 크리에이터가 내는 제안([CounterTarget])에는 이용료 문장이 없다(이용료는 가게가 낸다).
/// [onSend]가 예외(`Exception`)를 던지면 이 화면에 머물며 [failureMessage]를 보인다.
class ReviewSendPage extends ConsumerStatefulWidget {
  const ReviewSendPage({
    super.key,
    required this.target,
    required this.onSend,
    this.recipientPhotoUrl,
    this.failureMessage = defaultFailureMessage,
  });

  final ProposalTarget target;
  final Future<void> Function(OfferTerms terms) onSend;

  /// 받는 사람의 사진. 없으면 사진 자리만 보인다.
  final String? recipientPhotoUrl;
  final String failureMessage;

  static const pageLabel = '제안 만들기';
  static const step = 3;
  static const totalSteps = 3;
  static const title = '받는 사람과 조건을\n한 번 더 확인해요.';
  static const recipientLabel = '받는 사람';
  static const openCallRecipient = '공개 모집';
  static const recruitLabel = '모집';
  static const deliverableLabel = '결과물';
  static const benefitLabel = '제공 혜택';
  static const fixedCashLabel = '고정 현금';
  static const viewPayLabel = '조회수 수당';
  static const usageRightsLabel = '사용권';
  static const burdenLabel = '최대 현금 부담';
  static const none = '없음';
  static const editLabel = '고치기';
  static const sendLabel = '이 조건으로 보내기';
  static const publishLabel = '이 조건으로 공개하기';
  static const defaultFailureMessage = '잠시 문제가 생겼어요. 다시 시도해 주세요.';
  static const loadFailed = '조건을 불러오지 못했어요.';
  static const needsInstagram = '인스타그램을 연동하면 수락할 수 있어요';
  static const connectInstagram = '연동하기';
  static const openCallNotice = '크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.';

  /// 안내. 이용료는 최대 현금 부담이 있을 때만, 그리고 가게가 내는 제안에만 쓴다.
  static String notice({
    required int version,
    required int maxCashBurden,
    required int feeRate,
    required bool showFee,
  }) {
    const head = '보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요.';
    final fixed = '보낸 조건은 ${versionWithRo(version)} 고정';
    if (!showFee || maxCashBurden == 0) return '$head $fixed돼요.';
    final fee = feeAmountLabel(maxCashBurden, feeRate);
    return '$head $fixed되고, 이용료 $fee은 별도예요.';
  }

  @override
  ConsumerState<ReviewSendPage> createState() => _ReviewSendPageState();
}

class _ReviewSendPageState extends ConsumerState<ReviewSendPage> {
  bool _sending = false;

  /// 보내기에 실패했을 때 보일 문구. 실패하지 않았으면 null이다.
  String? _failedMessage;

  Future<void> _send(OfferTerms terms) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _failedMessage = null;
    });
    try {
      await widget.onSend(terms);
      // 성공하면 보통 화면이 닫힌다. 그대로 남는 화면이면 다시 누를 수 있게 둔다.
      if (mounted) setState(() => _sending = false);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          // 보내는 쪽이 실패 이유에 맞는 문구를 줬으면 그것을, 아니면 기본 문구를 보인다.
          _failedMessage = error is ProposalSendFailure && error.message != null
              ? error.message
              : widget.failureMessage;
        });
      }
    }
  }

  Future<void> _pickUsageRights(OfferTerms terms) async {
    final picked = await showUsageRightsSheet(
      context,
      selected: terms.usageRights,
    );
    if (picked == null || !mounted) return;
    ref
        .read(proposalDraftViewModelProvider(widget.target).notifier)
        .setUsageRights(picked);
  }

  /// 크리에이터가 조회수 수당이 켜진 제안을 보내려는데 인스타그램 연동이 없다. 연동을 읽는 중이거나
  /// 읽지 못했으면 막지 않는다(서버가 보낼 때 다시 확인한다).
  bool _needsInstagram(OfferTerms terms) {
    if (widget.target is! CounterTarget || terms.reward.viewPay == null) {
      return false;
    }
    final connection = ref.watch(instagramConnectViewModelProvider);
    return connection.hasValue && connection.requireValue.connection == null;
  }

  Future<void> _connectInstagram() async {
    await context.push(AppRoutes.creatorInstagram);
    // 연동하고 돌아오면 연동 상태를 다시 읽어 `이 조건으로 보내기`가 돌아오게 한다.
    ref.invalidate(instagramConnectViewModelProvider);
  }

  String? _storeName() {
    final target = widget.target;
    if (target is CounterTarget) return target.storeName;
    return ref.watch(myStoreViewModelProvider.select((s) => s.value?.name));
  }

  String _recipientName() => switch (widget.target) {
    RecruitTarget() => ReviewSendPage.openCallRecipient,
    NewOfferTarget(:final creatorName) => creatorName,
    ReplyTarget(:final counterpartName) => counterpartName,
    CounterTarget(:final storeName) => storeName,
  };

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final config = ref.watch(serverConfigViewModelProvider);
    final draft = ref.watch(proposalDraftViewModelProvider(target));
    final storeName = _storeName() ?? '';
    final Widget body;
    if (config.value != null && draft.value != null) {
      body = _Body(
        target: target,
        terms: draft.value!,
        config: config.value!,
        recipientName: _recipientName(),
        recipientPhotoUrl: widget.recipientPhotoUrl,
        storeName: storeName,
        sending: _sending,
        failedMessage: _failedMessage,
        onSend: () => _send(draft.value!),
        onPickUsageRights: () => _pickUsageRights(draft.value!),
        onEdit: () => Navigator.of(context).maybePop(),
        needsInstagram: _needsInstagram(draft.value!),
        onConnect: _connectInstagram,
      );
    } else if (config.hasError || draft.hasError) {
      body = CoraStateView.loadFailed(
        title: ReviewSendPage.loadFailed,
        onRetry: () {
          ref.invalidate(serverConfigViewModelProvider);
          ref.invalidate(proposalDraftViewModelProvider(target));
        },
      );
    } else {
      body = const CoraStateView.loading();
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraStepHeader(
              pageLabel: ReviewSendPage.pageLabel,
              step: ReviewSendPage.step,
              total: ReviewSendPage.totalSteps,
              onBack: _sending ? null : () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.target,
    required this.terms,
    required this.config,
    required this.recipientName,
    required this.recipientPhotoUrl,
    required this.storeName,
    required this.sending,
    required this.failedMessage,
    required this.onSend,
    required this.onPickUsageRights,
    required this.onEdit,
    required this.needsInstagram,
    required this.onConnect,
  });

  final ProposalTarget target;
  final OfferTerms terms;
  final ServerConfig config;
  final String recipientName;
  final String? recipientPhotoUrl;
  final String storeName;
  final bool sending;
  final String? failedMessage;
  final VoidCallback onSend;
  final VoidCallback onPickUsageRights;
  final VoidCallback onEdit;

  /// 인스타그램 연동이 필요해 보내기 버튼 자리에 `연동하기`가 보인다.
  final bool needsInstagram;
  final VoidCallback onConnect;

  bool get _recruit => target is RecruitTarget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reward = terms.reward;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final burden = reward.maxCashBurden;
    final rows = <_Row>[
      _Row(label: ReviewSendPage.recruitLabel, value: storeName),
      _Row(
        label: ReviewSendPage.deliverableLabel,
        value: deliverableLine(terms.format, terms.pieces),
      ),
      _Row(
        label: ReviewSendPage.benefitLabel,
        value: reward.voucher == null
            ? ReviewSendPage.none
            : benefitLine(reward.voucher!),
      ),
      _Row(
        label: ReviewSendPage.fixedCashLabel,
        value: reward.fixedCash == 0
            ? ReviewSendPage.none
            : fixedCashLabel(reward.fixedCash),
      ),
      _Row(
        label: ReviewSendPage.viewPayLabel,
        value: reward.viewPay == null
            ? ReviewSendPage.none
            : viewPayLine(reward.viewPay!),
      ),
      _Row(
        label: ReviewSendPage.usageRightsLabel,
        value: usageRightsLabel(terms.usageRights),
        onTap: onPickUsageRights,
      ),
      _Row(
        label: ReviewSendPage.burdenLabel,
        value: wonExact(burden),
        bold: true,
      ),
    ];
    final notice = _recruit
        ? ReviewSendPage.openCallNotice
        : ReviewSendPage.notice(
            version: target.versionNumber,
            maxCashBurden: burden,
            feeRate: config.feeRates.storeOffer,
            showFee: target is! CounterTarget,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Semantics(
                    header: true,
                    child: Text(
                      ReviewSendPage.title,
                      style: CoraTextStyles.title.copyWith(color: c.text),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _RecipientCard(
                    name: recipientName,
                    photoUrl: recipientPhotoUrl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(CoraRadius.panel),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++)
                            _RowView(row: rows[i], first: i == 0),
                        ],
                      ),
                    ),
                  ),
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
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (needsInstagram)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      ReviewSendPage.needsInstagram,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(color: c.text),
                    ),
                  ),
                ),
              if (failedMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      failedMessage!,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(color: c.text),
                    ),
                  ),
                ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    flex: 5,
                    child: CoraSecondaryButton(
                      label: ReviewSendPage.editLabel,
                      onPressed: sending ? null : onEdit,
                      tone: CoraSecondaryTone.subtle,
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: CoraPrimaryButton(
                      label: needsInstagram
                          ? ReviewSendPage.connectInstagram
                          : (_recruit
                                ? ReviewSendPage.publishLabel
                                : ReviewSendPage.sendLabel),
                      onPressed: sending
                          ? null
                          : (needsInstagram ? onConnect : onSend),
                      look: CoraPrimaryButtonLook.accent,
                      fitLabel: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 받는 사람 카드: 모서리 22, `surface` 바탕, 안쪽 14, 사진 52 원 + 라벨 12 / 이름 16/700.
/// 캔버스 오른쪽의 고른 작품 사진은 쓸 자료가 없어 그리지 않는다.
class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.panel),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: 12,
            children: [
              ExcludeSemantics(
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: 52,
                    child: CoraNetworkPhoto(
                      url: photoUrl,
                      alignment: const Alignment(0, -0.5),
                      background: c.creatorPhotoPlaceholder,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReviewSendPage.recipientLabel,
                      style: CoraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                    Text(
                      name,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row {
  const _Row({
    required this.label,
    required this.value,
    this.onTap,
    this.bold = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool bold;
}

/// 줄 하나: 위아래 10, 첫 줄 말고는 위에 1px `line`. 왼쪽 13 보조색, 오른쪽 15/500(마지막 줄 700).
class _RowView extends StatelessWidget {
  const _RowView({required this.row, required this.first});

  final _Row row;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 12,
          children: [
            Text(
              row.label,
              style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
            ),
            Flexible(
              child: Text(
                row.value,
                textAlign: TextAlign.right,
                style: CoraTextStyles.body.copyWith(
                  height: 1.448,
                  fontWeight: row.bold ? FontWeight.w700 : FontWeight.w500,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final onTap = row.onTap;
    return Semantics(
      container: true,
      button: onTap != null,
      label: '${row.label}, ${row.value}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: onTap == null
            ? content
            : CoraPressable(onTap: onTap, child: content),
      ),
    );
  }
}

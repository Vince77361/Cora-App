import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../domain/brand_usage_rights.dart';
import '../../domain/negotiation_repository.dart';
import '../../domain/terms_version.dart';
import '../terms_text.dart';
import 'agreement_view_model.dart';
import 'terms_view_model.dart';

/// 수정 제안에서 고르는 값. 돈과 혜택(제품 제공, 제작비, 성과 추가)과 제작물의 형식은 F1의 보상 편집 위젯이 맡은
/// 초안([OfferTerms])에 있고, 나머지는 여기에 있다.
class TermsProposalState {
  const TermsProposalState({
    required this.base,
    required this.target,
    required this.title,
    required this.startDate,
    required this.pieces,
    required this.revisionScope,
    required this.usageRights,
    required this.payoutDays,
    this.busy = false,
    this.error,
  });

  /// 고치는 바탕인 최신 판본.
  final TermsVersion base;

  /// F1의 보상 편집 위젯과 초안을 묶는 대상. 바탕 판본의 값에서 시작한다.
  final BrandProposalTarget target;
  final String title;
  final DateTime startDate;
  final int pieces;
  final RevisionScope revisionScope;
  final BrandUsageRights usageRights;
  final int payoutDays;
  final bool busy;
  final String? error;

  TermsProposalState copyWith({
    String? title,
    DateTime? startDate,
    int? pieces,
    RevisionScope? revisionScope,
    BrandUsageRights? usageRights,
    int? payoutDays,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => TermsProposalState(
    base: base,
    target: target,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    pieces: pieces ?? this.pieces,
    revisionScope: revisionScope ?? this.revisionScope,
    usageRights: usageRights ?? this.usageRights,
    payoutDays: payoutDays ?? this.payoutDays,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );

  /// 보낼 조건 전체(아홉 항목). 돈과 혜택과 형식은 [draft]에서 가져온다. 안 바꾼 성과 추가도 담는다(서버는
  /// `performance: null`을 `끄기`로 읽는다).
  TermsChanges changesWith(OfferTerms draft) => TermsChanges(
    title: title.trim(),
    fee: draft.reward.fixedCash,
    productProvided: draft.reward.voucher != null,
    performance: draft.reward.viewPay,
    startDate: startDate,
    format: draft.format,
    pieces: pieces,
    revisionScope: revisionScope,
    usageRights: usageRights,
    payoutDays: payoutDays,
  );

  /// 바탕 판본과 달라진 항목(고정 순서). 하나도 없으면 보낼 수 없다.
  List<TermsField> changedWith(OfferTerms draft) {
    final b = base;
    final c = changesWith(draft);
    return [
      if (c.title != b.title) TermsField.title,
      if (c.fee != b.fee) TermsField.fee,
      if (c.performance != b.performance) TermsField.performance,
      if (c.startDate != b.startDate) TermsField.startDate,
      if (c.format != b.format || c.pieces != b.pieces) TermsField.deliverable,
      if (c.productProvided != b.productProvided) TermsField.product,
      if (c.revisionScope != b.revisionScope) TermsField.revision,
      if (c.usageRights != b.usageRights) TermsField.usage,
      if (c.payoutDays != b.payoutDays) TermsField.payout,
    ];
  }
}

/// 조건 수정 제안 화면(협업마다 하나). 바탕 판본은 서버의 최신 판본을 한 번 읽어 고정한다: 고치는 동안 상대가 새
/// 판본을 내면 보낼 때 409 `STALE_VERSION`이 나고, 고치던 값은 버린다.
final termsProposalViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<TermsProposalViewModel, TermsProposalState, String>(
      TermsProposalViewModel.new,
      retry: (_, _) => null,
    );

class TermsProposalViewModel extends AsyncNotifier<TermsProposalState> {
  TermsProposalViewModel(this.collaborationId);

  final String collaborationId;

  NegotiationRepository get _repo => ref.read(negotiationRepositoryProvider);

  @override
  Future<TermsProposalState> build() async {
    ref.watch(currentUserIdProvider);
    final latest = await _repo.fetchLatest(collaborationId);
    final t = latest.terms;
    return TermsProposalState(
      base: t,
      target: BrandProposalTarget(
        recipientName: '',
        recruitLine: '',
        format: t.format,
        pieces: t.pieces,
        usageRights: t.usageRights,
        startFee: t.fee,
        startProductProvided: t.productProvided,
        startPerformance: t.performance,
        nextVersion: t.version + 1,
      ),
      title: t.title,
      startDate: t.startDate,
      pieces: t.pieces,
      revisionScope: t.revisionScope,
      usageRights: t.usageRights,
      payoutDays: t.payoutDays,
    );
  }

  void _update(TermsProposalState Function(TermsProposalState) change) {
    final current = state.value;
    if (current == null || current.busy) return;
    state = AsyncData(change(current).copyWith(clearError: true));
  }

  void setTitle(String title) => _update((s) => s.copyWith(title: title));
  void setStartDate(DateTime date) => _update(
    (s) => s.copyWith(startDate: DateTime(date.year, date.month, date.day)),
  );
  void setPieces(int pieces) => _update((s) => s.copyWith(pieces: pieces));
  void setRevision(RevisionScope scope) =>
      _update((s) => s.copyWith(revisionScope: scope));
  void setUsage(BrandUsageRights rights) =>
      _update((s) => s.copyWith(usageRights: rights));
  void setPayoutDays(int days) => _update((s) => s.copyWith(payoutDays: days));

  /// `제안 보내기`. [draft]는 F1 위젯이 든 초안이다. 성공하면 [TermsProposalSent]를, 상대가 먼저 새 판본을 냈으면
  /// [TermsProposalStale]을 돌려준다. 그 밖의 실패는 화면에 보일 문구를 [TermsProposalState.error]에 남기고
  /// [TermsProposalFailed]를 돌려준다.
  Future<TermsProposalOutcome> send(OfferTerms draft) async {
    final current = state.value;
    if (current == null || current.busy) return const TermsProposalFailed();
    if (current.changedWith(draft).isEmpty) return const TermsProposalFailed();
    state = AsyncData(current.copyWith(busy: true, clearError: true));
    try {
      final made = await _repo.propose(
        collaborationId,
        current.base.version,
        current.changesWith(draft),
      );
      if (!ref.mounted) return TermsProposalSent(made.version);
      // 12·06·협업 목록이 새 판본을 다시 읽게 한다.
      ref.invalidate(agreementViewModelProvider(collaborationId));
      ref.invalidate(termsViewModelProvider(collaborationId));
      return TermsProposalSent(made.version);
    } on NegotiationStale {
      if (!ref.mounted) return const TermsProposalStale();
      ref.invalidate(agreementViewModelProvider(collaborationId));
      ref.invalidate(termsViewModelProvider(collaborationId));
      return const TermsProposalStale();
    } catch (error) {
      if (!ref.mounted) return const TermsProposalFailed();
      final message = error is NegotiationRejected ? error.message : null;
      state = AsyncData(
        current.copyWith(
          busy: false,
          error: (message == null || message.trim().isEmpty)
              ? AgreementTexts.sendFailed
              : message,
        ),
      );
      return const TermsProposalFailed();
    }
  }
}

/// [TermsProposalViewModel.send]의 결과.
sealed class TermsProposalOutcome {
  const TermsProposalOutcome();
}

/// 새 판본이 만들어졌다([version]은 새 판본 번호).
final class TermsProposalSent extends TermsProposalOutcome {
  const TermsProposalSent(this.version);

  final int version;
}

/// 상대가 먼저 새 판본을 냈다(409 `STALE_VERSION`). 고치던 값은 버리고 12를 새로 읽는다.
final class TermsProposalStale extends TermsProposalOutcome {
  const TermsProposalStale();
}

/// 보내지 못했다. 문구는 [TermsProposalState.error]에 있다.
final class TermsProposalFailed extends TermsProposalOutcome {
  const TermsProposalFailed();
}

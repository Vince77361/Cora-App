import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../store_home/presentation/viewmodels/store_home_view_model.dart';
import '../../domain/offer_version.dart';
import '../../domain/proposal.dart';
import '../../domain/proposal_repository.dart';
import 'proposals_view_model.dart';

/// 서버 문구가 없을 때 화면이 보이는 실패 문구(캔버스에 없다).
const proposalActionFailed = '처리하지 못했어요. 다시 시도해 주세요.';
const proposalAlreadyHandled = '이미 처리된 제안이에요.';
const proposalReplyFailed = '제안을 보내지 못했어요. 다시 시도해 주세요.';

class ProposalDetailState {
  const ProposalDetailState({
    required this.detail,
    this.contractStage,
    this.busy = false,
    this.notice,
    this.staleVersion,
    this.accepted = false,
    this.acceptedCollaborationId,
  });

  final ProposalDetail detail;

  /// 합의한 제안의 협업 단계. 사장님이 결제 전인지(`오퍼 취소`가 보이는지) 가른다. 합의 전이거나 못 읽었으면 null이다.
  final CollaborationStage? contractStage;

  /// 수락하거나 끝내는 요청을 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 방금 한 일이 실패했을 때 버튼 위에 보일 문구.
  final String? notice;

  /// 수락하려던 판본이 최신이 아니었다. 값은 최신 판본 번호다.
  final int? staleVersion;

  /// 크리에이터가 방금 수락했다: `수락했어요.` 안내를 보여 주는 중.
  final bool accepted;
  final String? acceptedCollaborationId;

  ProposalDetailState copyWith({
    ProposalDetail? detail,
    CollaborationStage? contractStage,
    bool? busy,
    String? notice,
    bool clearNotice = false,
    int? staleVersion,
    bool clearStaleVersion = false,
    bool? accepted,
    String? acceptedCollaborationId,
  }) => ProposalDetailState(
    detail: detail ?? this.detail,
    contractStage: contractStage ?? this.contractStage,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : (notice ?? this.notice),
    staleVersion: clearStaleVersion
        ? null
        : (staleVersion ?? this.staleVersion),
    accepted: accepted ?? this.accepted,
    acceptedCollaborationId:
        acceptedCollaborationId ?? this.acceptedCollaborationId,
  );
}

/// 제안 상세(offerId마다 하나). 수락하고 끝내고 새 판본을 낸다. 바꾼 뒤에는 제안함 목록도 새로 읽는다.
final proposalDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProposalDetailViewModel, ProposalDetailState, String>(
      ProposalDetailViewModel.new,
      retry: (_, _) => null,
    );

class ProposalDetailViewModel extends AsyncNotifier<ProposalDetailState> {
  ProposalDetailViewModel(this._offerId);

  final String _offerId;

  ProposalRepository get _repo => ref.read(proposalRepositoryProvider);

  @override
  Future<ProposalDetailState> build() async {
    ref.watch(currentUserIdProvider);
    final detail = await _repo.fetchDetail(_offerId);
    return ProposalDetailState(
      detail: detail,
      contractStage: await _stageOf(detail),
    );
  }

  /// 제안이 바뀌면 제안함 목록과 사장님 홈의 보낸 오퍼 줄도 낡는다. 홈은 무효화하면 처음 탭으로 돌아가서, 살아 있을
  /// 때만 보던 탭을 지키는 새로 읽기를 부른다(아직 만들어지지 않았으면 다음에 열릴 때 새로 읽는다).
  void _invalidateLists() {
    ref.invalidate(proposalsViewModelProvider);
    if (ref.read(storeHomeViewModelProvider.exists)) {
      unawaited(ref.read(storeHomeViewModelProvider.notifier).refresh());
    }
  }

  /// 합의한 제안은 협업의 단계를 읽는다. 못 읽으면 null(결제 전인지 모른다).
  Future<CollaborationStage?> _stageOf(ProposalDetail detail) async {
    final id = detail.collaborationId;
    if (!detail.ended ||
        detail.endKind != ProposalEndKind.agreed ||
        id == null) {
      return null;
    }
    try {
      return (await ref.read(collaborationRepositoryProvider).fetch(id)).stage;
    } on Object {
      return null;
    }
  }

  /// 서버 값으로 다시 읽는다. 실패하면 보던 내용을 그대로 둔다.
  Future<void> reload() async {
    final current = state.value;
    try {
      final detail = await _repo.fetchDetail(_offerId);
      final stage = await _stageOf(detail);
      if (!ref.mounted) return;
      final base = state.value ?? current;
      state = AsyncData(
        base == null
            ? ProposalDetailState(detail: detail, contractStage: stage)
            : ProposalDetailState(
                detail: detail,
                contractStage: stage,
                busy: base.busy,
                notice: base.notice,
                staleVersion: base.staleVersion,
                accepted: base.accepted,
                acceptedCollaborationId: base.acceptedCollaborationId,
              ),
      );
    } on ProposalFailure {
      // 보던 값 유지.
    }
  }

  /// `판본 n 보기`: 이전 판본 안내를 걷고 최신 판본을 읽는다.
  Future<void> viewLatestVersion() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearStaleVersion: true));
    await reload();
  }

  /// 지금 보고 있는 판본을 수락한다. 만들어진 협업의 id를 돌려주고(없을 수 있다), 실패하면 null이다.
  /// 크리에이터는 [ProposalDetailState.accepted]로 안내를 보인다. 사장님은 돌려받은 id로 결제 화면에 간다.
  Future<String?> accept() async {
    final current = state.value;
    if (current == null || current.busy) return null;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      final collaborationId = await _repo.accept(
        _offerId,
        current.detail.latest.number,
      );
      if (!ref.mounted) return collaborationId;
      _invalidateLists();
      final accepted = current.detail.myParty == ProposalParty.creator;
      state = AsyncData(
        (state.value ?? current).copyWith(
          busy: false,
          accepted: accepted,
          acceptedCollaborationId: collaborationId,
        ),
      );
      if (!accepted) await reload();
      return collaborationId;
    } on ProposalFailure catch (failure) {
      if (!ref.mounted) return null;
      final stale = failure.staleVersion;
      if (stale != null) {
        state = AsyncData(
          (state.value ?? current).copyWith(busy: false, staleVersion: stale),
        );
        return null;
      }
      state = AsyncData(
        (state.value ?? current).copyWith(
          busy: false,
          notice:
              failure.message ??
              (failure.conflict
                  ? proposalAlreadyHandled
                  : proposalActionFailed),
        ),
      );
      if (failure.conflict) await reload();
      return null;
    }
  }

  /// 사유를 골라 제안을 끝낸다. 끝나면 상세와 제안함 목록을 새로 읽는다.
  Future<void> end(EndReason reason) async {
    final current = state.value;
    if (current == null || current.busy) return;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      await _repo.end(_offerId, reason);
    } on ProposalFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(
        (state.value ?? current).copyWith(
          busy: false,
          notice:
              failure.message ??
              (failure.conflict
                  ? proposalAlreadyHandled
                  : proposalActionFailed),
        ),
      );
      if (failure.conflict) await reload();
      return;
    }
    if (!ref.mounted) return;
    _invalidateLists();
    state = AsyncData((state.value ?? current).copyWith(busy: false));
    await reload();
  }

  /// 수락했지만 결제 전인 오퍼를 취소한다(사장님). 시트가 실패 문구를 보이도록 [ProposalFailure]를 그대로 던진다.
  /// 끝나면 상세와 목록을 새로 읽는다.
  Future<void> cancelOffer() async {
    await _repo.cancel(_offerId);
    if (!ref.mounted) return;
    _invalidateLists();
    await reload();
  }

  /// 사장님이 고쳐서 다시 보내는 다음 판본. F2의 마지막 버튼이 부른다. 실패하면 F2가 이유에 맞는 문구를 보이도록
  /// [ProposalSendFailure]로 알린다.
  Future<void> reply(OfferTerms terms) async {
    try {
      await _repo.reply(_offerId, terms);
    } on ProposalFailure catch (failure) {
      throw ProposalSendFailure(
        failure.message ??
            (failure.conflict ? proposalAlreadyHandled : proposalReplyFailed),
      );
    }
    if (ref.mounted) _invalidateLists();
  }
}

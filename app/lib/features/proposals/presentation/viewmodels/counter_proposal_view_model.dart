import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import '../../domain/counter_proposal_repository.dart';
import '../../domain/creator_series.dart';

/// F6의 보낼 대상과 D2에서 가져온 한 줄. 같은 값이면 같은 화면이다.
class CounterProposalArgs {
  const CounterProposalArgs({required this.target, this.pitch = ''});

  final CounterTarget target;

  /// D2에서 쓴 `이 가게라면 이렇게 찍겠다` 한 줄. 아이디어의 처음 값이 된다.
  final String pitch;

  @override
  bool operator ==(Object other) =>
      other is CounterProposalArgs &&
      other.target == target &&
      other.pitch == pitch;

  @override
  int get hashCode => Object.hash(target, pitch);
}

/// 서버 문구가 없을 때 F2가 보이는 실패 문구.
const counterProposalSendFailed = '제안을 보내지 못했어요. 다시 시도해 주세요.';

/// F6에서 쓰는 값: 내 시리즈, 고른 시리즈, 아이디어, 표현 원칙. 희망 보상과 형식은
/// [proposalDraftViewModelProvider]가 들고 있다(F1·F2와 같은 값을 본다).
class CounterProposalState {
  const CounterProposalState({
    required this.series,
    this.seriesId,
    this.idea = '',
    this.principles = const [],
  });

  final List<CreatorSeries> series;

  /// 고른 시리즈. 시리즈가 없으면 null이고, 이때는 형식을 따로 고른다.
  final String? seriesId;
  final String idea;
  final List<String> principles;

  CreatorSeries? get selectedSeries {
    for (final s in series) {
      if (s.id == seriesId) return s;
    }
    return null;
  }

  CounterProposalState copyWith({
    List<CreatorSeries>? series,
    String? seriesId,
    String? idea,
    List<String>? principles,
  }) => CounterProposalState(
    series: series ?? this.series,
    seriesId: seriesId ?? this.seriesId,
    idea: idea ?? this.idea,
    principles: principles ?? this.principles,
  );
}

final counterProposalViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<
      CounterProposalViewModel,
      CounterProposalState,
      CounterProposalArgs
    >(CounterProposalViewModel.new, retry: (_, _) => null);

class CounterProposalViewModel extends AsyncNotifier<CounterProposalState> {
  CounterProposalViewModel(this._args);

  final CounterProposalArgs _args;

  ProposalDraftViewModel get _draft =>
      ref.read(proposalDraftViewModelProvider(_args.target).notifier);

  CounterProposalRepository get _repo =>
      ref.read(counterProposalRepositoryProvider);

  @override
  Future<CounterProposalState> build() async {
    final series = await _repo.fetchSeries();
    final idea = _args.pitch.trim();
    // 시리즈가 있으면 첫 시리즈가 골라져 있고(캔버스), 그 형식이 이 제안의 형식이다. 고른 조건은 F1·F2와
    // 같은 초안이 들고 있으므로 초안이 만들어진 뒤에 형식을 맞춘다.
    if (series.isNotEmpty) {
      await ref.read(proposalDraftViewModelProvider(_args.target).future);
      if (ref.mounted) _draft.setFormat(series.first.format);
    }
    return CounterProposalState(
      series: series,
      seriesId: series.isEmpty ? null : series.first.id,
      idea: idea.length > CounterProposal.ideaMaxLength
          ? idea.substring(0, CounterProposal.ideaMaxLength)
          : idea,
    );
  }

  /// 시리즈를 고르면 그 형식으로 바뀐다.
  void selectSeries(CreatorSeries series) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(seriesId: series.id));
    _draft.setFormat(series.format);
  }

  void setIdea(String idea) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(idea: idea));
  }

  void setPrinciples(List<String> principles) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(principles: principles));
  }

  /// 시리즈를 만들고 그 시리즈를 고른다. 실패하면 [CounterProposalFailure]를 그대로 던진다(시트가 보인다).
  Future<void> addSeries({
    required String name,
    required ContentFormat format,
    String? note,
  }) async {
    final created = await _repo.addSeries(
      name: name,
      format: format,
      note: note,
    );
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(current.copyWith(series: [...current.series, created]));
    selectSeries(created);
  }

  /// F2의 마지막 버튼이 부른다. [terms]는 F1·F2가 고른 조건이다. 실패하면 F2가 이유에 맞는 문구를 보이도록
  /// [ProposalSendFailure]로 알린다.
  Future<void> send(OfferTerms terms) async {
    final current = state.value;
    if (current == null) return;
    final proposal = CounterProposal(
      terms: terms,
      seriesId: current.seriesId,
      idea: current.idea,
      principles: current.principles,
    );
    final target = _args.target;
    try {
      final storeId = target.storeId;
      if (storeId != null) {
        await _repo.sendToStore(storeId, proposal);
      } else {
        await _repo.sendVersion(target.offerId!, proposal);
      }
    } on CounterProposalFailure catch (failure) {
      throw ProposalSendFailure(failure.message ?? counterProposalSendFailed);
    }
  }
}

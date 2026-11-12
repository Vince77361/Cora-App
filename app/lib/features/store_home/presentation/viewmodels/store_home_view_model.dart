import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../domain/applicant.dart';
import '../../domain/sent_offer.dart';
import '../../domain/store_home_repository.dart';
import '../../domain/store_home_summary.dart';

/// 목록 탭.
enum StoreHomeTab { applicants, sentOffers }

class StoreHomeState {
  const StoreHomeState({
    required this.summary,
    required this.applicants,
    required this.sentOffers,
    this.collaborations = const {},
    this.tab = StoreHomeTab.applicants,
  });

  final StoreHomeSummary summary;
  final List<Applicant> applicants;
  final List<SentOffer> sentOffers;

  /// 보낸 오퍼에 걸린 협업을 id로 찾는 표. 줄이 결제 뒤의 단계를 말하는 데 쓴다. 협업을 읽지 못했으면
  /// 비어 있고, 줄은 단계 없이 오퍼의 상태만 보인다.
  final Map<String, Collaboration> collaborations;
  final StoreHomeTab tab;

  StoreHomeState copyWith({
    StoreHomeSummary? summary,
    List<Applicant>? applicants,
    List<SentOffer>? sentOffers,
    Map<String, Collaboration>? collaborations,
    StoreHomeTab? tab,
  }) => StoreHomeState(
    summary: summary ?? this.summary,
    applicants: applicants ?? this.applicants,
    sentOffers: sentOffers ?? this.sentOffers,
    collaborations: collaborations ?? this.collaborations,
    tab: tab ?? this.tab,
  );
}

/// 사장님 홈(A9)의 숫자, 지원자·보낸 오퍼 목록, 고른 탭. 홈 위에 쌓이는 오퍼 보내기(A5)도 이것으로
/// 오퍼를 보낸다. 오퍼를 보내거나 취소하면 숫자와 두 목록을 서버에서 다시 읽는다.
///
/// 로그인한 사용자가 바뀌면 다시 불러온다(고른 탭도 처음으로). Riverpod의 자동 재시도는 끈다.
final storeHomeViewModelProvider =
    AsyncNotifierProvider<StoreHomeViewModel, StoreHomeState>(
      StoreHomeViewModel.new,
      retry: (_, _) => null,
    );

class StoreHomeViewModel extends AsyncNotifier<StoreHomeState> {
  @override
  Future<StoreHomeState> build() async {
    ref.watch(currentUserIdProvider);
    return _load(StoreHomeTab.applicants);
  }

  StoreHomeRepository get _repo => ref.read(storeHomeRepositoryProvider);

  Future<StoreHomeState> _load(StoreHomeTab tab) async {
    // 레코드의 `.wait`는 실패를 ParallelWaitError로 감싸서 화면이 원래 예외를 알 수 없다.
    final results = await Future.wait<Object>([
      _repo.fetchSummary(),
      _repo.fetchApplicants(),
      _repo.fetchSentOffers(),
    ]);
    final sentOffers = results[2] as List<SentOffer>;
    return StoreHomeState(
      summary: results[0] as StoreHomeSummary,
      applicants: results[1] as List<Applicant>,
      sentOffers: sentOffers,
      collaborations: await _loadCollaborations(sentOffers),
      tab: tab,
    );
  }

  /// 협업이 걸린 보낸 오퍼가 있을 때만 내 협업(진행 중과 끝난 것)을 읽어 id로 묶는다. 못 읽어도 홈은
  /// 그대로 뜨고 줄이 오퍼의 상태만 보인다.
  Future<Map<String, Collaboration>> _loadCollaborations(
    List<SentOffer> sentOffers,
  ) async {
    if (sentOffers.every((o) => o.collaborationId == null)) return const {};
    try {
      final repo = ref.read(collaborationRepositoryProvider);
      final lists = await Future.wait([repo.fetchActive(), repo.fetchDone()]);
      return {
        for (final list in lists)
          for (final c in list) c.id: c,
      };
    } catch (_) {
      return const {};
    }
  }

  void selectTab(StoreHomeTab tab) {
    final current = state.value;
    if (current == null || current.tab == tab) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  /// 아래로 당겨 새로 고친다. 실패하면 보던 내용을 그대로 둔다(화면이 빈 오류로 바뀌지 않게).
  Future<void> refresh() async {
    final tab = state.value?.tab ?? StoreHomeTab.applicants;
    try {
      final fresh = await _load(tab);
      if (!ref.mounted) return;
      // 새로 읽는 사이 탭을 바꿨을 수 있어서 지금 탭을 우선한다.
      state = AsyncData(fresh.copyWith(tab: state.value?.tab ?? tab));
    } on StoreHomeFailure {
      // 보던 값 유지.
    }
  }

  /// [creatorId]에게 [terms]로 오퍼를 보낸다. 성공하면 보낸 오퍼 탭을 열고 목록을 새로 읽는다.
  /// 실패하면 [StoreHomeFailure]를 던진다.
  Future<void> sendOffer(String creatorId, OfferTermsInput terms) async {
    await _repo.sendOffer(creatorId, terms);
    await _reloadOn(StoreHomeTab.sentOffers);
  }

  /// 오퍼를 취소한다. 그사이 상태가 바뀌어 409여도 목록은 새로 읽어 둔다.
  Future<void> cancelOffer(String offerId) async {
    try {
      await _repo.cancelOffer(offerId);
    } on StoreHomeFailure catch (failure) {
      if (failure.conflict) await refresh();
      rethrow;
    }
    await refresh();
  }

  Future<void> _reloadOn(StoreHomeTab tab) async {
    // 보낸 직후에는 새 목록이 보이는 것이 먼저라 탭부터 바꾸고 읽는다. 읽기가 실패해도 보냈다는
    // 사실은 그대로라서 오류로 되돌리지 않는다.
    final current = state.value;
    if (current != null && ref.mounted) {
      state = AsyncData(current.copyWith(tab: tab));
    }
    await refresh();
  }
}

/// 사장님 홈 아래쪽에 잠깐 보이는 안내(예: `오퍼를 보냈어요.`). 홈이 보여 주고 스스로 지운다.
final storeHomeNoticeProvider = NotifierProvider<StoreHomeNotice, String?>(
  StoreHomeNotice.new,
);

class StoreHomeNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

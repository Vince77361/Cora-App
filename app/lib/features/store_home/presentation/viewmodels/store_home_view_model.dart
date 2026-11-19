import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../domain/applicant.dart';
import '../../domain/sent_offer.dart';
import '../../domain/store_home_repository.dart';
import '../../domain/store_home_summary.dart';

class StoreHomeState {
  const StoreHomeState({
    required this.summary,
    required this.applicants,
    required this.sentOffers,
  });

  final StoreHomeSummary summary;
  final List<Applicant> applicants;

  /// 홈은 보여 주지 않지만 오퍼 보내기와 제안 상세가 결제까지 남은 날을 여기서 찾는다.
  final List<SentOffer> sentOffers;
}

/// 사장님 홈의 `새 지원` 숫자와 지원자·보낸 오퍼 목록. 지원자 화면과 홈 위에 쌓이는 오퍼 보내기(A5)도 이것으로
/// 읽고 오퍼를 보낸다. 오퍼를 보내면 숫자와 두 목록을 서버에서 다시 읽는다(보낸 오퍼의 취소는 제안 상세가 한다).
///
/// 로그인한 사용자가 바뀌면 다시 불러온다. Riverpod의 자동 재시도는 끈다.
final storeHomeViewModelProvider =
    AsyncNotifierProvider<StoreHomeViewModel, StoreHomeState>(
      StoreHomeViewModel.new,
      retry: (_, _) => null,
    );

class StoreHomeViewModel extends AsyncNotifier<StoreHomeState> {
  @override
  Future<StoreHomeState> build() async {
    ref.watch(currentUserIdProvider);
    return _load();
  }

  StoreHomeRepository get _repo => ref.read(storeHomeRepositoryProvider);

  Future<StoreHomeState> _load() async {
    // 레코드의 `.wait`는 실패를 ParallelWaitError로 감싸서 화면이 원래 예외를 알 수 없다.
    final results = await Future.wait<Object>([
      _repo.fetchSummary(),
      _repo.fetchApplicants(),
      _repo.fetchSentOffers(),
    ]);
    return StoreHomeState(
      summary: results[0] as StoreHomeSummary,
      applicants: results[1] as List<Applicant>,
      sentOffers: results[2] as List<SentOffer>,
    );
  }

  /// 아래로 당겨 새로 고친다. 실패하면 보던 내용을 그대로 둔다(화면이 빈 오류로 바뀌지 않게).
  Future<void> refresh() async {
    try {
      final fresh = await _load();
      if (!ref.mounted) return;
      state = AsyncData(fresh);
    } on StoreHomeFailure {
      // 보던 값 유지.
    }
  }

  /// [creatorId]에게 [terms]로 오퍼를 보낸다. 성공하면 숫자와 목록을 새로 읽는다. 읽기가 실패해도 보냈다는
  /// 사실은 그대로라서 오류로 되돌리지 않는다. 실패하면 [StoreHomeFailure]를 던진다.
  Future<void> sendOffer(String creatorId, OfferTerms terms) async {
    await _repo.sendOffer(creatorId, terms);
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

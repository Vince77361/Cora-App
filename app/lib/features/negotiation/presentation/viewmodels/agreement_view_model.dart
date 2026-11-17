import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/domain/realtime_connection.dart';
import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_view_model.dart';
import '../../../offer_terms/domain/offer_terms.dart' show ContentFormat;
import '../../domain/negotiation_repository.dart';
import '../../domain/terms_version.dart';
import '../terms_text.dart';
import 'brand_collaborations_view_model.dart';
import 'terms_view_model.dart';

/// 12가 그리는 것: 협업(내 쪽, 진행 단계)과 조건 판본 목록·합의 상태.
class AgreementState {
  const AgreementState({
    required this.collaboration,
    required this.history,
    required this.needsInstagram,
    this.busy = false,
    this.notice,
    this.staleVersion,
    this.reloadFailed = false,
  });

  final Collaboration collaboration;
  final TermsHistory history;

  /// 내가 크리에이터이고, 성과 추가가 켜진 릴스·카드뉴스 판본을 아직 확인하지 않았고, 인스타그램이 연동돼 있지 않다.
  final bool needsInstagram;

  /// 수락을 서버에 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 화면에 보일 안내(서버 문구 또는 일반 실패 문구).
  final String? notice;

  /// 수락하려는 사이 상대가 더 새 판본을 냈다. 값은 최신 판본 번호이고, 있으면 12는 F8 옛 판본 상태를 보인다.
  final int? staleVersion;

  /// 옛 판본에서 `판본 N 보기`로 다시 읽으려다 실패했다.
  final bool reloadFailed;

  bool get isBrand => collaboration.role == CollaborationRole.commissioner;

  /// 내가 판본을 낼 때의 쪽.
  TermsProposer get myProposer =>
      isBrand ? TermsProposer.brand : TermsProposer.creator;

  TermsVersion get latest => history.latest;

  bool get myConfirmed =>
      isBrand ? latest.brandConfirmed : latest.creatorConfirmed;

  bool get agreed => history.agreement == TermsAgreement.agreed;

  /// 계약이 체결됐다(진행 단계가 계약 뒤).
  bool get contracted => (collaboration.brandProgress?.doneCount ?? 0) >= 3;

  /// 협의가 끝났다(그만뒀거나 진행 표에 없는 단계).
  bool get ended => collaboration.brandProgress == null;

  /// 계약 전이라 확인하고 고치고 그만둘 수 있는 단계다.
  bool get preContract => !contracted && !ended;

  /// 상대의 이름표(`브랜드` / `크리에이터`).
  String get counterpartRoleName =>
      isBrand ? AgreementTexts.creator : AgreementTexts.brand;

  /// 판본 [version]을 내가 냈다.
  bool proposedByMe(TermsVersion version) => version.proposedBy == myProposer;

  AgreementState copyWith({
    Collaboration? collaboration,
    TermsHistory? history,
    bool? needsInstagram,
    bool? busy,
    String? notice,
    bool clearNotice = false,
    int? staleVersion,
    bool clearStale = false,
    bool? reloadFailed,
  }) => AgreementState(
    collaboration: collaboration ?? this.collaboration,
    history: history ?? this.history,
    needsInstagram: needsInstagram ?? this.needsInstagram,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : (notice ?? this.notice),
    staleVersion: clearStale ? null : (staleVersion ?? this.staleVersion),
    reloadFailed: reloadFailed ?? this.reloadFailed,
  );
}

/// 협업 하나의 조건 합의(12). 협업마다 하나 만들고 화면을 떠나면 버린다. Riverpod의 자동 재시도는 끈다
/// (읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final agreementViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<AgreementViewModel, AgreementState, String>(
      AgreementViewModel.new,
      retry: (_, _) => null,
    );

class AgreementViewModel extends AsyncNotifier<AgreementState> {
  AgreementViewModel(this.collaborationId);

  final String collaborationId;

  NegotiationRepository get _repo => ref.read(negotiationRepositoryProvider);

  @override
  Future<AgreementState> build() async {
    ref.watch(currentUserIdProvider);
    // 대화방과 같은 실시간 연결을 듣는다. 상대가 새 판본을 내거나 확인하거나 계약하면 이 협업의 방이 `조건`·`계약`·`상태`로
    // 바뀌었다고 알려 오고, 그때 조용히 다시 읽는다. 끊겼다 붙었을 때도 놓친 것을 다시 읽는다.
    final connection = ref.watch(realtimeConnectionProvider);
    final events = connection.events.listen(_onEvent);
    final reconnected = connection.reconnected.listen((_) => _refreshQuietly());
    ref.onDispose(() {
      events.cancel();
      reconnected.cancel();
    });
    return _load();
  }

  void _onEvent(RealtimeEvent event) {
    if (event is! ConversationUpdated) return;
    if (event.reason == ConversationUpdateReason.read) return;
    final roomId = state.value?.collaboration.conversationId;
    if (roomId == null || roomId != event.conversationId) return;
    _refreshQuietly();
  }

  /// 화면을 그대로 두고 새로 읽는다. 읽는 중이거나 옛 판본 화면이 떠 있으면 건드리지 않고, 못 읽어도 안내를 띄우지
  /// 않는다(다음 알림이나 사용자의 동작이 다시 읽는다).
  Future<void> _refreshQuietly() async {
    final current = state.value;
    if (current == null || current.busy || current.staleVersion != null) return;
    try {
      final fresh = await _load();
      if (!ref.mounted) return;
      final now = state.value;
      if (now == null || now.busy || now.staleVersion != null) return;
      state = AsyncData(fresh.copyWith(notice: now.notice));
    } catch (_) {
      // 조용히 넘긴다.
    }
  }

  Future<AgreementState> _load() async {
    final results = await Future.wait<Object>([
      ref.read(collaborationRepositoryProvider).fetch(collaborationId),
      _repo.fetchHistory(collaborationId),
    ]);
    final collaboration = results[0] as Collaboration;
    final history = results[1] as TermsHistory;
    final latest = history.latest;
    final isCreator = collaboration.role == CollaborationRole.creator;
    // 연동 여부는 06이 읽는 `needsInstagram`이 알려 준다(판본 목록에는 없다). 연동이 필요한 경우에만 읽는다.
    var needsInstagram = false;
    if (isCreator &&
        !latest.creatorConfirmed &&
        latest.performance != null &&
        latest.format != ContentFormat.blog &&
        latest.format != ContentFormat.shorts) {
      needsInstagram = (await _repo.fetchLatest(
        collaborationId,
      )).needsInstagram;
    }
    return AgreementState(
      collaboration: collaboration,
      history: history,
      needsInstagram: needsInstagram,
    );
  }

  /// 다시 읽는다(옛 판본에서 `판본 N 보기`, 인스타그램을 연동하고 돌아온 뒤). 읽는 동안 화면은 그대로 두고, 못
  /// 읽으면 안내만 띄운다.
  Future<void> reload() async {
    final current = state.value;
    try {
      final fresh = await _load();
      if (!ref.mounted) return;
      state = AsyncData(fresh);
    } catch (_) {
      if (!ref.mounted || current == null) return;
      state = AsyncData(
        current.copyWith(
          busy: false,
          notice: AgreementTexts.actionFailed,
          reloadFailed: current.staleVersion != null,
        ),
      );
    }
  }

  /// `이 버전 수락`. 지금 화면의 판본 번호와 함께 보내고, 성공하면 다시 읽는다. 성공하면 true.
  Future<bool> confirm() async {
    final current = state.value;
    if (current == null || current.busy) return false;
    final version = current.latest.version;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      await _repo.confirm(collaborationId, version);
    } on NegotiationStale catch (stale) {
      if (!ref.mounted) return false;
      // 서버가 최신 번호를 안 알려 주면 다시 읽어 그 번호를 쓴다.
      var latest = stale.latestVersion;
      if (latest == null) {
        try {
          latest = (await _repo.fetchHistory(collaborationId)).latest.version;
        } catch (_) {
          latest = null;
        }
        if (!ref.mounted) return false;
      }
      state = AsyncData(
        current.copyWith(busy: false, staleVersion: latest ?? version + 1),
      );
      return false;
    } catch (error) {
      if (!ref.mounted) return false;
      final message = error is NegotiationRejected ? error.message : null;
      state = AsyncData(
        current.copyWith(
          busy: false,
          notice: (message == null || message.trim().isEmpty)
              ? AgreementTexts.actionFailed
              : message,
        ),
      );
      return false;
    }
    if (!ref.mounted) return true;
    _refreshOthers();
    await reload();
    return true;
  }

  /// `협의 그만두기`. 성공하면 null, 서버가 문구와 함께 거절하면 그 문구, 그 밖의 실패는 일반 문구를 돌려준다.
  /// 이유는 서버에만 남고 상대에게는 알리지 않는다.
  Future<String?> drop(DropReason reason) async {
    try {
      await _repo.drop(collaborationId, reason);
    } on NegotiationRejected catch (rejected) {
      return rejected.message ?? AgreementTexts.actionFailed;
    } on NegotiationFailure {
      return AgreementTexts.actionFailed;
    }
    if (!ref.mounted) return null;
    _refreshOthers();
    await reload();
    return null;
  }

  /// 07·06·협업 목록이 새 상태를 다시 읽게 한다.
  void _refreshOthers() {
    ref.invalidate(collaborationViewModelProvider(collaborationId));
    ref.invalidate(collaborationListViewModelProvider);
    ref.invalidate(brandCollaborationsViewModelProvider);
    ref.invalidate(termsViewModelProvider(collaborationId));
  }
}

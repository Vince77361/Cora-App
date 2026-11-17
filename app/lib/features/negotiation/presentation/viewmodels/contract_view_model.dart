import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../chat/domain/realtime_connection.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_view_model.dart';
import '../../../payment/domain/payment_repository.dart';
import '../../../payment/presentation/checkout_launcher.dart';
import '../../../payment/presentation/viewmodels/payment_view_model.dart'
    show paymentPollingProvider;
import '../../domain/contract.dart';
import '../../domain/negotiation_repository.dart';
import '../contract_text.dart';
import 'agreement_view_model.dart';
import 'brand_collaborations_view_model.dart';
import 'terms_view_model.dart';

/// 서버에는 `voidedNotice`의 읽음 표시가 없어서(새 동의가 생길 때까지 계속 참), 앱이 이미 보여 준 띠를 계약·판본마다
/// 기억한다. 앱을 끄면 사라진다(다시 보여도 해롭지 않은 안내라 저장소는 쓰지 않는다).
final voidedNoticesSeenProvider =
    NotifierProvider<VoidedNoticesSeen, Set<String>>(VoidedNoticesSeen.new);

class VoidedNoticesSeen extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void markSeen(String key) => state = {...state, key};
}

/// 계약에서 지금 내가 할 수 있는 것.
enum ContractMode {
  /// 합의 전 미리 보기. 확인란이 꺼져 있다.
  preview,

  /// 내가 동의할 차례다.
  consentable,

  /// 내가 동의했거나(크리에이터) 상대의 동의를 기다린다(브랜드).
  waiting,

  /// 체결됐다.
  concluded,
}

/// 동의를 서버에 보내는 동안의 단계.
enum ContractPhase {
  idle,

  /// 동의를 보내고 결제창을 여는 중. 창이 떠 있는 동안도 여기다.
  submitting,

  /// 결제창이 닫혔고 서버에 결제 상태를 묻는 중.
  checking,
}

class ContractState {
  const ContractState({
    required this.contract,
    required this.collaboration,
    required this.checked,
    this.method = PaymentMethod.card,
    this.phase = ContractPhase.idle,
    this.notice,
    this.staleVersion,
    this.showVoidedNotice = false,
    this.confirmingPaymentId,
  });

  final Contract contract;

  /// 내 쪽(역할)과 상대 사진을 알려 준다. 계약 응답에는 둘 다 없다.
  final Collaboration collaboration;

  /// 확인란 세 개의 상태(서버 문구와 같은 순서).
  final List<bool> checked;
  final PaymentMethod method;
  final ContractPhase phase;

  /// 화면에 보일 안내(서버 문구, 결제 실패, 일반 실패).
  final String? notice;

  /// 동의하려는 사이 새 판본이 나왔다. 값은 최신 판본 번호이고, 있으면 F8 옛 판본 상태를 보인다.
  final int? staleVersion;

  /// `조건이 바뀌어 동의가 취소됐어요` 띠를 이 화면에서 보인다.
  final bool showVoidedNotice;

  /// 결제창을 닫은 뒤 확인 시간 안에 결과를 받지 못한 결제. 있으면 결제가 아직 처리 중일 수 있어서 새 결제창을 열지 않고
  /// `다시 확인`만 할 수 있다(돈이 두 번 나가지 않게).
  final String? confirmingPaymentId;

  bool get isBrand => collaboration.role == CollaborationRole.commissioner;
  bool get busy => phase != ContractPhase.idle;
  bool get confirming => confirmingPaymentId != null;

  ContractMode get mode {
    final c = contract;
    if (c.concluded) return ContractMode.concluded;
    if (c.terms == null || c.status == ContractStatus.notReady) {
      return ContractMode.preview;
    }
    return switch ((isBrand, c.status)) {
      (false, ContractStatus.awaitingCreator) => ContractMode.consentable,
      (true, ContractStatus.awaitingBrand) ||
      (true, ContractStatus.paying) => ContractMode.consentable,
      _ => ContractMode.waiting,
    };
  }

  bool get allChecked => checked.isNotEmpty && checked.every((on) => on);

  /// 브랜드가 동의하기 전의 결제 상자를 보인다(견적이 있을 때).
  bool get showPayment => isBrand && mode == ContractMode.consentable;

  ContractState copyWith({
    Contract? contract,
    List<bool>? checked,
    PaymentMethod? method,
    ContractPhase? phase,
    String? notice,
    bool clearNotice = false,
    int? staleVersion,
    bool? showVoidedNotice,
    String? confirmingPaymentId,
    bool clearConfirming = false,
  }) => ContractState(
    contract: contract ?? this.contract,
    collaboration: collaboration,
    checked: checked ?? this.checked,
    method: method ?? this.method,
    phase: phase ?? this.phase,
    notice: clearNotice ? null : (notice ?? this.notice),
    staleVersion: staleVersion ?? this.staleVersion,
    showVoidedNotice: showVoidedNotice ?? this.showVoidedNotice,
    confirmingPaymentId: clearConfirming
        ? null
        : (confirmingPaymentId ?? this.confirmingPaymentId),
  );
}

/// 협업 하나의 계약(D4). 협업마다 하나 만들고 화면을 떠나면 버린다. Riverpod의 자동 재시도는 끈다(읽기 실패는
/// 화면의 "다시 시도"가 다시 부른다).
final contractViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ContractViewModel, ContractState, String>(
      ContractViewModel.new,
      retry: (_, _) => null,
    );

class ContractViewModel extends AsyncNotifier<ContractState> {
  ContractViewModel(this.collaborationId);

  final String collaborationId;

  NegotiationRepository get _repo => ref.read(negotiationRepositoryProvider);

  @override
  Future<ContractState> build() async {
    ref.watch(currentUserIdProvider);
    // 12와 같은 실시간 연결을 듣는다. 상대가 동의하거나 새 판본을 내면 이 협업의 방이 `계약`·`조건`으로 바뀌었다고 알려
    // 오고, 그때 조용히 다시 읽는다. 끊겼다 붙었을 때도 놓친 것을 다시 읽는다.
    final connection = ref.watch(realtimeConnectionProvider);
    final events = connection.events.listen(_onEvent);
    final reconnected = connection.reconnected.listen((_) => _refreshQuietly());
    ref.onDispose(() {
      events.cancel();
      reconnected.cancel();
    });
    final results = await Future.wait<Object>([
      ref.read(collaborationRepositoryProvider).fetch(collaborationId),
      _repo.fetchContract(collaborationId),
    ]);
    final contract = results[1] as Contract;
    return ContractState(
      contract: contract,
      collaboration: results[0] as Collaboration,
      checked: _cleared(contract),
      showVoidedNotice: _firstVoidedNotice(contract),
    );
  }

  static List<bool> _cleared(Contract contract) =>
      List.filled(contract.myConsentTexts.length, false);

  String _voidedKey(Contract contract) =>
      '$collaborationId/${contract.version}';

  /// 같은 판본의 띠는 한 번만 보인다. 여기서는 본 적이 있는지만 보고, 본 것으로 적는 것은 띠를 실제로 그린 뒤
  /// [markVoidedNoticeSeen]이 한다(그리기 전에 화면이 다시 만들어져도 띠가 사라지지 않게).
  bool _firstVoidedNotice(Contract contract) =>
      contract.voidedNotice &&
      !ref.read(voidedNoticesSeenProvider).contains(_voidedKey(contract));

  /// 띠가 화면에 그려진 뒤 부른다.
  void markVoidedNoticeSeen() {
    final current = state.value;
    if (current == null || !current.showVoidedNotice) return;
    ref
        .read(voidedNoticesSeenProvider.notifier)
        .markSeen(_voidedKey(current.contract));
  }

  void _onEvent(RealtimeEvent event) {
    if (event is! ConversationUpdated) return;
    if (event.reason == ConversationUpdateReason.read) return;
    final roomId = state.value?.collaboration.conversationId;
    if (roomId == null || roomId != event.conversationId) return;
    _refreshQuietly();
  }

  /// 화면을 그대로 두고 계약만 새로 읽는다. 동의나 결제를 보내는 중이거나 옛 판본 화면이면 건드리지 않고, 못 읽어도
  /// 안내를 띄우지 않는다.
  Future<void> _refreshQuietly() async {
    final current = state.value;
    if (current == null || current.busy || current.staleVersion != null) return;
    try {
      final fresh = await _repo.fetchContract(collaborationId);
      if (!ref.mounted) return;
      final now = state.value;
      if (now == null || now.busy || now.staleVersion != null) return;
      state = AsyncData(_withContract(now, fresh));
    } catch (_) {
      // 조용히 넘긴다.
    }
  }

  /// 새로 읽은 계약을 얹는다. 확인란 문구가 달라졌으면(새 판본) 확인을 모두 비운다.
  ContractState _withContract(ContractState now, Contract fresh) {
    final same = _sameTexts(now.contract.myConsentTexts, fresh.myConsentTexts);
    return ContractState(
      contract: fresh,
      collaboration: now.collaboration,
      checked: same ? now.checked : _cleared(fresh),
      method: now.method,
      notice: now.notice,
      showVoidedNotice: now.showVoidedNotice || _firstVoidedNotice(fresh),
      confirmingPaymentId: now.confirmingPaymentId,
    );
  }

  static bool _sameTexts(List<String> a, List<String> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((e) => e);

  /// 화면을 다시 읽는다(`다시 시도`).
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  void toggle(int index) {
    final current = state.value;
    if (current == null ||
        current.busy ||
        current.confirming ||
        current.mode != ContractMode.consentable ||
        index < 0 ||
        index >= current.checked.length) {
      return;
    }
    final next = [...current.checked];
    next[index] = !next[index];
    state = AsyncData(current.copyWith(checked: next));
  }

  void selectMethod(PaymentMethod method) {
    final current = state.value;
    if (current == null ||
        current.busy ||
        current.confirming ||
        current.method == method) {
      return;
    }
    state = AsyncData(current.copyWith(method: method));
  }

  /// `동의하고 계약하기`. 크리에이터는 동의만, 브랜드는 동의하고 결제창을 열어 결과를 기다린다. 이미 보내는 중이거나
  /// 확인란을 다 확인하지 않았으면 아무것도 하지 않는다.
  Future<void> consent() async {
    final start = state.value;
    if (start == null ||
        start.busy ||
        start.confirming ||
        start.mode != ContractMode.consentable ||
        !start.allChecked) {
      return;
    }
    final version = start.contract.version;
    if (version == null) return;
    state = AsyncData(
      start.copyWith(phase: ContractPhase.submitting, clearNotice: true),
    );
    if (start.isBrand) {
      await _consentAsBrand(start, version);
    } else {
      await _consentAsCreator(start, version);
    }
  }

  Future<void> _consentAsCreator(ContractState start, int version) async {
    try {
      final contract = await _repo.consentAsCreator(
        collaborationId,
        version,
        start.contract.myConsentTexts,
      );
      if (!ref.mounted) return;
      state = AsyncData(
        ContractState(
          contract: contract,
          collaboration: start.collaboration,
          // 동의한 것이라 확인란이 모두 켜진 채로 보인다.
          checked: List.filled(contract.myConsentTexts.length, true),
          method: start.method,
        ),
      );
      _refreshOthers();
    } catch (error) {
      await _fail(start, version, error);
    }
  }

  Future<void> _consentAsBrand(ContractState start, int version) async {
    final String paymentId;
    try {
      final created = await _repo.consentAsBrand(
        collaborationId,
        version,
        start.contract.myConsentTexts,
        start.method,
      );
      paymentId = created.paymentId;
      await ref
          .read(checkoutLauncherProvider)
          .open(created.checkoutUrl, amount: start.contract.quote?.total);
    } on NegotiationFailure {
      return _stop(start, ContractTexts.startFailed, reread: true);
    } on NegotiationRejected catch (rejected) {
      return _fail(start, version, rejected);
    } on NegotiationStale catch (stale) {
      return _fail(start, version, stale);
    } catch (_) {
      // 결제창을 열지 못했다(아직 붙이지 않은 PG 주소 등). 서버는 이미 결제를 만들었을 수 있어서(계약이 `PAYING`)
      // 계약을 다시 읽어 화면을 서버와 맞춘다.
      return _stop(start, ContractTexts.startFailed, reread: true);
    }
    if (!ref.mounted) return;

    // 창을 닫았다고 결제가 끝난 것이 아니다. PG 통지는 늦게 올 수 있어서 서버에 묻는다.
    state = AsyncData(
      state.requireValue.copyWith(phase: ContractPhase.checking),
    );
    final polling = ref.read(paymentPollingProvider);
    for (var i = 0; i < polling.attempts; i++) {
      if (i > 0) await Future<void>.delayed(polling.interval);
      if (!ref.mounted) return;
      final PaymentStatus status;
      try {
        status = await ref
            .read(paymentRepositoryProvider)
            .fetchStatus(paymentId);
      } on PaymentFailure {
        // 한 번 못 읽었다고 멈추지 않는다. 다음 번에 다시 묻는다.
        continue;
      }
      if (!ref.mounted) return;
      switch (status) {
        case PaymentStatus.approved:
          return _afterApproved();
        case PaymentStatus.failed:
        case PaymentStatus.cancelled:
          return _stop(start, ContractTexts.paymentIncomplete, reread: true);
        case PaymentStatus.pending:
          break;
      }
    }
    // 확인 시간 안에 결과를 받지 못했다. 결제가 아직 처리 중일 수 있으니 다시 결제하라고 하지 않고 확인만 권한다.
    _keepConfirming(paymentId);
  }

  /// 결제 결과를 아직 모른다: 새 결제창을 막고 `다시 확인`만 남긴다.
  void _keepConfirming(String paymentId) {
    if (!ref.mounted) return;
    state = AsyncData(
      state.requireValue.copyWith(
        phase: ContractPhase.idle,
        notice: ContractTexts.paymentConfirming,
        confirmingPaymentId: paymentId,
      ),
    );
  }

  /// `다시 확인`. 결제 상태를 다시 묻고 계약도 다시 읽는다. 승인이면 체결을 확인하고, 실패·취소면 다시 결제할 수 있게
  /// 풀고, 아직 처리 중이면 그대로 둔다. 새 결제를 만들지 않는다.
  Future<void> recheckPayment() async {
    final current = state.value;
    final paymentId = current?.confirmingPaymentId;
    if (current == null || paymentId == null || current.busy) return;
    state = AsyncData(
      current.copyWith(phase: ContractPhase.checking, clearNotice: true),
    );
    final PaymentStatus status;
    try {
      status = await ref.read(paymentRepositoryProvider).fetchStatus(paymentId);
    } on PaymentFailure {
      return _keepConfirming(paymentId);
    }
    if (!ref.mounted) return;
    switch (status) {
      case PaymentStatus.approved:
        return _afterApproved();
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        state = AsyncData(
          state.requireValue.copyWith(
            phase: ContractPhase.idle,
            notice: ContractTexts.paymentIncomplete,
            clearConfirming: true,
          ),
        );
        await _refreshQuietly();
      case PaymentStatus.pending:
        _keepConfirming(paymentId);
        // 웹훅이 먼저 체결했을 수 있어서 계약도 다시 읽는다.
        try {
          final fresh = await _repo.fetchContract(collaborationId);
          if (!ref.mounted || !fresh.concluded) return;
          return _afterApproved();
        } catch (_) {
          // 못 읽어도 확인 중 화면은 그대로다.
        }
    }
  }

  /// 결제가 승인됐다. 체결은 서버가 승인과 한 트랜잭션으로 하므로 계약을 다시 읽어 `체결`을 확인한다.
  Future<void> _afterApproved() async {
    final before = state.requireValue;
    try {
      final contract = await _repo.fetchContract(collaborationId);
      if (!ref.mounted) return;
      state = AsyncData(
        ContractState(
          contract: contract,
          collaboration: before.collaboration,
          checked: contract.concluded
              ? List.filled(contract.myConsentTexts.length, true)
              : _cleared(contract),
          method: before.method,
          // 승인됐는데 체결이 아니면(그사이 조건이 바뀌어 서버가 환급했다) 완료되지 않은 것이다.
          notice: contract.concluded ? null : ContractTexts.paymentIncomplete,
          showVoidedNotice:
              before.showVoidedNotice || _firstVoidedNotice(contract),
        ),
      );
      _refreshOthers();
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(
        before.copyWith(
          phase: ContractPhase.idle,
          notice: ContractTexts.actionFailed,
        ),
      );
    }
  }

  /// 보내기를 마치고 [notice]를 띄운다. [reread]면 결제 취소 뒤 달라진 계약 상태를 조용히 다시 읽는다.
  Future<void> _stop(
    ContractState start,
    String notice, {
    bool reread = false,
  }) async {
    if (!ref.mounted) return;
    state = AsyncData(
      state.requireValue.copyWith(phase: ContractPhase.idle, notice: notice),
    );
    if (reread) await _refreshQuietly();
  }

  /// 동의가 거절됐다: 옛 판본이면 F8 상태로, 서버 문구가 있으면 그 문구로, 아니면 일반 문구로.
  Future<void> _fail(ContractState start, int version, Object error) async {
    if (!ref.mounted) return;
    if (error is NegotiationStale) {
      var latest = error.latestVersion;
      if (latest == null) {
        try {
          latest = (await _repo.fetchContract(collaborationId)).version;
        } catch (_) {
          latest = null;
        }
        if (!ref.mounted) return;
      }
      state = AsyncData(
        state.requireValue.copyWith(
          phase: ContractPhase.idle,
          staleVersion: latest ?? version + 1,
        ),
      );
      return;
    }
    final message = error is NegotiationRejected ? error.message : null;
    state = AsyncData(
      state.requireValue.copyWith(
        phase: ContractPhase.idle,
        notice: (message == null || message.trim().isEmpty)
            ? ContractTexts.actionFailed
            : message,
      ),
    );
    // 서버가 지금은 동의할 수 없다고 하면 화면이 낡았을 수 있어 다시 읽는다.
    if (error is NegotiationRejected) await _refreshQuietly();
  }

  /// 옛 판본 화면에서 12로 가기 전에 12와 06이 새 판본을 읽게 한다.
  void refreshAgreement() {
    ref.invalidate(agreementViewModelProvider(collaborationId));
    ref.invalidate(termsViewModelProvider(collaborationId));
  }

  /// 07·06·12·협업 목록이 새 상태를 다시 읽게 한다.
  void _refreshOthers() {
    ref.invalidate(collaborationViewModelProvider(collaborationId));
    ref.invalidate(collaborationListViewModelProvider);
    ref.invalidate(brandCollaborationsViewModelProvider);
    refreshAgreement();
  }
}

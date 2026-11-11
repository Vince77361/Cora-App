import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/payment_quote.dart';
import '../../domain/payment_repository.dart';
import '../checkout_launcher.dart';

/// 결제창이 닫힌 뒤 결제 상태를 묻는 간격과 횟수. 테스트가 짧게 바꿔 끼운다.
class PaymentPolling {
  const PaymentPolling({
    this.interval = const Duration(seconds: 1),
    this.attempts = 10,
  });

  final Duration interval;
  final int attempts;
}

final paymentPollingProvider = Provider<PaymentPolling>(
  (ref) => const PaymentPolling(),
);

/// 결제를 마친 결과. 화면이 홈으로 갈지 머물지 정한다.
enum PaymentOutcome {
  /// 서버가 결제 승인을 확인했다. 홈으로 간다.
  approved,

  /// 실패했거나, 묻는 횟수를 다 쓰도록 결제 중이었다. A8에 남는다. 통지가 나중에 와서 결제가
  /// 완료되면 홈에 반영된다.
  incomplete,

  /// 결제를 시작하지 못했다. [PaymentState.problem]에 이유가 있다.
  notStarted,
}

/// A8에 남는 문제 문구의 종류.
enum PaymentProblem {
  /// 결제가 완료되지 않았다(실패, 취소, 확인 시간 초과).
  incomplete,

  /// 결제할 수 있는 오퍼가 아니다(409: 기한이 지났거나 이미 결제했다).
  unavailable,

  /// 결제를 시작하지 못했다(연결 문제 등).
  startFailed,
}

enum PaymentPhase {
  /// 수단을 고르는 중.
  idle,

  /// 결제를 만들고 결제창을 여는 중. 창이 떠 있는 동안도 여기다.
  starting,

  /// 창이 닫혔고 서버에 결제 상태를 묻는 중.
  checking,
}

class PaymentState {
  const PaymentState({
    required this.quote,
    this.method = PaymentMethod.card,
    this.phase = PaymentPhase.idle,
    this.problem,
  });

  final PaymentQuote quote;
  final PaymentMethod method;
  final PaymentPhase phase;
  final PaymentProblem? problem;

  bool get busy => phase != PaymentPhase.idle;

  PaymentState copyWith({
    PaymentMethod? method,
    PaymentPhase? phase,
    PaymentProblem? problem,
    bool clearProblem = false,
  }) => PaymentState(
    quote: quote,
    method: method ?? this.method,
    phase: phase ?? this.phase,
    problem: clearProblem ? null : (problem ?? this.problem),
  );
}

/// 가게 결제(A8). 협업마다 하나 만들고 화면을 떠나면 버린다. 견적을 읽고, 수단을 고르고,
/// 결제를 시작해 결제창이 닫히면 승인될 때까지 서버에 묻는다.
///
/// Riverpod의 자동 재시도는 끈다(견적 읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final paymentViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<PaymentViewModel, PaymentState, String>(
      PaymentViewModel.new,
      retry: (_, _) => null,
    );

class PaymentViewModel extends AsyncNotifier<PaymentState> {
  PaymentViewModel(this.collaborationId);

  final String collaborationId;

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  @override
  Future<PaymentState> build() async {
    ref.watch(currentUserIdProvider);
    return PaymentState(quote: await _repo.fetchQuote(collaborationId));
  }

  void selectMethod(PaymentMethod method) {
    final current = state.value;
    if (current == null || current.busy || current.method == method) return;
    state = AsyncData(current.copyWith(method: method));
  }

  /// 결제를 시작한다. 결제창이 닫히면 [PaymentPolling]만큼 상태를 묻고, 결과를 돌려준다.
  /// 이미 진행 중이면 아무것도 하지 않고 null.
  Future<PaymentOutcome?> pay() async {
    final start = state.value;
    if (start == null || start.busy) return null;
    state = AsyncData(
      start.copyWith(phase: PaymentPhase.starting, clearProblem: true),
    );

    final String paymentId;
    try {
      final created = await _repo.create(collaborationId, start.method);
      paymentId = created.paymentId;
      await ref
          .read(checkoutLauncherProvider)
          .open(created.checkoutUrl, amount: start.quote.total);
    } on PaymentFailure catch (failure) {
      return _stop(
        failure.conflict
            ? PaymentProblem.unavailable
            : PaymentProblem.startFailed,
      );
    } catch (_) {
      // 결제창을 열지 못했다(아직 붙이지 않은 PG 주소 등).
      return _stop(PaymentProblem.startFailed);
    }
    if (!ref.mounted) return null;

    // 창을 닫았다고 결제가 끝난 것이 아니다. PG 통지는 늦게 올 수 있어서 서버에 묻는다.
    state = AsyncData(
      state.requireValue.copyWith(phase: PaymentPhase.checking),
    );
    final polling = ref.read(paymentPollingProvider);
    for (var i = 0; i < polling.attempts; i++) {
      if (i > 0) await Future<void>.delayed(polling.interval);
      if (!ref.mounted) return null;
      final PaymentStatus status;
      try {
        status = await _repo.fetchStatus(paymentId);
      } on PaymentFailure {
        // 한 번 못 읽었다고 멈추지 않는다. 다음 번에 다시 묻는다.
        continue;
      }
      if (!ref.mounted) return null;
      switch (status) {
        case PaymentStatus.approved:
          state = AsyncData(
            state.requireValue.copyWith(phase: PaymentPhase.idle),
          );
          return PaymentOutcome.approved;
        case PaymentStatus.failed:
        case PaymentStatus.cancelled:
          return _stop(PaymentProblem.incomplete);
        case PaymentStatus.pending:
          break;
      }
    }
    return _stop(PaymentProblem.incomplete);
  }

  PaymentOutcome? _stop(PaymentProblem problem) {
    if (!ref.mounted) return null;
    state = AsyncData(
      state.requireValue.copyWith(phase: PaymentPhase.idle, problem: problem),
    );
    return problem == PaymentProblem.incomplete
        ? PaymentOutcome.incomplete
        : PaymentOutcome.notStarted;
  }
}

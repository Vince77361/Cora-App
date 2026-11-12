import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_view_model.dart';
import '../../domain/payout_account.dart';
import '../../domain/payout_account_repository.dart';

/// 일반 실패 문구. 서버가 문구를 보내면(4xx) 그것을 쓴다.
const saveFailedMessage = '계좌를 등록하지 못했어요. 잠시 뒤 다시 시도해 주세요.';

class PayoutAccountState {
  const PayoutAccountState({
    required this.account,
    required this.banks,
    this.editing = false,
    this.busy = false,
    this.error,
  });

  /// 등록한 계좌. 없으면 null이라 등록 칸을 보인다.
  final PayoutAccount? account;
  final List<Bank> banks;

  /// 등록한 계좌가 있어도 `바꾸기`를 눌러 칸을 다시 연 상태.
  final bool editing;
  final bool busy;
  final String? error;

  /// 등록 칸을 보일지(계좌가 없거나 바꾸는 중).
  bool get showForm => account == null || editing;

  PayoutAccountState copyWith({
    PayoutAccount? account,
    bool? editing,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => PayoutAccountState(
    account: account ?? this.account,
    banks: banks,
    editing: editing ?? this.editing,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );
}

/// 지급받을 계좌 화면. 계좌와 은행 목록을 읽고, 등록하면 서버가 보류된 지급을 이어 보낸다.
/// Riverpod의 자동 재시도는 끈다(읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final payoutAccountViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      PayoutAccountViewModel,
      PayoutAccountState
    >(PayoutAccountViewModel.new, retry: (_, _) => null);

class PayoutAccountViewModel extends AsyncNotifier<PayoutAccountState> {
  PayoutAccountRepository get _repo =>
      ref.read(payoutAccountRepositoryProvider);

  @override
  Future<PayoutAccountState> build() async {
    ref.watch(currentUserIdProvider);
    final results = await Future.wait<Object?>([_repo.fetch(), _repo.banks()]);
    return PayoutAccountState(
      account: results[0] as PayoutAccount?,
      banks: results[1]! as List<Bank>,
    );
  }

  void startEdit() {
    final current = state.value;
    if (current == null || current.busy) return;
    state = AsyncData(current.copyWith(editing: true, clearError: true));
  }

  /// 등록한다. 성공하면 true. 실패하면 이유가 [PayoutAccountState.error]에 남고 칸은 그대로다.
  Future<bool> save({
    required String bankCode,
    required String accountNumber,
    required String holderName,
  }) async {
    final current = state.value;
    if (current == null || current.busy) return false;
    state = AsyncData(current.copyWith(busy: true, clearError: true));
    try {
      final saved = await _repo.save(
        bankCode: bankCode,
        accountNumber: accountNumber,
        holderName: holderName,
      );
      if (!ref.mounted) return true;
      // 서버가 계좌 없이 멈춘 지급을 이어 보내므로 협업 화면의 지급 문구가 바뀐다.
      ref.invalidate(collaborationViewModelProvider);
      ref.invalidate(collaborationListViewModelProvider);
      state = AsyncData(
        current.copyWith(account: saved, editing: false, busy: false),
      );
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final message = error is PayoutAccountFailure ? error.message : null;
      state = AsyncData(
        current.copyWith(
          busy: false,
          error: (message == null || message.trim().isEmpty)
              ? saveFailedMessage
              : message,
        ),
      );
      return false;
    }
  }
}

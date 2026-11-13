import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../../domain/trial_compare_repository.dart';
import '../../domain/trial_comparison.dart';
import '../../domain/trial_info.dart';

/// G3 지난 3개월 비교. 화면을 떠나면 버린다(다시 열면 서버에서 새로 읽는다).
final trialCompareViewModelProvider =
    AsyncNotifierProvider.autoDispose<TrialCompareViewModel, TrialComparison>(
      TrialCompareViewModel.new,
      retry: (_, _) => null,
    );

class TrialCompareViewModel extends AsyncNotifier<TrialComparison> {
  @override
  Future<TrialComparison> build() =>
      ref.read(trialCompareRepositoryProvider).fetchComparison();

  /// `나중에`: 홈의 체험단 줄을 7일 숨기고, 홈이 서버 값을 다시 읽게 한다. 실패하면 [TrialCompareFailure].
  Future<void> snooze() async {
    await ref.read(trialCompareRepositoryProvider).snooze();
    await ref.read(myStoreViewModelProvider.notifier).reload();
  }
}

/// 체험단 계약 정보 입력(저장, 지우기). 저장하거나 지우면 내 가게를 서버 값으로 다시 읽는다.
final trialInfoViewModelProvider =
    NotifierProvider.autoDispose<TrialInfoViewModel, TrialInfoFormState>(
      TrialInfoViewModel.new,
    );

class TrialInfoFormState {
  const TrialInfoFormState({this.busy = false, this.failed = false});

  final bool busy;
  final bool failed;
}

class TrialInfoViewModel extends Notifier<TrialInfoFormState> {
  @override
  TrialInfoFormState build() => const TrialInfoFormState();

  /// 저장한다. 성공하면 true.
  Future<bool> save(TrialInfo info) =>
      _run(() => ref.read(trialCompareRepositoryProvider).saveInfo(info));

  /// 저장된 계약 정보를 지운다. 성공하면 true.
  Future<bool> clear() =>
      _run(() => ref.read(trialCompareRepositoryProvider).deleteInfo());

  Future<bool> _run(Future<void> Function() call) async {
    if (state.busy) return false;
    state = const TrialInfoFormState(busy: true);
    try {
      await call();
    } on TrialCompareFailure {
      if (ref.mounted) state = const TrialInfoFormState(failed: true);
      return false;
    }
    await ref.read(myStoreViewModelProvider.notifier).reload();
    if (ref.mounted) state = const TrialInfoFormState();
    return true;
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/me.dart';
import '../../domain/me_repository.dart';
import '../../domain/me_repository_provider.dart';
import '../../domain/user_role.dart';
import 'me_view_model.dart';

/// 화면을 떠나면 선택 상태도 버린다. 그래서 "역할 다시 고르기"로 다시 열 때마다 저장된
/// 역할에서 시작한다.
final roleSelectViewModelProvider =
    AsyncNotifierProvider.autoDispose<RoleSelectViewModel, RoleSelectState>(
      RoleSelectViewModel.new,
      // 내 정보를 못 불러온 오류가 자동으로 재시도되며 로딩에 머물지 않게 한다.
      retry: (_, _) => null,
    );

/// 역할 선택 화면(A1)의 상태.
class RoleSelectState {
  const RoleSelectState({
    required this.me,
    required this.selected,
    this.saving = false,
    this.saveFailed = false,
  });

  final Me me;

  /// 지금 고른 카드. 저장하기 전까지는 화면 안의 선택일 뿐이다.
  final UserRole selected;

  /// 저장 요청이 진행 중이다.
  final bool saving;

  /// 마지막 저장이 실패했다. 선택은 그대로 남는다.
  final bool saveFailed;

  RoleSelectState copyWith({
    Me? me,
    UserRole? selected,
    bool? saving,
    bool? saveFailed,
  }) => RoleSelectState(
    me: me ?? this.me,
    selected: selected ?? this.selected,
    saving: saving ?? this.saving,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

class RoleSelectViewModel extends AsyncNotifier<RoleSelectState> {
  @override
  FutureOr<RoleSelectState> build() {
    // 내 정보가 이미 있으면 첫 프레임부터 카드를 그린다(빈 화면이 한 번 비치지 않게).
    // 내 정보가 바뀌어도(저장 직후) 이 화면은 다시 만들지 않으므로 watch가 아니라 read다.
    // AsyncData일 때만 쓴다. 다른 사용자로 바뀐 뒤 불러오기가 실패하면 AsyncError가 옛
    // 사용자의 값을 그대로 들고 있어서, `value`를 읽으면 옛 사용자의 역할이 그려진다.
    final current = ref.read(meViewModelProvider);
    if (current case AsyncData(value: final me?)) return _initial(me);
    return _waitForMe();
  }

  Future<RoleSelectState> _waitForMe() async {
    final me = await ref.read(meViewModelProvider.future);
    // 내 정보가 없다는 건 로그아웃 상태다. 이 화면은 로그인한 사람만 오므로 일어나지 않는다.
    if (me == null) throw const MeFailure();
    return _initial(me);
  }

  /// 역할이 없으면 맨 위 카드(가게)를 골라 둔다. 버튼을 바로 누를 수 있게 하려는 것이다.
  RoleSelectState _initial(Me me) =>
      RoleSelectState(me: me, selected: me.role ?? UserRole.store);

  void select(UserRole role) {
    final current = state.value;
    // 저장 중에 선택이 바뀌면 화면의 선택과 저장되는 역할이 어긋난다.
    if (current == null || current.saving) return;
    state = AsyncData(current.copyWith(selected: role, saveFailed: false));
  }

  /// 고른 역할을 저장한다. 실패하면 화면에 남아 선택을 유지하고 [RoleSelectState.saveFailed]가 켜진다.
  Future<void> confirm() async {
    final current = state.value;
    if (current == null || current.saving) return;
    // 이전 실패 표시는 저장을 다시 시작하면서 지운다. 아래 상태들은 이 값에서 이어 간다.
    final saving = current.copyWith(saving: true, saveFailed: false);
    state = AsyncData(saving);
    try {
      final me = await ref
          .read(meRepositoryProvider)
          .updateRole(current.selected);
      // 이 화면이 이미 사라졌으면 상태를 건드리지 않는다.
      if (!ref.mounted) return;
      ref.read(meViewModelProvider.notifier).replace(me);
      state = AsyncData(saving.copyWith(me: me, saving: false));
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(saving.copyWith(saving: false, saveFailed: true));
    }
  }
}

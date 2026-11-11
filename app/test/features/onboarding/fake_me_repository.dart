import 'dart:async';

import 'package:cora/features/onboarding/domain/me.dart';
import 'package:cora/features/onboarding/domain/me_repository.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';

/// 손으로 쓴 가짜 내 정보 저장소. 서버가 가진 역할을 흉내 내고 실패와 지연을 정한다.
class FakeMeRepository implements MeRepository {
  /// [role]이 서버에 저장된 역할이다. null이면 아직 고르지 않은 사람.
  FakeMeRepository({this.role});

  /// 서버에 저장된 역할. [updateRole]이 바꾼다.
  UserRole? role;

  /// true이면 [fetchMe]가 [MeFailure]를 던진다(서버에 닿지 않는 상황).
  bool failFetch = false;

  /// true이면 [updateRole]이 [MeFailure]를 던진다.
  bool failSave = false;

  /// 설정하면 [fetchMe]가 이 Completer가 끝날 때까지 기다린다(불러오는 중 상태 확인용).
  Completer<void>? holdFetch;

  /// 설정하면 [updateRole]이 이 Completer가 끝날 때까지 기다린다(저장 중 상태 확인용).
  Completer<void>? holdSave;

  int fetchCalls = 0;
  int updateCalls = 0;

  /// 마지막으로 저장에 성공한 역할.
  UserRole? savedRole;

  @override
  Future<Me> fetchMe() async {
    fetchCalls++;
    final hold = holdFetch;
    if (hold != null) await hold.future;
    if (failFetch) throw const MeFailure();
    return Me(id: 'user-1', role: role);
  }

  @override
  Future<Me> updateRole(UserRole next) async {
    updateCalls++;
    final hold = holdSave;
    if (hold != null) await hold.future;
    if (failSave) throw const MeFailure();
    role = next;
    savedRole = next;
    return Me(id: 'user-1', role: next);
  }
}

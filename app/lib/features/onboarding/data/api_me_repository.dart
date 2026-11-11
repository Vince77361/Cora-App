import 'package:cora_api/api.dart' as api;

import '../domain/me.dart';
import '../domain/me_repository.dart';
import '../domain/user_role.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 정보를 주고받는다. 생성된 타입은 여기서
/// 도메인 타입으로 바꾸고, 이 파일 밖으로 내보내지 않는다.
class ApiMeRepository implements MeRepository {
  ApiMeRepository(api.ApiClient client) : _users = api.UsersApi(client);

  final api.UsersApi _users;

  @override
  Future<Me> fetchMe() => _guard(_users.getMe);

  @override
  Future<Me> updateRole(UserRole role) =>
      _guard(() => _users.updateMyRole(api.UpdateRoleDto(role: _toWire(role))));

  /// 어떤 실패든 [MeFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  Future<Me> _guard(Future<api.MeModel?> Function() call) async {
    try {
      final model = await call();
      // 생성 코드는 본문이 비면 null을 준다. 내 정보가 없는 성공은 없으므로 실패로 본다.
      if (model == null) throw const MeFailure();
      return Me(id: model.id, role: _fromWire(model.role));
    } on MeFailure {
      rethrow;
    } catch (_) {
      throw const MeFailure();
    }
  }

  static api.UserRole _toWire(UserRole role) => switch (role) {
    UserRole.store => api.UserRole.STORE,
    UserRole.brand => api.UserRole.BRAND,
    UserRole.creator => api.UserRole.CREATOR,
  };

  static UserRole? _fromWire(api.UserRole? role) => switch (role) {
    null => null,
    api.UserRole.STORE => UserRole.store,
    api.UserRole.BRAND => UserRole.brand,
    api.UserRole.CREATOR => UserRole.creator,
  };
}

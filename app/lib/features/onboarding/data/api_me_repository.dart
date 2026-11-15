import 'dart:convert';

import 'package:cora_api/api.dart' as api;
import 'package:http/http.dart' show Response;

import '../domain/me.dart';
import '../domain/me_repository.dart';
import '../domain/user_role.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 정보를 주고받는다. 생성된 타입은 여기서
/// 도메인 타입으로 바꾸고, 이 파일 밖으로 내보내지 않는다.
class ApiMeRepository implements MeRepository {
  ApiMeRepository(api.ApiClient client) : _users = api.UsersApi(client);

  final api.UsersApi _users;

  @override
  Future<Me> fetchMe() => _guard(_users.getMeWithHttpInfo);

  @override
  Future<Me> updateRole(UserRole role) => _guard(
    () =>
        _users.updateMyRoleWithHttpInfo(api.UpdateRoleDto(role: _toWire(role))),
  );

  /// 어떤 실패든 [MeFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  Future<Me> _guard(Future<Response> Function() call) async {
    try {
      final response = await call();
      if (response.statusCode >= 400 || response.statusCode == 204) {
        throw const MeFailure();
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      // 본문이 비거나 모양이 다르면 내 정보가 없는 성공은 없으므로 실패로 본다.
      if (json is! Map<String, dynamic>) throw const MeFailure();
      final id = json['id'];
      if (id is! String) throw const MeFailure();
      return Me(id: id, role: _fromWire(json['role']));
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

  /// 서버의 역할 값을 읽는다. null은 "아직 역할이 없음"이다. 모르는 값은 null로 뭉개지 않고
  /// 실패로 던진다: 생성된 enum은 모르는 값을 null로 바꿔 버려서, 그대로 쓰면 앱이 역할 선택
  /// 화면(A1)으로 보내 서버의 역할을 덮어쓸 수 있다. 그래서 생성 모델 대신 원본 JSON을 읽는다.
  static UserRole? _fromWire(Object? role) => switch (role) {
    null => null,
    'STORE' => UserRole.store,
    'BRAND' => UserRole.brand,
    'CREATOR' => UserRole.creator,
    _ => throw const MeFailure(),
  };
}

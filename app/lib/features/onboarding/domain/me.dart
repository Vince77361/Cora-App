import 'user_role.dart';

/// 로그인한 사용자 자신의 정보. 불변 값이다.
class Me {
  const Me({required this.id, required this.role});

  final String id;

  /// 아직 역할을 고르지 않은 사용자는 null이다.
  final UserRole? role;

  @override
  bool operator ==(Object other) =>
      other is Me && other.id == id && other.role == role;

  @override
  int get hashCode => Object.hash(id, role);

  @override
  String toString() => 'Me(id: $id, role: $role)';
}

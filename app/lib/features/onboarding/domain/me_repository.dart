import 'me.dart';
import 'user_role.dart';

/// 내 정보를 서버와 주고받는 포트.
abstract class MeRepository {
  /// 내 정보를 가져온다. 처음 부르면 서버가 사용자 행을 만든다.
  Future<Me> fetchMe();

  /// 내 역할을 저장하고 바뀐 내 정보를 돌려준다.
  Future<Me> updateRole(UserRole role);
}

/// 내 정보를 서버와 주고받지 못했다. 서버 응답의 메시지는 담지 않는다. 화면은 정해진
/// 문구를 보여 주면 되고, 서버 문구가 로그에 남을 이유가 없다.
class MeFailure implements Exception {
  const MeFailure();

  @override
  String toString() => 'MeFailure';
}

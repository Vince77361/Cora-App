import 'package:cora/features/instagram_connect/domain/instagram_connection.dart';
import 'package:cora/features/instagram_connect/domain/instagram_repository.dart';

/// 손으로 쓴 가짜 인스타그램 저장소. 가짜 연결은 입력한 아이디를 그대로 연결한다(서버의 가짜 어댑터처럼).
class FakeInstagramRepository implements InstagramRepository {
  FakeInstagramRepository({this.connection});

  InstagramConnection? connection;

  /// 설정하면 연결이 이 오류로 실패한다.
  InstagramFailure? failComplete;
  bool failFetch = false;

  /// 연결이 끝난 직후 부른다(서버가 오퍼의 `needsInstagram`을 바꾸는 것을 흉내 내려고).
  void Function()? onConnected;

  int beginCalls = 0;
  final completed = <String>[];

  @override
  Future<InstagramConnection?> fetch() async {
    if (failFetch) throw const InstagramFailure();
    return connection;
  }

  @override
  Future<String> begin() async {
    beginCalls++;
    return 'https://api.instagram.test/oauth/authorize';
  }

  @override
  Future<InstagramConnection> complete(String code) async {
    final error = failComplete;
    if (error != null) throw error;
    completed.add(code);
    connection = InstagramConnection(
      handle: code.replaceFirst('@', '').toLowerCase(),
      followers: 1200,
    );
    onConnected?.call();
    return connection!;
  }
}

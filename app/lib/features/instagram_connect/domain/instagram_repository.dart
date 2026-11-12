import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'instagram_connection.dart';

/// 인스타그램 연동을 읽고 연결하는 포트.
abstract class InstagramRepository {
  /// 연동된 계정. 없으면 null.
  Future<InstagramConnection?> fetch();

  /// 인스타그램 승인 화면 주소를 받는다(실제 연동에서 앱이 열 주소).
  Future<String> begin();

  /// 승인 뒤 받은 [code]로 연결을 마친다. 개발용 가짜 연동에서는 [code]가 연결할 계정 아이디다.
  Future<InstagramConnection> complete(String code);
}

/// 서버에 닿지 못했거나 서버가 거절했다. [message]는 서버가 화면에 그대로 보이라고 보낸 문구(4xx일
/// 때만)이고, 없으면 화면이 일반 문구를 쓴다.
class InstagramFailure implements Exception {
  const InstagramFailure({this.message});

  final String? message;

  @override
  String toString() => 'InstagramFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final instagramRepositoryProvider = Provider<InstagramRepository>(
  (ref) => throw UnimplementedError(
    'instagramRepositoryProvider must be overridden',
  ),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'server_config.dart';

/// 서버 설정(범위, 수수료율)을 읽는 포트.
abstract class ServerConfigRepository {
  Future<ServerConfig> fetch();
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class ServerConfigFailure implements Exception {
  const ServerConfigFailure();

  @override
  String toString() => 'ServerConfigFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final serverConfigRepositoryProvider = Provider<ServerConfigRepository>(
  (ref) => throw UnimplementedError(
    'serverConfigRepositoryProvider must be overridden',
  ),
);

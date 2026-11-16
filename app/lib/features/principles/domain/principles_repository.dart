import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'principles.dart';

/// 내 협업 원칙을 서버와 주고받는 포트.
abstract class PrinciplesRepository {
  /// 내 협업 원칙. 아직 정하지 않았으면 null. 서버에 닿지 못하면 [PrinciplesFailure].
  Future<Principles?> fetchMine();

  /// 협업 원칙을 만들거나 통째로 바꾼다. 실패하면 [PrinciplesFailure].
  Future<Principles> save(Principles principles);
}

/// 협업 원칙을 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class PrinciplesFailure implements Exception {
  const PrinciplesFailure();

  @override
  String toString() => 'PrinciplesFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final principlesRepositoryProvider = Provider<PrinciplesRepository>(
  (ref) => throw UnimplementedError(
    'principlesRepositoryProvider must be overridden',
  ),
);

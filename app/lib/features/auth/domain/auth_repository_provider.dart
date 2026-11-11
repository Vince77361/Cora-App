import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

/// 인증 저장소. 기본값은 일부러 던진다. main.dart가 Supabase 구현으로, 테스트가 가짜로 바꿔 끼운다.
///
/// 포트 옆에 두는 이유: core(API 클라이언트)와 여러 기능이 이 포트를 쓰는데, 프레젠테이션
/// 파일에 두면 core가 한 기능의 화면 계층에 기대게 된다.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      throw UnimplementedError('authRepositoryProvider must be overridden'),
);

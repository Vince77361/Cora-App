import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository_provider.dart';
import 'auth_session.dart';

/// 로그인 세션의 변화(포트의 `watchSession`).
///
/// 포트(`authRepositoryProvider`) 옆 domain에 두는 이유: 여러 기능의 ViewModel이 "지금 누구인가"를
/// 알아야 하는데, 이 값을 한 기능의 presentation 파일에 두면 다른 기능이 그 화면 계층을
/// import하게 된다.
final authSessionProvider = StreamProvider<AuthSession?>(
  (ref) => ref.watch(authRepositoryProvider).watchSession(),
);

/// 로그인한 사용자의 ID. 로그아웃 상태(또는 아직 세션을 읽는 중)이면 null.
///
/// 사용자 ID만 고르므로 같은 사용자의 토큰 갱신에는 알리지 않는다. 사용자가 바뀔 때(로그인,
/// 로그아웃, 다른 계정)만 이 값을 보는 쪽이 다시 계산한다.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authSessionProvider.select((s) => s.value?.userId)),
);

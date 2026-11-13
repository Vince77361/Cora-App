import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/server_config.dart';
import '../../domain/server_config_repository.dart';

/// 서버 설정(범위, 수수료율). 한 번 읽어 앱이 켜져 있는 동안 들고 있고, 실패하면 화면의 다시 시도
/// 버튼이 [reload]로 다시 읽는다. 범위는 로그인과 상관없어 사용자가 바뀌어도 다시 읽지 않는다.
///
/// Riverpod의 자동 재시도는 끈다. 실패하면 재시도가 끝날 때까지 로딩으로 남아 화면이 오래 비어 있다.
final serverConfigViewModelProvider =
    AsyncNotifierProvider<ServerConfigViewModel, ServerConfig>(
      ServerConfigViewModel.new,
      retry: (_, _) => null,
    );

class ServerConfigViewModel extends AsyncNotifier<ServerConfig> {
  @override
  Future<ServerConfig> build() =>
      ref.watch(serverConfigRepositoryProvider).fetch();

  /// 실패한 읽기를 다시 한다.
  void reload() => ref.invalidateSelf();
}

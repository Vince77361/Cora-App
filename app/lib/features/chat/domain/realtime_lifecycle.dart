import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/current_user_provider.dart';
import 'realtime_connection.dart';

/// 로그인 세션에 맞춰 실시간 연결을 켜고 끈다. 세션이 생기면 [RealtimeConnection.start], 없어지면
/// [RealtimeConnection.stop]이다. 다른 계정으로 바뀌면 옛 연결을 끊고 새로 붙는다. 앱의 뿌리(`CoraApp`)가 지켜 본다.
final realtimeLifecycleProvider = Provider<void>((ref) {
  final connection = ref.watch(realtimeConnectionProvider);
  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    unawaited(_apply(connection, previous, next));
  }, fireImmediately: true);
  ref.onDispose(() => unawaited(connection.stop()));
});

Future<void> _apply(
  RealtimeConnection connection,
  String? previous,
  String? next,
) async {
  if (previous != null && previous != next) await connection.stop();
  if (next != null) await connection.start();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/instagram_connection.dart';
import '../../domain/instagram_repository.dart';

/// 서버가 문구를 보내지 않았을 때의 일반 실패 문구.
const connectFailedMessage = '연동하지 못했어요. 다시 시도해 주세요.';

/// 운영 빌드에서 승인 주소를 받았지만 앱이 그 주소를 열고 돌아오는 길은 9번 계획에서 붙인다.
/// 실패가 아니므로 실패 문구를 쓰지 않는다(캔버스에 없는 문구).
const connectSoonMessage = '인스타그램 연동은 곧 열려요.';

class InstagramConnectState {
  const InstagramConnectState({
    required this.connection,
    this.busy = false,
    this.error,
  });

  /// 연동된 계정. 없으면 null이라 `인스타그램 연동하기`를 보인다.
  final InstagramConnection? connection;
  final bool busy;
  final String? error;

  InstagramConnectState copyWith({
    InstagramConnection? connection,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => InstagramConnectState(
    connection: connection ?? this.connection,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );
}

/// 인스타그램 연동 화면과 개발용 가짜 연결 화면이 함께 쓴다. Riverpod의 자동 재시도는 끈다.
final instagramConnectViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      InstagramConnectViewModel,
      InstagramConnectState
    >(InstagramConnectViewModel.new, retry: (_, _) => null);

class InstagramConnectViewModel extends AsyncNotifier<InstagramConnectState> {
  InstagramRepository get _repo => ref.read(instagramRepositoryProvider);

  @override
  Future<InstagramConnectState> build() async {
    ref.watch(currentUserIdProvider);
    return InstagramConnectState(connection: await _repo.fetch());
  }

  /// 실제 연동: 승인 주소를 받는다. 앱이 그 주소를 열고 돌려받는 길은 9번 계획에서 붙이므로 지금은
  /// 안내만 남긴다. 주소를 받으면 true.
  Future<bool> begin() async {
    final current = state.value;
    if (current == null || current.busy) return false;
    state = AsyncData(current.copyWith(busy: true, clearError: true));
    try {
      await _repo.begin();
      if (!ref.mounted) return false;
      state = AsyncData(
        current.copyWith(busy: false, error: connectSoonMessage),
      );
      return true;
    } catch (error) {
      return _fail(current, error);
    }
  }

  /// 연결을 마친다([code]는 개발용 가짜 연동에서 계정 아이디). 성공하면 true.
  Future<bool> complete(String code) async {
    final current = state.value;
    if (current == null || current.busy) return false;
    state = AsyncData(current.copyWith(busy: true, clearError: true));
    try {
      final connection = await _repo.complete(code.trim());
      if (!ref.mounted) return true;
      state = AsyncData(current.copyWith(connection: connection, busy: false));
      return true;
    } catch (error) {
      return _fail(current, error);
    }
  }

  bool _fail(InstagramConnectState before, Object error) {
    if (!ref.mounted) return false;
    final message = error is InstagramFailure ? error.message : null;
    final latest = state.value ?? before;
    state = AsyncData(
      latest.copyWith(
        busy: false,
        error: (message == null || message.trim().isEmpty)
            ? connectFailedMessage
            : message,
      ),
    );
    return false;
  }
}

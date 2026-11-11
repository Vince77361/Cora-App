import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/me.dart';
import '../../domain/me_repository_provider.dart';

/// 로그인한 사용자의 내 정보. 앱 전체에서 하나만 두고 라우터와 역할 선택 화면이 함께 쓴다.
///
/// 첫 `GET /me`는 서버가 사용자 행을 처음 만드는 호출이라, 두 곳이 동시에 부르면 서로
/// 부딪칠 수 있다. 그래서 요청은 이 provider 하나만 보내고 나머지는 같은 결과를 기다린다.
///
/// Riverpod의 자동 재시도는 끈다. 실패하면 재시도가 끝날 때까지 로딩으로 남아 오류 화면이
/// 한참 뒤에 뜨고, 다시 시도는 사용자가 "다시 시도"로 정한다.
final meViewModelProvider = AsyncNotifierProvider<MeViewModel, Me?>(
  MeViewModel.new,
  retry: (_, _) => null,
);

class MeViewModel extends AsyncNotifier<Me?> {
  /// 로그아웃 상태면 null. 로그인한 사용자가 바뀌면(로그인·로그아웃·다른 계정) 다시 불러온다.
  /// 같은 사용자의 토큰 갱신은 사용자 ID가 그대로라 다시 부르지 않는다.
  @override
  Future<Me?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(meRepositoryProvider).fetchMe();
  }

  /// 역할을 저장한 뒤 서버가 돌려준 내 정보로 바꾼다. 다시 불러오지 않는다.
  void replace(Me me) => state = AsyncData(me);
}

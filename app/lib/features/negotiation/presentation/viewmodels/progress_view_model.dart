import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../creator_profile/domain/creator_profile_repository.dart';

/// 07 머리 아래 `{크리에이터 이름}과 {브랜드 이름}`에서 내가 크리에이터일 때의 내 활동 이름. 협업 응답에는
/// 상대(브랜드)의 이름만 있어서 내 프로필에서 읽는다. 못 읽으면 null이고 화면이 `나`로 대신한다.
final myCreatorNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    return (await ref.read(creatorProfileRepositoryProvider).fetchMine())
        ?.displayName;
  } catch (_) {
    return null;
  }
});

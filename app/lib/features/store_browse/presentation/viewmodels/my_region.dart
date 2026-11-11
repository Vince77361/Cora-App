import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../creator_profile/domain/creator_profile_repository.dart';

/// 내 활동 지역의 시·도. 가게가 다른 시·도에 있으면 사진 위에 시·도 표지를 붙이는 데 쓴다.
/// 프로필을 읽지 못하면 null이다: 표지를 못 붙일 뿐이라 화면을 막지 않는다.
Future<String?> fetchMySido(Ref ref) async {
  try {
    return (await ref.read(creatorProfileRepositoryProvider).fetchMine())
        ?.regionSido;
  } catch (_) {
    return null;
  }
}

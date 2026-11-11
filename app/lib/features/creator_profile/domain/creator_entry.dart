import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_routes.dart';
import 'creator_profile_repository.dart';

/// 크리에이터가 앱에 들어올 때 처음 보여 줄 경로. 프로필이 없으면 만들기 화면, 있으면 홈.
/// 조회에 실패하면 던진다(라우터가 역할 선택 화면의 오류와 "다시 시도"로 보낸다).
Future<String> creatorEntryPath(Ref ref) async {
  final profile = await ref.read(creatorProfileRepositoryProvider).fetchMine();
  return profile == null ? AppRoutes.creatorProfileSetup : AppRoutes.creator;
}

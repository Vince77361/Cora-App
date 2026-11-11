import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/domain/user_role.dart';
import 'app_routes.dart';

/// [role]이 앱에 들어올 때 처음 보여 줄 경로를 정한다. 로그인 직후, 앱을 다시 켰을 때, 역할을
/// 고른 직후, 그리고 자기 역할의 홈(`/store`, `/creator`)을 열 때 라우터가 부른다.
///
/// 규칙(설계 2번 계획):
/// - 가게: 가게가 없으면 `/store/onboarding/links`, 초안(`DRAFT`)이면 진행 단계에 따라
///   `/store/onboarding/page`(PAGE)·`/store/onboarding/drafts`(DRAFTS)·`/store/onboarding/terms`
///   (TERMS), 공개됐으면 `/store`.
/// - 크리에이터: 프로필이 없으면 `/creator/profile/setup`, 있으면 `/creator`.
/// - 브랜드: `/brand`.
///
/// 판단에 필요한 조회는 가게(9번 작업)·크리에이터(10번 작업)가 provider로 제공하고, 그
/// 작업이 [roleEntryResolverProvider]를 그 조회를 쓰는 구현으로 바꾼다. 라우터는 이 함수가
/// 던진 오류를 역할 선택 화면으로 보낸다.
typedef RoleEntryResolver = Future<String> Function(Ref ref, UserRole role);

/// 지금은 조회가 없으므로 가게와 크리에이터는 `준비 중이에요.` 화면으로 보낸다.
Future<String> defaultRoleEntryResolver(Ref ref, UserRole role) async =>
    switch (role) {
      UserRole.store => AppRoutes.storeComingSoon('가게 홈'),
      UserRole.creator => AppRoutes.creatorComingSoon('크리에이터 홈'),
      UserRole.brand => AppRoutes.brand,
    };

final roleEntryResolverProvider = Provider<RoleEntryResolver>(
  (ref) => defaultRoleEntryResolver,
);

/// [role]의 홈 경로. 이 경로를 열면 라우터가 [RoleEntryResolver]로 실제 진입 경로를 고른다.
String roleHomePath(UserRole role) => switch (role) {
  UserRole.store => AppRoutes.store,
  UserRole.brand => AppRoutes.brand,
  UserRole.creator => AppRoutes.creator,
};

/// [path]가 어느 역할의 화면인지. 역할 화면이 아니면 null.
UserRole? roleOwningPath(String path) {
  for (final role in UserRole.values) {
    final home = roleHomePath(role);
    if (path == home || path.startsWith('$home/')) return role;
  }
  return null;
}

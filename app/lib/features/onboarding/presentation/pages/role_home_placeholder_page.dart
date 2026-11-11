import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../auth/domain/auth_repository_provider.dart';
import '../../domain/user_role.dart';

/// 임시 화면: 역할별 홈 자리만 잡아 둔다. 가게·브랜드·크리에이터 홈을 만드는 계획이 이
/// 파일을 각각의 실제 홈으로 바꾼다. 그때까지 역할을 다시 고르거나 로그아웃할 수 있어야
/// 계정을 바꿔 가며 확인할 수 있다.
class RoleHomePlaceholderPage extends ConsumerWidget {
  const RoleHomePlaceholderPage({super.key, required this.role});

  final UserRole role;

  static String titleFor(UserRole role) => switch (role) {
    UserRole.store => '가게 홈',
    UserRole.brand => '브랜드 홈',
    UserRole.creator => '크리에이터 홈',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CoraLogo(),
                    const SizedBox(height: 36),
                    Text(
                      titleFor(role),
                      style: CoraTextStyles.title.copyWith(color: c.text),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                bottom > 32 ? bottom : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CoraPrimaryButton(
                    label: '역할 다시 고르기',
                    onPressed: () => context.go(AppRoutes.role),
                  ),
                  const SizedBox(height: 8),
                  CoraPrimaryButton(
                    label: '로그아웃',
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

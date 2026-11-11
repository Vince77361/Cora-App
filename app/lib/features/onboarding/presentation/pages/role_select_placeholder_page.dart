import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// 임시 화면: 로그인 뒤 도착하는 `/role` 자리만 잡아 둔다.
/// Task 10이 A1 역할 선택 화면(RoleSelectPage)으로 바꾸고 이 파일은 지운다.
class RoleSelectPlaceholderPage extends ConsumerWidget {
  const RoleSelectPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
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
                      '역할 선택',
                      style: CoraTextStyles.title.copyWith(color: c.text),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 32),
              child: CoraPrimaryButton(
                label: '로그아웃',
                onPressed: () =>
                    ref.read(authViewModelProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

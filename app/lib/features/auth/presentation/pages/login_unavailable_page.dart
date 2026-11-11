import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';

/// 운영 빌드의 로그인 자리. 카카오·Apple 로그인(유입 전략 계획)이 들어오기 전까지 보여 준다.
/// 운영 빌드에는 이메일 로그인이 없다.
class LoginUnavailablePage extends StatelessWidget {
  const LoginUnavailablePage({super.key});

  static const message = '로그인 준비 중이에요.';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoraLogo(),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../viewmodels/dev_login_view_model.dart';

/// 개발 환경 전용 이메일 로그인. 운영 빌드에는 없다(정식 로그인은 카카오·Apple).
///
/// 로그인에 성공하면 세션이 바뀌고 라우터가 다음 화면으로 보낸다. 이 화면은 이동하지 않는다.
class DevLoginPage extends ConsumerStatefulWidget {
  const DevLoginPage({super.key});

  static const failureMessage = '이메일이나 비밀번호를 확인해 주세요.';

  @override
  ConsumerState<DevLoginPage> createState() => _DevLoginPageState();
}

class _DevLoginPageState extends ConsumerState<DevLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  DevLoginViewModel get _vm => ref.read(devLoginViewModelProvider.notifier);

  void _signIn() =>
      _vm.signIn(email: _email.text.trim(), password: _password.text);

  void _signUp() =>
      _vm.signUp(email: _email.text.trim(), password: _password.text);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final submit = ref.watch(devLoginViewModelProvider);
    final submitting = submit.isLoading;
    final failed = submit.hasError && !submitting;
    return Scaffold(
      // 키보드가 올라오면 본문이 줄어들고, 줄어든 만큼은 스크롤로 본다.
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: CoraLogo()),
              const SizedBox(height: 36),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: '이메일'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: submitting ? null : (_) => _signIn(),
                decoration: const InputDecoration(labelText: '비밀번호'),
              ),
              if (failed) ...[
                const SizedBox(height: 12),
                // 화면이 바뀌지 않으므로 스크린 리더가 실패를 바로 읽게 한다.
                Semantics(
                  liveRegion: true,
                  child: Text(
                    DevLoginPage.failureMessage,
                    style: CoraTextStyles.body.copyWith(color: c.text),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CoraPrimaryButton(
                label: '로그인',
                onPressed: submitting ? null : _signIn,
              ),
              const SizedBox(height: 8),
              _TextAction(
                label: '개발용 계정 만들기',
                style: CoraTextStyles.bodyLarge,
                color: c.text,
                onTap: submitting ? null : _signUp,
              ),
              const SizedBox(height: 16),
              _TextAction(
                label: '모션 갤러리',
                style: CoraTextStyles.label,
                color: c.textSecondary,
                onTap: () => context.push(AppRoutes.devMotion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 채움 없는 글자 버튼. 기본 버튼 아래의 보조 동작에 쓴다. 누르는 칸은 높이 48 이상.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.style,
    required this.color,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: style.copyWith(
                color: enabled ? color : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../auth_messages.dart';
import '../viewmodels/login_view_model.dart';

/// E1 로그인(NLogin / DarkNLogin). 사진과 제목, 그리고 휴대폰 번호·카카오·네이버 버튼.
///
/// `휴대폰 번호로 시작하기`는 E2로 간다. 카카오·네이버는 이 화면에서 바로 로그인한다.
/// 성공하면 세션이 바뀌고 라우터가 화면을 옮기므로 이 화면은 이동하지 않는다.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @visibleForTesting
  static const photoKey = ValueKey<String>('LoginPage.photo');
  @visibleForTesting
  static const kakaoKey = ValueKey<String>('LoginPage.kakao');
  @visibleForTesting
  static const naverKey = ValueKey<String>('LoginPage.naver');
  @visibleForTesting
  static const termsKey = ValueKey<String>('LoginPage.terms');

  static const _photoAsset = 'assets/images/login_hero.jpg';

  // 캔버스: 사진 상자 위·좌우 12, 높이 420. 사진 아래에서 로고까지 28.
  static const _photoMargin = 12.0;
  static const _photoMaxHeight = 420.0;
  static const _photoToLogo = 28.0;

  // 캔버스에서 제목 블록과 아래 버튼 영역 사이에 남는 틈(약 7). 화면이 짧으면 사진이
  // 줄어들어도 이 틈은 남긴다.
  static const _minGapToButtons = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final submit = ref.watch(loginViewModelProvider);
    final busy = submit.isLoading;
    final failed = submit.hasError && !busy;
    final devScreens = ref.watch(appConfigProvider).devScreensEnabled;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final vm = ref.read(loginViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 위쪽은 사진 → 로고·제목. 화면이 짧으면 사진만 줄어든다(비율·자르기 위치는 그대로).
            Expanded(
              child: Column(
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _photoMargin,
                        _photoMargin,
                        _photoMargin,
                        0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _photoMaxHeight,
                        ),
                        child: const SizedBox.expand(child: _HeroPhoto()),
                      ),
                    ),
                  ),
                  const SizedBox(height: _photoToLogo),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 개발 빌드에서만 로고를 길게 누르면 모션 갤러리가 열린다. 화면 모양은
                          // 캔버스 그대로 두려고 따로 버튼을 두지 않았다.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: devScreens
                                ? () => context.push(AppRoutes.devMotion)
                                : null,
                            child: const CoraLogo.hero(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '브랜드와 크리에이터가\n콘텐츠로 만나는 곳',
                            style: CoraTextStyles.title.copyWith(color: c.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: _minGapToButtons),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CoraPrimaryButton(
                    look: CoraPrimaryButtonLook.accent,
                    label: '휴대폰 번호로 시작하기',
                    onPressed: busy
                        ? null
                        : () => context.push(AppRoutes.loginVerify),
                  ),
                  const SizedBox(height: 8),
                  _SocialButton(
                    key: kakaoKey,
                    mark: 'K',
                    label: '카카오로 계속하기',
                    onTap: busy ? null : vm.signInWithKakao,
                  ),
                  const SizedBox(height: 8),
                  _SocialButton(
                    key: naverKey,
                    mark: 'N',
                    label: '네이버로 계속하기',
                    onTap: busy ? null : vm.signInWithNaver,
                  ),
                  const SizedBox(height: 6),
                  // 실패하면 약관 줄 자리에 안내가 대신 보인다(캔버스에 없는 상태).
                  failed
                      ? Semantics(
                          liveRegion: true,
                          child: Text(
                            AuthMessages.tryLater,
                            textAlign: TextAlign.center,
                            style: CoraTextStyles.legal.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        )
                      : const _Terms(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사진 상자: 사진 + 아래 그라데이션 + 왼쪽 위 알약 + 아래 문구.
class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      key: LoginPage.photoKey,
      borderRadius: BorderRadius.circular(CoraRadius.xxl),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.photoPlaceholder),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              LoginPage._photoAsset,
              fit: BoxFit.cover,
              // CSS object-position 50% 25%.
              alignment: const Alignment(0, -0.5),
              excludeFromSemantics: true,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 220,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c.photoScrim.withValues(alpha: 0), c.photoScrim],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.photoChip,
                  borderRadius: BorderRadius.circular(CoraRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '#민의옷장기록 · 릴스 0:30',
                    style: CoraTextStyles.caption.copyWith(
                      color: c.onPhotoChip,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Text(
                '팔로워 수보다 콘텐츠로 만나요.',
                style: CoraTextStyles.photoCaption.copyWith(color: c.onPhoto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카카오·네이버 버튼. 알약 56, 동그라미 글자(K, N) + 이름.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    super.key,
    required this.mark,
    required this.label,
    required this.onTap,
  });

  final String mark;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final textColor = enabled ? c.text : c.textSecondary;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.background,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        mark,
                        style: CoraTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.buttonMedium.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 약관 문구. `이용약관`과 `개인정보 처리방침`은 밑줄 링크 모양이다.
class _Terms extends StatelessWidget {
  const _Terms();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = CoraTextStyles.legal.copyWith(color: c.textSecondary);
    final link = base.copyWith(
      color: c.text,
      decoration: TextDecoration.underline,
      decorationColor: c.text,
    );
    // E8(고객센터)가 생기면 두 링크를 거기로 연결한다. 지금은 눌러도 아무 일도 하지 않는다.
    return Text.rich(
      key: LoginPage.termsKey,
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: '계속하면 '),
          TextSpan(text: '이용약관', style: link),
          const TextSpan(text: '과 '),
          TextSpan(text: '개인정보 처리방침', style: link),
          const TextSpan(text: '에 동의하게 돼요.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

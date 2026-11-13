import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';

/// 내 가게(`/store/me`). 사장님 홈 머리의 가게 사진을 누르면 열린다. 캔버스에 없는 화면이라
/// 가게 사진·이름 머리와 줄 다섯 개를 기존 토큰으로 최소로 만들었다.
class StoreMePage extends ConsumerWidget {
  const StoreMePage({super.key});

  static const title = '내 가게';
  static const storePage = '가게 페이지';
  static const trialInfo = '체험단 계약 정보';
  static const archive = '보관함';
  static const settings = '설정';
  static const signOut = '로그아웃';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final store = ref.watch(myStoreViewModelProvider).value;
    void comingSoon(String title) => context.push(
      AppRoutes.storeComingSoon(title),
      extra: AppRoutes.stacked,
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: CoraStepHeader.rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CoraBackButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.store),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: Row(
                        spacing: 14,
                        children: [
                          SizedBox.square(
                            dimension: 64,
                            child: ClipOval(
                              child: CoraNetworkPhoto(
                                url: store?.coverPhotoUrl,
                                background: c.coverPlaceholder,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: CoraTextStyles.fieldLabel.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                                Text(
                                  store?.name ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: CoraTextStyles.heading.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: c.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Row(
                      label: storePage,
                      onTap: () => context.push(AppRoutes.storePage),
                    ),
                    _Row(
                      label: trialInfo,
                      onTap: () => context.push(AppRoutes.storeTrialInfo),
                    ),
                    _Row(label: archive, onTap: () => comingSoon(archive)),
                    _Row(label: settings, onTap: () => comingSoon(settings)),
                    _Row(
                      label: signOut,
                      onTap: () =>
                          ref.read(authViewModelProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_select_card.dart';
import '../../domain/user_role.dart';
import '../viewmodels/me_view_model.dart';
import '../viewmodels/role_select_view_model.dart';

/// A1 시작 · 역할 선택(NRole / DarkNRole). 카드 세 장 중 하나를 고르고 아래 버튼으로 저장한다.
///
/// 저장에 성공하면 그 역할의 홈으로 간다. 실패하면 이 화면에 남아 선택을 그대로 두고 안내를
/// 보여 준다. 내 정보를 불러오지 못했을 때는 화면 전체가 오류와 "다시 시도"다.
class RoleSelectPage extends ConsumerWidget {
  const RoleSelectPage({super.key});

  /// 캔버스에 없는 문구(서버에 닿지 못한 경우). 소유자 확인 전의 임시 문구다.
  static const serverUnreachable = '서버에 연결하지 못했어요.';

  /// 캔버스 A1: 위 여백 72, 로고 → 36 → 제목 → 12 → 설명 → 32 → 카드(간격 10).
  static const _top = 72.0;

  /// 카드의 그림자(아래로 20쯤 퍼진다)가 스크롤 영역 끝에서 잘리지 않게 두는 여백.
  static const _scrollBottom = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleSelectViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: state.when(
          // 내 정보를 기다리는 동안은 배경만 둔다(라우터가 불러오는 중에는 이 화면을 열지 않는다).
          loading: () => const SizedBox.expand(),
          error: (_, _) => CoraErrorView(
            message: serverUnreachable,
            // 내 정보를 다시 불러오는 동안은 첫 화면에서 기다리고, 결과에 맞는 곳(역할이 없으면
            // 여기, 있으면 홈)으로 라우터가 보낸다. 불러오기가 눈 깜짝할 새 끝나도 같은 길을
            // 지나도록 직접 첫 화면으로 간다. 이 화면의 ViewModel도 함께 비운다. 옛 화면이
            // 사라지는 동안 같은 ViewModel을 새 화면이 이어받으면 지난 오류 상태가 보인다.
            onRetry: () {
              ref.invalidate(meViewModelProvider);
              ref.invalidate(roleSelectViewModelProvider);
              context.go(AppRoutes.splash);
            },
          ),
          data: (s) => _Content(state: s),
        ),
      ),
    );
  }
}

class _Role {
  const _Role(this.role, this.overline, this.title, this.subtitle, this.button);

  final UserRole role;
  final String overline;
  final String title;
  final String subtitle;
  final String button;
}

const _roles = [
  _Role(
    UserRole.store,
    '일을 맡기는 쪽',
    '가게를 알리고 싶어요',
    '식당, 미용실, 공방 같은 동네 가게',
    '가게 링크로 시작하기',
  ),
  _Role(
    UserRole.brand,
    '일을 맡기는 쪽',
    '브랜드 제품을 알리고 싶어요',
    '쇼핑몰, 제조사, 브랜드 담당자',
    '크리에이터 둘러보기',
  ),
  _Role(
    UserRole.creator,
    '일을 하는 쪽',
    '콘텐츠를 만들고 싶어요',
    '팔로워가 적어도 누구나 시작할 수 있어요',
    '내 협업 원칙 정하기',
  ),
];

class _Content extends ConsumerWidget {
  const _Content({required this.state});

  final RoleSelectState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final vm = ref.read(roleSelectViewModelProvider.notifier);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final current = _roles.firstWhere((r) => r.role == state.selected);

    return Column(
      children: [
        // 카드 목록은 스크롤된다. 글자가 커져도 넘치지 않고, 아래 버튼은 그대로 고정이다.
        // 스크롤 영역이 버튼 위에서 끝나므로 내용이 버튼 밑에 가려지지 않는다.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: RoleSelectPage._top,
              bottom: RoleSelectPage._scrollBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CoraLogo(),
                      const SizedBox(height: 36),
                      Text(
                        '어떤 일로\n오셨나요?',
                        style: CoraTextStyles.display.copyWith(color: c.text),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.',
                        style: CoraTextStyles.body.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      for (final r in _roles)
                        CoraSelectCard(
                          overline: r.overline,
                          title: r.title,
                          subtitle: r.subtitle,
                          selected: r.role == state.selected,
                          onTap: () => vm.select(r.role),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.saveFailed)
                // 저장에 실패해도 화면을 떠나지 않는다. 버튼을 다시 누르면 다시 저장한다.
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      RoleSelectPage.serverUnreachable,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              CoraPrimaryButton(
                label: current.button,
                onPressed: state.saving ? null : () => _confirm(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    await ref.read(roleSelectViewModelProvider.notifier).confirm();
    if (!context.mounted) return;
    final after = ref.read(roleSelectViewModelProvider).value;
    // 저장에 성공했을 때만 홈으로 간다(실패하면 saveFailed가 켜져 있다).
    if (after == null || after.saveFailed || after.saving) return;
    context.go(
      AppRoutes.homeFor(after.selected),
      extra: AppRoutes.fromRoleSelect,
    );
  }
}

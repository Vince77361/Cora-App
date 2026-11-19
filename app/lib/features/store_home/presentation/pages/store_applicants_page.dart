import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_list_row.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../store_home_text.dart';
import '../viewmodels/store_home_view_model.dart';

/// 지원자 목록(`지원자 보기`). 옛 홈의 지원자 탭을 화면 하나로 뗀 것이라 줄 모양은 그대로다. 캔버스에는 없는
/// 화면이다. 줄의 `오퍼 보내기`는 그 크리에이터가 받는 사람으로 채워진 오퍼 보내기(A5)를 연다.
class StoreApplicantsPage extends ConsumerWidget {
  const StoreApplicantsPage({super.key});

  static const title = '지원자 보기';
  static const sendOffer = '오퍼 보내기';
  static const empty = '아직 지원한 크리에이터가 없어요.';
  static const emptyDescription = '가게가 공개되면 지원이 도착해요.';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '지원자를 불러오지 못했어요.';

  /// 캔버스 NStoreHome 목록 사진의 `object-position: 50% 25%`(사람 사진은 얼굴이 위쪽에 있다).
  static const _faceAlignment = Alignment(0, -0.5);

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storeHomeViewModelProvider);
    final now = ref.watch(clockProvider).now();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(title: title, onBack: () => _leave(context)),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) =>
                  value.applicants.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: CoraStateView.empty(
                            title: empty,
                            description: emptyDescription,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: ref
                              .read(storeHomeViewModelProvider.notifier)
                              .refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(8, 10, 8, 32),
                            children: [
                              for (final applicant in value.applicants)
                                CoraListRow(
                                  photoUrl: applicant.creator.photoUrl,
                                  photoAlignment: _faceAlignment,
                                  title: applicant.creator.displayName,
                                  subtitle: applicantMeta(applicant, now),
                                  actionLabel: sendOffer,
                                  actionHighlighted: true,
                                  onAction: () => context.push(
                                    AppRoutes.storeOfferNew(
                                      applicant.creator.userId,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                AsyncError() => CoraStateView.loadFailed(
                  title: loadFailed,
                  onRetry: () => ref.invalidate(storeHomeViewModelProvider),
                ),
                _ => const CoraStateView.loading(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/pages/reward_budget_page.dart';
import '../../../offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import '../../../offer_terms/presentation/widgets/format_step.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../viewmodels/my_store_view_model.dart';

/// 모집 조건(등록 마지막 단계). 형식(이 화면) → 보상·예산 설정(F1) → 보내기 전 검토(F2)를 거쳐, F2의
/// `이 조건으로 공개하기`가 조건을 저장하고 가게를 공개한다. 공개하면 사장님 홈으로 간다.
///
/// 형식 단계의 머리글은 F1·F2와 같은 `제안 만들기`다(화면에는 그리지 않고 화면 읽기 프로그램용 이름이다).
class RecruitTermsPage extends ConsumerWidget {
  const RecruitTermsPage({super.key});

  static const pageLabel = '제안 만들기';
  static const nextLabel = '다음';
  static const publishFailed = '가게를 공개하지 못했어요. 다시 시도해 주세요.';
  static const loadFailed = '모집 조건을 불러오지 못했어요.';
  static const target = RecruitTarget();

  /// 조건을 저장하고 공개한다. 공개만 실패해도 다시 누르면 저장부터 다시 하지만, 같은 값을
  /// 덮어쓰는 일이라 문제가 없다.
  Future<void> _publish(
    BuildContext context,
    WidgetRef ref,
    OfferTerms terms,
  ) async {
    final store = ref.read(myStoreViewModelProvider.notifier);
    await store.setDefaultTerms(terms);
    await store.publish();
    if (context.mounted) context.go(AppRoutes.store);
  }

  void _next(BuildContext context, WidgetRef ref) {
    Navigator.of(context, rootNavigator: true).push(
      CoraTransitions.push(
        RewardBudgetPage(
          target: target,
          failureMessage: publishFailed,
          onSend: (terms) => _publish(context, ref, terms),
        ),
      ).createRoute(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(proposalDraftViewModelProvider(target));
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final Widget body;
    if (draft.value != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: FormatStep(
                selected: draft.value!.format,
                onPick: ref
                    .read(proposalDraftViewModelProvider(target).notifier)
                    .setFormat,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            child: CoraPrimaryButton(
              label: nextLabel,
              onPressed: () => _next(context, ref),
              // 캔버스(NOffer, DarkNOffer)의 `다음`은 다크에서도 라임이다.
              look: CoraPrimaryButtonLook.accent,
            ),
          ),
        ],
      );
    } else if (draft.hasError) {
      body = CoraStateView.loadFailed(
        title: loadFailed,
        onRetry: () {
          ref.invalidate(serverConfigViewModelProvider);
          ref.invalidate(proposalDraftViewModelProvider(target));
        },
      );
    } else {
      body = const CoraStateView.loading();
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 첫 단계의 이전 버튼은 흐리고 아무 일도 하지 않는다(캔버스 NOffer).
            const CoraStepHeader(
              pageLabel: pageLabel,
              step: 1,
              total: 3,
              backDimmed: true,
              onBack: _noop,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

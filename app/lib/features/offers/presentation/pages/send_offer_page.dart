import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/widgets/offer_terms_wizard.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../../proposals/presentation/viewmodels/proposals_view_model.dart';
import '../../../store_home/domain/applicant.dart';
import '../../../store_home/domain/store_home_repository.dart';
import '../../../store_home/presentation/viewmodels/store_home_view_model.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../viewmodels/send_offer_view_model.dart';

/// A5 오퍼 보내기(NOffer / DarkNOffer). 형식 → 보상(빠른 조합) → 확인 세 단계를 가게의 모집 조건에서
/// 시작해 보여 주고, 마지막 단계의 `검토하고 보내기`가 F2를 연다. F2의 `이 조건으로 보내기`가 지원한
/// 크리에이터에게 오퍼를 보내면 사장님 홈의 `보낸 오퍼` 탭으로 돌아가 `오퍼를 보냈어요.`를 잠깐 보인다.
class SendOfferPage extends ConsumerStatefulWidget {
  const SendOfferPage({super.key, required this.creatorId});

  final String creatorId;

  static String pageLabel(String creatorName) => '$creatorName에게 오퍼';
  static const sent = '오퍼를 보냈어요.';
  static const conflict = '이미 보낸 오퍼가 있어요.';

  /// 캔버스에 없는 상태의 문구.
  static const failed = '오퍼를 보내지 못했어요. 다시 시도해 주세요.';
  static const notFound = '지원한 크리에이터를 찾지 못했어요.';

  @override
  ConsumerState<SendOfferPage> createState() => _SendOfferPageState();
}

class _SendOfferPageState extends ConsumerState<SendOfferPage> {
  /// 처음 찾은 크리에이터를 들고 있는다. 보낸 직후 홈이 새로 읽히면 지원자 목록에서 빠지는데,
  /// 그 사이 화면이 `찾지 못했어요`로 바뀌면 안 된다.
  Applicant? _applicant;

  /// F2의 마지막 버튼이 부른다. 실패하면 F2가 실패 이유에 맞는 문구를 보이도록 [ProposalSendFailure]로 알린다.
  Future<void> _send(OfferTerms terms) async {
    try {
      await ref
          .read(storeHomeViewModelProvider.notifier)
          .sendOffer(widget.creatorId, terms);
    } on StoreHomeFailure catch (failure) {
      throw ProposalSendFailure(
        failure.conflict ? SendOfferPage.conflict : SendOfferPage.failed,
      );
    }
    if (!mounted) return;
    // 보낸 오퍼는 제안함(F3)의 `상대 대기`에 모인다. 이미 읽어 둔 목록이 있으면 낡았으므로 버린다.
    ref.invalidate(proposalsViewModelProvider);
    ref.read(proposalsNoticeProvider.notifier).show(SendOfferPage.sent);
    // F1·F2가 위에 떠 있을 수 있어 제안함으로 가며 함께 닫는다.
    context.go(AppRoutes.storeProposals);
  }

  @override
  Widget build(BuildContext context) {
    _applicant ??= ref.watch(sendOfferApplicantProvider(widget.creatorId));
    final applicant = _applicant;
    final store = ref.watch(myStoreViewModelProvider).value;
    final config = ref.watch(serverConfigViewModelProvider);
    final Widget body;
    if (applicant == null || store == null || config.value == null) {
      final loading =
          ref.watch(storeHomeViewModelProvider).isLoading || config.isLoading;
      body = loading
          ? const CoraStateView.loading()
          : CoraStateView.loadFailed(
              title: SendOfferPage.notFound,
              onRetry: () {
                ref.invalidate(storeHomeViewModelProvider);
                ref.invalidate(serverConfigViewModelProvider);
              },
            );
    } else {
      final name = applicant.creator.displayName;
      body = OfferTermsWizard(
        target: NewOfferTarget(creatorId: widget.creatorId, creatorName: name),
        pageLabel: SendOfferPage.pageLabel(name),
        storeName: store.name ?? '',
        recipientPhotoUrl: applicant.creator.photoUrl,
        onSend: _send,
      );
    }
    return Scaffold(body: SafeArea(bottom: false, child: body));
  }
}

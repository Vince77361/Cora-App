import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/presentation/widgets/offer_terms_wizard.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../../store_home/domain/applicant.dart';
import '../../../store_home/domain/store_home_repository.dart';
import '../../../store_home/presentation/viewmodels/store_home_view_model.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../viewmodels/send_offer_view_model.dart';

/// A5 오퍼 보내기(NOffer / DarkNOffer). 오퍼 조건 3단계를 가게의 기본 조건에서 시작해 보여 주고,
/// 마지막 단계에서 지원한 크리에이터에게 오퍼를 보낸다. 보내면 사장님 홈의 `보낸 오퍼` 탭으로
/// 돌아가 `오퍼를 보냈어요.`를 잠깐 보인다.
class SendOfferPage extends ConsumerStatefulWidget {
  const SendOfferPage({super.key, required this.creatorId});

  final String creatorId;

  static String pageLabel(String creatorName) => '$creatorName에게 오퍼';
  static const confirmTitle = '이 오퍼를\n보낼까요?';
  static const confirmDescription = '상대가 수락하면 그때 결제해요.';
  static const submitLabel = '오퍼 보내기';
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

  String? _failure;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  Future<void> _send(OfferTerms terms) async {
    try {
      await ref
          .read(storeHomeViewModelProvider.notifier)
          .sendOffer(widget.creatorId, terms);
    } on StoreHomeFailure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure.conflict
              ? SendOfferPage.conflict
              : SendOfferPage.failed;
        });
      }
      rethrow;
    }
    if (!mounted) return;
    ref.read(storeHomeNoticeProvider.notifier).show(SendOfferPage.sent);
    _leave();
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
      final defaults = config.value!.defaultTerms;
      body = OfferTermsWizard(
        pageLabel: SendOfferPage.pageLabel(applicant.creator.displayName),
        initial: store.defaultTerms ?? defaults,
        defaults: defaults,
        storeName: store.name ?? '',
        confirmTitle: SendOfferPage.confirmTitle,
        confirmDescription: SendOfferPage.confirmDescription,
        submitLabel: SendOfferPage.submitLabel,
        failureMessage: _failure ?? SendOfferPage.failed,
        onSubmit: _send,
      );
    }
    return Scaffold(body: SafeArea(bottom: false, child: body));
  }
}

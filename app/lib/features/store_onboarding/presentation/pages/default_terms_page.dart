import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/presentation/widgets/offer_terms_wizard.dart';
import '../viewmodels/my_store_view_model.dart';

/// 기본 오퍼 조건(등록 마지막 단계). 오퍼 조건 3단계를 그대로 쓰고, 마지막에 조건을 저장한 뒤
/// 가게를 공개한다. 공개하면 사장님 홈으로 간다.
class DefaultTermsPage extends ConsumerWidget {
  const DefaultTermsPage({super.key});

  static const headerTitle = '기본 오퍼 조건';
  static const confirmTitle = '이 조건으로 가게를\n공개할까요?';
  static const confirmDescription =
      '크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.';
  static const submitLabel = '가게 공개하기';
  static const publishFailed = '가게를 공개하지 못했어요. 다시 시도해 주세요.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(myStoreViewModelProvider).value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // 진입 규칙이 가게를 이미 읽어 두었다. 읽는 동안은 배경만 둔다.
        child: store == null
            ? const SizedBox.expand()
            : OfferTermsWizard(
                headerTitle: headerTitle,
                initial: _inputOf(store.defaultTerms),
                storeName: store.name ?? '',
                confirmTitle: confirmTitle,
                confirmDescription: confirmDescription,
                submitLabel: submitLabel,
                failureMessage: publishFailed,
                onSubmit: (input) => _publish(context, ref, input),
              ),
      ),
    );
  }

  /// 조건을 저장하고 공개한다. 공개만 실패해도 다시 누르면 저장부터 다시 하지만, 같은 값을
  /// 덮어쓰는 일이라 문제가 없다.
  Future<void> _publish(
    BuildContext context,
    WidgetRef ref,
    OfferTermsInput input,
  ) async {
    final store = ref.read(myStoreViewModelProvider.notifier);
    await store.setDefaultTerms(input);
    await store.publish();
    if (context.mounted) context.go(AppRoutes.store);
  }

  /// 이미 저장한 기본 조건이 있으면 그 값에서 시작한다(DONE에서 다시 열었을 때).
  static OfferTermsInput? _inputOf(OfferTerms? terms) => terms == null
      ? null
      : OfferTermsInput(
          format: terms.format,
          rewardType: terms.rewardType,
          voucherName: terms.voucherName,
          voucherValue: terms.voucherValue,
        );
}

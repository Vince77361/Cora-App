import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../collaboration_text.dart';
import '../viewmodels/collaboration_view_model.dart';
import 'collaboration_page.dart';

/// 식사권 보여주기(캔버스에 없다). 가게 직원에게 화면을 보여 주는 용도라 가게 이름과 식사권 이름을
/// 큰 글자로, 아래에 협업 번호를 보인다.
class VoucherPage extends ConsumerWidget {
  const VoucherPage({super.key, required this.collaborationId});

  final String collaborationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collaborationViewModelProvider(collaborationId));
    void leave() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.creatorCollaboration(collaborationId));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(onBack: leave),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => _Ticket(
                  storeName: value.collaboration.counterpartName,
                  voucherName:
                      value.collaboration.terms.reward.voucher?.name ?? '',
                  shortId: value.collaboration.shortId,
                ),
                AsyncError() => CoraStateView.loadFailed(
                  title: loadFailedMessage,
                  onRetry: () => ref.invalidate(
                    collaborationViewModelProvider(collaborationId),
                  ),
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

class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.storeName,
    required this.voucherName,
    required this.shortId,
  });

  final String storeName;
  final String voucherName;
  final String shortId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.xxl),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Text(
                  storeName,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodyLarge.copyWith(
                    fontSize: 20,
                    color: c.textSecondary,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    voucherName,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.display.copyWith(
                      fontSize: 40,
                      letterSpacing: -2,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                ),
                Text(
                  CollaborationPage.voucherNumber(shortId),
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/role_entry.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../../onboarding/presentation/viewmodels/me_view_model.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_view_model.dart';
import '../wallet_text.dart';

/// E7 정산(NWallet / DarkNWallet), 크리에이터만. 큰 상자(다음 지급과 계좌), 두 칸(이번 달 받은
/// 금액, 보관 중), 내역. 맨 아래 수수료 안내 줄은 법률·세무 확인 전까지 그리지 않는다(소유자 결정).
class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  void _back(BuildContext context, WidgetRef ref) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final role = ref.read(meViewModelProvider).value?.role;
    context.go(role == null ? AppRoutes.splash : roleHomePath(role));
  }

  /// 계좌를 등록하거나 바꾸고 돌아오면 계좌 줄을 새로 읽는다.
  Future<void> _openAccount(BuildContext context, WidgetRef ref) async {
    await context.push(AppRoutes.creatorPayoutAccount);
    ref.invalidate(walletViewModelProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CoraPageHeader(
              title: WalletTexts.title,
              onBack: () => _back(context, ref),
              extent: 64,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value, isLoading: false) => _Body(
                  wallet: value,
                  onAccount: () => _openAccount(context, ref),
                ),
                AsyncError(isLoading: false) => CoraErrorView(
                  message: WalletTexts.loadFailed,
                  onRetry: () => ref.invalidate(walletViewModelProvider),
                ),
                _ => const SizedBox.expand(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.wallet, required this.onAccount});

  final Wallet wallet;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 32 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NextPayoutCard(wallet: wallet, onAccount: onAccount),
          // 위 10, 좌우 16, 간격 8.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Expanded(
                    child: _StatCard(
                      label: WalletTexts.receivedThisMonth,
                      value: wonExact(wallet.receivedThisMonth),
                    ),
                  ),
                  Expanded(
                    child: _StatCard(
                      label: WalletTexts.held,
                      value: wonExact(wallet.heldAmount),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 위 20, 좌우 20, 아래 4.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Semantics(
              header: true,
              child: Text(
                WalletTexts.history,
                style: CoraTextStyles.label.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          if (wallet.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                WalletTexts.empty,
                style: CoraTextStyles.bodySmall.copyWith(
                  color: c.textSecondary,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [for (final e in wallet.entries) _EntryRow(entry: e)],
              ),
            ),
        ],
      ),
    );
  }
}

/// 큰 상자(위 4, 좌우 16, 안쪽 20, 둥근 28). 다음 지급 예정 날짜, 금액, 구분선, 계좌 줄과 버튼.
class _NextPayoutCard extends StatelessWidget {
  const _NextPayoutCard({required this.wallet, required this.onAccount});

  final Wallet wallet;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final next = wallet.nextPayout;
    final account = wallet.account;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            next == null
                ? WalletTexts.noNextPayout
                : WalletTexts.nextPayout(next.date),
            style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            next == null ? WalletTexts.noAmount : wonExact(next.amount),
            style: CoraTextStyles.bigAmount.copyWith(color: c.text),
          ),
          const SizedBox(height: 14),
          // 구분선 위 14·아래 14(border-top 1, padding-top 14).
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Flexible(
                    child: account == null
                        ? Text(
                            WalletTexts.registerAccountPrompt,
                            style: CoraTextStyles.bodySmall.copyWith(
                              color: c.text,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              text: '${accountLabel(account)} ',
                              children: [
                                TextSpan(
                                  text: account.holderName,
                                  style: TextStyle(color: c.textSecondary),
                                ),
                              ],
                            ),
                            style: CoraTextStyles.bodySmall.copyWith(
                              color: c.text,
                            ),
                          ),
                  ),
                  _ChipButton(
                    label: account == null
                        ? WalletTexts.registerAccount
                        : WalletTexts.changeAccount,
                    onTap: onAccount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `계좌 변경`/`계좌 등록` 버튼(높이 36, 좌우 12, 알약, 13/500). 라이트·다크 모두 흰 바탕에 #17181C 글자.
class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});

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
          child: Container(
            key: const ValueKey('wallet-account-button'),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.chipAction,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              label,
              style: CoraTextStyles.label.copyWith(color: c.onChipAction),
            ),
          ),
        ),
      ),
    );
  }
}

/// 작은 상자(안쪽 14, 둥근 20). 이름표 12 보조, 값 18/700.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CoraTextStyles.amountMedium.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}

/// 내역 줄(안쪽 12, 간격 12). 왼쪽 제목 15/500과 설명 12 보조, 오른쪽 금액 15/700과 상태 12 보조.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subtitle = entrySubtitle(entry);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entryTitle(entry),
                  style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: CoraTextStyles.fieldLabel.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entryAmount(entry),
                style: CoraTextStyles.amountSmall.copyWith(color: c.text),
              ),
              Text(
                entryState(entry),
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

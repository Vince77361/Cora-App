import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../domain/payout_account.dart';
import '../viewmodels/payout_account_view_model.dart';

/// 지급받을 계좌(캔버스에 없다). 계좌가 없으면 은행·계좌번호·예금주를 받는 칸을, 있으면 NWallet의
/// 계좌 줄(`국민은행 ****12`, 예금주, `바꾸기`)을 보인다. 계좌번호는 뒤 2자리만 보인다.
class PayoutAccountPage extends ConsumerStatefulWidget {
  const PayoutAccountPage({super.key});

  static const title = '지급받을 계좌';
  static const heading = '지급받을 계좌를\n알려 주세요';
  static const bank = '은행';
  static const bankPlaceholder = '은행을 골라 주세요';
  static const number = '계좌번호';
  static const holder = '예금주';
  static const register = '등록하기';
  static const change = '바꾸기';
  static const loadFailed = '지급 계좌를 불러오지 못했어요.';

  @override
  ConsumerState<PayoutAccountPage> createState() => _PayoutAccountPageState();
}

class _PayoutAccountPageState extends ConsumerState<PayoutAccountPage> {
  final _number = TextEditingController();
  final _holder = TextEditingController();
  Bank? _bank;

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorOffers);
    }
  }

  bool get _complete {
    final digits = _number.text.length;
    return _bank != null &&
        digits >= 10 &&
        digits <= 14 &&
        _holder.text.trim().isNotEmpty;
  }

  Future<void> _pickBank(List<Bank> banks) async {
    final picked = await showModalBottomSheet<Bank>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.background,
      barrierColor: context.colors.scrim.withValues(alpha: 0.4),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      builder: (_) => _BankSheet(banks: banks, selected: _bank),
    );
    if (picked != null && mounted) setState(() => _bank = picked);
  }

  Future<void> _save() async {
    final bank = _bank;
    if (bank == null || !_complete) return;
    final ok = await ref
        .read(payoutAccountViewModelProvider.notifier)
        .save(
          bankCode: bank.code,
          accountNumber: _number.text,
          holderName: _holder.text.trim(),
        );
    if (!mounted || !ok) return;
    // 등록한 번호를 화면에 남기지 않는다.
    _number.clear();
    _holder.clear();
    setState(() => _bank = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(payoutAccountViewModelProvider);
    final value = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final showForm = value?.showForm ?? false;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: value != null && !showForm
                  ? PayoutAccountPage.title
                  : null,
              onBack: _leave,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) =>
                  value.showForm
                      ? _Form(
                          state: value,
                          bank: _bank,
                          number: _number,
                          holder: _holder,
                          onPickBank: () => _pickBank(value.banks),
                          onChanged: () => setState(() {}),
                          onSubmit: _save,
                        )
                      : _Registered(
                          account: value.account!,
                          onChange: ref
                              .read(payoutAccountViewModelProvider.notifier)
                              .startEdit,
                        ),
                AsyncError() => CoraStateView.loadFailed(
                  title: PayoutAccountPage.loadFailed,
                  onRetry: () => ref.invalidate(payoutAccountViewModelProvider),
                ),
                _ => const CoraStateView.loading(),
              },
            ),
            if (value != null && showForm)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (value.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            value.error!,
                            textAlign: TextAlign.center,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                    CoraPrimaryButton(
                      label: PayoutAccountPage.register,
                      onPressed: _complete && !value.busy ? _save : null,
                      look: CoraPrimaryButtonLook.accent,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.bank,
    required this.number,
    required this.holder,
    required this.onPickBank,
    required this.onChanged,
    required this.onSubmit,
  });

  final PayoutAccountState state;
  final Bank? bank;
  final TextEditingController number;
  final TextEditingController holder;
  final VoidCallback onPickBank;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Semantics(
            header: true,
            child: Text(
              PayoutAccountPage.heading,
              style: CoraTextStyles.headline.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: 18),
          CoraPickBox(
            label: PayoutAccountPage.bank,
            value: bank?.fullName,
            placeholder: PayoutAccountPage.bankPlaceholder,
            onTap: state.busy ? null : onPickBank,
          ),
          CoraFieldBox(
            fieldKey: const ValueKey('payout-number'),
            label: PayoutAccountPage.number,
            controller: number,
            enabled: !state.busy,
            maxLength: 14,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          ),
          CoraFieldBox(
            fieldKey: const ValueKey('payout-holder'),
            label: PayoutAccountPage.holder,
            controller: holder,
            enabled: !state.busy,
            maxLength: 30,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}

/// 등록된 계좌(캔버스 NWallet의 계좌 줄): 모서리 28, 안쪽 20, `surface`. 왼쪽에 `국민은행 ****12`와
/// 예금주(보조색) 14px, 오른쪽에 흰 알약 `바꾸기`(높이 36, 13/500).
class _Registered extends StatelessWidget {
  const _Registered({required this.account, required this.onChange});

  final PayoutAccount account;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.xxl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Wrap(
                    spacing: 4,
                    children: [
                      Text(
                        account.maskedLabel,
                        style: CoraTextStyles.bodySmall.copyWith(color: c.text),
                      ),
                      Text(
                        account.holderName,
                        style: CoraTextStyles.bodySmall.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                onTap: onChange,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: onChange,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.chipAction,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: SizedBox(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              PayoutAccountPage.change,
                              maxLines: 1,
                              style: CoraTextStyles.label.copyWith(
                                color: c.onChipAction,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 은행 고르기 시트(캔버스에 없다): 이름 줄이 세로로 이어지고 고른 은행은 `surfaceSelected`다.
class _BankSheet extends StatelessWidget {
  const _BankSheet({required this.banks, required this.selected});

  final List<Bank> banks;
  final Bank? selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        math.max(24.0, MediaQuery.viewPaddingOf(context).bottom),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Semantics(
            header: true,
            child: Text(
              PayoutAccountPage.bank,
              style: CoraTextStyles.heading.copyWith(color: c.text),
            ),
          ),
        ),
        for (final bank in banks)
          Semantics(
            container: true,
            button: true,
            selected: bank.code == selected?.code,
            onTap: () => Navigator.of(context).pop(bank),
            child: ExcludeSemantics(
              child: CoraPressable(
                onTap: () => Navigator.of(context).pop(bank),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bank.code == selected?.code
                        ? c.surfaceSelected
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(CoraRadius.lg),
                  ),
                  child: SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          bank.name,
                          style: CoraTextStyles.bodyLarge.copyWith(
                            color: bank.code == selected?.code
                                ? c.onSurfaceSelected
                                : c.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

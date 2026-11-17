import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../contract_text.dart';
import '../viewmodels/contract_view_model.dart';
import '../widgets/canvas_text.dart';
import '../widgets/contract_parts.dart';

/// D4 협업 계약(NContract / DarkNContract): 합의한 조건 요약과 확인란 세 개. 크리에이터는 확인하고 동의하고, 브랜드는
/// 크리에이터가 동의한 뒤 결제 상자와 함께 동의하고 결제해 계약을 체결한다. 12의 `계약하러 가기`와 07의 `계약서 확인하고
/// 동의하기`가 연다.
///
/// 라우트의 `?preview=1`은 따로 읽지 않는다: 양쪽이 같은 판본을 확인하기 전이면 서버가 `NOT_READY`로 답하고, 화면은
/// 그 상태를 미리 보기로 그린다.
class ContractPage extends ConsumerStatefulWidget {
  const ContractPage({super.key, required this.collaborationId});

  final String collaborationId;

  @override
  ConsumerState<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends ConsumerState<ContractPage> {
  ContractViewModel get _vm =>
      ref.read(contractViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.chats);
    }
  }

  /// F8 옛 판본의 `판본 N 보기`: 12에서 새 판본을 확인한다(설계 F8).
  void _openAgreement() {
    _vm.refreshAgreement();
    context.pushReplacement(
      AppRoutes.collaborationAgreement(widget.collaborationId),
    );
  }

  void _openProgress() {
    context.go(AppRoutes.collaborationProgress(widget.collaborationId));
  }

  @override
  Widget build(BuildContext context) {
    final provider = contractViewModelProvider(widget.collaborationId);
    final async = ref.watch(provider);
    final value = async.value;
    if (value == null) {
      return _Shell(
        onBack: _leave,
        child: async.hasError
            ? CoraStateView.loadFailed(
                title: ContractTexts.loadFailed,
                onRetry: () => ref.invalidate(provider),
              )
            : const CoraStateView.loading(),
      );
    }
    final stale = value.staleVersion;
    if (stale != null) {
      // F8 옛 판본. 계약을 낼 수 없으니 새 판본을 보러 간다.
      return _Shell(
        onBack: _leave,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CoraStateView.staleVersion(
            version: stale,
            onOpen: _openAgreement,
          ),
        ),
      );
    }
    final terms = value.contract.terms;
    if (terms == null) {
      return _Shell(
        onBack: _leave,
        child: CoraStateView.loadFailed(
          title: ContractTexts.loadFailed,
          onRetry: () => ref.invalidate(provider),
        ),
      );
    }
    final bottom = math.max(28.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: _leave),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: _Body(state: value, onToggle: _vm.toggle, vm: _vm),
              ),
            ),
            _BottomBar(
              state: value,
              bottom: bottom,
              onConsent: _vm.consent,
              onProgress: _openProgress,
            ),
          ],
        ),
      ),
    );
  }
}

/// 불러오는 중, 불러오기 실패, 옛 판본에서 쓰는 틀: 위에 머리만 있다.
class _Shell extends StatelessWidget {
  const _Shell({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: onBack),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 머리(높이 56, 좌우 8, 60 / 1fr / 60): 뒤로 가기, 가운데 `협업 계약` 16/500.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CoraBackButton(onPressed: onBack),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  ContractTexts.title,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.onToggle, required this.vm});

  final ContractState state;
  final ValueChanged<int> onToggle;
  final ContractViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final contract = state.contract;
    final terms = contract.terms!;
    final mode = state.mode;
    final quote = contract.quote;
    // 상대 사진만 알 수 있다. 크리에이터 화면의 상대는 브랜드(오른쪽), 브랜드 화면의 상대는 크리에이터(왼쪽)다.
    final photo = state.collaboration.counterpartPhotoUrl;
    final texts = contract.myConsentTexts;
    // 크리에이터가 동의한 뒤에는 확인한 채로 보인다. 그 밖에는 확인란을 직접 켠다.
    final canToggle = mode == ContractMode.consentable && !state.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.showVoidedNotice) const _VoidedNotice(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  ContractTexts.heading(terms.version),
                  style: canvasText(
                    26,
                    FontWeight.w900,
                    c.text,
                    spacingEm: -0.045,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ContractTexts.subtitle,
                style: canvasText(14, FontWeight.w400, c.textSecondary),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: ContractSummary(
            terms: terms,
            creatorName: contract.creatorName,
            brandName: contract.brandName,
            creatorPhotoUrl: state.isBrand ? photo : null,
            brandPhotoUrl: state.isBrand ? null : photo,
          ),
        ),
        if (mode == ContractMode.concluded)
          _Concluded(at: contract.concludedAt)
        else ...[
          if (state.showPayment && quote != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ContractPaymentBox(
                quote: quote,
                payoutDays: terms.payoutDays,
                method: state.method,
                onMethod: vm.selectMethod,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
            child: Column(
              children: [
                for (var i = 0; i < texts.length; i++)
                  ContractCheckRow(
                    label: texts[i],
                    checked: i < state.checked.length && state.checked[i],
                    onTap: canToggle ? () => onToggle(i) : null,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 내 동의가 새 판본으로 취소됐을 때의 띠(캔버스 밖): `surface` 상자에 13/500 글.
class _VoidedNotice extends StatelessWidget {
  const _VoidedNotice();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              ContractTexts.voided,
              style: canvasText(13, FontWeight.w500, c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// 체결된 뒤(캔버스 밖): 요약 아래에 `계약이 체결됐어요.`와 체결한 날.
class _Concluded extends StatelessWidget {
  const _Concluded({required this.at});

  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final when = at?.toLocal();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            header: true,
            child: Text(
              ContractTexts.concluded,
              style: canvasText(20, FontWeight.w900, c.text, spacingEm: -0.03),
            ),
          ),
          if (when != null) ...[
            const SizedBox(height: 4),
            Text(
              ContractTexts.concludedAt(when),
              style: canvasText(14, FontWeight.w400, c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 아래 고정 영역(캔버스): 안쪽 0/16/28, 위에 안내(12, 가운데, 아래 10), 그 아래 버튼(높이 58).
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.bottom,
    required this.onConsent,
    required this.onProgress,
  });

  final ContractState state;
  final double bottom;
  final VoidCallback onConsent;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mode = state.mode;
    final note = state.notice ?? _note();
    final VoidCallback? onPressed;
    final String label;
    switch (mode) {
      case ContractMode.concluded:
        label = ContractTexts.openProgress;
        onPressed = onProgress;
      case ContractMode.consentable:
        if (state.phase == ContractPhase.checking) {
          label = ContractTexts.checking;
          onPressed = null;
        } else if (!state.allChecked) {
          label = ContractTexts.notReady;
          onPressed = null;
        } else {
          label = ContractTexts.consent;
          onPressed = state.busy ? null : onConsent;
        }
      case ContractMode.preview:
      case ContractMode.waiting:
        label = ContractTexts.consent;
        onPressed = null;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  note,
                  textAlign: TextAlign.center,
                  style: canvasText(
                    12,
                    FontWeight.w400,
                    state.notice != null ? c.text : c.textSecondary,
                  ),
                ),
              ),
            ),
          CoraPrimaryButton(
            label: label,
            onPressed: onPressed,
            look: CoraPrimaryButtonLook.accent,
          ),
        ],
      ),
    );
  }

  String? _note() => switch (state.mode) {
    ContractMode.concluded => null,
    ContractMode.preview => ContractTexts.previewNote,
    ContractMode.consentable => null,
    ContractMode.waiting =>
      state.isBrand
          ? ContractTexts.brandWaitsCreator
          : ContractTexts.creatorWaitsBrand,
  };
}

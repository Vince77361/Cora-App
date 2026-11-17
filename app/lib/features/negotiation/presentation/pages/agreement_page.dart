import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_chat_tokens.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../chat/presentation/widgets/drop_sheet.dart';
import '../../domain/terms_version.dart';
import '../terms_text.dart';
import '../viewmodels/agreement_view_model.dart';
import '../widgets/agreement_parts.dart';
import '../widgets/canvas_text.dart';

/// 12 조건 합의·변경 기록(Agreement / DarkAgreement): 협업의 조건 판본을 보고, 이번 판본에서 바뀐 조건과 변경 기록을
/// 확인하고, 내 차례면 `이 버전 수락`, 아니면 `수정 제안`이나 계약으로 간다. 대화방 머리의 조건 요약이 연다.
class AgreementPage extends ConsumerStatefulWidget {
  const AgreementPage({super.key, required this.collaborationId});

  final String collaborationId;

  @override
  ConsumerState<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends ConsumerState<AgreementPage> {
  AgreementViewModel get _vm =>
      ref.read(agreementViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.chats);
    }
  }

  void _propose() {
    context.push(
      AppRoutes.collaborationTermsPropose(widget.collaborationId),
      extra: AppRoutes.fromAgreement,
    );
  }

  void _openContract() {
    context.push(AppRoutes.collaborationContract(widget.collaborationId));
  }

  Future<void> _connectInstagram() async {
    await context.push(AppRoutes.creatorInstagram);
    // 연동하고 돌아오면 서버가 `needsInstagram`을 바꿨으므로 버튼이 `이 버전 수락`이 된다.
    if (mounted) await _vm.reload();
  }

  Future<void> _openMenu() async {
    final drop = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
      backgroundColor: Colors.transparent,
      barrierColor: CoraChatTokens.menuScrim,
      elevation: 0,
      showDragHandle: false,
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CoraRadius.xxl),
          ),
        ),
        child: const _AgreementMenuSheet(),
      ),
    );
    if (!mounted || drop != true) return;
    await showDropSheet(context, onConfirm: _vm.drop);
  }

  @override
  Widget build(BuildContext context) {
    final provider = agreementViewModelProvider(widget.collaborationId);
    final async = ref.watch(provider);
    final value = async.value;
    if (value != null && value.staleVersion != null && value.reloadFailed) {
      return _Shell(
        onBack: _leave,
        child: CoraStateView.loadFailed(
          title: AgreementTexts.loadFailed,
          onRetry: _vm.reload,
        ),
      );
    }
    if (value != null && value.staleVersion != null) {
      // F8 옛 판본: 버튼은 12를 최신 판본으로 새로 읽는다.
      return _Shell(
        onBack: _leave,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CoraStateView.staleVersion(
            version: value.staleVersion!,
            onOpen: _vm.reload,
          ),
        ),
      );
    }
    if (value == null) {
      return _Shell(
        onBack: _leave,
        child: async.hasError
            ? CoraStateView.loadFailed(
                title: AgreementTexts.loadFailed,
                onRetry: () => ref.invalidate(provider),
              )
            : const CoraStateView.loading(),
      );
    }
    final bottom = math.max(24.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AgreementHeader(
              onBack: _leave,
              onMenu: value.preContract ? _openMenu : null,
            ),
            Expanded(child: _Body(state: value)),
            _ActionBar(
              state: value,
              bottom: bottom,
              onAccept: () => _vm.confirm(),
              onConnect: _connectInstagram,
              onPropose: _propose,
              onContract: _openContract,
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
            AgreementHeader(onBack: onBack),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final AgreementState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final history = state.history;
    final latest = history.latest;
    final previous = history.previous;
    final changed = latest.changedFields.toSet();
    final otherName = state.counterpartRoleName;
    final myConfirmed = state.myConfirmed;
    final otherConfirmed = state.isBrand
        ? latest.creatorConfirmed
        : latest.brandConfirmed;

    Widget cell(TermsField field) {
      final isChanged = previous != null && changed.contains(field);
      return TermsCell(
        name: cellName(field),
        value: termsFieldValue(field, latest),
        previousValue: isChanged ? changedFromValue(field, previous) : null,
      );
    }

    // 캔버스(Agreement)의 칸 순서. 콘텐츠 제목은 이번 판본에서 바뀌었을 때만, 성과 추가는 있거나 바뀌었을 때만 보인다.
    final cells = <Widget>[
      if (changed.contains(TermsField.title)) cell(TermsField.title),
      cell(TermsField.fee),
      if (latest.performance != null ||
          changed.contains(TermsField.performance))
        cell(TermsField.performance),
      cell(TermsField.startDate),
      cell(TermsField.deliverable),
      cell(TermsField.product),
      cell(TermsField.revision),
      cell(TermsField.usage),
      cell(TermsField.payout),
      TermsCell(name: AgreementTexts.adMark, value: AgreementTexts.adMarkValue),
    ];

    // 변경 기록은 오래된 판본이 위다(캔버스).
    final lines = [
      for (final v in history.versions.reversed)
        (
          version: v.version,
          text: historyText(
            v,
            mine: state.proposedByMe(v),
            counterpartRoleName: otherName,
          ),
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgreementStatusBox(
            version: latest.version,
            status: agreementStatus(history.agreement),
            myLine: confirmLine(AgreementTexts.me, confirmed: myConfirmed),
            myConfirmed: myConfirmed,
            otherLine: confirmLine(otherName, confirmed: otherConfirmed),
            otherConfirmed: otherConfirmed,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaxCashRow(value: maxCashLine(latest)),
                Semantics(
                  header: true,
                  child: Text(
                    AgreementTexts.heading,
                    style: canvasText(
                      22,
                      FontWeight.w900,
                      c.text,
                      spacingEm: -0.03,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AgreementTexts.legend,
                  style: canvasText(13, FontWeight.w400, c.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TermsGrid(cells: cells),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    AgreementTexts.history,
                    style: canvasText(14, FontWeight.w500, c.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                HistoryList(lines: lines),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 아래 고정 막대(캔버스): 안쪽 12/16/24, `background`, 위로 번지는 그림자, 세로 8. 버튼 높이 52. 맨 아래 안내는 12px.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.bottom,
    required this.onAccept,
    required this.onConnect,
    required this.onPropose,
    required this.onContract,
  });

  final AgreementState state;
  final double bottom;
  final VoidCallback onAccept;
  final VoidCallback onConnect;
  final VoidCallback onPropose;
  final VoidCallback onContract;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final busy = state.busy;
    final notice = state.notice;
    final pre = state.preContract;
    final needsInstagram = pre && !state.myConfirmed && state.needsInstagram;
    final canAccept = pre && !state.myConfirmed && !state.agreed;
    final editable = state.history.editable;

    Widget pill(
      String label,
      VoidCallback? onTap, {
      required bool primary,
      Key? key,
    }) => CoraPillButton(
      key: key,
      label: label,
      onPressed: onTap,
      background: primary ? c.accent : c.surface,
      foreground: primary ? c.onAccent : c.text,
      textStyle: canvasText(
        15,
        primary ? FontWeight.w700 : FontWeight.w500,
        primary ? c.onAccent : c.text,
      ),
      height: 52,
    );

    final modify = pill(
      AgreementTexts.modify,
      busy || !editable ? null : onPropose,
      primary: false,
    );
    final Widget? accept = !canAccept
        ? null
        : needsInstagram
        ? pill(
            AgreementTexts.connectInstagram,
            busy ? null : onConnect,
            primary: true,
          )
        : pill(AgreementTexts.accept, busy ? null : onAccept, primary: true);

    final Widget buttons;
    if (state.ended) {
      buttons = const SizedBox.shrink();
    } else if (state.contracted) {
      buttons = pill(
        AgreementTexts.viewContract,
        busy ? null : onContract,
        primary: true,
      );
    } else {
      final contractLabel = state.agreed
          ? AgreementTexts.goContract
          : AgreementTexts.preview;
      if (accept == null) {
        // 캔버스(Agreement)의 모양: `수정 제안`과 주 버튼 하나.
        buttons = Row(
          spacing: 8,
          children: [
            Expanded(flex: 10, child: modify),
            Expanded(
              flex: 14,
              child: pill(
                contractLabel,
                busy ? null : onContract,
                primary: true,
              ),
            ),
          ],
        );
      } else {
        // 캔버스 밖: 내가 확인하지 않은 판본이면 `수정 제안`과 `이 버전 수락`이 한 줄, 계약서 보기는 그 아래 한 줄.
        buttons = Column(
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(flex: 10, child: modify),
                Expanded(flex: 14, child: accept),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: pill(
                contractLabel,
                busy ? null : onContract,
                primary: false,
              ),
            ),
          ],
        );
      }
    }

    final note = state.ended
        ? AgreementTexts.ended
        : state.contracted
        ? AgreementTexts.afterContract
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        boxShadow: [
          BoxShadow(
            color: c.termsBarShadow,
            offset: const Offset(0, -8),
            blurRadius: CoraShadows.blurRadiusFor(24),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            if (needsInstagram)
              Semantics(
                liveRegion: true,
                child: Text(
                  AgreementTexts.needsInstagram,
                  textAlign: TextAlign.center,
                  style: canvasText(12, FontWeight.w400, c.textSecondary),
                ),
              ),
            if (notice != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  notice,
                  textAlign: TextAlign.center,
                  style: canvasText(12, FontWeight.w400, c.text),
                ),
              ),
            if (note != null)
              Text(
                note,
                textAlign: TextAlign.center,
                style: canvasText(12, FontWeight.w400, c.textSecondary),
              ),
            buttons,
            Text(
              versionNotice(state.latest.version),
              textAlign: TextAlign.center,
              style: canvasText(12, FontWeight.w400, c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 점 셋이 여는 시트(캔버스 밖): `협의 그만두기`와 `닫기`. 대화방 메뉴 시트와 같은 모양이다.
class _AgreementMenuSheet extends StatelessWidget {
  const _AgreementMenuSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(28.0, MediaQuery.viewPaddingOf(context).bottom);
    return Semantics(
      container: true,
      label: AgreementTexts.menu,
      child: Padding(
        padding: EdgeInsets.only(top: 12, bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const SizedBox(width: 40, height: 5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              container: true,
              button: true,
              label: AgreementTexts.dropMenu,
              onTap: () => Navigator.of(context).pop(true),
              child: ExcludeSemantics(
                child: CoraPressable(
                  onTap: () => Navigator.of(context).pop(true),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AgreementTexts.dropMenu,
                          style: CoraTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Semantics(
                container: true,
                button: true,
                label: '닫기',
                onTap: () => Navigator.of(context).pop(),
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            '닫기',
                            style: CoraTextStyles.buttonMedium.copyWith(
                              color: c.text,
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
    );
  }
}

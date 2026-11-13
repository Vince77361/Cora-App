import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../domain/source_link.dart';
import '../viewmodels/store_links_view_model.dart';
import '../widgets/inline_action_text.dart';
import '../widgets/store_icons.dart';
import '../widgets/store_text_box.dart';
import 'store_manual_page.dart';

/// A2 가게 링크 입력(NStoreLink / DarkNStoreLink), 등록 1/3.
///
/// 링크를 하나 이상 넣고 `가게 페이지 만들기`를 누르면 서버가 분석한다. 성공하면 A3으로 간다.
/// 링크가 없거나 읽지 못하면 직접 입력으로 간다.
class StoreLinksPage extends ConsumerWidget {
  const StoreLinksPage({super.key});

  static const title = '가게 링크 하나면 돼요.';
  static const subtitle =
      '네이버 지도, 캐치테이블, 인스타그램, 체험단 후기 글 중 무엇이든 괜찮아요. 가입 없이 먼저 볼 수 있어요.';
  static const note = '가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요. ';
  static const manualEntryLabel = '링크가 없거나 안 열리면 직접 입력';
  static const createLabel = '가게 페이지 만들기';
  static const analyzingLabel = '가게 정보를 가져오는 중이에요';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeLinksViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: state.when(
          // 저장된 가게는 이미 메모리에 있어 곧바로 끝난다. 그동안은 배경만 둔다.
          loading: () => const SizedBox.expand(),
          error: (_, _) => const SizedBox.expand(),
          data: (s) => _LinksForm(initial: s),
        ),
      ),
    );
  }
}

class _LinksForm extends ConsumerStatefulWidget {
  const _LinksForm({required this.initial});

  final StoreLinksState initial;

  @override
  ConsumerState<_LinksForm> createState() => _LinksFormState();
}

class _LinksFormState extends ConsumerState<_LinksForm> {
  late final Map<SourceLinkKind, TextEditingController> _controllers = {
    for (final kind in SourceLinkKind.values)
      kind: TextEditingController(text: widget.initial.textOf(kind)),
  };
  final _focus = {for (final kind in SourceLinkKind.values) kind: FocusNode()};

  /// 한 번이라도 입력란을 떠난 종류. 입력하는 도중에 틀렸다고 알리면 `n`, `na`처럼 쓰는
  /// 동안 계속 깜빡이므로, 떠난 뒤부터 형식 안내를 보여 준다.
  final _touched = <SourceLinkKind>{};

  @override
  void initState() {
    super.initState();
    for (final kind in SourceLinkKind.values) {
      _focus[kind]!.addListener(() {
        if (!_focus[kind]!.hasFocus && _touched.add(kind) && mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      // 첫 화면으로 들어왔으면 쌓인 화면이 없다. 역할을 다시 고를 수 있게 A1로 간다.
      context.go(AppRoutes.role);
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    // 눌러서 만드는 순간에는 모든 입력란의 안내를 보여 준다.
    setState(() => _touched.addAll(SourceLinkKind.values));
    final outcome = await ref
        .read(storeLinksViewModelProvider.notifier)
        .submit();
    if (!mounted) return;
    switch (outcome) {
      case StoreLinksOutcome.analyzed:
        context.push(AppRoutes.storeOnboardingPage, extra: AppRoutes.stacked);
      case StoreLinksOutcome.analysisFailed:
        _enterManually(afterFailure: true);
      case StoreLinksOutcome.failed:
        break;
    }
  }

  /// 직접 입력(F7)으로 간다. 링크 분석이 실패해서 가는 때만 그 안내를 함께 보인다.
  void _enterManually({bool afterFailure = false}) {
    context.push(
      AppRoutes.storeOnboardingManual,
      extra: StoreManualArgs(afterFailure: afterFailure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state =
        ref.watch(storeLinksViewModelProvider).value ?? widget.initial;
    final vm = ref.read(storeLinksViewModelProvider.notifier);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final error = state.errorMessage;
    final noteStyle = CoraTextStyles.meta.copyWith(
      height: 1.6,
      color: c.textSecondary,
    );

    final String label;
    final VoidCallback? onPressed;
    if (state.analyzing) {
      label = StoreLinksPage.analyzingLabel;
      onPressed = null;
    } else {
      label = StoreLinksPage.createLabel;
      onPressed = state.canSubmit ? _submit : null;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
          CoraStepHeader(pageLabel: '가게 등록', step: 1, total: 3, onBack: _back),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StoreLinksPage.title,
                          style: CoraTextStyles.headline.copyWith(
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          StoreLinksPage.subtitle,
                          style: CoraTextStyles.body.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        for (final kind in SourceLinkKind.values)
                          _LinkField(
                            kind: kind,
                            controller: _controllers[kind]!,
                            focusNode: _focus[kind]!,
                            summary: state.summaryOf(kind),
                            invalid:
                                _touched.contains(kind) &&
                                state.isInvalid(kind),
                            enabled: !state.analyzing,
                            onChanged: (text) => vm.setInput(kind, text),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Semantics(
                      liveRegion: true,
                      child: InlineActionText(
                        // 서버에 닿지 못했을 때는 안내 대신 그 문구를 보인다.
                        text: error == null ? StoreLinksPage.note : '$error ',
                        style: error == null
                            ? noteStyle
                            : noteStyle.copyWith(color: c.text),
                        action: StoreLinksPage.manualEntryLabel,
                        actionStyle: noteStyle.copyWith(
                          color: c.text,
                          fontWeight: FontWeight.w500,
                        ),
                        onTap: state.analyzing ? null : () => _enterManually(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            child: CoraPrimaryButton(
              label: label,
              onPressed: onPressed,
              look: CoraPrimaryButtonLook.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// 링크 입력 칸 한 개(NStoreLink): 모서리 20, `surface` 바탕, 안쪽 14/16. 위 줄에 이름(13/500)과
/// 오른쪽 ✓ 요약(12), 6 아래에 값(15). 값이 있으면 이름이 `text`, 비어 있으면 `textSecondary`다.
/// 형식이 틀리면 칸 아래에 안내가 붙는다.
class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.kind,
    required this.controller,
    required this.focusNode,
    required this.summary,
    required this.invalid,
    required this.enabled,
    required this.onChanged,
  });

  final SourceLinkKind kind;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? summary;
  final bool invalid;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filled = controller.text.trim().isNotEmpty;
    final valueStyle = CoraTextStyles.buttonMedium.copyWith(
      fontWeight: FontWeight.w400,
      color: c.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.field),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          kind.fieldLabel,
                          style: CoraTextStyles.label.copyWith(
                            color: filled ? c.text : c.textSecondary,
                          ),
                        ),
                      ),
                      if (summary != null)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StoreIcon(StoreIconPainter.check(c.onAccent)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    summary!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CoraTextStyles.fieldLabel.copyWith(
                                      color: c.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: ValueKey('storeLinks.${kind.name}'),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    onChanged: onChanged,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 500,
                    maxLines: 1,
                    style: valueStyle,
                    cursorColor: c.text,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    decoration: storeFieldDecoration(
                      hint: kind.example,
                      hintStyle: valueStyle.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (invalid)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(
                kind.invalidHint,
                style: CoraTextStyles.fieldLabel.copyWith(color: c.text),
              ),
            ),
          ),
      ],
    );
  }
}

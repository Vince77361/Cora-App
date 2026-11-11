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
import '../widgets/store_icons.dart';
import '../widgets/store_text_box.dart';
import 'store_edit_page.dart';

/// A2 가게 링크 입력(NStoreLink / DarkNStoreLink), 등록 1/3.
///
/// 링크를 하나 이상 넣고 `가게 페이지 만들기`를 누르면 서버가 분석한다. 성공하면 A3으로 간다.
/// 링크에서 읽지 못하면 이 화면에 남아 안내와 `직접 입력하기`를 보여 준다.
class StoreLinksPage extends ConsumerWidget {
  const StoreLinksPage({super.key});

  static const title = '가게 링크만 넣으면\n소개 페이지를 만들어 드려요.';
  static const subtitle = '사진, 메뉴, 영업시간을 링크에서 가져와요. 2개 이상 넣으면 더 정확해요.';
  static const note = '가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.';
  static const createLabel = '가게 페이지 만들기';
  static const analyzingLabel = '가게 정보를 가져오는 중이에요';
  static const analysisFailedNote = '정보를 가져오지 못했어요. 직접 입력할 수 있어요.';
  static const manualEntryLabel = '직접 입력하기';

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
    if (!mounted || outcome != StoreLinksOutcome.analyzed) return;
    context.push(AppRoutes.storeOnboardingPage, extra: AppRoutes.stacked);
  }

  void _enterManually() {
    context.push(
      AppRoutes.storeOnboardingEdit,
      extra: const StoreEditArgs(thenOpenPreview: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state =
        ref.watch(storeLinksViewModelProvider).value ?? widget.initial;
    final vm = ref.read(storeLinksViewModelProvider.notifier);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final note = state.analysisFailed
        ? StoreLinksPage.analysisFailedNote
        : (state.errorMessage ?? StoreLinksPage.note);
    final noteStyle = CoraTextStyles.meta.copyWith(
      height: 1.6,
      color: state.analysisFailed || state.errorMessage != null
          ? c.text
          : c.textSecondary,
    );

    final String label;
    final VoidCallback? onPressed;
    if (state.analysisFailed) {
      label = StoreLinksPage.manualEntryLabel;
      onPressed = _enterManually;
    } else if (state.analyzing) {
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
                      child: Text(note, style: noteStyle),
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
                      Text(
                        kind.fieldLabel,
                        style: CoraTextStyles.label.copyWith(
                          color: filled ? c.text : c.textSecondary,
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

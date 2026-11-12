import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/regions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../domain/my_store.dart';
import '../viewmodels/my_store_view_model.dart';
import '../viewmodels/store_edit_view_model.dart';
import '../widgets/option_sheet.dart';
import '../widgets/store_icons.dart';
import '../widgets/store_text_box.dart';

/// 가게 정보 고치기 화면을 열 때 넘기는 값(`extra`).
class StoreEditArgs {
  const StoreEditArgs({this.focusIntro = false, this.thenOpenPreview = false});

  /// A3의 `고치기`로 들어왔다. 소개 입력란에 커서를 둔다.
  final bool focusIntro;

  /// A2에서 `직접 입력하기`로 들어왔다. 저장하면 닫는 대신 가게 페이지(A3)를 연다.
  final bool thenOpenPreview;
}

/// 가게 정보 고치기(캔버스에 없는 화면). 입력 칸 모양은 NEditProfile / DarkNEditProfile을 따른다.
class StoreEditPage extends ConsumerWidget {
  const StoreEditPage({super.key, this.args = const StoreEditArgs()});

  final StoreEditArgs args;

  static const title = '가게 정보 고치기';
  static const saveLabel = '저장';
  static const loadFailed = '가게 정보를 불러오지 못했어요.';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';
  static const photoTooLarge = '사진이 너무 커요. 5MB 이하로 골라 주세요.';
  static const photoFailed = '사진을 올리지 못했어요. 다시 시도해 주세요.';
  static const uploadingPhoto = '사진을 올리는 중이에요';
  static const changePhoto = '사진 바꾸기';
  static const sidoListKey = ValueKey<String>('storeEdit.sidoList');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeEditViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const CoraStateView.loading(),
          error: (_, _) => CoraStateView.loadFailed(
            title: loadFailed,
            // 가게는 `내 가게`를 거쳐 읽으므로 그쪽 실패도 함께 비워야 다시 불러온다.
            onRetry: () {
              ref.invalidate(myStoreViewModelProvider);
              ref.invalidate(storeEditViewModelProvider);
            },
          ),
          data: (s) => _EditForm(initial: s, args: args),
        ),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.initial, required this.args});

  final StoreEditState initial;
  final StoreEditArgs args;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final Map<StoreTextField, TextEditingController> _controllers = {
    for (final field in StoreTextField.values)
      field: TextEditingController(text: widget.initial.valueOf(field)),
  };
  final _introFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.args.focusIntro) {
      // 시트가 올라온 뒤에 커서를 둔다. 첫 프레임에 요청하면 올라오는 동안 키보드가 먼저 뜬다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _introFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _introFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref.read(storeEditViewModelProvider.notifier).save();
    if (!saved || !mounted) return;
    if (widget.args.thenOpenPreview) {
      // A2에서 직접 입력하러 왔다. 가게 페이지를 A2 위에 쌓고 이 시트는 치운다.
      context.pushReplacement(
        AppRoutes.storeOnboardingPage,
        extra: AppRoutes.stacked,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _chooseIndustry(IndustryCategory current) async {
    final picked = await showStoreOptionSheet<IndustryCategory>(
      context,
      title: '업종 분류',
      options: IndustryCategory.values,
      labelOf: (c) => c.label,
      selected: current,
    );
    if (picked == null || !mounted) return;
    ref.read(storeEditViewModelProvider.notifier).setIndustry(picked);
  }

  Future<void> _chooseSido(String? current) async {
    final picked = await showStoreOptionSheet<String>(
      context,
      title: '지역',
      options: sidoList,
      labelOf: (s) => s,
      selected: current,
      listKey: StoreEditPage.sidoListKey,
    );
    if (picked == null || !mounted) return;
    ref.read(storeEditViewModelProvider.notifier).setRegionSido(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vm = ref.read(storeEditViewModelProvider.notifier);
    final state = ref.watch(storeEditViewModelProvider).value ?? widget.initial;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final message = state.saveFailed
        ? StoreEditPage.saveFailed
        : switch (state.photoProblem) {
            StorePhotoProblem.tooLarge => StoreEditPage.photoTooLarge,
            StorePhotoProblem.failed => StoreEditPage.photoFailed,
            null => null,
          };

    StoreTextBox box(
      StoreTextField field,
      String label,
      int maxLength, {
      bool multiline = false,
    }) => StoreTextBox(
      fieldKey: ValueKey('storeEdit.${field.name}'),
      label: label,
      controller: _controllers[field]!,
      focusNode: field == StoreTextField.intro ? _introFocus : null,
      maxLength: maxLength,
      multiline: multiline,
      onChanged: (text) => vm.setText(field, text),
    );

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Expanded(child: a),
        Expanded(child: b),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
          // NEditProfile 머리글: 뒤로 가기, 가운데 제목 16/500.
          SizedBox(
            height: CoraStepHeader.rowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CoraBackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      StoreEditPage.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _CoverPicker(
                      url: state.coverPhotoUrl,
                      preview: state.coverPreview,
                      uploading: state.uploadingPhoto,
                      onPick: vm.changePhoto,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        box(StoreTextField.name, '가게 이름', 30),
                        pair(
                          box(StoreTextField.category, '업종', 50),
                          box(StoreTextField.neighborhood, '동네', 50),
                        ),
                        StorePickBox(
                          label: '업종 분류',
                          value: state.industry.label,
                          placeholder: '업종 고르기',
                          onTap: () => _chooseIndustry(state.industry),
                        ),
                        pair(
                          StorePickBox(
                            label: '지역',
                            value: state.regionSido,
                            placeholder: '시·도 고르기',
                            onTap: () => _chooseSido(state.regionSido),
                          ),
                          box(StoreTextField.regionSigungu, '구·군', 20),
                        ),
                        box(StoreTextField.signatureMenu, '대표 메뉴', 50),
                        box(StoreTextField.hours, '영업시간', 50),
                        pair(
                          box(StoreTextField.seats, '좌석', 50),
                          box(StoreTextField.bestShootingTime, '찍기 좋은 시간', 50),
                        ),
                        box(StoreTextField.intro, '소개', 300, multiline: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(color: c.text),
                      ),
                    ),
                  ),
                CoraPrimaryButton(
                  label: StoreEditPage.saveLabel,
                  onPressed: state.canSave ? _save : null,
                  look: CoraPrimaryButtonLook.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 맨 위 대표 사진(NEditProfile의 원형 사진 자리에 해당): 모서리 28의 가로 사진, 오른쪽 아래에 36
/// 둥근 카메라 버튼. 사진을 고르면 그 사진이 바로 보인다. 아래 `사진 바꾸기` 글자도 같은 동작이다.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.url,
    required this.preview,
    required this.uploading,
    required this.onPick,
  });

  final String? url;
  final Uint8List? preview;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: uploading ? null : onPick,
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(CoraRadius.xxl),
                        child: preview != null
                            ? ColoredBox(
                                color: c.coverPlaceholder,
                                child: Image.memory(
                                  preview!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox.expand(),
                                ),
                              )
                            : CoraNetworkPhoto(
                                url: url,
                                alignment: const Alignment(0, -0.1),
                                background: c.coverPlaceholder,
                              ),
                      ),
                    ),
                    if (uploading)
                      Positioned.fill(
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.photoChip,
                              borderRadius: BorderRadius.circular(
                                CoraRadius.pill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                StoreEditPage.uploadingPhoto,
                                style: CoraTextStyles.caption.copyWith(
                                  color: c.onPhotoChip,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.avatarEditButton,
                          shape: BoxShape.circle,
                          boxShadow: CoraShadows.avatarEdit(c.avatarEditShadow),
                        ),
                        child: SizedBox.square(
                          dimension: 36,
                          child: Center(
                            child: StoreIcon(
                              StoreIconPainter.camera(c.text),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Semantics(
          container: true,
          button: true,
          enabled: !uploading,
          onTap: uploading ? null : onPick,
          child: CoraPressable(
            onTap: uploading ? null : onPick,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    StoreEditPage.changePhoto,
                    style: CoraTextStyles.label.copyWith(
                      color: c.textSecondary,
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

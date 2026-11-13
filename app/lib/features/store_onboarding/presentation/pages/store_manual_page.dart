import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../domain/my_store.dart';
import '../viewmodels/store_edit_view_model.dart' show StorePhotoProblem;
import '../viewmodels/store_links_view_model.dart';
import '../viewmodels/store_manual_view_model.dart';
import '../widgets/store_icons.dart';
import '../widgets/store_text_box.dart';
import 'store_edit_page.dart';

/// F7을 열 때 넘기는 값(`extra`).
class StoreManualArgs {
  const StoreManualArgs({this.afterFailure = false});

  /// A2의 링크 분석이 실패해서 왔다. 맨 위에 안내가 보인다. 링크가 없어서 직접 입력으로 온
  /// 사람에게는 보이지 않는다.
  final bool afterFailure;
}

/// F7 매장 직접 입력(NStoreManual / DarkNStoreManual), 등록 1/3.
///
/// 링크가 없거나 읽지 못했을 때 가게 이름만 채우면 A3으로 이어 간다. 같은 이름의 가게가 둘 이상이면
/// 지점을 고른다.
class StoreManualPage extends ConsumerStatefulWidget {
  const StoreManualPage({super.key, this.args = const StoreManualArgs()});

  final StoreManualArgs args;

  static const failureNotice = '링크에서 정보를 가져오지 못했어요. 아래만 채우면 계속할 수 있어요.';
  static const createLabel = '가게 페이지 만들기';
  static const photoLabel = '가게 사진 올리기 (사용 권한이 있는 사진만)';
  static String branchesLabel(int count) => '지점 · 같은 이름의 가게가 $count곳 있어요';

  /// 캔버스에 없는 상태의 문구.
  static const createFailed = '가게를 만들지 못했어요. 다시 시도해 주세요.';
  static const changePhoto = '사진 바꾸기';
  static const uploadingPhoto = '사진을 올리는 중이에요';

  @override
  ConsumerState<StoreManualPage> createState() => _StoreManualPageState();
}

class _StoreManualPageState extends ConsumerState<StoreManualPage> {
  final _name = TextEditingController();
  final _menu = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _menu.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.storeOnboardingLinks);
    }
  }

  Future<void> _create() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final created = await ref
        .read(storeManualViewModelProvider.notifier)
        .create();
    if (!created || !mounted) return;
    // F7은 A2 위에 쌓여 있다. 자리를 A3으로 바꿔 A3에서 뒤로 가면 A2다.
    context.pushReplacement(
      AppRoutes.storeOnboardingPage,
      extra: AppRoutes.stacked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(storeManualViewModelProvider).value;
    final vm = ref.read(storeManualViewModelProvider.notifier);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final message = switch ((state?.problem, state?.photoProblem)) {
      (StoreManualProblem.alreadyPublished, _) =>
        StoreLinksViewModel.alreadyPublished,
      (StoreManualProblem.failed, _) => StoreManualPage.createFailed,
      (_, StorePhotoProblem.tooLarge) => StoreEditPage.photoTooLarge,
      (_, StorePhotoProblem.failed) => StoreEditPage.photoFailed,
      _ => null,
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              CoraStepHeader(
                pageLabel: '가게 등록',
                step: 1,
                total: 3,
                onBack: _back,
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.args.afterFailure)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _Notice(text: StoreManualPage.failureNotice),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 8,
                          children: [
                            StoreTextBox(
                              fieldKey: const ValueKey('storeManual.name'),
                              label: '가게 이름',
                              controller: _name,
                              maxLength: 30,
                              onChanged: vm.setName,
                            ),
                            if (state != null && state.showsBranches)
                              _BranchBox(
                                branches: state.branches,
                                selected: state.selectedBranch,
                                onPick: vm.selectBranch,
                              ),
                            StoreTextBox(
                              fieldKey: const ValueKey(
                                'storeManual.signatureMenu',
                              ),
                              label: '대표 메뉴와 가격',
                              controller: _menu,
                              maxLength: 50,
                              onChanged: vm.setSignatureMenu,
                            ),
                            _PhotoButton(
                              preview: state?.coverPreview,
                              uploading: state?.uploadingPhoto ?? false,
                              onPick: vm.changePhoto,
                            ),
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
                      label: StoreManualPage.createLabel,
                      look: CoraPrimaryButtonLook.accent,
                      onPressed: state != null && state.canCreate
                          ? _create
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 맨 위 안내(NStoreManual): 모서리 18, `surface` 바탕, 안쪽 12/16. 앞에 18 크기 느낌표 동그라미,
/// 글은 13에 줄 높이 1.55.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: StoreIcon(StoreIconPainter.info(c.text), size: 18),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  style: CoraTextStyles.meta.copyWith(
                    height: 1.55,
                    color: c.text,
                    fontWeight: FontWeight.w400,
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

/// 지점 고르기(NStoreManual): 모서리 20 `surface` 상자, 안쪽 14/18. 이름 12, 8 아래에 줄 목록(줄 사이 6).
/// 줄은 높이 48, 안쪽 좌우 14, 모서리 14, 고른 줄만 바탕이 있다(`quietSelected`: 라이트 #FFFFFF,
/// 다크 #2A2D33). 왼쪽에 지점 이름 14, 오른쪽에 동네 12 보조색.
class _BranchBox extends StatelessWidget {
  const _BranchBox({
    required this.branches,
    required this.selected,
    required this.onPick,
  });

  final List<StoreBranch> branches;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              StoreManualPage.branchesLabel(branches.length),
              style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                for (final (i, branch) in branches.indexed)
                  _BranchRow(
                    branch: branch,
                    selected: i == selected,
                    onTap: () => onPick(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final StoreBranch branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${branch.label} ${branch.shownPlace}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? c.quietSelected : Colors.transparent,
                borderRadius: BorderRadius.circular(CoraRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        branch.label,
                        style: CoraTextStyles.bodySmall.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        branch.shownPlace,
                        textAlign: TextAlign.end,
                        style: CoraTextStyles.fieldLabel.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 사진 올리기(NStoreManual): 높이 56, 모서리 20, `surface` 바탕, 더하기 아이콘과 이름(14/500)이
/// 가운데에 있다. 사진을 고르면 그 사진이 같은 자리에 보이고(캔버스에 없는 모양) 누르면 바꾼다.
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.preview,
    required this.uploading,
    required this.onPick,
  });

  final Uint8List? preview;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onTap = uploading ? null : onPick;
    if (preview != null) {
      return Semantics(
        container: true,
        button: true,
        enabled: !uploading,
        label: StoreManualPage.changePhoto,
        onTap: onTap,
        child: ExcludeSemantics(
          child: CoraPressable(
            onTap: onTap,
            child: SizedBox(
              height: 160,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(CoraRadius.field),
                      child: ColoredBox(
                        color: c.coverPlaceholder,
                        child: Image.memory(
                          preview!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox.expand(),
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
      );
    }
    final label = uploading
        ? StoreManualPage.uploadingPhoto
        : StoreManualPage.photoLabel;
    return Semantics(
      container: true,
      button: true,
      enabled: !uploading,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(CoraRadius.field),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    StoreIcon(StoreIconPainter.plus(c.text), size: 18),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

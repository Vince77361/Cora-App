import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../instagram_connect/presentation/viewmodels/instagram_connect_view_model.dart';
import '../../domain/featured_post.dart';
import '../featured_posts_text.dart';
import '../viewmodels/featured_posts_view_model.dart';
import '../widgets/featured_post_buttons.dart';
import '../widgets/featured_post_icon.dart';
import '../widgets/personal_account_notice.dart';
import '../widgets/post_row.dart';
import '../widgets/post_sheet.dart';

/// 대표 게시물(캔버스 M19G6Empty·Full·Sheet·Personal). 가게 사장님에게 가장 먼저 보이는 게시물 최대 4개를 인스타그램이나
/// 사진첩에서 골라 담고, 꾹 눌러 끌어 순서를 바꾼다. 바뀐 것은 `저장하기`를 눌러야 서버에 한 번에 저장된다(1번이 카드 첫 장).
class FeaturedPostsPage extends ConsumerStatefulWidget {
  const FeaturedPostsPage({super.key});

  @override
  ConsumerState<FeaturedPostsPage> createState() => _FeaturedPostsPageState();
}

enum _LeaveChoice { save, discard }

class _FeaturedPostsPageState extends ConsumerState<FeaturedPostsPage> {
  /// 시트가 열려 있는 동안 라임 고리를 두를 칸.
  int? _openedIndex;

  FeaturedPostsViewModel get _vm =>
      ref.read(featuredPostsViewModelProvider.notifier);

  void _back() {
    if (Navigator.of(context).canPop()) {
      // maybePop이어야 바뀐 것이 있을 때 PopScope가 가로채 저장 여부를 묻는다.
      Navigator.of(context).maybePop();
    } else {
      context.go(AppRoutes.creator);
    }
  }

  Future<void> _askLeave() async {
    final choice = await showModalBottomSheet<_LeaveChoice>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.colors.scrim.withValues(alpha: 0.4),
      elevation: 0,
      showDragHandle: false,
      builder: (context) => const _LeaveSheet(),
    );
    if (!mounted || choice == null) return;
    if (choice == _LeaveChoice.save) {
      if (await _vm.save() && mounted) context.pop();
    } else {
      context.pop();
    }
  }

  Future<void> _save() async {
    if (await _vm.save() && mounted) context.pop();
  }

  Future<void> _fromInstagram({int? replaceIndex}) async {
    final state = ref.read(featuredPostsViewModelProvider).value;
    if (state == null) return;
    if (!state.instagramConnected) {
      // 연동하지 않았으면 고르기 대신 연동 화면이 열린다(설계 7.2).
      await context.push(AppRoutes.creatorInstagram);
      if (mounted) await _vm.refreshInstagram();
      return;
    }
    final drafts = await context.push<List<FeaturedPost>>(
      AppRoutes.creatorFeaturedPostsPick,
      extra: replaceIndex != null,
    );
    if (!mounted || drafts == null || drafts.isEmpty) return;
    if (replaceIndex != null) {
      _vm.replaceAt(replaceIndex, drafts.first);
    } else {
      _vm.addAll(drafts);
    }
  }

  Future<void> _fromGallery({int? replaceIndex}) async {
    // 서버 사진 한도(5MB)를 넘지 않게 고르는 쪽에서 긴 변 2048·품질 85로 줄인다.
    final photo = await ref
        .read(photoPickerProvider)
        .pick(
          maxSide: FeaturedPostLimits.photoMaxSide,
          quality: FeaturedPostLimits.photoQuality,
        );
    if (!mounted || photo == null) return;
    final post = await context.push<FeaturedPost>(
      AppRoutes.creatorFeaturedPostsCompose,
      extra: photo,
    );
    if (!mounted || post == null) return;
    if (replaceIndex != null) {
      _vm.replaceAt(replaceIndex, post);
    } else {
      _vm.addAll([post]);
    }
  }

  Future<void> _openSheet(int index) async {
    setState(() => _openedIndex = index);
    final action = await showPostSheet(
      context,
      number: index + 1,
      canMoveToFront: index > 0,
    );
    if (!mounted) return;
    setState(() => _openedIndex = null);
    switch (action) {
      case PostSheetAction.replaceFromInstagram:
        await _fromInstagram(replaceIndex: index);
      case PostSheetAction.replaceFromGallery:
        await _fromGallery(replaceIndex: index);
      case PostSheetAction.moveToFront:
        _vm.moveToFront(index);
      case PostSheetAction.remove:
        _vm.removeAt(index);
      case null:
        break;
    }
  }

  Future<void> _showHowTo() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    builder: (context) => const _HowToSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(featuredPostsViewModelProvider);
    final value = async.value;
    final personalRejected = ref.watch(instagramPersonalAccountProvider);

    return PopScope(
      canPop: !(value?.dirty ?? false),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askLeave();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: switch (async) {
            AsyncData(:final value) => _Body(
              state: value,
              personal: !value.instagramConnected && personalRejected,
              openedIndex: _openedIndex,
              onBack: _back,
              onTapPost: _openSheet,
              onReorder: _vm.reorder,
              onSave: _save,
              onFromInstagram: _fromInstagram,
              onFromGallery: _fromGallery,
              onHowTo: _showHowTo,
            ),
            AsyncError() => Column(
              children: [
                CoraPageHeader(extent: 64, onBack: _back),
                Expanded(
                  child: CoraStateView.loadFailed(
                    title: FeaturedPostsText.loadFailed,
                    onRetry: () =>
                        ref.invalidate(featuredPostsViewModelProvider),
                  ),
                ),
              ],
            ),
            _ => Column(
              children: [
                CoraPageHeader(extent: 64, onBack: _back),
                const Expanded(child: CoraStateView.loading()),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.personal,
    required this.openedIndex,
    required this.onBack,
    required this.onTapPost,
    required this.onReorder,
    required this.onSave,
    required this.onFromInstagram,
    required this.onFromGallery,
    required this.onHowTo,
  });

  final FeaturedPostsState state;
  final bool personal;
  final int? openedIndex;
  final VoidCallback onBack;
  final ValueChanged<int> onTapPost;
  final void Function(int from, int to) onReorder;
  final VoidCallback onSave;
  final Future<void> Function({int? replaceIndex}) onFromInstagram;
  final Future<void> Function({int? replaceIndex}) onFromGallery;
  final VoidCallback onHowTo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = state.items;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final canAdd = items.length < FeaturedPostLimits.maxPosts;
    final dirty = state.dirty;
    final busy = state.saving;

    Widget hint() {
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Text(
            FeaturedPostsText.emptyHint,
            textAlign: TextAlign.center,
            style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
          ),
        );
      }
      // 개인 계정 화면(캔버스 M19G6Personal)에는 끌기 안내가 없다. 안내 상자가 자리를 차지해서다.
      if (items.length < 2 || personal) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            FeaturedPostIcon(
              FeaturedPostGlyph.grip,
              size: 16,
              color: c.textSecondary,
            ),
            Flexible(
              child: Text(
                FeaturedPostsText.reorderHint,
                textAlign: TextAlign.center,
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 저장하기가 위에 있으면 고르기 버튼은 보조 버튼 한 줄로 내려앉는다(캔버스 밖).
    final sourceButtons = <Widget>[
      if (canAdd && personal) ...[
        FeaturedPostButton(
          label: FeaturedPostsText.fromGallery,
          glyph: FeaturedPostGlyph.gallery,
          hot: !dirty,
          onPressed: busy ? null : onFromGallery,
        ),
        FeaturedPostButton(
          label: FeaturedPostsText.personalHowTo,
          onPressed: onHowTo,
        ),
      ] else if (canAdd && !dirty) ...[
        FeaturedPostButton(
          label: FeaturedPostsText.fromInstagram,
          glyph: FeaturedPostGlyph.instagram,
          iconStroke: 2.2,
          hot: true,
          onPressed: onFromInstagram,
        ),
        FeaturedPostButton(
          label: FeaturedPostsText.fromGallery,
          glyph: FeaturedPostGlyph.gallery,
          onPressed: onFromGallery,
        ),
      ] else if (canAdd)
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FeaturedPostButton(
                label: FeaturedPostsText.fromInstagram,
                glyph: FeaturedPostGlyph.instagram,
                onPressed: busy ? null : onFromInstagram,
              ),
            ),
            Expanded(
              child: FeaturedPostButton(
                label: FeaturedPostsText.fromGallery,
                glyph: FeaturedPostGlyph.gallery,
                onPressed: busy ? null : onFromGallery,
              ),
            ),
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoraPageHeader(
          extent: 64,
          title: FeaturedPostsText.title,
          onBack: onBack,
          trailing: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              FeaturedPostsText.counter(items.length),
              style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (personal)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PersonalAccountNotice(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      FeaturedPostsText.intro,
                      style: CoraTextStyles.meta.copyWith(
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, personal ? 12 : 14, 16, 0),
                  child: FeaturedPostGrid(
                    items: items,
                    selectedIndex: openedIndex,
                    cellHeight: personal
                        ? FeaturedPostGrid.personalCellHeight
                        : FeaturedPostGrid.defaultCellHeight,
                    onTap: onTapPost,
                    onReorder: onReorder,
                  ),
                ),
                hint(),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(color: c.text),
                    ),
                  ),
                ),
              if (dirty)
                CoraPrimaryButton(
                  label: FeaturedPostsText.save,
                  look: CoraPrimaryButtonLook.accent,
                  onPressed: busy ? null : onSave,
                ),
              ...sourceButtons,
            ],
          ),
        ),
      ],
    );
  }
}

/// 바뀐 것이 있는 채로 나갈 때 묻는 시트(캔버스 밖, 설계 7.1). 시트 밖을 누르면 머문다.
class _LeaveSheet extends StatelessWidget {
  const _LeaveSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Semantics(
                header: true,
                child: Text(
                  FeaturedPostsText.leaveAsk,
                  style: CoraTextStyles.heading.copyWith(color: c.text),
                ),
              ),
            ),
            CoraPrimaryButton(
              label: FeaturedPostsText.save,
              look: CoraPrimaryButtonLook.accent,
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.save),
            ),
            FeaturedPostButton(
              label: FeaturedPostsText.leaveDiscard,
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.discard),
            ),
          ],
        ),
      ),
    );
  }
}

/// `프로페셔널 계정으로 바꾸는 방법` 안내 시트(캔버스 밖, 설계 7.4).
class _HowToSheet extends StatelessWidget {
  const _HowToSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      FeaturedPostsText.howToTitle,
                      style: CoraTextStyles.heading.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FeaturedPostsText.howToSteps,
                    style: CoraTextStyles.bodySmall.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FeaturedPostButton(
              label: FeaturedPostsText.howToClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/share/share_launcher.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_info_tile.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../domain/my_store.dart';
import '../../domain/store_page_copy.dart';
import '../../domain/store_repository.dart';
import '../viewmodels/my_store_view_model.dart';
import '../viewmodels/store_edit_view_model.dart' show StoreTextField;
import '../widgets/store_icons.dart';
import '../widgets/tags_edit_sheet.dart';
import 'store_edit_page.dart';

/// A3 자동 생성된 가게 페이지(NStorePage / DarkNStorePage), 등록 2/3.
///
/// 링크나 직접 입력으로 만든 가게를 크리에이터에게 보이는 모양으로 보여 준다. 항목을 누르면 그 항목을
/// 고치고, 소개 상자를 누르면 꼬리표·자주 한 말·모집 한 줄을 고친다. 아래 두 버튼은 `AI로 직접 제작`
/// (A4)과 `크리에이터 모집`(모집 조건 1단계)이다. 가게 이름이나 시·도가 없으면 두 버튼이 그 안내를
/// 보이고 고치는 화면을 연다. [onboarding]이 false이면 등록이 끝난 뒤 사장님 홈에서 연 `가게 페이지`라
/// 단계 머리글(`2 / 3`·진행 막대)이 없다.
class StorePagePreviewPage extends ConsumerStatefulWidget {
  const StorePagePreviewPage({super.key, this.onboarding = true});

  final bool onboarding;

  static const autoFilledChip = '링크에서 자동으로 만들었어요';
  static const publicPage = '· 공개 페이지';
  static const share = '공유';
  static const introTitle = '이런 가게가 맞나요? · 탭해서 고치기';
  static const fixIntro = '고치기';
  static const makeWithAi = 'AI로 직접 제작';
  static const recruit = '크리에이터 모집';
  static const nameMissing = '가게 이름을 넣어 주세요.';
  static const regionMissing = '가게 지역을 골라 주세요.';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  ConsumerState<StorePagePreviewPage> createState() =>
      _StorePagePreviewPageState();
}

enum _Next { ai, recruit }

class _StorePagePreviewPageState extends ConsumerState<StorePagePreviewPage> {
  bool _advancing = false;
  bool _failed = false;

  /// 이름이나 지역이 없는 채로 버튼을 눌렀다. 채우면 안내가 사라진다.
  bool _pressedIncomplete = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        widget.onboarding ? AppRoutes.storeOnboardingLinks : AppRoutes.store,
      );
    }
  }

  void _edit([StoreTextField? field]) {
    context.push(
      AppRoutes.storeOnboardingEdit,
      extra: StoreEditArgs(focusField: field),
    );
  }

  /// 공개된 가게의 주소만 공유한다(등록 중에는 아직 열리지 않는 주소다).
  Future<void> _share(MyStore store) async {
    final url = store.publicUrl;
    if (url == null || !store.isPublished) return;
    try {
      await ref.read(shareLauncherProvider).shareText('https://$url');
    } on Exception {
      // 공유 창을 못 열어도 화면에는 영향이 없다. 다시 누르면 된다.
    }
  }

  Future<void> _go(MyStore store, _Next next) async {
    if (!store.hasName || !store.hasRegion) {
      setState(() => _pressedIncomplete = true);
      _edit();
      return;
    }
    // 공개된 가게는 등록 단계가 이미 끝났다.
    final step = next == _Next.ai
        ? StoreOnboardingStep.drafts
        : StoreOnboardingStep.terms;
    if (!store.isPublished) {
      setState(() {
        _advancing = true;
        _failed = false;
      });
      try {
        await ref.read(myStoreViewModelProvider.notifier).advance(step);
      } on StoreFailure {
        if (mounted) {
          setState(() {
            _advancing = false;
            _failed = true;
          });
        }
        return;
      }
      if (!mounted) return;
      setState(() => _advancing = false);
    }
    switch (next) {
      case _Next.ai:
        widget.onboarding
            ? context.push(
                AppRoutes.storeOnboardingDrafts,
                extra: AppRoutes.stacked,
              )
            : context.push(AppRoutes.storeDrafts);
      case _Next.recruit:
        context.push(AppRoutes.storeOnboardingTerms, extra: AppRoutes.stacked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = ref.watch(myStoreViewModelProvider).value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: store == null
            ? const SizedBox.expand()
            : Column(
                children: [
                  CoraStepHeader(
                    pageLabel: widget.onboarding ? '가게 등록' : '가게 페이지',
                    step: 2,
                    total: 3,
                    showProgress: widget.onboarding,
                    onBack: _back,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _Content(
                        store: store,
                        onEditField: _edit,
                        onEditIntro: () => showTagsEditSheet(context),
                        onShare: () => _share(store),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _warning(store, c),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              flex: 10,
                              child: CoraSecondaryButton(
                                label: StorePagePreviewPage.makeWithAi,
                                tone: CoraSecondaryTone.subtle,
                                fitLabel: true,
                                horizontalPadding: 0,
                                onPressed: _advancing
                                    ? null
                                    : () => _go(store, _Next.ai),
                              ),
                            ),
                            Expanded(
                              flex: 16,
                              child: CoraPrimaryButton(
                                label: StorePagePreviewPage.recruit,
                                look: CoraPrimaryButtonLook.accent,
                                onPressed: _advancing
                                    ? null
                                    : () => _go(store, _Next.recruit),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 다음으로 갈 수 없는 이유를 버튼 위에 한 줄로 알린다.
  Widget _warning(MyStore store, CoraColors c) {
    final text = _failed
        ? StorePagePreviewPage.saveFailed
        : !_pressedIncomplete
        ? null
        : !store.hasName
        ? StorePagePreviewPage.nameMissing
        : !store.hasRegion
        ? StorePagePreviewPage.regionMissing
        : null;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: CoraTextStyles.meta.copyWith(color: c.text),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.store,
    required this.onEditField,
    required this.onEditIntro,
    required this.onShare,
  });

  final MyStore store;
  final void Function(StoreTextField field) onEditField;
  final VoidCallback onEditIntro;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = store.publicUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _Cover(store: store),
        ),
        if (url != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _AddressRow(
              url: url,
              shareEnabled: store.isPublished,
              onShare: onShare,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _Grid(store: store, onEdit: onEditField),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          // 아래 글은 ExcludeSemantics로 가리므로 읽히도록 제목과 내용을 이 노드에 준다.
          child: Semantics(
            container: true,
            button: true,
            label: StorePagePreviewPage.introTitle,
            value: StorePageCopy.introLine(store),
            onTap: onEditIntro,
            child: ExcludeSemantics(
              child: CoraPressable(
                onTap: onEditIntro,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(CoraRadius.field),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                StorePagePreviewPage.introTitle,
                                style: CoraTextStyles.caption.copyWith(
                                  color: c.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SoftButton(
                              label: StorePagePreviewPage.fixIntro,
                              onTap: onEditIntro,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          StorePageCopy.introLine(store),
                          style: CoraTextStyles.body.copyWith(
                            height: 1.55,
                            color: c.text,
                          ),
                        ),
                      ],
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

/// 공개 주소 줄(NStorePage): 모서리 16, `surface` 바탕, 안쪽 10/14, 13. 왼쪽에 `주소 · 공개 페이지`
/// (뒤쪽 보조색), 오른쪽에 `공유`(500). 공유는 공개된 뒤에만 켜지고 등록 중에는 흐리다.
class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.url,
    required this.shareEnabled,
    required this.onShare,
  });

  final String url;
  final bool shareEnabled;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = CoraTextStyles.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.text,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Text.rich(
                TextSpan(
                  text: '$url ',
                  style: base,
                  children: [
                    TextSpan(
                      text: StorePagePreviewPage.publicPage,
                      style: base.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            container: true,
            button: true,
            enabled: shareEnabled,
            label: StorePagePreviewPage.share,
            onTap: shareEnabled ? onShare : null,
            child: ExcludeSemantics(
              child: CoraPressable(
                onTap: shareEnabled ? onShare : null,
                child: Opacity(
                  opacity: shareEnabled ? 1 : 0.3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
                    child: Text(
                      StorePagePreviewPage.share,
                      style: CoraTextStyles.label.copyWith(color: c.text),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 사진 위에 얹는 표지(NStorePage): 높이 300, 모서리 28, 아래 160은 어둡게 눕히고, 왼쪽 위에
/// `링크에서 자동으로 만들었어요` 알약, 왼쪽 아래에 `업종, 동네`와 가게 이름.
class _Cover extends StatelessWidget {
  const _Cover({required this.store});

  final MyStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = store.categoryAndNeighborhood;
    final name = (store.name ?? '').trim();
    return Semantics(
      container: true,
      image: true,
      label: '가게 대표 사진',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CoraRadius.xxl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoraNetworkPhoto(
                  url: store.coverPhotoUrl,
                  // CSS object-position: 50% 45%.
                  alignment: const Alignment(0, -0.1),
                  background: c.coverPlaceholder,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.photoScrim.withValues(alpha: 0),
                          c.photoScrim.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                if (store.wasAutoFilled)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.photoChip,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StoreIcon(StoreIconPainter.sparkle(c.text)),
                            const SizedBox(width: 6),
                            Text(
                              StorePagePreviewPage.autoFilledChip,
                              style: CoraTextStyles.caption.copyWith(
                                color: c.onPhotoChip,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (line != null)
                        Text(
                          line,
                          style: CoraTextStyles.meta.copyWith(
                            color: c.onPhotoSecondary,
                          ),
                        ),
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: CoraTextStyles.title.copyWith(
                            letterSpacing: -1.04,
                            height: 1.448,
                            color: c.onPhoto,
                          ),
                        ),
                      ],
                    ],
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

/// 항목 칸 2열(NStorePage `dl`): 칸 사이 8. 칸을 누르면 그 항목을 고치는 화면이 열린다.
class _Grid extends StatelessWidget {
  const _Grid({required this.store, required this.onEdit});

  final MyStore store;
  final void Function(StoreTextField field) onEdit;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      CoraInfoTile(
        label: '대표 메뉴',
        value: store.signatureMenu,
        onTap: () => onEdit(StoreTextField.signatureMenu),
      ),
      CoraInfoTile(
        label: '영업시간',
        value: store.hours,
        onTap: () => onEdit(StoreTextField.hours),
      ),
      CoraInfoTile(
        label: '좌석',
        value: store.seats,
        onTap: () => onEdit(StoreTextField.seats),
      ),
      CoraInfoTile(
        label: '찍기 좋은 시간',
        value: store.bestShootingTime,
        onTap: () => onEdit(StoreTextField.bestShootingTime),
      ),
    ];
    return Column(
      spacing: 8,
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Expanded(child: tiles[i]),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
      ],
    );
  }
}

/// 카드 안의 작은 알약 버튼(NStorePage `고치기`): 높이 32, 안쪽 12, 12/500, 연한 라임 채움.
class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.label, required this.onTap});

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
          child: SizedBox(
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.softAction,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: CoraTextStyles.caption.copyWith(
                      color: c.onSoftAction,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

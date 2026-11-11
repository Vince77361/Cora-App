import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
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
import '../../domain/store_repository.dart';
import '../viewmodels/my_store_view_model.dart';
import '../widgets/store_icons.dart';
import 'store_edit_page.dart';

/// A3 자동 생성된 가게 페이지(NStorePage / DarkNStorePage), 등록 2/3.
///
/// 링크에서 만든 가게를 크리에이터에게 보이는 모양으로 보여 주고, 고치거나 이대로 다음으로 간다.
/// `이대로 다음`은 가게 이름과 시·도가 있어야 켜진다. [onboarding]이 false이면 등록이 끝난 뒤
/// 사장님 홈에서 연 `가게 페이지`라 단계 머리글(`2 / 3`·진행 막대)과 `이대로 다음`이 없고
/// `정보 고치기` 버튼 하나만 있다.
class StorePagePreviewPage extends ConsumerStatefulWidget {
  const StorePagePreviewPage({super.key, this.onboarding = true});

  final bool onboarding;

  static const autoFilledChip = '링크에서 자동으로 만들었어요';
  static const introTitle = '크리에이터에게 보여줄 소개';
  static const fixIntro = '고치기';
  static const fixInfo = '정보 고치기';
  static const next = '이대로 다음';
  static const nameMissing = '가게 이름을 넣어 주세요.';
  static const regionMissing = '가게 지역을 골라 주세요.';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  ConsumerState<StorePagePreviewPage> createState() =>
      _StorePagePreviewPageState();
}

class _StorePagePreviewPageState extends ConsumerState<StorePagePreviewPage> {
  bool _advancing = false;
  bool _failed = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        widget.onboarding ? AppRoutes.storeOnboardingLinks : AppRoutes.store,
      );
    }
  }

  void _edit({bool focusIntro = false}) {
    context.push(
      AppRoutes.storeOnboardingEdit,
      extra: StoreEditArgs(focusIntro: focusIntro),
    );
  }

  Future<void> _next() async {
    setState(() {
      _advancing = true;
      _failed = false;
    });
    try {
      await ref
          .read(myStoreViewModelProvider.notifier)
          .advance(StoreOnboardingStep.drafts);
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
    context.push(AppRoutes.storeOnboardingDrafts, extra: AppRoutes.stacked);
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
                    title: widget.onboarding ? '가게 등록' : '가게 페이지',
                    step: 2,
                    total: 3,
                    showProgress: widget.onboarding,
                    onBack: _back,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _Content(store: store, onFixIntro: _fixIntro),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.onboarding)
                          CoraPrimaryButton(
                            label: StorePagePreviewPage.fixInfo,
                            look: CoraPrimaryButtonLook.accent,
                            onPressed: _edit,
                          )
                        else ...[
                          _warning(store, c),
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                flex: 10,
                                child: CoraSecondaryButton(
                                  label: StorePagePreviewPage.fixInfo,
                                  onPressed: _edit,
                                ),
                              ),
                              Expanded(
                                flex: 16,
                                child: CoraPrimaryButton(
                                  label: StorePagePreviewPage.next,
                                  look: CoraPrimaryButtonLook.accent,
                                  onPressed:
                                      store.hasName &&
                                          store.hasRegion &&
                                          !_advancing
                                      ? _next
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _fixIntro() => _edit(focusIntro: true);

  /// 다음으로 갈 수 없는 이유를 버튼 위에 한 줄로 알린다.
  Widget _warning(MyStore store, CoraColors c) {
    final text = _failed
        ? StorePagePreviewPage.saveFailed
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
  const _Content({required this.store, required this.onFixIntro});

  final MyStore store;
  final VoidCallback onFixIntro;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final intro = (store.intro ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _Cover(store: store),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _Grid(store: store),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          StorePagePreviewPage.introTitle,
                          style: CoraTextStyles.caption.copyWith(color: c.text),
                        ),
                      ),
                      _SoftButton(
                        label: StorePagePreviewPage.fixIntro,
                        onTap: onFixIntro,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    intro.isEmpty ? CoraInfoTile.emptyValue : intro,
                    style: CoraTextStyles.body.copyWith(
                      height: 1.55,
                      color: intro.isEmpty ? c.textSecondary : c.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// 항목 칸 2열(NStorePage `dl`): 칸 사이 8. 위 네 칸은 캔버스의 항목이고, `업종 분류`와 `지역`은
/// 공통 모델이 더한 항목이다(고치기는 `정보 고치기`에서).
class _Grid extends StatelessWidget {
  const _Grid({required this.store});

  final MyStore store;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      CoraInfoTile(label: '대표 메뉴', value: store.signatureMenu),
      CoraInfoTile(label: '영업시간', value: store.hours),
      CoraInfoTile(label: '좌석', value: store.seats),
      CoraInfoTile(label: '찍기 좋은 시간', value: store.bestShootingTime),
      CoraInfoTile(label: '업종 분류', value: store.industry.label),
      CoraInfoTile(label: '지역', value: store.regionText),
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

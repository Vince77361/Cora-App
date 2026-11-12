import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_segmented_tabs.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../domain/content_draft.dart';
import '../../domain/my_store.dart';
import '../../domain/store_repository.dart';
import '../viewmodels/content_drafts_view_model.dart';
import '../viewmodels/my_store_view_model.dart';

/// A4 AI 콘텐츠 초안(NStoreAI / DarkNStoreAI), 등록 3/3.
///
/// 탭 세 개(카드뉴스, 릴스 대본, 블로그 글)마다 장면 세 장과 본문 글이 있다. `다시 만들기`는 지금
/// 보고 있는 탭만 다시 만든다. [onboarding]이 false이면 등록이 끝난 뒤 사장님 홈에서 다시 연
/// 화면이라 머리글의 `3 / 3`·진행 막대와 `저장하고 오퍼 만들기`가 없다.
class ContentDraftsPage extends ConsumerStatefulWidget {
  const ContentDraftsPage({super.key, this.onboarding = true});

  final bool onboarding;

  static const title = '가게 계정에 올릴\n초안도 만들었어요.';
  static const subtitle = '가게 페이지 정보로 AI가 썼어요. 그대로 올려도, 고쳐서 올려도 돼요.';
  static const regenerate = '다시 만들기';
  static const saveAndOffer = '저장하고 오퍼 만들기';
  static const copy = '복사';
  static const copied = '복사했어요.';
  static const limitReached = '오늘은 더 만들 수 없어요.';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '초안을 불러오지 못했어요.';
  static const regenerateFailed = '다시 만들지 못했어요. 다시 시도해 주세요.';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';
  static const writing = 'AI가 초안을 쓰는 중이에요.';

  /// 복사했다는 안내를 보여 주는 시간.
  static const copiedFor = Duration(seconds: 2);

  @override
  ConsumerState<ContentDraftsPage> createState() => _ContentDraftsPageState();
}

class _ContentDraftsPageState extends ConsumerState<ContentDraftsPage> {
  bool _advancing = false;
  bool _saveFailed = false;
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        widget.onboarding ? AppRoutes.storeOnboardingPage : AppRoutes.store,
      );
    }
  }

  Future<void> _copy(String body) async {
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(ContentDraftsPage.copiedFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _saveAndOffer() async {
    setState(() {
      _advancing = true;
      _saveFailed = false;
    });
    try {
      await ref
          .read(myStoreViewModelProvider.notifier)
          .advance(StoreOnboardingStep.terms);
    } on StoreFailure {
      if (mounted) {
        setState(() {
          _advancing = false;
          _saveFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _advancing = false);
    context.push(AppRoutes.storeOnboardingTerms, extra: AppRoutes.stacked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentDraftsViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CoraStepHeader(
              pageLabel: widget.onboarding ? '가게 등록' : 'AI 글',
              step: 3,
              total: 3,
              showProgress: widget.onboarding,
              onBack: _back,
            ),
            Expanded(
              child: state.when(
                loading: () => const _Writing(),
                error: (_, _) => _loadFailed(),
                data: _content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 초안을 불러오지 못했을 때. 등록 중이면 초안 없이도 다음 단계로 갈 수 있어야 해서(초안은 나중에
  /// 사장님 홈의 `AI 글`에서 다시 볼 수 있다) `저장하고 오퍼 만들기`를 그대로 둔다.
  Widget _loadFailed() {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Column(
      children: [
        Expanded(
          child: CoraStateView.loadFailed(
            title: ContentDraftsPage.loadFailed,
            onRetry: () => ref.invalidate(contentDraftsViewModelProvider),
          ),
        ),
        if (widget.onboarding)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_saveFailed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        ContentDraftsPage.saveFailed,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(color: c.text),
                      ),
                    ),
                  ),
                CoraPrimaryButton(
                  label: ContentDraftsPage.saveAndOffer,
                  look: CoraPrimaryButtonLook.accent,
                  onPressed: _advancing ? null : _saveAndOffer,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _content(ContentDraftsState state) {
    final c = context.colors;
    final vm = ref.read(contentDraftsViewModelProvider.notifier);
    final cover = ref.watch(myStoreViewModelProvider).value?.coverPhotoUrl;
    final draft = state.current;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final note = _saveFailed
        ? ContentDraftsPage.saveFailed
        : state.regenerateFailed
        ? ContentDraftsPage.regenerateFailed
        : state.limitReached
        ? ContentDraftsPage.limitReached
        : null;
    final again = CoraSecondaryButton(
      label: ContentDraftsPage.regenerate,
      tone: CoraSecondaryTone.muted,
      onPressed: state.canRegenerate ? vm.regenerate : null,
    );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                        ContentDraftsPage.title,
                        style: CoraTextStyles.title.copyWith(
                          letterSpacing: -1.3,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ContentDraftsPage.subtitle,
                        style: CoraTextStyles.bodySmall.copyWith(
                          height: 1.6,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: CoraSegmentedTabs(
                    labels: [for (final d in state.drafts) d.kind.tabLabel],
                    selected: state.selected,
                    onChanged: vm.select,
                    horizontalPadding: 16,
                    textStyle: CoraTextStyles.bodyLarge.copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    key: ValueKey('drafts.slides.${draft.kind.name}'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: draft.scenes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _Slide(
                      scene: draft.scenes[i],
                      coverUrl: cover,
                      tone: (i + state.versionOf(draft.kind)) % 2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _BodyBox(
                    label: draft.bodyLabel,
                    body: draft.body,
                    copied: _copied,
                    onCopy: () => _copy(draft.body),
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
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      note,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(color: c.text),
                    ),
                  ),
                ),
              if (widget.onboarding)
                Row(
                  spacing: 8,
                  children: [
                    Expanded(flex: 10, child: again),
                    Expanded(
                      flex: 16,
                      child: CoraPrimaryButton(
                        label: ContentDraftsPage.saveAndOffer,
                        look: CoraPrimaryButtonLook.accent,
                        onPressed: _advancing ? null : _saveAndOffer,
                      ),
                    ),
                  ],
                )
              else
                again,
            ],
          ),
        ),
      ],
    );
  }
}

class _Writing extends StatelessWidget {
  const _Writing();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Text(
          ContentDraftsPage.writing,
          style: CoraTextStyles.body.copyWith(color: c.textSecondary),
        ),
      ),
    );
  }
}

/// 슬라이드 한 장(NStoreAI): 200 x 250, 모서리 22. 사진 장면은 가게 대표 사진 위에 아래 140을
/// 어둡게 눕히고, 아닌 장면은 두 톤을 번갈아 쓴다. 왼쪽 위 작은 글자, 왼쪽 아래 큰 글자.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.scene,
    required this.coverUrl,
    required this.tone,
  });

  final DraftScene scene;
  final String? coverUrl;

  /// 사진이 없는 장면의 톤 번호(0 또는 1).
  final int tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photo = scene.usesPhoto;
    final background = photo
        ? c.coverPlaceholder
        : (tone == 0 ? c.slideTint : c.slideNeutral);
    final foreground = photo
        ? c.onSlidePhoto
        : (tone == 0 ? c.onSlideTint : c.onSlideNeutral);
    return SizedBox(
      width: 200,
      height: 250,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo) ...[
                CoraNetworkPhoto(
                  url: coverUrl,
                  alignment: const Alignment(0, -0.1),
                  background: c.coverPlaceholder,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.photoScrim.withValues(alpha: 0),
                          c.photoScrim.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                left: 14,
                top: 12,
                child: Text(
                  scene.label,
                  style: CoraTextStyles.caption.copyWith(color: foreground),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  scene.text,
                  style: CoraTextStyles.title.copyWith(
                    fontSize: 19,
                    letterSpacing: -0.76,
                    color: foreground,
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

/// 본문 상자(NStoreAI): 모서리 20, `surface` 바탕, 안쪽 14/16. 위 줄에 이름(12)과 `복사`, 6 아래에
/// 본문(14, 줄 높이 1.6, 줄바꿈 유지). 복사 버튼은 캔버스에 없는 부분이라 NStorePage의 작은 알약
/// 버튼 모양을 따랐다.
class _BodyBox extends StatelessWidget {
  const _BodyBox({
    required this.label,
    required this.body,
    required this.copied,
    required this.onCopy,
  });

  final String label;
  final String body;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
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
                    label,
                    style: CoraTextStyles.fieldLabel.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Semantics(
                  container: true,
                  button: true,
                  liveRegion: copied,
                  label: copied
                      ? ContentDraftsPage.copied
                      : ContentDraftsPage.copy,
                  onTap: onCopy,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: onCopy,
                      child: SizedBox(
                        height: 32,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.softAction,
                            borderRadius: BorderRadius.circular(
                              CoraRadius.pill,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                copied
                                    ? ContentDraftsPage.copied
                                    : ContentDraftsPage.copy,
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
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: CoraTextStyles.bodySmall.copyWith(
                height: 1.6,
                color: c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

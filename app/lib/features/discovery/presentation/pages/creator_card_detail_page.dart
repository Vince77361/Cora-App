import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../domain/discovery_card.dart';
import '../discovery_text.dart';
import '../viewmodels/brand_discovery_view_model.dart';
import '../widgets/like_note_sheet.dart';

/// 크리에이터 상세(임시: 7번 계획의 B5가 대신한다). 카드를 누르면 열리고, 카드의 내용을 크게 보여 준다:
/// 사진, 이름, 콘텐츠 한 줄, 꼬리표, `잘 맞는 점`. 아래 `넘기기`와 `관심 보내기`는 01의 결정과 같은
/// 서버 동작이고, 보내면 01로 돌아가 알림 문구가 뜬다. 카드의 사진이 `Hero`로 이어진다.
///
/// 카드는 01이 `extra`로 넘긴다. 없으면(깊은 링크 등) 오늘 목록에서 [creatorId]를 찾는다.
class CreatorCardDetailPage extends ConsumerStatefulWidget {
  const CreatorCardDetailPage({super.key, required this.creatorId, this.card});

  final String creatorId;
  final CreatorCard? card;

  @visibleForTesting
  static const photoHeight = 420.0;

  @override
  ConsumerState<CreatorCardDetailPage> createState() =>
      _CreatorCardDetailPageState();
}

class _CreatorCardDetailPageState extends ConsumerState<CreatorCardDetailPage> {
  bool _busy = false;
  String? _error;

  Future<void> _decide(
    CreatorCard card,
    SwipeOutcome outcome, {
    String? note,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(brandDiscoveryViewModelProvider.notifier)
          .decide(card, outcome, note: note);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = DiscoveryTexts.retryLater;
      });
      return;
    }
    if (mounted) context.pop();
  }

  Future<void> _like(CreatorCard card) async {
    final result = await showLikeNoteSheet(context);
    if (result == null || !mounted) return;
    await _decide(card, SwipeOutcome.like, note: result.note);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loaded = ref.watch(brandDiscoveryViewModelProvider).value?.loaded;
    CreatorCard? card = widget.card;
    if (card == null && loaded != null) {
      for (final candidate in loaded) {
        if (candidate.creatorId == widget.creatorId) card = candidate;
      }
    }
    if (card == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: CoraStepHeader.rowHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CoraBackButton(onPressed: _backOrHome),
                  ),
                ),
              ),
              const CoraStateView.empty(title: DiscoveryTexts.loadFailedTitle),
            ],
          ),
        ),
      );
    }
    final shown = card;
    final bottom = math.max(24.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: CreatorCardDetailPage.photoHeight,
                        child: Hero(
                          tag: CoraHeroTag.of('creator', shown.creatorId),
                          child: CoraNetworkPhoto(
                            url: shown.photoUrl,
                            alignment: const Alignment(0, -0.4),
                            background: c.photoPlaceholder,
                          ),
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                          child: CoraBackButton(onPressed: _backOrHome),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shown.displayName,
                          style: CoraTextStyles.title.copyWith(color: c.text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shown.headline ?? DiscoveryTexts.noHeadline,
                          style: CoraTextStyles.bodyLarge.copyWith(
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            Text(
                              DiscoveryTexts.feeBandLabel(shown.feeBand),
                              style: CoraTextStyles.heading.copyWith(
                                color: c.text,
                              ),
                            ),
                            for (final tag in shown.tags)
                              Text(
                                '#$tag',
                                style: CoraTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: c.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        if (shown.reasons.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Semantics(
                            header: true,
                            child: Text(
                              DiscoveryTexts.fitTitle,
                              style: CoraTextStyles.heading.copyWith(
                                color: c.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(
                                  CoraRadius.xl,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final reason in shown.reasons)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          reason.label,
                                          style: CoraTextStyles.body.copyWith(
                                            color: c.text,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: CoraSecondaryButton(
                        label: DiscoveryTexts.detailPass,
                        onPressed: _busy
                            ? null
                            : () => _decide(shown, SwipeOutcome.pass),
                      ),
                    ),
                    Expanded(
                      child: CoraPrimaryButton(
                        label: DiscoveryTexts.detailLike,
                        look: CoraPrimaryButtonLook.accent,
                        onPressed: _busy ? null : () => _like(shown),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _backOrHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.brand);
    }
  }
}

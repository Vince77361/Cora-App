import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/text/count_and_date_labels.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../offer_terms/presentation/offer_terms_text.dart' show won;
import '../../../store_browse/presentation/widgets/photo_overlays.dart';
import '../../domain/campaign_detail.dart';
import '../../domain/discovery_card.dart';
import '../creator_discovery_text.dart';
import '../discovery_text.dart';
import '../viewmodels/campaign_detail_view_model.dart';
import '../viewmodels/creator_discovery_view_model.dart';

/// D1 캠페인 상세(캔버스 NCampaign). 08이나 03에서 캠페인 카드를 누르면 열린다. 사진 위에 브랜드와
/// 캠페인 한 줄, 아래에 제작비와 `나와 잘 맞는 이유`, `꼭 담을 것`, `요구하지 않아요`, `일정`, `제품 사용`이
/// 있고 맨 아래에 `넘기기`와 `관심 보내기`가 붙는다. 두 버튼은 08의 결정과 같은 서버 동작이고, 보내면 앞
/// 화면으로 돌아간다.
///
/// 카드는 08이 `extra`로 넘긴다. 있으면 상세를 읽는 동안에도 사진과 제목이 먼저 보이고 사진이 `Hero`
/// (`campaign:<id>`)로 이어진다.
class CampaignDetailPage extends ConsumerStatefulWidget {
  const CampaignDetailPage({super.key, required this.campaignId, this.card});

  final String campaignId;
  final CampaignCard? card;

  @override
  ConsumerState<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends ConsumerState<CampaignDetailPage> {
  bool _busy = false;
  String? _error;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creator);
    }
  }

  Future<void> _decide(CampaignDetail detail, SwipeOutcome outcome) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // 03에서 열렸다면 08의 뷰모델이 없다. 결정을 보내는 동안은 살려 둔다(자동으로 버려지지 않게).
    final keepAlive = ref.listenManual(
      creatorDiscoveryViewModelProvider,
      (_, _) {},
    );
    try {
      await ref
          .read(creatorDiscoveryViewModelProvider.notifier)
          .decide(detail.asCard, outcome);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = DiscoveryTexts.retryLater;
      });
      return;
    } finally {
      keepAlive.close();
    }
    if (mounted) _back();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = campaignDetailViewModelProvider(widget.campaignId);
    final async = ref.watch(provider);
    final detail = async.value;
    final seed = widget.card;
    final header = detail != null
        ? _HeaderData(
            brandName: detail.brandName,
            tagline: detail.brandTagline,
            headline: detail.headline,
            photoUrl: detail.photoUrl,
          )
        : seed == null
        ? null
        : _HeaderData(
            brandName: seed.brandName,
            tagline: seed.brandTagline,
            headline: seed.headline,
            photoUrl: seed.photoUrl,
          );
    final bottom = math.max(28.0, MediaQuery.viewPaddingOf(context).bottom);

    final Widget content;
    if (detail != null) {
      content = _Body(detail: detail);
    } else if (async.hasError) {
      content = CoraStateView.loadFailed(
        title: CreatorDiscoveryTexts.detailLoadFailedTitle,
        onRetry: () => ref.invalidate(provider),
      );
    } else {
      content = const CoraStateView.loading();
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: header == null
                ? SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: PhotoBackButton(onPressed: _back),
                          ),
                        ),
                        Expanded(child: content),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Stack(
                      children: [
                        _Photo(
                          campaignId: widget.campaignId,
                          data: header,
                          onBack: _back,
                        ),
                        // 사진(높이 260) 위로 흰 면이 24 겹쳐 올라온다.
                        Padding(
                          padding: const EdgeInsets.only(
                            top: _Photo.height - 24,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.background,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: detail != null
                                  ? content
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: content,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (detail != null)
            ColoredBox(
              color: c.background,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                          flex: 10,
                          child: _ActionButton(
                            label: CreatorDiscoveryTexts.pass,
                            background: c.surface,
                            foreground: c.text,
                            style: CoraTextStyles.buttonMedium,
                            onTap: _busy
                                ? null
                                : () => _decide(detail, SwipeOutcome.pass),
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: _ActionButton(
                            label: CreatorDiscoveryTexts.like,
                            background: c.accent,
                            foreground: c.onAccent,
                            style: CoraTextStyles.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            onTap: _busy
                                ? null
                                : () => _decide(detail, SwipeOutcome.like),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderData {
  const _HeaderData({
    required this.brandName,
    required this.tagline,
    required this.headline,
    required this.photoUrl,
  });

  final String brandName;
  final String? tagline;
  final String headline;
  final String? photoUrl;
}

/// 사진(높이 260): 아래 160에 어두운 덮개, 왼쪽 위 뒤로 가기, 아래에 `{브랜드 이름}, {한 줄 소개}`와 캠페인 한 줄.
/// 사진 기준점은 08 카드와 같은 62% 50%다.
class _Photo extends StatelessWidget {
  const _Photo({
    required this.campaignId,
    required this.data,
    required this.onBack,
  });

  final String campaignId;
  final _HeaderData data;
  final VoidCallback onBack;

  static const height = 260.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: '${data.brandName} 대표 사진',
            child: ExcludeSemantics(
              child: Hero(
                tag: CoraHeroTag.of('campaign', campaignId),
                child: CoraNetworkPhoto(
                  url: data.photoUrl,
                  alignment: const Alignment(0.24, 0),
                  background: c.photoPlaceholder,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: CoraSwipeTokens.detailPhotoScrim,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: top + 10,
            child: PhotoBackButton(onPressed: onBack),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CreatorDiscoveryTexts.brandLine(data.brandName, data.tagline),
                  style: CoraTextStyles.meta.copyWith(
                    color: c.onPhotoSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  header: true,
                  child: Text(
                    data.headline,
                    style: CoraTextStyles.display.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.96,
                      color: c.onPhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 사진 아래 흰 면의 내용: 제작비 줄, `나와 잘 맞는 이유`, `꼭 담을 것`·`요구하지 않아요`, `일정`·`제품 사용`.
class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final CampaignDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fit = CreatorDiscoveryTexts.fitText(detail);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 10,
            children: [
              Text(
                won(detail.fee),
                style: CoraTextStyles.display.copyWith(
                  height: 1.448,
                  color: c.text,
                ),
              ),
              Flexible(
                child: Text(
                  CreatorDiscoveryTexts.deliverable(detail.productProvided),
                  style: CoraTextStyles.body.copyWith(
                    height: 1.448,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (fit != null) ...[
            const SizedBox(height: 20),
            _Box(
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      CreatorDiscoveryTexts.fitTitle,
                      style: CoraTextStyles.label.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(fit, style: CoraTextStyles.body.copyWith(color: c.text)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Expanded(
                  child: _ListBox(
                    title: CreatorDiscoveryTexts.mustTitle,
                    items: detail.mustInclude,
                    empty: CreatorDiscoveryTexts.mustEmpty,
                  ),
                ),
                Expanded(
                  child: _ListBox(
                    title: CreatorDiscoveryTexts.notRequiredTitle,
                    items: [for (final r in detail.notRequired) r.label],
                    empty: CreatorDiscoveryTexts.notRequiredEmpty,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Expanded(
                  child: _ValueTile(
                    label: CreatorDiscoveryTexts.scheduleTitle,
                    value: afterDateLabel(
                      detail.startFrom,
                    ),
                  ),
                ),
                Expanded(
                  child: _ValueTile(
                    label: CreatorDiscoveryTexts.trialTitle,
                    value: CreatorDiscoveryTexts.trialValue(detail.trialDays),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double radius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// `꼭 담을 것`, `요구하지 않아요` 상자(캔버스 `<ul>`): 안쪽 14, 모서리 20, 제목 12/500 보조색,
/// 목록은 14px 줄 높이 1.6에 왼쪽 16 들여쓰고 점을 단다. 비면 [empty] 한 줄이다.
class _ListBox extends StatelessWidget {
  const _ListBox({
    required this.title,
    required this.items,
    required this.empty,
  });

  final String title;
  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = CoraTextStyles.bodySmall.copyWith(height: 1.6, color: c.text);
    return _Box(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: CoraTextStyles.caption.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(empty, style: style)
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -12,
                      top: (14 * 1.6 - 5) / 2,
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.text,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 5),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(item, style: style),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// `일정`, `제품 사용` 칸(캔버스 `<dl>`): 안쪽 12/14, 모서리 18, 이름 12px 보조색, 값 15/500, 그 사이 2.
class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Box(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: CoraTextStyles.caption.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아래 버튼(캔버스: 높이 56의 알약, `넘기기`는 flex 1·`surface`, `관심 보내기`는 flex 1.6·라임).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.style,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final TextStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    enabled: onTap != null,
    onTap: onTap,
    child: ExcludeSemantics(
      child: CoraPressable(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

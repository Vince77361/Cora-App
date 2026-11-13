import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/text/josa.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../collaboration/presentation/link_launcher.dart';
import '../../../collaboration/presentation/store_collaboration_text.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../../offers/presentation/pages/send_offer_page.dart';
import '../../../store_home/domain/applicant.dart';
import '../../domain/store_result.dart';
import '../../domain/store_result_repository.dart';
import '../store_result_text.dart';
import '../viewmodels/store_result_view_model.dart';

/// G1 7일 결과(NResult / DarkNResult). 사진 위에 조회수, 우리 가게 평소 게시물과의 비교, 크리에이터 지급과
/// 사장님께 환불, 아래에 `새 오퍼`·`영상 받기`·`다시 만나기`. `집계 출처와 계산 보기`는 F4로 잇는다.
class StoreResultPage extends ConsumerStatefulWidget {
  const StoreResultPage({super.key, required this.collaborationId});

  final String collaborationId;

  static const title = '7일 결과';
  static const comparisonTitle = '우리 가게 평소 게시물 대비';
  static const usualBar = '평소';
  static const nowBar = '이번';

  /// 테스트가 막대 너비를 읽는 열쇠.
  static const usualBarKey = Key('result-bar-usual');
  static const nowBarKey = Key('result-bar-now');
  static const payout = '크리에이터 지급';
  static const refund = '사장님께 환불';
  static const newOffer = '새 오퍼';
  static const receiveVideo = '영상 받기';
  static const sourceLink = '집계 출처와 계산 보기';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '7일 결과를 불러오지 못했어요.';
  static const notAvailable = '7일 결과를 볼 수 없는 협업이에요.';

  static String meetAgain(String name) =>
      '${josa(name, JosaPair.gwaWa)} 다시 만나기';

  @override
  ConsumerState<StoreResultPage> createState() => _StoreResultPageState();
}

class _StoreResultPageState extends ConsumerState<StoreResultPage> {
  String? _notice;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  /// 크리에이터가 낸 게시 링크를 바깥 브라우저로 연다. `http`·`https`만 연다.
  Future<void> _receiveVideo(StoreResult result) async {
    final url = openableLink(result.postUrl);
    final opened =
        url != null && await ref.read(externalLinkLauncherProvider).open(url);
    if (!mounted || opened) return;
    setState(() => _notice = linkFailedMessage);
  }

  void _openOffer(StoreResultState state, {required bool again}) {
    final creator = state.result.creator;
    context.push(
      AppRoutes.storeOfferNew(creator.userId),
      extra: SendOfferArgs(
        creator: CreatorSummary(
          userId: creator.userId,
          displayName: creator.name,
          photoUrl: creator.photoUrl,
        ),
        start: again ? state.pastTerms : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      storeResultViewModelProvider(widget.collaborationId),
    );
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final value = async.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: StoreResultPage.title,
              extent: 64,
              onBack: _leave,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Content(
                    result: value.result,
                    onOpenReport: () => context.push(
                      AppRoutes.storeViewReport(widget.collaborationId),
                    ),
                  ),
                ),
                AsyncError(:final error) =>
                  error is StoreResultFailure && error.notFound
                      ? const CoraStateView.empty(
                          title: StoreResultPage.notAvailable,
                        )
                      : CoraStateView.loadFailed(
                          title: StoreResultPage.loadFailed,
                          onRetry: () => ref.invalidate(
                            storeResultViewModelProvider(
                              widget.collaborationId,
                            ),
                          ),
                        ),
                _ => const CoraStateView.loading(),
              },
            ),
            if (value != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: _Actions(
                  state: value,
                  notice: _notice,
                  onNewOffer: () => _openOffer(value, again: false),
                  onReceive: () => _receiveVideo(value.result),
                  onMeetAgain: () => _openOffer(value, again: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.result, required this.onOpenReport});

  final StoreResult result;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final views = result.views;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _Hero(result: result),
        ),
        if (result.fixedCashOnly)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _FixedCashOnly(fixedCash: result.fixedCash),
          )
        else ...[
          if (result.hasComparison)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _Comparison(
                tenths: result.multiplierTenths!,
                usual: result.usualViews!,
                views: views!,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            // 두 칸의 높이를 맞춘다(글자가 커지면 한쪽이 두 줄이 될 수 있다).
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Expanded(
                    child: _Tile(
                      label: StoreResultPage.payout,
                      value: wonExact(result.payout),
                    ),
                  ),
                  Expanded(
                    child: _Tile(
                      label: StoreResultPage.refund,
                      value: wonExact(result.refund),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 조회수 수당이 있던 협업만 성과 확인(F4)이 있다. 12/400, 바깥 여백 8/24.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                link: true,
                onTap: onOpenReport,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: onOpenReport,
                    child: Text(
                      StoreResultPage.sourceLink,
                      // 캔버스 `<a>`는 `text-decoration`이 없어 브라우저 기본 밑줄이 보인다.
                      style: CoraTextStyles.fieldLabel.copyWith(
                        color: context.colors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 사진 위에 `{활동 이름} · {형식} · {M}월 {D}일 게시`와 큰 조회수. 사진은 크리에이터 사진이다
/// (서버가 게시물 사진을 주지 않는다).
class _Hero extends StatelessWidget {
  const _Hero({required this.result});

  final StoreResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final views = result.views;
    return SizedBox(
      height: 236,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: true,
              label: '${josa(result.creator.name, JosaPair.iGa)} 올린 콘텐츠',
              child: ExcludeSemantics(
                child: CoraNetworkPhoto(
                  url: result.creator.photoUrl,
                  alignment: const Alignment(0, -0.4),
                  background: c.creatorPhotoPlaceholder,
                ),
              ),
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
                      c.photoScrim.withValues(alpha: 0.72),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultSubtitle(result),
                    style: CoraTextStyles.meta.copyWith(
                      color: c.onPhotoSecondary,
                    ),
                  ),
                  if (views != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        viewsLabel(views),
                        // 캔버스는 줄 높이를 주지 않아(`normal`) 글자 크기의 1.448배다.
                        style: CoraTextStyles.display.copyWith(
                          fontSize: 30,
                          letterSpacing: -1.5,
                          height: 1.448,
                          color: c.onPhoto,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 평소 게시물과의 비교 상자: 안쪽 18/20, 모서리 26, `surface`.
class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.tenths,
    required this.usual,
    required this.views,
  });

  final int tenths;
  final int usual;
  final int views;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StoreResultPage.comparisonTitle,
              style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 8,
              children: [
                Text(
                  multiplierLabel(tenths),
                  style: CoraTextStyles.display.copyWith(
                    fontSize: 40,
                    letterSpacing: -2,
                    height: 1.448,
                    color: c.text,
                  ),
                ),
                Flexible(
                  child: Text(
                    usualLabel(usual),
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: _Bars(usual: usual, views: views),
            ),
          ],
        ),
      ),
    );
  }
}

/// 평소·이번 막대(높이 10, 모서리 5, 사이 6). 글자 칸은 44, 막대 앞 간격은 8이다.
///
/// 캔버스의 막대 너비는 줄 전체에 대한 비율이라(`width: 32%`), 이번 막대(100%)는 글자 칸을 뺀
/// 나머지로 줄어든다. 같은 모양이 되도록 비율을 줄 너비에 곱하고 남은 너비로 자른다.
class _Bars extends StatelessWidget {
  const _Bars({required this.usual, required this.views});

  final int usual;
  final int views;

  static const double _label = 44;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final peak = math.max(usual, views);
    return LayoutBuilder(
      builder: (context, box) {
        final row = box.maxWidth;
        final room = math.max(0.0, row - _label - _gap);
        double width(int v) => math.min(row * v / peak, room);
        Widget line(
          Key barKey,
          String label,
          int value,
          Color text,
          Color bar,
        ) => Row(
          children: [
            SizedBox(
              width: _label,
              child: Text(
                label,
                style: CoraTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: text,
                ),
              ),
            ),
            const SizedBox(width: _gap),
            DecoratedBox(
              decoration: BoxDecoration(
                color: bar,
                borderRadius: BorderRadius.circular(5),
              ),
              child: SizedBox(key: barKey, width: width(value), height: 10),
            ),
          ],
        );
        return Column(
          spacing: 6,
          children: [
            line(
              StoreResultPage.usualBarKey,
              StoreResultPage.usualBar,
              usual,
              c.textSecondary,
              c.line,
            ),
            line(
              StoreResultPage.nowBarKey,
              StoreResultPage.nowBar,
              views,
              c.text,
              c.compareBarNow,
            ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: label,
      value: value,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.field),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CoraTextStyles.fieldLabel.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: CoraTextStyles.amountMedium.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 조회수 수당이 없던 협업: 큰 숫자와 비교, 지급·환불 줄 대신 고정 현금 한 줄(캔버스에 없다).
class _FixedCashOnly extends StatelessWidget {
  const _FixedCashOnly({required this.fixedCash});

  final int fixedCash;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Text(
          fixedCashLine(fixedCash),
          style: CoraTextStyles.amountMedium.copyWith(color: c.text),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.notice,
    required this.onNewOffer,
    required this.onReceive,
    required this.onMeetAgain,
  });

  final StoreResultState state;
  final String? notice;
  final VoidCallback onNewOffer;
  final VoidCallback onReceive;
  final VoidCallback onMeetAgain;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = CoraTextStyles.buttonMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (notice != null)
          Semantics(
            liveRegion: true,
            child: Text(
              notice!,
              textAlign: TextAlign.center,
              style: CoraTextStyles.meta.copyWith(color: c.text),
            ),
          ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: CoraPillButton(
                label: StoreResultPage.newOffer,
                onPressed: onNewOffer,
                background: c.subtleAction,
                foreground: c.onSubtleAction,
                textStyle: small,
                height: 52,
              ),
            ),
            Expanded(
              child: CoraPillButton(
                label: StoreResultPage.receiveVideo,
                onPressed: onReceive,
                background: c.subtleAction,
                foreground: c.onSubtleAction,
                textStyle: small,
                height: 52,
              ),
            ),
          ],
        ),
        CoraPillButton(
          label: StoreResultPage.meetAgain(state.result.creator.name),
          onPressed: onMeetAgain,
          background: c.accent,
          foreground: c.onAccent,
          textStyle: CoraTextStyles.button,
          height: 58,
        ),
      ],
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../theme/cora_colors.dart';
import '../../theme/cora_shadows.dart';
import '../../theme/cora_shapes.dart';
import '../../theme/cora_swipe_tokens.dart';
import '../../theme/cora_text_styles.dart';
import '../cora_network_photo.dart';

/// 추천 카드 한 장의 모양(캔버스 01 발견, 08 크리에이터의 발견). 사진이 가득 차고, 위아래를
/// 어둡게 눕혀 흰 글자가 읽히게 한다. 맨 아래 글자 덮개는 카드 위에 겹쳐 놓는 버튼 줄이
/// 글자를 가리지 않도록 [bottomInset]만큼 비운다.
///
/// 위쪽 진행 막대(캔버스의 작은 3칸)는 카드 수에 묶인 화면 요소라 여기에 두지 않는다.
class SwipeCardFrame extends StatelessWidget {
  const SwipeCardFrame({
    super.key,
    required this.photoUrl,
    required this.badge,
    required this.name,
    required this.title,
    required this.priceLine,
    required this.tags,
    this.heroTag,
    this.bottomInset = CoraSwipeTokens.textInsetBottom,
    this.photoAlignment = CoraSwipeTokens.photoAlignment,
  });

  /// 사진 주소. 없거나 불러오지 못하면 바탕색만 보인다.
  final String? photoUrl;

  /// 왼쪽 위의 작은 글자(예: `운영자 추천 1 / 3`).
  final String badge;

  /// 사진 위 맨 위 줄(크리에이터·가게 이름).
  final String name;

  /// 큰 제목. 줄바꿈(`\n`)을 그대로 보여 준다.
  final String title;

  /// 제작비·보상 줄. `accent` 색이다. 비어 있으면 그리지 않는다.
  final String priceLine;

  /// 꼬리표. 앞에 `#`을 붙여 보여 준다.
  final List<String> tags;

  /// 카드 → 상세 공유 요소 전환의 태그(`CoraHeroTag`). 없으면 전환을 쓰지 않는다.
  final Object? heroTag;

  /// 글자 덮개 아래쪽 여백.
  final double bottomInset;

  /// 사진 가운데 기준점(CSS `object-position`). 01은 50% 30%, 08은 62% 50%다.
  final Alignment photoAlignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget photo = CoraNetworkPhoto(
      url: photoUrl,
      alignment: photoAlignment,
      background: c.photoPlaceholder,
    );
    if (heroTag != null) photo = Hero(tag: heroTag!, child: photo);

    final nameStyle = CoraTextStyles.label.copyWith(
      fontSize: 14,
      color: c.onPhotoSecondary,
      shadows: [CoraSwipeTokens.textShadow],
    );
    final titleStyle = CoraTextStyles.display.copyWith(
      fontSize: 36,
      letterSpacing: -1.8,
      height: 1.1,
      color: c.onPhoto,
      shadows: [CoraSwipeTokens.textShadow],
    );
    final priceStyle = CoraTextStyles.display.copyWith(
      fontSize: 20,
      letterSpacing: -0.4,
      height: 1.448,
      color: c.accent,
      shadows: [CoraSwipeTokens.textShadow],
    );
    final tagStyle = CoraTextStyles.body.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.448,
      color: c.onPhotoSecondary,
      shadows: [CoraSwipeTokens.textShadow],
    );

    return Semantics(
      container: true,
      label: '$name의 상세 보기',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CoraRadius.xxl),
          boxShadow: CoraShadows.swipeCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CoraRadius.xxl),
          child: ColoredBox(
            color: CoraSwipeTokens.backdrop,
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo,
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: CoraSwipeTokens.topScrimHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: CoraSwipeTokens.topScrim,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 28,
                  child: ExcludeSemantics(
                    child: Text(
                      badge,
                      style: CoraTextStyles.caption.copyWith(color: c.onPhoto),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: CoraSwipeTokens.bottomScrim,
                        stops: CoraSwipeTokens.bottomScrimStops,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        CoraSwipeTokens.textInsetSide,
                        CoraSwipeTokens.textInsetTop,
                        CoraSwipeTokens.textInsetSide,
                        bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          Text(name, style: nameStyle),
                          Text(title, style: titleStyle),
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              if (priceLine.isNotEmpty)
                                Text(priceLine, style: priceStyle),
                              for (final tag in tags)
                                Text('#$tag', style: tagStyle),
                            ],
                          ),
                        ],
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
}

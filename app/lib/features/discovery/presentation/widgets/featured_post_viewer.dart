import 'package:flutter/material.dart';

import '../../../../core/ui/swipe_deck/swipe_card_frame.dart';
import '../../domain/featured_post_ref.dart';
import 'swipe_progress_bar.dart';

/// 대표 게시물을 한 장씩 넘겨 보는 카드(캔버스 M19G1Swipe). 카드 틀([SwipeCardFrame])의 사진과 한 줄이
/// 지금 보는 게시물을 따라가고, 위에 게시물 수만큼의 진행 막대를 얹는다.
///
/// 카드의 오른쪽 절반을 탭하면 다음 게시물, 왼쪽 절반은 이전 게시물이다. 가로 밀기는 카드를 넘기는 결정에
/// 쓰이므로 게시물 넘기기는 짧은 탭만 쓴다. 맨 처음·맨 끝에서는 그대로 있다. 스크린 리더는 탭 대신 카드를
/// 조절 가능한 항목으로 읽고 올리기·내리기(`onIncrease`·`onDecrease`)로 다음·이전 게시물을 넘긴다(캔버스 밖).
///
/// [onOpenDetail]을 주면(브랜드 01) 카드 아래쪽 글자 덮개를 탭할 때 상세를 연다. 게시물이 하나뿐이면
/// 카드 어디를 탭해도 상세다. 카드가 바뀌면(`key`) 첫 게시물부터 다시 본다.
class FeaturedPostViewer extends StatefulWidget {
  const FeaturedPostViewer({
    super.key,
    required this.posts,
    required this.badgeBuilder,
    required this.name,
    required this.fallbackTitle,
    required this.priceLine,
    required this.tags,
    this.heroTag,
    this.semanticLabel,
    this.onOpenDetail,
  }) : assert(posts.length > 0);

  final List<FeaturedPostRef> posts;

  /// 왼쪽 위 글자. 지금 보는 번호(1부터)와 게시물 수를 받는다.
  final String Function(int index, int total) badgeBuilder;

  /// 사진 위 맨 위 줄(활동 이름).
  final String name;

  /// 지금 보는 게시물에 한 줄이 없을 때 큰 글자로 보일 것.
  final String fallbackTitle;

  /// 형광색 줄(`{분야} · 팔로워 {n}`, 제작비). 비어 있으면 그리지 않는다.
  final String priceLine;
  final List<String> tags;
  final Object? heroTag;
  final String? semanticLabel;
  final VoidCallback? onOpenDetail;

  /// 글자 덮개가 시작하는 높이 비율. 이 아래를 탭하면 [onOpenDetail]이다. 실제 글자 덮개의 높이는 글자 수와
  /// 글자 크기에 따라 달라(1.3배에서는 55% 선 위까지 올라올 수 있다) 이 비율은 "글자 덮개의 기준 높이"일 뿐이고,
  /// 그 위로 올라온 글자 윗부분을 탭하면 상세가 아니라 게시물 넘기기가 된다(Ruling T8-1, 소유자 확인 항목).
  static const detailZoneFrom = 0.55;

  @override
  State<FeaturedPostViewer> createState() => _FeaturedPostViewerState();
}

class _FeaturedPostViewerState extends State<FeaturedPostViewer> {
  int _index = 0;

  int get _last => widget.posts.length - 1;

  void _go(int next) {
    final clamped = next.clamp(0, _last);
    if (clamped != _index) setState(() => _index = clamped);
  }

  void _onTapUp(TapUpDetails details, Size size) {
    final detail = widget.onOpenDetail;
    final inDetailZone =
        details.localPosition.dy >
        size.height * FeaturedPostViewer.detailZoneFrom;
    if (detail != null && (inDetailZone || widget.posts.length == 1)) {
      detail();
      return;
    }
    final right = details.localPosition.dx >= size.width / 2;
    _go(_index + (right ? 1 : -1));
  }

  @override
  Widget build(BuildContext context) {
    final index = _index.clamp(0, _last);
    final post = widget.posts[index];
    final caption = post.caption?.trim() ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final total = widget.posts.length;
        String number(int i) => '${i + 1} / $total';
        return Semantics(
          container: true,
          value: number(index),
          increasedValue: index < _last ? number(index + 1) : null,
          decreasedValue: index > 0 ? number(index - 1) : null,
          onIncrease: index < _last ? () => _go(index + 1) : null,
          onDecrease: index > 0 ? () => _go(index - 1) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _onTapUp(details, size),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SwipeCardFrame(
                  photoUrl: post.photoUrl,
                  badge: widget.badgeBuilder(index + 1, widget.posts.length),
                  name: widget.name,
                  title: caption.isEmpty ? widget.fallbackTitle : caption,
                  titleMaxLines: 2,
                  priceLine: widget.priceLine,
                  tags: widget.tags,
                  heroTag: widget.heroTag,
                  semanticLabel: widget.semanticLabel,
                ),
                SwipeProgressBar(segments: widget.posts.length, current: index),
              ],
            ),
          ),
        );
      },
    );
  }
}

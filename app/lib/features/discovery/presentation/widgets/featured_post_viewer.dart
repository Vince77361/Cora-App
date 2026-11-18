import 'package:flutter/material.dart';

import '../../../../core/ui/swipe_deck/swipe_card_frame.dart';
import '../../domain/featured_post_ref.dart';
import 'swipe_progress_bar.dart';

/// 대표 게시물을 한 장씩 넘겨 보는 카드(캔버스 M19G1Swipe). 카드 틀([SwipeCardFrame])의 사진과 한 줄이
/// 지금 보는 게시물을 따라가고, 위에 게시물 수만큼의 진행 막대를 얹는다.
///
/// 카드의 오른쪽 절반을 탭하면 다음 게시물, 왼쪽 절반은 이전 게시물이다. 가로 밀기는 카드를 넘기는 결정에
/// 쓰이므로 게시물 넘기기는 짧은 탭만 쓴다. 맨 처음·맨 끝에서는 그대로 있다.
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

  /// 글자 덮개가 시작하는 높이 비율. 이 아래를 탭하면 [onOpenDetail]이다.
  static const detailZoneFrom = 0.55;

  @override
  State<FeaturedPostViewer> createState() => _FeaturedPostViewerState();
}

class _FeaturedPostViewerState extends State<FeaturedPostViewer> {
  int _index = 0;

  int get _last => widget.posts.length - 1;

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
    final next = (_index + (right ? 1 : -1)).clamp(0, _last);
    if (next != _index) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final index = _index.clamp(0, _last);
    final post = widget.posts[index];
    final caption = post.caption?.trim() ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
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
        );
      },
    );
  }
}

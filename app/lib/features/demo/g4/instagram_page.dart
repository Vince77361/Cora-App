import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// B3 인스타그램에서 가져오기 (`NInstagram.dc.html`). 게시물을 고른 순서대로 번호가 붙는다.
class InstagramPage extends StatefulWidget {
  const InstagramPage({super.key});

  @override
  State<InstagramPage> createState() => _InstagramPageState();
}

class _InstagramPageState extends State<InstagramPage> {
  static const _m = DemoImages.minCloset;
  static const _s = DemoImages.seoyun;
  static const _c = DemoImages.onecup;

  // [사진, x, y]
  static const List<List<Object>> _items = [
    [_m, 50.0, 28.0],
    [_s, 50.0, 40.0],
    [_m, 40.0, 60.0],
    [_c, 50.0, 30.0],
    [_m, 80.0, 20.0],
    [_s, 30.0, 70.0],
    [_c, 50.0, 60.0],
    [_m, 20.0, 80.0],
    [_s, 70.0, 30.0],
    [_m, 50.0, 45.0],
    [_c, 30.0, 40.0],
    [_m, 60.0, 90.0],
  ];

  final List<int> _sel = [0, 2, 4];

  void _toggle(int i) {
    setState(() {
      if (!_sel.remove(i)) _sel.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G4TitleHeader(
                  title: '인스타그램에서 가져오기',
                  leading: G4HeaderButton(
                    svg: G4Icons.close,
                    label: '닫기',
                    size: 20,
                    fallback: 'NProfile.dc.html',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                  child: Text(
                    '@min.closet 계정의 게시물이에요. 포트폴리오에 보여줄 것만 골라요.',
                    style: g4Style(14, color: c.sub, height: 1.6),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      for (var r = 0; r < _items.length ~/ 3; r++) ...[
                        if (r > 0) const SizedBox(height: 2),
                        Row(
                          children: [
                            for (var k = 0; k < 3; k++) ...[
                              if (k > 0) const SizedBox(width: 2),
                              Expanded(
                                child: _Cell(
                                  c: c,
                                  index: r * 3 + k,
                                  item: _items[r * 3 + k],
                                  order: _sel.indexOf(r * 3 + k),
                                  onTap: _toggle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(23, 24, 28, 0.1),
                  offset: Offset(0, -12),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_sel.length}개 골랐어요',
                        style: g4Style(
                          15,
                          weight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      Text('고른 순서대로 보여줘요', style: g4Style(12, color: c.sub)),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoGo(context, 'NProfile.dc.html'),
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: G4Colors.lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '포트폴리오에 추가',
                      style: g4Style(
                        16,
                        weight: FontWeight.w700,
                        color: G4Colors.onLime,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.c,
    required this.index,
    required this.item,
    required this.order,
    required this.onTap,
  });

  final G4Colors c;
  final int index;
  final List<Object> item;

  /// 고른 순서(0부터). 안 골랐으면 -1.
  final int order;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final on = order >= 0;
    return Semantics(
      button: true,
      selected: on,
      label: '게시물 ${index + 1}${on ? ', 선택됨' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Container(
          height: 128,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.thumbBg),
          child: Stack(
            children: [
              Positioned.fill(
                child: DemoPhoto(
                  item[0] as String,
                  x: item[1] as double,
                  y: item[2] as double,
                  opacity: on ? 1 : 0.85,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on
                        ? G4Colors.lime
                        : const Color.fromRGBO(255, 255, 255, 0.35),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(255, 255, 255, 0.9),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    on ? '${order + 1}' : '',
                    style: g4Style(
                      12,
                      weight: FontWeight.w700,
                      color: G4Colors.onLime,
                    ),
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

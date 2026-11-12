import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

class _Card {
  const _Card(this.name, this.meta, this.views, this.img, this.bg, this.mid);
  final String name;
  final String meta;
  final String views;
  final String img;
  final Color bg;
  final int mid;
}

/// B4 빠른 입찰 (NBidding)
class BiddingPage extends StatefulWidget {
  const BiddingPage({super.key});

  @override
  State<BiddingPage> createState() => _BiddingPageState();
}

class _BiddingPageState extends State<BiddingPage> {
  static const _cards = [
    _Card(
      '민의 옷장 기록',
      '코디 릴스, 팔로워 2,100명',
      '8천 – 1.2만 회',
      DemoImages.minCloset,
      Color(0xFFD9DCE6),
      10000,
    ),
    _Card(
      '하루 한 컵',
      '리빙 릴스, 팔로워 640명',
      '2천 – 4천 회',
      DemoImages.onecup,
      Color(0xFFF3E3D3),
      3000,
    ),
    _Card(
      '서윤의 작은 취향',
      '소품 릴스, 팔로워 8,200명',
      '2만 – 3만 회',
      DemoImages.seoyun,
      Color(0xFFE8DDCB),
      25000,
    ),
  ];
  static const _amounts = [30000, 50000, 100000];

  int _i = 0;
  int _pick = 1;
  int _spent = 180000;
  int _count = 2;

  void _next() => setState(() => _i = (_i + 1) % _cards.length);

  void _bid() {
    final a = _amounts[_pick];
    if (_spent + a > 500000) return;
    setState(() {
      _spent += a;
      _count += 1;
      _i = (_i + 1) % _cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    final c = _cards[_i];
    final a = _amounts[_pick];
    final left = 500000 - _spent;
    final leftFactor = (left / 500000 * 100).round() / 100;
    final perView = a / c.mid;
    final perViewText = '약 ${perView.round() < 1 ? 1 : perView.round()}원';
    final cardBg = dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
    final barFill = dark ? const Color(0xFF0F1012) : const Color(0xFF17181C);
    final circleText = dark ? const Color(0xFFE4FFB0) : G6Palette.onLime;
    final tileBg = p.card;
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: G6IconButton(
                              svg: g6CloseSvg,
                              color: p.text,
                              size: 20,
                              onTap: () => demoBack(context),
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        SizedBox(
                          width: 88,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  demoGo(context, 'NBidResult.dc.html'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Text(
                                  '입찰 $_count건',
                                  style: g6Text(
                                    13,
                                    p.sub,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(23, 24, 28, 0.08),
                        offset: Offset(0, 16),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('남은 예산', style: g6Text(13, p.sub)),
                          Text('총 500,000원', style: g6Text(13, p.sub)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g6Won(left),
                        style: g6Text(
                          28,
                          p.text,
                          weight: FontWeight.w900,
                          ls: -0.04,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 6,
                          color: p.line,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: leftFactor,
                            child: Container(height: 6, color: barFill),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 330,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Positioned.fill(child: ColoredBox(color: c.bg)),
                              Positioned.fill(
                                child: DemoPhoto(c.img, x: 50, y: 28),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 170,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color.fromRGBO(23, 24, 28, 0),
                                        Color.fromRGBO(23, 24, 28, 0.8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 14,
                                top: 14,
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: Container(
                                      width: 86,
                                      height: 86,
                                      color: const Color.fromRGBO(
                                        198,
                                        255,
                                        61,
                                        0.9,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${a ~/ 10000}만',
                                            style: g6Text(
                                              20,
                                              circleText,
                                              weight: FontWeight.w900,
                                              ls: -0.04,
                                            ),
                                          ),
                                          Text(
                                            '입찰가',
                                            style: g6Text(
                                              11,
                                              circleText,
                                              weight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      c.name,
                                      style: g6Text(
                                        20,
                                        const Color(0xFFFFFFFF),
                                        weight: FontWeight.w900,
                                        ls: -0.04,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.meta,
                                      style: g6Text(
                                        13,
                                        const Color(0xFFE4E6EA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _tile(p, tileBg, '예상 조회수', c.views)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tile(p, tileBg, '조회 1회당', perViewText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _amounts.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _pick = i),
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == _pick ? p.selBg : p.unselBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_amounts[i] ~/ 10000}만 원',
                                style: g6Text(
                                  14,
                                  i == _pick ? p.selFg : p.unselFg,
                                  weight: FontWeight.w500,
                                ),
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
        G6BottomBar(
          child: Row(
            children: [
              Expanded(
                child: G6PillButton(
                  label: '넘기기',
                  bg: const Color(0xFFF2F3F5),
                  fg: const Color(0xFF17181C),
                  weight: FontWeight.w500,
                  onTap: _next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: G6PillButton(
                  label: '입찰하기',
                  bg: G6Palette.lime,
                  fg: G6Palette.onLime,
                  onTap: _bid,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(G6Palette p, Color bg, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: g6Text(12, p.sub)),
          const SizedBox(height: 2),
          Text(value, style: g6Text(15, p.text, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

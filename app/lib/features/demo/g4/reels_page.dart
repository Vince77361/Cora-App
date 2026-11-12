import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_role_nav.dart';
import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// B1 릴스 피드 탐색 (`NReels.dc.html`). 영상 대신 사진을 쓴다. 세로로 넘기거나 화면을 눌러 다음 카드로 간다.
class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _Reel {
  const _Reel({
    required this.name,
    required this.title,
    required this.meta,
    required this.asset,
    required this.bg,
  });
  final String name;
  final String title;
  final String meta;
  final String asset;
  final Color bg;
}

class _ReelsPageState extends State<ReelsPage> {
  static const _items = [
    _Reel(
      name: '민의 옷장 기록',
      title: '같은 니트,\n세 가지 액세서리',
      meta: '릴스 0:30, 팔로워 2,100명',
      asset: DemoImages.minCloset,
      bg: Color(0xFFD9DCE6),
    ),
    _Reel(
      name: '하루 한 컵',
      title: '주말 아침,\n잔 하나로 바뀌는 식탁',
      meta: '릴스 0:24, 팔로워 640명',
      asset: DemoImages.onecup,
      bg: Color(0xFFF3E3D3),
    ),
    _Reel(
      name: '서윤의 작은 취향',
      title: '출근 전 30초,\n오늘의 손목 루틴',
      meta: '릴스 0:30, 팔로워 8,200명',
      asset: DemoImages.seoyun,
      bg: Color(0xFFE8DDCB),
    ),
  ];

  static const _speaker =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 9h4l5-4v14l-5-4H4z"></path><path d="{D}"></path></svg>';
  static const _mutedPath = 'M17 9l4 6M21 9l-4 6';
  static const _onPath = 'M16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11';
  static const _logo =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><circle cx="9.5" cy="13" r="6.5"></circle><circle cx="16.5" cy="13" r="6.5" stroke="#C6FF3D"></circle></svg>';
  static const _profile =
      '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="8" r="4"></circle><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"></path></svg>';
  static const _bookmark =
      '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M6 3h12v18l-6-4-6 4z"></path></svg>';
  static const _heartOff =
      '<svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';
  static const _heartOn =
      '<svg width="44" height="44" viewBox="0 0 24 24" fill="#C6FF3D" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';

  // 끝없이 세로로 넘길 수 있게 큰 수에서 시작한다. 3000 % 3 == 0.
  late final PageController _pages = PageController(initialPage: 3000);
  int _page = 3000;
  final Map<int, bool> _liked = {};
  bool _muted = true;

  int get _i => _page % _items.length;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    final liked = _liked[_i] ?? false;
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned(left: 0, right: 0, top: 0, height: 64, child: _Header(c: c)),
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          bottom: 100,
          child: Semantics(
            label: '릴스',
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _items[_i].bg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 24, 28, 0.16),
                    offset: Offset(0, 16),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _next,
                      child: PageView.builder(
                        controller: _pages,
                        scrollDirection: Axis.vertical,
                        onPageChanged: (p) => setState(() => _page = p),
                        itemBuilder: (_, p) =>
                            _ReelPage(reel: _items[p % _items.length]),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 120,
                    child: const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(23, 24, 28, 0.38),
                              Color.fromRGBO(23, 24, 28, 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 14,
                    height: 3,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.38,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 28,
                    child: IgnorePointer(
                      child: Text(
                        _items[_i].meta,
                        style: g4Style(
                          12,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 22,
                    child: Semantics(
                      button: true,
                      toggled: _muted,
                      label: _muted ? '소리 켜기' : '소리 끄기',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _muted = !_muted),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: G4ShadowSvg(
                              _speaker.replaceFirst(
                                '{D}',
                                _muted ? _mutedPath : _onPath,
                              ),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => demoGo(context, 'NCreatorView.dc.html'),
                          child: const SizedBox(
                            width: 52,
                            height: 52,
                            child: Center(
                              child: G4ShadowSvg(
                                _profile,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const SizedBox(
                          width: 52,
                          height: 52,
                          child: Center(
                            child: G4ShadowSvg(
                              _bookmark,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _liked[_i] = !liked),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: G4ShadowSvg(
                                liked ? _heartOn : _heartOff,
                                // 다크 파일의 꺼진 하트 선은 #0F1012다(artifact 그대로).
                                color: liked
                                    ? G4Colors.lime
                                    : (c.dark ? c.bg : Colors.white),
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => demoGo(context, 'NOffer.dc.html'),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: G4Colors.lime,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '오퍼 보내기',
                              style: g4Style(
                                15,
                                weight: FontWeight.w700,
                                color: G4Colors.onLime,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        demoRoleNav(
          // 브랜드에게 릴스는 "발견" 탭의 한 보기(공통 모델 14장)다.
          current: demoRole.value == DemoRole.brand ? 0 : 1,
          fallback: DemoRole.store,
          activeColor: c.navActive,
        ),
      ],
    );
  }
}

/// 릴스 한 장: 사진, 아래쪽 어두운 띠, 가게(크리에이터) 이름과 제목.
class _ReelPage extends StatelessWidget {
  const _ReelPage({required this.reel});

  final _Reel reel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: reel.bg)),
        Positioned.fill(child: DemoPhoto(reel.asset, x: 50, y: 25)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 360,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(23, 24, 28, 0),
                    Color.fromRGBO(23, 24, 28, 0.2),
                    Color.fromRGBO(23, 24, 28, 0.48),
                    Color.fromRGBO(23, 24, 28, 0.66),
                  ],
                  stops: [0, 0.35, 0.7, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 96,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reel.name,
                  style: g4Style(
                    14,
                    weight: FontWeight.w500,
                    color: const Color(0xFFE4E6EA),
                    shadows: const [
                      Shadow(
                        color: Color.fromRGBO(0, 0, 0, 0.28),
                        offset: Offset(0, 1),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reel.title,
                  style: g4Style(
                    30,
                    weight: FontWeight.w900,
                    color: Colors.white,
                    em: -0.05,
                    height: 1.12,
                    shadows: const [
                      Shadow(
                        color: Color.fromRGBO(0, 0, 0, 0.28),
                        offset: Offset(0, 1),
                        blurRadius: 14,
                      ),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.c});

  final G4Colors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              DemoSvg(_ReelsPageState._logo, color: c.text, size: 26),
              const SizedBox(width: 6),
              Text(
                'cora',
                style: g4Style(
                  24,
                  weight: FontWeight.w900,
                  color: c.text,
                  em: -0.05,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

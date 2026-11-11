import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

class _Item {
  const _Item(this.name, this.meta, this.on, this.initial);
  final String name;
  final String meta;
  final bool on;
  final String initial;
}

/// C1 외부 리스트 검색 (NDirectory)
class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  static const _items = [
    _Item('면치기 일기', '@noodle.diary, 팔로워 1.2만, 3일 전 업데이트', false, '면'),
    _Item('하루 한 컵', '@onecup.day, 팔로워 640, 가입함', true, '하'),
    _Item('성수 한 끼', '@seongsu.meal, 팔로워 4,800, 5일 전 업데이트', false, '성'),
    _Item('국물 수집가', '@soup.collector, 팔로워 2.3만, 1일 전 업데이트', false, '국'),
    _Item('민의 옷장 기록', '@min.closet, 팔로워 2,100, 가입함', true, '민'),
    _Item('골목 미식회', '@alley.gourmet, 팔로워 8,900, 6일 전 업데이트', false, '골'),
  ];
  static const _labels = ['전체', '가입함', '미가입'];
  static const _searchSvg =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-4-4"></path></svg>';

  int _tab = 0;
  final _search = TextEditingController(text: '라멘 맛집');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    final rows = _items
        .where((x) => _tab == 0 || (_tab == 1 ? x.on : !x.on))
        .toList();
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            DemoSvg(g6LogoSvg, color: p.text, size: 26),
                            const SizedBox(width: 6),
                            Text(
                              'cora',
                              style: g6Text(
                                24,
                                p.text,
                                weight: FontWeight.w900,
                                ls: -0.05,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => demoGo(context, 'NReels.dc.html'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    '릴스',
                                    style: g6Text(
                                      13,
                                      p.sub,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFFF2F3F5)
                                      : const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: dark
                                      ? null
                                      : const [
                                          BoxShadow(
                                            color: Color.fromRGBO(
                                              23,
                                              24,
                                              28,
                                              0.10,
                                            ),
                                            offset: Offset(0, 2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                ),
                                child: Text(
                                  '리스트',
                                  style: g6Text(
                                    13,
                                    const Color(0xFF17181C),
                                    weight: FontWeight.w500,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        DemoSvg(_searchSvg, color: p.sub, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            style: g6Text(15, p.text),
                            cursorColor: p.text,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _labels.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == _tab ? p.selBg : p.unselBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _labels[i],
                              style: g6Text(
                                13,
                                i == _tab ? p.selFg : p.unselFg,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text('팔로워 1천 – 5만', style: g6Text(12, p.sub)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Text(
                    '인스타그램 공개 정보로 만든 목록이에요. 매주 일부씩 업데이트해요.',
                    style: g6Text(12, p.sub),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [for (final r in rows) _row(context, p, r)],
                  ),
                ),
              ],
            ),
          ),
        ),
        DemoBottomNav(
          activeColor: dark ? G6Palette.lime : null,
          items: [
            DemoNavItem(
              label: '홈',
              canvasFile: 'NStoreHome.dc.html',
              svg:
                  '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 10l8-6 8 6v10H4z"></path></svg>',
            ),
            DemoNavItem(
              label: '찾기',
              canvasFile: 'NReels.dc.html',
              current: true,
              svg:
                  '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><rect x="6" y="3" width="12" height="17" rx="3"></rect><path d="M3 7v10M21 7v10"></path></svg>',
            ),
            DemoNavItem(
              label: '대화',
              canvasFile: 'NChatThread.dc.html',
              svg:
                  '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 5h16v11H10l-6 4z"></path></svg>',
            ),
            DemoNavItem(
              label: '오퍼',
              canvasFile: 'NOffer.dc.html',
              svg:
                  '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"></path></svg>',
            ),
            DemoNavItem(
              label: 'AI 글',
              canvasFile: 'NStoreAI.dc.html',
              svg:
                  '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"></path></svg>',
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, G6Palette p, _Item r) {
    final dark = p.dark;
    final avatarBg = r.on ? const Color(0xFFF3FFD6) : p.card;
    final badgeBg = r.on
        ? (dark ? const Color(0xFFF3FFD6) : const Color(0xFFF8F9FA))
        : (dark ? const Color(0xFFF2F3F5) : G6Palette.lime);
    final badgeFg = r.on
        ? (dark ? G6Palette.onLime : const Color(0xFF5C6068))
        : (dark ? const Color(0xFF0F1012) : G6Palette.onLime);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          demoGo(context, r.on ? 'NOffer.dc.html' : 'NOutreach.dc.html'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                r.initial,
                style: g6Text(16, p.sub, weight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: g6Text(15, p.text, weight: FontWeight.w500),
                  ),
                  Text(r.meta, style: g6Text(12, p.sub)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                r.on ? '가입함' : '연락하기',
                style: g6Text(12, badgeFg, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

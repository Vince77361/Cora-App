import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

class _Role {
  const _Role(this.side, this.title, this.desc, this.href, this.next);
  final String side;
  final String title;
  final String desc;
  final String href;
  final String next;
}

/// A1 시작 · 역할 선택 (NRole)
class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  static const _items = [
    _Role(
      '일을 맡기는 쪽',
      '가게를 알리고 싶어요',
      '식당, 미용실, 공방 같은 동네 가게',
      'NStoreLink.dc.html',
      '가게 링크로 시작하기',
    ),
    _Role(
      '일을 맡기는 쪽',
      '브랜드 제품을 알리고 싶어요',
      '쇼핑몰, 제조사, 브랜드 담당자',
      'Main.dc.html',
      '크리에이터 둘러보기',
    ),
    _Role(
      '일을 하는 쪽',
      '콘텐츠를 만들고 싶어요',
      '팔로워가 적어도 누구나 시작할 수 있어요',
      'Principles.dc.html',
      '내 협업 원칙 정하기',
    ),
  ];
  static const _checkSvg =
      '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';

  int _pick = 0;

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    final cur = _items[_pick];
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DemoSvg(g6LogoSvg, color: p.text, size: 28),
                          const SizedBox(width: 6),
                          Text(
                            'cora',
                            style: g6Text(
                              26,
                              p.text,
                              weight: FontWeight.w900,
                              ls: -0.05,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text(
                        '어떤 일로\n오셨나요?',
                        style: g6Text(
                          32,
                          p.text,
                          weight: FontWeight.w900,
                          ls: -0.05,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.',
                        style: g6Text(15, p.sub, height: 1.6),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  child: Column(
                    children: [
                      for (var i = 0; i < _items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _card(p, dark, i),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        G6BottomBar(
          child: G6PillButton(
            label: cur.next,
            bg: dark ? const Color(0xFFF2F3F5) : G6Palette.lime,
            fg: dark ? const Color(0xFF17181C) : G6Palette.onLime,
            weight: dark ? FontWeight.w500 : FontWeight.w700,
            onTap: () => demoGo(context, cur.href),
          ),
        ),
      ],
    );
  }

  Widget _card(G6Palette p, bool dark, int i) {
    final it = _items[i];
    final on = i == _pick;
    final bg = on
        ? (dark ? const Color(0xFFF2F3F5) : const Color(0xFFE3E5E9))
        : (dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF));
    final fg = on
        ? (dark ? const Color(0xFF0F1012) : const Color(0xFF17181C))
        : (dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C));
    final dot = on
        ? (dark ? const Color(0xFF0F1012) : G6Palette.lime)
        : (dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB));
    final check = on
        ? (dark ? const Color(0xFFF2F3F5) : G6Palette.onLime)
        : Colors.transparent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _pick = i),
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: on
              ? null
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 24, 28, 0.06),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: 0.75,
                    child: Text(
                      it.side,
                      style: g6Text(12, fg, weight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    it.title,
                    style: g6Text(19, fg, weight: FontWeight.w700, ls: -0.02),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: 0.8,
                    child: Text(it.desc, style: g6Text(13, fg)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              child: DemoSvg(_checkSvg, color: check, size: 13),
            ),
          ],
        ),
      ),
    );
  }
}

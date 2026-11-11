import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 03 관심·보류 (`Likes.dc.html`).
class LikesPage extends StatelessWidget {
  const LikesPage({super.key});

  static const String _heart =
      '<svg width="12" height="12" viewBox="0 0 24 24" fill="#FFFFFF"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';
  static const String _compare =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="2.2"><rect x="3" y="4" width="8" height="16" rx="2"></rect><rect x="13" y="4" width="8" height="16" rx="2"></rect></svg>';

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G1Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('관심·보류', style: g1Text(26, 900, p.text, ls: -0.03)),
                      const SizedBox(height: 4),
                      Text(
                        '관심 표시는 협업 확정이 아니에요. 모아두고 비교해요.',
                        style: g1Text(13, 400, p.sub),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      _tab(p, '전체 2', true),
                      const SizedBox(width: 6),
                      _tab(p, '서로 관심 1', false),
                      const SizedBox(width: 6),
                      _tab(p, '보낸 관심 1', false),
                      const SizedBox(width: 6),
                      _tab(p, '보류 0', false),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(child: _mutualCard(context)),
                      const SizedBox(width: 10),
                      Expanded(child: _waitingCard()),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '서윤의 작은 취향과 서로 관심',
                            style: g1Text(13, 500, p.text),
                          ),
                          G1Tap(
                            onTap: () => demoGo(context, 'Terms.dc.html'),
                            child: Text(
                              '협업 조건 확인',
                              style: g1Text(13, 500, g1Ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '민의 옷장 기록은 상대의 응답을 기다리고 있어요.',
                        style: g1Text(12, 400, p.sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 100,
          height: 54,
          child: G1Tap(
            onTap: () => demoGo(context, 'Compare.dc.html'),
            child: Container(
              decoration: BoxDecoration(
                color: g1Lime,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DemoSvg(_compare, size: 18),
                  const SizedBox(width: 8),
                  Text('후보 2명 비교하기', style: g1Text(16, 700, g1OnLime)),
                ],
              ),
            ),
          ),
        ),
        g1BottomNav(context, 1),
      ],
    );
  }

  Widget _tab(G1Palette p, String label, bool selected) {
    final Color bg;
    final Color fg;
    if (selected) {
      bg = p.dark ? const Color(0xFFF2F3F5) : Colors.white;
      fg = g1Ink;
    } else {
      bg = p.surface;
      fg = p.text;
    }
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected && !p.dark
            ? const [
                BoxShadow(
                  color: Color(0x1A17181C),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Text(label, style: g1Text(13, 500, fg)),
    );
  }

  Widget _tile({
    required Color bg,
    required String blob,
    required double y,
    required Widget badge,
    required String name,
    required String line1,
    required String line2,
  }) {
    const sub = Color(0xFFE4E6EA);
    return SizedBox(
      height: 272,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: bg),
            DemoPhoto(DemoImages.forBlob(blob), x: 50, y: y),
            Positioned(left: 8, top: 8, child: badge),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
                decoration: BoxDecoration(
                  gradient: g1FadeDown([
                    0,
                    0.92,
                  ], base: const Color(0xFF111418)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: g1Text(16, 700, Colors.white)),
                    const SizedBox(height: 2),
                    Text(line1, style: g1Text(12, 400, sub)),
                    const SizedBox(height: 2),
                    Text(line2, style: g1Text(12, 400, sub)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mutualCard(BuildContext context) {
    return G1Tap(
      onTap: () => demoGo(context, 'Match.dc.html'),
      child: _tile(
        bg: const Color(0xFFE8DDCB),
        blob: '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
        y: 40,
        badge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: g1Olive,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DemoSvg(_heart, size: 12),
              const SizedBox(width: 4),
              Text('서로 관심', style: g1Text(11, 500, Colors.white)),
            ],
          ),
        ),
        name: '서윤의 작은 취향',
        line1: '출근 전 30초, 오늘의 손목 루틴',
        line2: '30만 원, 11월 16일 이후',
      ),
    );
  }

  Widget _waitingCard() {
    return _tile(
      bg: const Color(0xFFD9DCE6),
      blob: '/_blob/b69c53f92919508dbffde40eedb1953c',
      y: 30,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xB8111418),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('응답 대기', style: g1Text(11, 500, Colors.white)),
      ),
      name: '민의 옷장 기록',
      line1: '같은 니트, 세 가지 액세서리',
      line2: '35만 원, 일정 협의',
    );
  }
}

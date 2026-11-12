import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

/// B7 입찰 결과 (NBidResult)
class BidResultPage extends StatelessWidget {
  const BidResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    // 다크 파일은 예산 카드 바탕이 화면 바탕과 같고 금액이 라임색이다.
    final cardBg = dark ? const Color(0xFF0F1012) : const Color(0xFFF8F9FA);
    final amount = dark ? G6Palette.lime : const Color(0xFF17181C);
    final fill = dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);
    final listBg = p.card;
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const G6Header(title: '입찰 결과'),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이번 주 입찰 예산', style: g6Text(13, p.sub)),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '180,000원',
                            style: g6Text(
                              32,
                              amount,
                              weight: FontWeight.w900,
                              ls: -0.05,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('/ 500,000원 사용', style: g6Text(14, p.sub)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 6,
                          color: p.line,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.36,
                            child: Container(height: 6, color: fill),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final e in const [
                            ('수락', '1'),
                            ('대기', '1'),
                            ('거절', '1'),
                          ])
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: e.$1,
                                      style: TextStyle(color: p.sub),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(text: e.$2),
                                  ],
                                ),
                                style: g6Text(13, p.text),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      _item(
                        p,
                        bg: listBg,
                        thumbBg: const Color(0xFFE8DDCB),
                        asset: DemoImages.seoyun,
                        y: 30,
                        name: '서윤의 작은 취향',
                        sub: '10만 원 입찰, 수락했어요',
                        subColor: p.text,
                        trailing: _action(
                          '결제하기',
                          bg: dark
                              ? const Color(0xFFF2F3F5)
                              : const Color(0xFFFFFFFF),
                          shadow: !dark,
                          onTap: () => demoGo(context, 'NPay.dc.html'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _item(
                        p,
                        bg: listBg,
                        thumbBg: const Color(0xFFD9DCE6),
                        asset: DemoImages.minCloset,
                        y: 12,
                        name: '민의 옷장 기록',
                        sub: '5만 원 입찰, 2일 안에 답이 와요',
                        subColor: p.sub,
                        trailing: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('대기', style: g6Text(13, p.sub)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _item(
                        p,
                        bg: listBg,
                        thumbBg: const Color(0xFFF3E3D3),
                        asset: DemoImages.onecup,
                        y: 25,
                        name: '하루 한 컵',
                        sub: '3만 원 입찰, 일정이 안 맞아 거절',
                        subColor: p.sub,
                        trailing: _action(
                          '다시 입찰',
                          bg: const Color(0xFFFFFFFF),
                          shadow: false,
                          onTap: () => demoGo(context, 'NBidding.dc.html'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        G6BottomBar(
          child: G6PillButton(
            label: '계속 입찰하기',
            bg: dark ? const Color(0xFFF2F3F5) : G6Palette.lime,
            fg: dark ? const Color(0xFF17181C) : G6Palette.onLime,
            weight: dark ? FontWeight.w500 : FontWeight.w700,
            onTap: () => demoGo(context, 'NBidding.dc.html'),
          ),
        ),
      ],
    );
  }

  Widget _item(
    G6Palette p, {
    required Color bg,
    required Color thumbBg,
    required String asset,
    required double y,
    required String name,
    required String sub,
    required Color subColor,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: thumbBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DemoPhoto(asset, x: 50, y: y),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: g6Text(15, p.text, weight: FontWeight.w700)),
                Text(sub, style: g6Text(13, subColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _action(
    String label, {
    required Color bg,
    required bool shadow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 24, 28, 0.10),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: g6Text(13, const Color(0xFF17181C), weight: FontWeight.w500),
        ),
      ),
    );
  }
}

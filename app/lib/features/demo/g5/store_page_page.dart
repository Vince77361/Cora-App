import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g5_common.dart';

/// A3 자동 생성된 가게 페이지 (`NStorePage.dc.html`)
class StorePagePage extends StatelessWidget {
  const StorePagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = G5Palette.of(context);
    final badgeStar =
        '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${pal.dark ? '#F2F3F5' : '#17181C'}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"></path></svg>';
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G5Header(
                  pal: pal,
                  onBack: () => demoBack(context),
                  center: const SizedBox.shrink(),
                  right: '2 / 3',
                ),
                G5Progress(pal: pal, fraction: 0.67),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E3C8),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: DemoPhoto(DemoImages.ramen, x: 50, y: 45),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 160,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(23, 24, 28, 0),
                                Color.fromRGBO(23, 24, 28, 0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DemoSvg(badgeStar, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '링크에서 자동으로 만들었어요',
                                style: g5Text(
                                  12,
                                  G5Palette.ink,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '라멘집, 성수동',
                              style: g5Text(13, const Color(0xFFE4E6EA)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '한그릇 라멘',
                              style: g5Text(
                                26,
                                const Color(0xFFFFFFFF),
                                weight: FontWeight.w900,
                                letterSpacing: -0.04,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _fact(pal, '대표 메뉴', '돈코츠 라멘 11,000원'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _fact(pal, '영업시간', '11:30 – 21:00'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _fact(pal, '좌석', '18석, 바 좌석')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _fact(pal, '찍기 좋은 시간', '오후 3시 – 5시'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: pal.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '크리에이터에게 보여줄 소개',
                            style: g5Text(
                              12,
                              pal.text,
                              weight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(31, 42, 0, 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '고치기',
                              style: g5Text(
                                12,
                                pal.dark
                                    ? const Color(0xFFE4FFB0)
                                    : G5Palette.limeInk,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.',
                        style: g5Text(15, pal.text, height: 1.55),
                      ),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: G5BigButton(
                    label: '정보 고치기',
                    background: pal.card,
                    foreground: pal.text,
                    size: 15,
                    weight: FontWeight.w500,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: G5BigButton(
                    label: '이대로 다음',
                    background: G5Palette.lime,
                    foreground: G5Palette.limeInk,
                    onTap: () => demoGo(context, 'NStoreAI.dc.html'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fact(G5Palette pal, String term, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: g5Text(12, pal.sub)),
          const SizedBox(height: 4),
          Text(value, style: g5Text(15, pal.text, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 04 후보 비교 (`Compare.dc.html`).
class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  static const String _back =
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: G1Tap(
                            onTap: () => demoBack(context),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: DemoSvg(_back, color: p.text, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '후보 비교',
                          textAlign: TextAlign.center,
                          style: g1Text(16, 500, p.text),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('팔로워 수는 비교하지 않아요', style: g1Text(12, 400, p.sub)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 104,
          bottom: 28,
          child: Row(
            children: [
              Expanded(
                child: _CompareCard(
                  bg: const Color(0xFFE8DDCB),
                  blob: '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
                  x: 60,
                  y: 30,
                  chip: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: p.dark ? const Color(0xFFF2F3F5) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: p.dark
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x1A17181C),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                    ),
                    child: Text('서로 관심', style: g1Text(12, 500, g1Ink)),
                  ),
                  name: '서윤의 작은 취향',
                  title: '출근 전 30초, 오늘의 손목 루틴',
                  price: '30만 원',
                  detail: '11월 16일 이후\n얼굴 출연 없음',
                  action: G1Tap(
                    onTap: () => demoGo(context, 'Terms.dc.html'),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: g1Lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text('조건 보기', style: g1Text(15, 700, g1OnLime)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompareCard(
                  bg: const Color(0xFFD9DCE6),
                  blob: '/_blob/b69c53f92919508dbffde40eedb1953c',
                  x: 50,
                  y: 25,
                  chip: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x9917181C),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('응답 대기', style: g1Text(12, 500, Colors.white)),
                  ),
                  name: '민의 옷장 기록',
                  title: '같은 니트, 세 가지 액세서리',
                  price: '35만 원',
                  detail: '일정 협의\n추가 촬영 별도',
                  action: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '응답 기다리는 중',
                      style: g1Text(14, 500, g1PhotoText),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.bg,
    required this.blob,
    required this.x,
    required this.y,
    required this.chip,
    required this.name,
    required this.title,
    required this.price,
    required this.detail,
    required this.action,
  });

  final Color bg;
  final String blob;
  final double x;
  final double y;
  final Widget chip;
  final String name;
  final String title;
  final String price;
  final String detail;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: bg),
          DemoPhoto(DemoImages.forBlob(blob), x: x, y: y),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: g1FadeDown([0, 0.6, 0.88], stops: const [0, 0.45, 1]),
              ),
            ),
          ),
          Positioned(left: 12, top: 12, child: chip),
          Positioned(
            left: 14,
            right: 12,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name, style: g1Text(13, 500, g1PhotoText)),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: g1Text(20, 900, Colors.white, ls: -0.045, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(price, style: g1Text(24, 900, g1Lime, ls: -0.03)),
                const SizedBox(height: 8),
                Text(detail, style: g1Text(13, 400, g1PhotoText, height: 1.5)),
                const SizedBox(height: 14),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

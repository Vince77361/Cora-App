import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 02 넘기기 이유 (`Pass.dc.html`). 이유를 하나 고르거나(다시 누르면 해제) 그냥 넘긴다.
class PassPage extends StatefulWidget {
  const PassPage({super.key});

  @override
  State<PassPage> createState() => _PassPageState();
}

const List<(String, String)> _reasons = [
  ('분위기가 달라요', 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM8 14s1.5 2 4 2 4-2 4-2'),
  ('분야가 달라요', 'M4 6h16M4 12h16M4 18h10'),
  ('조건이 안 맞아요', 'M12 2v20M17 6H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6'),
  ('이유 없이 넘기기', 'M5 12h14M13 6l6 6-6 6'),
];

class _PassPageState extends State<PassPage> {
  int _pick = 2;

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    final pageBg = p.dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);
    final sheetBg = p.dark ? const Color(0xFF0F1012) : Colors.white;
    return DemoFrame(
      background: pageBg,
      children: [
        // 방금 넘긴 카드가 왼쪽으로 기울어 있는 뒷모습
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          height: 560,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.translationValues(-40, 0, 0)
              ..rotateZ(-6 * math.pi / 180),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFE8DDCB)),
                  DemoPhoto(
                    DemoImages.forBlob(
                      '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
                    ),
                    x: 50,
                    y: 30,
                  ),
                  Positioned(
                    right: 26,
                    top: 40,
                    child: Transform.rotate(
                      angle: 14 * math.pi / 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x8C17181C),
                          border: Border.all(color: Colors.white, width: 5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('넘김', style: g1Text(38, 500, Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0x730F1012))),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              reverse: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: p.dark
                              ? const Color(0xFF2A2D33)
                              : const Color(0xFFE6E8EB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '어떤 점이 달랐나요?',
                            style: g1Text(20, 500, p.text, ls: -0.02),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '다음 추천에만 반영하고, 서윤의 작은 취향에게는 알리지 않아요.',
                            style: g1Text(14, 400, p.sub),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _reasons.length; i++) _row(p, i),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          G1Tap(
                            onTap: () => demoGo(context, 'Main.dc.html'),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: p.dark
                                    ? const Color(0xFFF2F3F5)
                                    : g1Lime,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '넘기고 다음 추천 보기',
                                style: g1Text(
                                  16,
                                  p.dark ? 500 : 700,
                                  p.dark ? g1Ink : g1OnLime,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          G1Tap(
                            onTap: () => demoGo(context, 'Main.dc.html'),
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              child: Text('취소', style: g1Text(14, 500, p.sub)),
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
        ),
      ],
    );
  }

  Widget _row(G1Palette p, int i) {
    final on = _pick == i;
    final (label, path) = _reasons[i];
    final iconBg = on
        ? (p.dark ? const Color(0xFFF2F3F5) : g1Lime)
        : (p.dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA));
    final iconFg = on ? (p.dark ? const Color(0xFF0F1012) : g1OnLime) : p.sub;
    final dot = on ? (p.dark ? const Color(0xFF0F1012) : g1Lime) : p.line;
    final check = on
        ? (p.dark ? const Color(0xFFF2F3F5) : g1OnLime)
        : Colors.transparent;
    return G1Tap(
      onTap: () => setState(() => _pick = on ? -1 : i),
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: DemoSvg(
                  '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="$path"></path></svg>',
                  color: iconFg,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: g1Text(16, 400, p.text))),
              const SizedBox(width: 14),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: DemoSvg(
                  '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>',
                  color: check,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

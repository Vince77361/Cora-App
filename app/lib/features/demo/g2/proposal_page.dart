import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g2_palette.dart';

/// 10 콘텐츠 기반 제안: 브랜드가 고른 내 콘텐츠 위에 제안이 얹힌다.
class ProposalPage extends StatelessWidget {
  const ProposalPage({super.key});

  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final p = G2Palette.of(context);
    final headColor = p.dark
        ? const Color(0xFFF2F3F5)
        : const Color(0xFF17181C);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => demoGo(context, 'CreatorDiscover.dc.html'),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: DemoSvg(
                            G2Icons.close,
                            color: headColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '받은 제안',
                    textAlign: TextAlign.center,
                    style: g2Text(
                      16,
                      color: headColor,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 56,
          bottom: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: const Color(0xFF0F1012),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DemoPhoto(DemoImages.seoyun, x: 50, y: 35),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 180,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(15, 16, 18, 0.55),
                            Color.fromRGBO(15, 16, 18, 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 520,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.45, 1],
                          colors: [
                            Color.fromRGBO(15, 16, 18, 0),
                            Color.fromRGBO(15, 16, 18, 0.55),
                            Color.fromRGBO(15, 16, 18, 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 사진 넘김 막대
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: p.dark ? const Color(0xFF0F1012) : _white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 브랜드 머리글
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 24,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              color: G2Palette.photoGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const DemoPhoto(
                              DemoImages.moaStudio,
                              x: 62,
                              y: 40,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '모아 스튜디오',
                                  style: g2Text(
                                    14,
                                    color: _white,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '내 콘텐츠 「매일 손이 가는 물건들」에 제안했어요',
                                  style: g2Text(
                                    12,
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.8,
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
                  // 말풍선과 금액
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 168,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.rotate(
                          angle: -1.5 * math.pi / 180,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(255, 255, 255, 0.94),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '브랜드가 좋아한 점',
                                  style: g2Text(
                                    12,
                                    color: headColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '실제로 사용하는 장면이 좋았어요. 새 주얼리도 서윤님의 일상 안에서 소개하고 싶어요.',
                                  style: g2Text(
                                    17,
                                    color: const Color(0xFF17181C),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '30만 원 + 제품',
                              style: g2Text(
                                28,
                                color: G2Palette.lime,
                                weight: FontWeight.w900,
                                spacingEm: -0.04,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '릴스 1편',
                              style: g2Text(
                                14,
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 아래 버튼과 한 줄 입력
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => demoGo(context, 'Chat.dc.html'),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: G2Palette.lime,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '관심 보내기',
                                      style: g2Text(
                                        15,
                                        color: G2Palette.onLime,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => demoGo(context, 'Chat.dc.html'),
                                  child: _glass(
                                    radius: 999,
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.16,
                                    ),
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '조건부터 질문하기',
                                        style: g2Text(
                                          15,
                                          color: _white,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _glass(
                            radius: 999,
                            color: const Color.fromRGBO(255, 255, 255, 0.12),
                            child: SizedBox(
                              height: 52,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(18, 0, 6, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        style: g2Text(15, color: _white),
                                        cursorColor: _white,
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          border: InputBorder.none,
                                          hintText: '내가 만들고 싶은 콘텐츠를 한 줄로',
                                          hintStyle: g2Text(
                                            15,
                                            color: const Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          demoGo(context, 'Chat.dc.html'),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: G2Palette.lime,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: DemoSvg(
                                            '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>',
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// `backdrop-filter: blur(8px)` + 반투명 채움.
  static Widget _glass({
    required double radius,
    required Color color,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color),
          child: child,
        ),
      ),
    );
  }
}

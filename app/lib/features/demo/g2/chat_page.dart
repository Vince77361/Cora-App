import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g2_palette.dart';

/// 11 다이렉트 대화: 메시지 요청을 받고 수락·거절을 고른다.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static const _white = Color(0xFFFFFFFF);
  static const _lockIcon =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="11" width="14" height="10" rx="2"></rect><path d="M8 11V8a4 4 0 0 1 8 0v3"></path></svg>';

  @override
  Widget build(BuildContext context) {
    final p = G2Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 112),
            child: Stack(
              children: [
                // 위쪽 사진
                SizedBox(
                  height: 330,
                  width: double.infinity,
                  child: Container(
                    color: G2Palette.photoGreen,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: DemoPhoto(DemoImages.moaStudio, x: 62, y: 50),
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 200,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.fromRGBO(15, 16, 18, 0),
                                  Color.fromRGBO(15, 16, 18, 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => demoBack(context),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: DemoSvg(
                                  G2Icons.back,
                                  color: _white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 44,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '메시지 요청',
                                style: g2Text(
                                  13,
                                  color: const Color.fromRGBO(
                                    255,
                                    255,
                                    255,
                                    0.85,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '모아 스튜디오',
                                style: g2Text(
                                  28,
                                  color: _white,
                                  weight: FontWeight.w900,
                                  spacingEm: -0.04,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '느린 결, 일상의 주얼리 캠페인',
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
                        ),
                      ],
                    ),
                  ),
                ),
                // 흰 판
                Padding(
                  padding: const EdgeInsets.only(top: 306),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '“안녕하세요! 주얼리를 먼저 7일 정도 사용해보신 뒤, 11월 16일 이후 촬영이 가능하실까요?”',
                          style: g2Text(
                            22,
                            color: p.text,
                            weight: FontWeight.w500,
                            spacingEm: -0.03,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('오늘 오후 2:14', style: g2Text(13, color: p.sub)),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _cell(p, '제작물', '릴스 1편')),
                            const SizedBox(width: 8),
                            Expanded(child: _cell(p, '제작비', '30만 원')),
                            const SizedBox(width: 8),
                            Expanded(child: _cell(p, '촬영', '11/16 이후')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: DemoSvg(_lockIcon, color: p.sub, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '수락하기 전에는 내 추가 연락처가 공개되지 않아요. 수락 후에도 대화 관리에서 차단하거나 신고할 수 있어요.',
                                style: g2Text(14, color: p.sub, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 아래 고정 버튼
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '거절',
                      style: g2Text(16, color: p.text, weight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => demoGo(context, 'NChatThread.dc.html'),
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: G2Palette.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '대화 수락',
                        style: g2Text(
                          16,
                          color: G2Palette.onLime,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(G2Palette p, String k, String v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: g2Text(12, color: p.sub)),
          const SizedBox(height: 4),
          Text(
            v,
            style: g2Text(15, color: p.text, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

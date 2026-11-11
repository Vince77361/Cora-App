import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g3_common.dart';

/// 13 기획 가이드 (`Guide.dc.html`)
class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  static const _brand = [
    '제품 소재와 관리 방법',
    '제품명·브랜드명 정확히',
    '광고 관계 표시',
    '확인 안 된 효능 표현 빼기',
  ];
  static const _mine = [
    '도입부와 이야기 흐름',
    '촬영 장소·구도·음악',
    '평소 말투와 솔직한 후기',
    '얼굴 없이 손 중심 촬영',
  ];

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.text),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, p),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '출근 전 30초, 오늘의 손목 루틴',
                          style: TextStyle(fontSize: 13, color: p.sub),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '정보는 정확하게,\n표현은 나답게.',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: g3Ls(24, -0.04),
                            height: 1.3,
                            color: p.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _colHead('브랜드가 정해요', p.sub)),
                            const SizedBox(width: 8),
                            Expanded(child: _colHead('내가 정해요', p.text)),
                          ],
                        ),
                        for (var i = 0; i < 4; i++) ...[
                          const SizedBox(height: 8),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _cell(_brand[i], p)),
                                const SizedBox(width: 8),
                                Expanded(child: _cell(_mine[i], p)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '장면 흐름 제안',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: p.text,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _scene1(p)),
                        const SizedBox(width: 8),
                        Expanded(child: _scene2(p)),
                        const SizedBox(width: 8),
                        Expanded(child: _scene3(p)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: G3Pill(
              label: '이 방향으로 저장',
              background: p.accent,
              color: p.onAccent,
              height: 54,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              onTap: () => demoGo(context, 'Review.dc.html'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, G3Palette p) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            G3HeaderButton(svg: g3BackSvg, color: p.text, label: '뒤로'),
            const SizedBox(width: 4),
            Text(
              '기획 가이드',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colHead(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _cell(String label, G3Palette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, height: 1.45, color: p.text),
      ),
    );
  }

  Widget _sceneShell({required Color bg, required List<Widget> children}) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(children: children),
    );
  }

  Widget _num(String n, Color color) => Positioned(
    left: 10,
    top: 10,
    child: Text(
      n,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
    ),
  );

  Widget _title(String t, Color color, FontWeight w) => Positioned(
    left: 10,
    right: 10,
    bottom: 10,
    child: Text(
      t,
      style: TextStyle(fontSize: 14, fontWeight: w, color: color),
    ),
  );

  Widget _scene1(G3Palette p) {
    return _sceneShell(
      bg: const Color(0xFFEDE6DA),
      children: [
        Positioned(
          top: 34,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFD8EEF2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        _num('1', p.sub),
        _title('세안', p.text, FontWeight.w500),
      ],
    );
  }

  Widget _scene2(G3Palette p) {
    return _sceneShell(
      bg: const Color(0xFFE3E4EA),
      children: [
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 40,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF8C93A8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ),
        ),
        _num('2', p.sub),
        _title('옷 고르기', p.text, FontWeight.w500),
      ],
    );
  }

  Widget _scene3(G3Palette p) {
    return _sceneShell(
      bg: p.card,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: 100,
          child: const DemoPhoto(DemoImages.seoyun, x: 50, y: 40),
        ),
        _num('3', const Color(0xFFFFFFFF)),
        _title('주얼리 착용', p.text, FontWeight.w700),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 06 받은 제안 · 판본 1 (`Terms.dc.html`). 세부 조건은 하나만 펼쳐진다(처음에는 `추천된 이유`).
class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _Group {
  const _Group(this.id, this.title, this.summary, this.items);

  final String id;
  final String title;
  final String summary;
  final List<(String, String)> items;
}

const List<_Group> _groups = [
  _Group('why', '추천된 이유', '손·소품 중심의 담백한 표현', [
    ('잘 맞는 점', '미니멀한 브랜드 분위기'),
    ('주요 분야', '소품, 데일리룩'),
    ('팔로워', '8,200명'),
  ]),
  _Group('edit', '수정과 촬영', '기획안 기준 1회 수정', [
    ('수정 범위', '기획안 기준 1회'),
    ('추가 촬영', '별도 협의'),
  ]),
  _Group('use', '콘텐츠 활용', '브랜드 계정 재게시만', [
    ('재게시', '브랜드 계정만'),
    ('광고 활용', '별도 협의'),
  ]),
  _Group('pay', '지급과 광고 표시', '최종 게시 후 7일 이내 지급', [
    ('지급 시점', '최종 게시 후 7일 이내'),
    ('광고 표시', '게시물·영상에 명확히'),
  ]),
];

class _TermsPageState extends State<TermsPage> {
  String? _open = 'why';

  static const String _back =
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';
  static const String _chevron =
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6 6-6"></path></svg>';

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
          bottom: 90,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 248,
                  child: _hero(context),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 224),
                  child: _body(p),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 90,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: p.bg,
              boxShadow: [
                BoxShadow(
                  color: p.dark
                      ? const Color(0x73000000)
                      : const Color(0x0F17181C),
                  offset: const Offset(0, -8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: G1Tap(
                    onTap: () => demoGo(context, 'Agreement.dc.html'),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text('조건 수정 제안', style: g1Text(15, 700, p.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 14,
                  child: G1Tap(
                    onTap: () => demoGo(context, 'Progress.dc.html'),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: g1Lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text('이 판본 수락', style: g1Text(15, 700, g1OnLime)),
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

  Widget _hero(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFE8DDCB)),
        DemoPhoto(
          DemoImages.forBlob('/_blob/d607dd0c30dba30c6efc831cbd7a6f4f'),
          x: 50,
          y: 42,
        ),
        Positioned(
          left: 10,
          top: 10,
          child: G1Tap(
            onTap: () => demoBack(context, fallback: 'Main.dc.html'),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xE6FFFFFF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const DemoSvg(_back, color: g1Ink, size: 22),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 44),
            decoration: BoxDecoration(gradient: g1FadeDown([0, 0.85])),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('서윤의 작은 취향', style: g1Text(13, 500, g1PhotoText)),
                Text(
                  '출근 전 30초, 오늘의 손목 루틴',
                  style: g1Text(24, 900, Colors.white, ls: -0.04, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(G1Palette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('받은 제안 · 판본 1', style: g1Text(15, 700, p.sub)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: g1Lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '내가 응답할 차례',
                        style: g1Text(12, 500, g1OnLime),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 격자 칸처럼 세 칸의 높이를 맞춘다.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _stat(p, '현금 고정비', '30만 원', 18, 900, ls: -0.03),
                      const SizedBox(width: 6),
                      _stat(p, '혜택', '제품 제공', 15, 700),
                      const SizedBox(width: 6),
                      _stat(p, '성과 추가', '없음', 15, 700),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 30만 원.',
                  style: g1Text(12, 400, p.sub),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('일상형 릴스 1편', style: g1Text(16, 700, p.text)),
                    const SizedBox(width: 20),
                    Text('11월 16일 이후', style: g1Text(16, 500, p.sub)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.',
              style: g1Text(14, 400, p.text, height: 1.55),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final g in _groups) _group(p, g)],
            ),
          ),
        ],
      ),
    );
  }

  /// 핵심 조건 한 칸. 세 칸이 같은 너비로 나란히 선다.
  Widget _stat(
    G1Palette p,
    String label,
    String value,
    double size,
    int weight, {
    double ls = 0,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: g1Text(11, 400, p.sub)),
            const SizedBox(height: 2),
            Text(value, style: g1Text(size, weight, p.text, ls: ls)),
          ],
        ),
      ),
    );
  }

  Widget _group(G1Palette p, _Group g) {
    final open = _open == g.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        G1Tap(
          onTap: () => setState(() => _open = open ? null : g.id),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.title, style: g1Text(16, 700, p.text)),
                      const SizedBox(height: 2),
                      Text(g.summary, style: g1Text(13, 400, p.sub)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: DemoSvg(_chevron, color: p.sub, size: 18),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var i = 0; i < g.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.items[i].$1, style: g1Text(14, 400, p.sub)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          g.items[i].$2,
                          textAlign: TextAlign.right,
                          style: g1Text(14, 500, p.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

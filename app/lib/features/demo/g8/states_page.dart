import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g8_common.dart';

const String _heartSvg =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"></path></svg>';
const String _imageSvg =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="3"></rect><path d="M3 15l5-5 4 4 3-3 6 6"></path></svg>';
const String _chatSvg =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16v11H10l-6 4z"></path></svg>';
const String _warnSvg =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 8v5M12 16.5v.5"></path><path d="M10.3 3.9L2.6 17.5A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"></path></svg>';

class _Pattern {
  const _Pattern(this.svg, this.title, this.body, this.cta, this.href);

  final String svg;
  final String title;
  final String body;
  final String cta;
  final String href;
}

const List<_Pattern> _patterns = [
  _Pattern(
    _heartSvg,
    '오늘 추천을 모두 봤어요',
    '관심과 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.',
    '저장한 후보 보기',
    'Likes.dc.html',
  ),
  _Pattern(
    _imageSvg,
    '영상을 불러오지 못했어요',
    '연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.',
    '다시 시도',
    'Main.dc.html',
  ),
  _Pattern(
    _chatSvg,
    '아직 받은 제안이 없어요',
    '포트폴리오를 채우면 가게와 브랜드의 추천에 더 자주 보여요.',
    '콘텐츠 올리기',
    'NUpload.dc.html',
  ),
  _Pattern(
    _warnSvg,
    '이전 판본이라 수락할 수 없어요',
    '상대가 판본 3을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.',
    '판본 3 보기',
    'Agreement.dc.html',
  ),
];

/// F8 빈 상태·오류 패턴 (`NStates.dc.html`)
class StatesPage extends StatelessWidget {
  const StatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = G8Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 64,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '상태 패턴',
                    style: g8Text(16, pal.text, weight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _loading(pal),
                      for (final p in _patterns) ...[
                        const SizedBox(height: 10),
                        _pattern(context, pal, p),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 불러오는 중: 회색 막대로 그린 자리표시.
  Widget _loading(G8Palette pal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: pal.line,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.70,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: pal.line,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.45,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: pal.line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('불러오는 중', style: g8Text(12, pal.sub)),
        ],
      ),
    );
  }

  Widget _pattern(BuildContext context, G8Palette pal, _Pattern p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pal.dark ? pal.bg : pal.raised,
              shape: BoxShape.circle,
            ),
            child: DemoSvg(p.svg, color: pal.sub, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: g8Text(15, pal.text, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(p.body, style: g8Text(13, pal.sub, height: 1.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoGo(context, p.href),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      // 다크에서도 흰 바탕에 어두운 글자 그대로다.
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    // 글 길이만큼만 차지한다(`width: max-content`).
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        p.cta,
                        style: g8Text(
                          13,
                          G8Palette.ink,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

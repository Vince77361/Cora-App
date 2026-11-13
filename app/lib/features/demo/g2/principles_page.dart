import 'dart:ui';

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g2_palette.dart';

class _Question {
  const _Question(
    this.id,
    this.multi,
    this.kicker,
    this.title,
    this.hint,
    this.opts,
  );
  final String id;
  final bool multi;
  final String kicker;
  final String title;
  final String hint;
  final List<List<String>> opts;
}

const _questions = <_Question>[
  _Question(
    'field',
    true,
    '함께하고 싶은 분야',
    '어떤 분야의\n제안을 받고 싶나요?',
    '여러 개 골라도 돼요.',
    [
      ['액세서리·주얼리', '반지, 팔찌, 시계'],
      ['리빙·소품', '컵, 조명, 향'],
      ['뷰티', '스킨케어, 메이크업'],
      ['패션', '의류, 가방'],
    ],
  ),
  _Question(
    'block',
    true,
    '제안받지 않을 업종',
    '피하고 싶은\n업종이 있나요?',
    '고른 업종의 브랜드에게는 내 프로필이 보이지 않아요.',
    [
      ['도박·사행성', '베팅, 복권'],
      ['대출', '금융 상품'],
      ['주류', '술, 주점'],
      ['다이어트 보조제', '건강기능식품'],
    ],
  ),
  _Question(
    'face',
    false,
    '촬영 방식',
    '얼굴이 나오는\n촬영도 괜찮나요?',
    '손이나 소품 중심으로만 찍고 싶다면 알려주세요.',
    [
      ['얼굴 없이 할래요', '손·소품 중심'],
      ['괜찮아요', '얼굴 출연 가능'],
    ],
  ),
  _Question(
    'script',
    false,
    '말하는 방식',
    '정해진 대본을\n읽는 건 어때요?',
    '브랜드의 필수 정보는 어느 쪽이든 정확히 담아요.',
    [
      ['내 말투로 할래요', '솔직한 사용 후기'],
      ['대본도 괜찮아요', '정해진 문구 낭독'],
    ],
  ),
  _Question(
    'honest',
    false,
    '후기 방식',
    '단점도 솔직하게\n말해도 될까요?',
    '브랜드가 제안 전에 미리 알 수 있게 보여줘요.',
    [
      ['솔직하게 말할래요', '장점과 단점 모두'],
      ['좋은 점 위주로', '단점은 브랜드에 따로 전달'],
    ],
  ),
  _Question('fee', false, '희망 제작비', '릴스 1편에\n얼마를 생각하나요?', '협의로 바뀔 수 있어요.', [
    ['20만 원대', ''],
    ['30만 원대', ''],
    ['40만 원대', ''],
    ['50만 원 이상', ''],
  ]),
  _Question(
    'days',
    false,
    '제품 사용 기간',
    '제품은 얼마나\n써보고 찍고 싶나요?',
    '배송 일정을 정할 때 함께 보여요.',
    [
      ['3일', ''],
      ['7일', ''],
      ['14일', ''],
      ['상관없어요', ''],
    ],
  ),
];

/// 09 협업 원칙: 질문 7개를 한 장씩 고른다.
class PrinciplesPage extends StatefulWidget {
  const PrinciplesPage({super.key});

  @override
  State<PrinciplesPage> createState() => _PrinciplesPageState();
}

class _PrinciplesPageState extends State<PrinciplesPage> {
  int _step = 0;
  final Map<String, List<int>> _picks = {
    'field': [],
    'block': [],
    'face': [],
    'script': [],
    'honest': [],
    'fee': [],
    'days': [],
  };

  void _pick(_Question q, int i) {
    setState(() {
      final list = _picks[q.id]!;
      if (q.multi) {
        list.contains(i) ? list.remove(i) : list.add(i);
      } else {
        _picks[q.id] = [i];
      }
    });
  }

  String _label(String id) {
    final q = _questions.firstWhere((x) => x.id == id);
    final l = _picks[id]!.map((i) => q.opts[i][0]).toList();
    return l.isEmpty ? '고르지 않음' : l.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final p = G2Palette.of(context);
    final n = _questions.length;
    final asking = _step < n;
    final q = asking ? _questions[_step] : _questions[n - 1];
    final has = (_picks[q.id] ?? []).isNotEmpty;
    final progress =
        (((_step + 1 > n ? n : _step + 1) / n) * 100).round() / 100;

    return DemoFrame(
      background: p.bg,
      children: [
        // 머리글
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 64,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // 첫 질문에서는 실제 앱처럼 이 화면을 떠난다.
                    if (_step > 0) {
                      setState(() => _step -= 1);
                    } else {
                      demoBack(context, fallback: 'NRole.dc.html');
                    }
                  },
                  child: Opacity(
                    opacity: 1,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: DemoSvg(G2Icons.back, color: p.text, size: 24),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoGo(context, 'CreatorDiscover.dc.html'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    child: Text(
                      '나중에',
                      style: g2Text(14, color: p.sub, weight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 유리 카드
        Positioned(
          left: 16,
          right: 16,
          top: 76,
          bottom: 112,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(23, 24, 28, 0.08),
                  offset: Offset(0, 16),
                  blurRadius: 40,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: p.dark
                      ? const Color.fromRGBO(28, 30, 34, 0.85)
                      : const Color.fromRGBO(255, 255, 255, 0.75),
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: G2Palette.lime,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: DemoSvg(
                                '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>',
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asking ? q.kicker : '모두 골랐어요',
                                  style: g2Text(
                                    13,
                                    color: p.text,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  asking
                                      ? '${_step + 1} / $n 단계'
                                      : '$n / $n 단계',
                                  style: g2Text(12, color: p.sub),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 4,
                          color: p.line,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 4,
                              color: p.dark
                                  ? const Color(0xFFF2F3F5)
                                  : const Color(0xFF17181C),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: asking ? _asking(p, q) : _finished(p),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 아래 고정 버튼
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: asking ? _nextButton(p, has, n) : _finishButtons(p),
          ),
        ),
      ],
    );
  }

  Widget _asking(G2Palette p, _Question q) {
    final cur = _picks[q.id] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Text(
          '질문',
          style: g2Text(12, color: p.text, weight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          q.title,
          style: g2Text(
            26,
            color: p.text,
            weight: FontWeight.w900,
            spacingEm: -0.045,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(q.hint, style: g2Text(14, color: p.sub, height: 1.55)),
        const SizedBox(height: 18),
        for (var i = 0; i < q.opts.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _option(p, q, i, cur.contains(i)),
        ],
      ],
    );
  }

  Widget _option(G2Palette p, _Question q, int i, bool on) {
    final Color bg;
    final Color fg;
    final Color dot;
    final Color check;
    if (p.dark) {
      bg = on ? const Color(0xFFF2F3F5) : const Color(0xFF1C1E22);
      fg = on ? const Color(0xFF0F1012) : const Color(0xFFF2F3F5);
      dot = on ? const Color(0xFF0F1012) : const Color(0xFF2A2D33);
      check = on ? const Color(0xFFF2F3F5) : Colors.transparent;
    } else {
      bg = on ? const Color(0xFFE3E5E9) : const Color(0xFFF8F9FA);
      fg = const Color(0xFF17181C);
      dot = on ? G2Palette.lime : const Color(0xFFE6E8EB);
      check = on ? G2Palette.onLime : Colors.transparent;
    }
    final label = q.opts[i][0];
    final sub = q.opts[i][1];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pick(q, i),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: g2Text(16, color: fg, weight: FontWeight.w500),
                  ),
                  if (sub.isNotEmpty)
                    Opacity(
                      opacity: 0.75,
                      child: Text(sub, style: g2Text(12, color: fg)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              child: Center(
                child: DemoSvg(
                  '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>',
                  color: check,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finished(G2Palette p) {
    final items = <List<String>>[
      ['함께하고 싶은 분야', _label('field')],
      ['피하는 업종', _label('block')],
      ['촬영 방식', _label('face')],
      ['말하는 방식', _label('script')],
      ['후기 방식', _label('honest')],
      ['희망 제작비', _label('fee')],
      ['제품 사용 기간', _label('days')],
    ];
    Widget cell(List<String> m) => Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m[0], style: g2Text(12, color: p.sub)),
          const SizedBox(height: 4),
          Text(
            m[1],
            style: g2Text(
              14,
              color: p.text,
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cell(items[i])),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < items.length
                    ? cell(items[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: 8));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Text(
          '나답게 일하는 기준이\n완성됐어요.',
          style: g2Text(
            26,
            color: p.text,
            weight: FontWeight.w900,
            spacingEm: -0.045,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '프로필과 받은 제안에 이 기준이 함께 보여요.',
          style: g2Text(14, color: p.sub, height: 1.55),
        ),
        const SizedBox(height: 18),
        ...rows,
      ],
    );
  }

  Widget _nextButton(G2Palette p, bool has, int n) {
    final Color bg;
    final Color fg;
    if (p.dark) {
      bg = has ? const Color(0xFFF2F3F5) : const Color(0xFF2A2D33);
      fg = has ? const Color(0xFF0F1012) : const Color(0xFFA0A4AD);
    } else {
      bg = has ? G2Palette.lime : const Color(0xFFE6E8EB);
      fg = has ? G2Palette.onLime : const Color(0xFF5C6068);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: has ? () => setState(() => _step += 1) : null,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _step == n - 1 ? '다 골랐어요' : '다음',
          style: g2Text(16, color: fg, weight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _finishButtons(G2Palette p) {
    return Row(
      children: [
        Expanded(
          flex: 10,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _step = 0),
            child: Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '다시 고르기',
                style: g2Text(
                  15,
                  color: const Color(0xFF17181C),
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 16,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => demoGo(context, 'CreatorDiscover.dc.html'),
            child: Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: G2Palette.lime,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '저장하고 캠페인 보기',
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
    );
  }
}

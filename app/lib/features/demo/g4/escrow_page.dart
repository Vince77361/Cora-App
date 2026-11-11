import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// A7 에스크로 결제·지급 (`NEscrow.dc.html`).
class EscrowPage extends StatelessWidget {
  const EscrowPage({super.key});

  static const _shield =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"></path></svg>';

  // [제목, 부제, 상태]
  static const _rows = [
    ['오퍼 수락', '11월 10일', 'done'],
    ['가게 결제 완료', 'Cora가 금액을 보관해요', 'done'],
    ['방문하고 촬영하기', '식사권은 방문 때 보여주세요', 'now'],
    ['콘텐츠 올리고 링크 제출', '11월 23일까지', 'todo'],
    ['7일간 조회수 집계 후 지급', '최대 10만 원', 'todo'],
  ];

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G4TitleHeader(
                  title: '한그릇 라멘 협업',
                  leading: G4HeaderButton(
                    svg: G4Icons.back,
                    label: '뒤로',
                    size: 24,
                  ),
                ),
                _Summary(c: c),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    children: [
                      for (var i = 0; i < _rows.length; i++)
                        _Step(c: c, index: i, row: _rows[i]),
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
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.fill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '문의하기',
                      style: g4Style(
                        15,
                        weight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => demoGo(context, 'Review.dc.html'),
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: G4Colors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '콘텐츠 링크 제출',
                        style: g4Style(
                          16,
                          weight: FontWeight.w700,
                          color: G4Colors.onLime,
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
}

class _Summary extends StatelessWidget {
  const _Summary({required this.c});

  final G4Colors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DemoSvg(EscrowPage._shield, color: c.text, size: 16),
              const SizedBox(width: 8),
              Text('Cora가 안전하게 보관 중', style: g4Style(13, color: c.sub)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '100,000원',
            style: g4Style(
              40,
              weight: FontWeight.w900,
              color: c.text,
              em: -0.05,
            ),
          ),
          const SizedBox(height: 4),
          Text('+ 2인 식사권 (방문 때 사용)', style: g4Style(14, color: c.sub)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(c: c, label: '지금 받을 금액', value: '43,200원'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(c: c, label: '조회수', value: '4,320회'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.c, required this.label, required this.value});

  final G4Colors c;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: g4Style(12, color: c.sub)),
        const SizedBox(height: 2),
        Text(
          value,
          style: g4Style(18, weight: FontWeight.w500, color: c.text),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.c, required this.index, required this.row});

  final G4Colors c;
  final int index;
  final List<String> row;

  @override
  Widget build(BuildContext context) {
    final done = row[2] == 'done';
    final now = row[2] == 'now';
    final isLast = index == EscrowPage._rows.length - 1;
    final Color dotBg;
    final Color dotFg;
    if (c.dark) {
      dotBg = done || now ? const Color(0xFFF2F3F5) : const Color(0xFF1C1E22);
      dotFg = done
          ? G4Colors.lime
          : now
          ? const Color(0xFF0F1012)
          : const Color(0xFFA0A4AD);
    } else {
      dotBg = done
          ? const Color(0xFFE6E8EB)
          : now
          ? G4Colors.lime
          : const Color(0xFFF8F9FA);
      dotFg = done
          ? G4Colors.ink
          : now
          ? G4Colors.onLime
          : const Color(0xFF5C6068);
    }
    final titleColor = done ? c.sub : c.text;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    done ? '✓' : '${index + 1}',
                    style: g4Style(12, weight: FontWeight.w500, color: dotFg),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : c.line,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row[0],
                      style: g4Style(
                        15,
                        weight: now ? FontWeight.w700 : FontWeight.w400,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(row[1], style: g4Style(13, color: c.sub)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

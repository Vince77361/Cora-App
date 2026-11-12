import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 04 후보 비교 (`Compare.dc.html`). 같은 결과물 기준으로 맞춘 표이고, 점 표시는 조건이 다른 항목이다.
class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  static const String _back =
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

  /// (항목, 서윤의 작은 취향, 민의 옷장 기록, 조건이 다른 항목인가)
  static const List<(String, String, String, bool)> _rows = [
    ('결과물', '릴스 1편 · 30초', '릴스 1편 · 30초', false),
    ('혜택', '제품 제공', '제품 제공', false),
    ('현금 고정비', '30만 원', '35만 원', true),
    ('성과 상한', '없음', '없음', false),
    ('사용권', '브랜드 계정 재게시', '재게시 + 광고 3개월', true),
    ('촬영 가능일', '11월 16일 이후', '일정 협의', true),
    ('얼굴 출연', '없음', '있음', true),
  ];

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 64,
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
                                  child: DemoSvg(
                                    _back,
                                    color: p.text,
                                    size: 24,
                                  ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '같은 결과물 기준으로 맞췄어요. 점 표시는 조건이 다른 항목이에요. 팔로워 수는 비교하지 않아요.',
                    style: g1Text(13, 400, p.sub),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _table(p),
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
                  child: G1Tap(
                    onTap: () => demoGo(context, 'NBudget.dc.html'),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: p.dark
                            ? const Color(0xFF2A2D33)
                            : const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text('민에게 제안', style: g1Text(15, 500, p.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: G1Tap(
                    onTap: () => demoGo(context, 'Terms.dc.html'),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: g1Lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text('서윤의 제안 보기', style: g1Text(16, 700, g1OnLime)),
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

  Widget _table(G1Palette p) {
    return Table(
      columnWidths: const {
        0: FractionColumnWidth(0.26),
        1: FractionColumnWidth(0.37),
        2: FractionColumnWidth(0.37),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(horizontalInside: BorderSide(color: p.line)),
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            _head(
              p,
              bg: const Color(0xFFE8DDCB),
              blob: '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
              x: 60,
              y: 30,
              name: '서윤의 작은 취향',
              status: '서로 관심',
            ),
            _head(
              p,
              bg: const Color(0xFFD9DCE6),
              blob: '/_blob/b69c53f92919508dbffde40eedb1953c',
              x: 50,
              y: 25,
              name: '민의 옷장 기록',
              status: '응답 대기',
            ),
          ],
        ),
        for (final r in _rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (r.$4) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF17181C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      r.$1,
                      softWrap: false,
                      style: g1Text(12, 500, p.sub),
                    ),
                  ],
                ),
              ),
              _cell(p, r.$2, r.$4),
              _cell(p, r.$3, r.$4),
            ],
          ),
      ],
    );
  }

  Widget _cell(G1Palette p, String text, bool strong) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      child: Text(text, style: g1Text(14, strong ? 700 : 400, p.text)),
    );
  }

  TableCell _head(
    G1Palette p, {
    required Color bg,
    required String blob,
    required double x,
    required double y,
    required String name,
    required String status,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.bottom,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 132,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: bg),
                    DemoPhoto(DemoImages.forBlob(blob), x: x, y: y),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(name, style: g1Text(14, 700, p.text)),
            Text(status, style: g1Text(12, 400, p.sub)),
          ],
        ),
      ),
    );
  }
}

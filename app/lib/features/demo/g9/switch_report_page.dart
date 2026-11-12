import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g9_common.dart';

const String _bellSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"></path><path d="M10 20a2 2 0 0 0 4 0"></path></svg>';

class _Row {
  const _Row(this.term, this.before, this.after, {this.strong = true});

  final String term;
  final String before;
  final String after;

  /// 마지막 줄만 Cora 칸이 굵지 않다(font-weight 500).
  final bool strong;
}

const List<_Row> _rows = [
  _Row('들어간 돈', '월 [계약 금액] × 3', '오퍼 4건 · 152,000원'),
  _Row('생긴 콘텐츠', '블로그 글 9개', '릴스 4편 + 가게 계정 게시물 12개'),
  _Row('가게 계정에 남은 것', '없음', 'AI 게시물 12개'),
  _Row('평소 대비 반응', '확인 어려움', '평균 2.6배'),
  _Row('누가 왔나', '플랫폼이 선정', '지원자 중 직접 좋아요', strong: false),
];

/// G3 체험단 재계약 전 비교 (`NSwitchReport.dc.html`)
class SwitchReportPage extends StatelessWidget {
  const SwitchReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = G9Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G9Header(
                  pal: pal,
                  title: '지난 3개월 비교',
                  onBack: () => g9Back(context, 'NStoreHome.dc.html'),
                ),
                const SizedBox(height: 4),
                _notice(pal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Text(
                    '같은 3개월,\n무엇이 남았나요?',
                    style: g9Text(
                      24,
                      pal.text,
                      weight: FontWeight.w900,
                      height: 1.3,
                      letterSpacing: -0.045,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _table(pal),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Text(
                    '체험단 금액은 사장님이 입력한 값이에요. 숫자는 가상 예시예요.',
                    style: g9Text(12, pal.sub, height: 1.6),
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
                  child: G9Button(
                    label: '나중에',
                    size: 15,
                    weight: FontWeight.w500,
                    background: pal.soft,
                    foreground: pal.text,
                    onTap: () => demoGo(context, 'NStoreHome.dc.html'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: G9Button(
                    label: '다음 달은 Cora로 오퍼 보내기',
                    background: G9Palette.lime,
                    foreground: G9Palette.limeInk,
                    onTap: () => demoGo(context, 'NOffer.dc.html'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 체험단 계약 종료 안내 상자.
  Widget _notice(G9Palette pal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          DemoSvg(_bellSvg, color: pal.text, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '체험단 계약이 12월 10일에 끝나요. 다시 계약하기 전에 비교해 보세요.',
              style: g9Text(13, pal.text, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 체험단과 Cora를 나란히 놓은 표. 열 너비(첫 칸 34%, 나머지는 캔버스를 그대로 잰 85 : 151.3)와
  /// 줄 위 1px 선, 칸 안 여백을 캔버스와 같게 둔다.
  Widget _table(G9Palette pal) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FractionColumnWidth(0.34),
        1: FlexColumnWidth(85),
        2: FlexColumnWidth(151.3),
      },
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                '체험단',
                style: g9Text(13, pal.sub, weight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                'Cora',
                style: g9Text(13, pal.text, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        for (final r in _rows)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: pal.line)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 13, 0, 12),
                child: Text(
                  r.term,
                  style: g9Text(13, pal.sub, weight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 13, 6, 12),
                child: Text(r.before, style: g9Text(14, pal.text)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 13, 6, 12),
                child: Text(
                  r.after,
                  style: g9Text(
                    14,
                    pal.text,
                    weight: r.strong ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

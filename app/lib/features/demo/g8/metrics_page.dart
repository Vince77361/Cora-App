import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g8_common.dart';

const List<(String, String)> _source = [
  ('게시물', 'instagram.com/p/[게시 링크]'),
  ('측정 기간', '11월 4일 – 11월 10일 (7일)'),
  ('자료 출처', '연결 계정 · 캡처 제출 중 확정 예정'),
];

const List<(String, String)> _calc = [
  ('조회수 수당', '12,500회 × 1,000회당 2,000원 = 25,000원'),
  ('1인 상한', '60,000원 · 상한 안'),
  ('사장님께 환불', '35,000원'),
  ('크리에이터 지급 예정', '25,000원'),
];

/// 조회 자료의 확인 상태. 캔버스의 `st`.
enum _Status { unchecked, confirmed, disputed }

/// F4 조회 자료와 보상 계산 (`NMetrics.dc.html`)
class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  _Status _status = _Status.unchecked;

  @override
  Widget build(BuildContext context) {
    final pal = G8Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 캔버스 머리의 "안" 표시는 확정 화면이라 넣지 않는다.
                G8Header(
                  pal: pal,
                  onBack: () => demoBack(context, fallback: 'NEscrow.dc.html'),
                  center: Text(
                    '성과 확인',
                    style: g8Text(16, pal.text, weight: FontWeight.w500),
                  ),
                ),
                _dataCard(pal),
                _calcCard(pal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Text(
                    '자료가 확인되기 전에는 0원이나 지급 완료로 처리하지 않아요. 지급 방식(직접 지급 기록 또는 Cora 보관)은 아직 정하는 중이에요.',
                    style: g8Text(12, pal.sub, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        G8BottomBar(
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: G8BigButton(
                  label: '이의 제기',
                  onTap: () => setState(() => _status = _Status.disputed),
                  background: pal.button,
                  foreground: pal.text,
                  size: 15,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 16,
                child: G8BigButton(
                  label: '자료 확인했어요',
                  onTap: () => setState(() => _status = _Status.confirmed),
                  background: G8Palette.lime,
                  foreground: G8Palette.limeInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(G8Palette pal) {
    final (label, bg, fg) = switch (_status) {
      _Status.unchecked => ('미확인', pal.raised, pal.sub),
      _Status.confirmed => ('확인 완료', G8Palette.lime, G8Palette.limeInk),
      _Status.disputed => ('이의 제기됨', pal.raised, pal.text),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: g8Text(12, fg, weight: FontWeight.w500)),
    );
  }

  Widget _dataCard(G8Palette pal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('조회 자료', style: g8Text(13, pal.sub)),
              _statusChip(pal),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '12,500회',
            style: g8Text(
              32,
              pal.text,
              weight: FontWeight.w900,
              letterSpacing: -0.05,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _source.length; i++)
            G8KeyValueRow(
              pal: pal,
              term: _source[i].$1,
              value: _source[i].$2,
              first: i == 0,
            ),
        ],
      ),
    );
  }

  Widget _calcCard(G8Palette pal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '보상 계산',
              style: g8Text(13, pal.sub, weight: FontWeight.w500),
            ),
          ),
          for (var i = 0; i < _calc.length; i++)
            G8KeyValueRow(
              pal: pal,
              term: _calc[i].$1,
              value: _calc[i].$2,
              first: i == 0,
              bold: i == _calc.length - 1,
            ),
        ],
      ),
    );
  }
}

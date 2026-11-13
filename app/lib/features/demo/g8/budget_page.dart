import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g8_common.dart';

/// 고정 현금 선택지(원). 캔버스의 `amounts`.
const List<int> _amounts = [0, 30000, 50000, 100000];

/// 조회수 수당의 1인 상한(원).
const int _perfCap = 60000;

/// F1 보상·예산 설정 (`NBudget.dc.html`)
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  int _fixed = 0;
  bool _perf = true;

  @override
  Widget build(BuildContext context) {
    final pal = G8Palette.of(context);
    final maxPay = _amounts[_fixed] + (_perf ? _perfCap : 0);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 190),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G8Header(
                  pal: pal,
                  onBack: () =>
                      demoBack(context, fallback: 'NStorePage.dc.html'),
                  center: const SizedBox.shrink(), // 소유자 요청으로 머리의 알약 제목은 뺀다.
                  right: '2 / 3',
                ),
                G8Progress(pal: pal, fraction: 0.67),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '보상을 정해요.',
                        style: g8Text(
                          26,
                          pal.text,
                          weight: FontWeight.w900,
                          height: 1.3,
                          letterSpacing: -0.045,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('식사권과 현금은 따로 계산해요.', style: g8Text(14, pal.sub)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _benefitCard(pal),
                      const SizedBox(height: 8),
                      _fixedCard(pal),
                      const SizedBox(height: 8),
                      _perfCard(pal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        G8BottomBar(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: pal.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('최대 현금 부담 · 남으면 환불', style: g8Text(13, pal.sub)),
                    Text(
                      g8Won(maxPay),
                      style: g8Text(
                        22,
                        pal.text,
                        weight: FontWeight.w900,
                        letterSpacing: -0.04,
                      ),
                    ),
                  ],
                ),
              ),
              G8BigButton(
                label: '검토하고 보내기',
                onTap: () => demoGo(context, 'NReviewSend.dc.html'),
                background: G8Palette.lime,
                foreground: G8Palette.limeInk,
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardBox(G8Palette pal) =>
      BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(20));

  Widget _benefitCard(G8Palette pal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardBox(pal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('제공 혜택', style: g8Text(13, pal.sub)),
              Text('현금과 더하지 않아요', style: g8Text(12, pal.sub)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '식사권 40,000원 · 2인',
            style: g8Text(17, pal.text, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _fixedCard(G8Palette pal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardBox(pal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('고정 현금 (선택)', style: g8Text(13, pal.sub)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _amounts.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _fixedChip(pal, i)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fixedChip(G8Palette pal, int i) {
    final on = i == _fixed;
    final a = _amounts[i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _fixed = i),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? pal.raised : const Color(0x00000000),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          a == 0 ? '없음' : '${a ~/ 10000}만 원',
          style: g8Text(13, pal.text, weight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _perfCard(G8Palette pal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardBox(pal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _perf = !_perf),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('조회수 수당', style: g8Text(15, pal.text)),
                      Text(
                        '조회수만큼 더 드려요 · 기본으로 켜져 있어요',
                        style: g8Text(12, pal.sub),
                      ),
                    ],
                  ),
                ),
                _switch(pal),
              ],
            ),
          ),
          if (_perf)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  G8KeyValueRow(
                    pal: pal,
                    term: '단가',
                    value: '1,000회당 2,000원',
                    first: true,
                    divider: false,
                    padding: 8,
                    valueSize: 14,
                    gap: 0,
                  ),
                  G8KeyValueRow(
                    pal: pal,
                    term: '1인 상한',
                    value: '최대 60,000원',
                    divider: false,
                    padding: 8,
                    valueSize: 14,
                    gap: 0,
                  ),
                  G8KeyValueRow(
                    pal: pal,
                    term: '측정 기간',
                    value: '게시 후 7일',
                    divider: false,
                    padding: 8,
                    valueSize: 14,
                    gap: 0,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 48×28 스위치. 켜면 라임, 끄면 칸 바탕과 다른 회색. 손잡이는 22, 위 3, 왼쪽 23(켬)/3(끔).
  Widget _switch(G8Palette pal) {
    return Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: _perf ? G8Palette.lime : pal.line,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 3,
            left: _perf ? 23 : 3,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: pal.knob,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

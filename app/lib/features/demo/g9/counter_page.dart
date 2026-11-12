import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g9_common.dart';

const String _ramenBlob = '/_blob/05c6e2f12662029787761493c831ec3a';

const List<(String, String)> _series = [
  ('한 그릇 일기', '30초 릴스 · 손 중심'),
  ('동네 점심 지도', '카드뉴스 5장'),
  ('소리로 먹는 집', 'ASMR 릴스'),
];

/// F6 크리에이터 역제안 (`NCounter.dc.html`). 크리에이터가 가게 오퍼에 자기 시리즈로 제안한다.
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _picked = 0;
  final _idea = TextEditingController(
    text: '면을 들어 올리는 손만 찍고, 국물 끓는 소리로 시작하는 30초 릴스로 만들게요.',
  );
  final _ideaFocus = FocusNode();

  @override
  void dispose() {
    _idea.dispose();
    _ideaFocus.dispose();
    super.dispose();
  }

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
                  title: '내 방식으로 제안',
                  onBack: () => g9Back(context, 'NStoreView.dc.html'),
                ),
                const SizedBox(height: 4),
                _store(pal),
                _terms(pal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                  child: Text(
                    '내 시리즈로 만들기',
                    style: g9Text(13, pal.sub, weight: FontWeight.w500),
                  ),
                ),
                _seriesRow(pal),
                _ideaBox(pal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _fact(pal, '희망 보상', '식사권 + 3만 원')),
                        const SizedBox(width: 8),
                        Expanded(child: _fact(pal, '표현 원칙', '#얼굴출연없음')),
                      ],
                    ),
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
            child: G9Button(
              label: '검토하고 보내기',
              background: G9Palette.lime,
              foreground: G9Palette.limeInk,
              onTap: () => demoGo(context, 'NReviewSend.dc.html'),
            ),
          ),
        ),
      ],
    );
  }

  /// 제안할 가게.
  Widget _store(G9Palette pal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF6E3C8),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: DemoPhoto(DemoImages.forBlob(_ramenBlob)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '한그릇 라멘',
                  style: g9Text(16, pal.text, weight: FontWeight.w700),
                ),
                Text('성수동 · 방문 1회 · 오후 3–5시 촬영 가능', style: g9Text(12, pal.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 가게가 내건 조건.
  Widget _terms(G9Palette pal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '가게 조건: 식사권 40,000원 · 2인 + 1,000회당 2,000원, 1인 최대 60,000원 · 추가 부담 없음',
        style: g9Text(13, pal.sub, height: 1.6),
      ),
    );
  }

  /// 시리즈 카드 가로 줄: 카드 폭 140, 간격 8, 줄이 넘치면 옆으로 민다.
  Widget _seriesRow(G9Palette pal) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _series.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Semantics(
                selected: i == _picked,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _picked = i),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: i == _picked ? pal.picked : pal.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _series[i].$1,
                          style: g9Text(14, pal.text, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(_series[i].$2, style: g9Text(12, pal.sub)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 아이디어 입력 상자(textarea 3줄).
  Widget _ideaBox(G9Palette pal) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _ideaFocus.requestFocus,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('아이디어', style: g9Text(12, pal.sub)),
            const SizedBox(height: 4),
            TextField(
              controller: _idea,
              focusNode: _ideaFocus,
              minLines: 3,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              cursorColor: pal.text,
              style: g9Text(15, pal.text, height: 1.55),
              decoration: const InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
            // 캔버스의 textarea는 글줄 안에 놓이는 상자라 아래에 글줄 내림 여백 4.5px이 남는다.
            const SizedBox(height: 4.5),
          ],
        ),
      ),
    );
  }

  Widget _fact(G9Palette pal, String term, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: g9Text(12, pal.sub)),
          const SizedBox(height: 2),
          Text(value, style: g9Text(15, pal.text, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

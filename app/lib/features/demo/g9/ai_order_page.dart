import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g9_common.dart';

const String _ramenBlob = '/_blob/05c6e2f12662029787761493c831ec3a';

const String _tickSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';

const List<(String, String)> _facts = [
  ('사용한 자료', '가게 페이지 · 확인한 사진 3장'),
  ('게시 계정', '한그릇 라멘 (가게 계정)'),
  ('가격', '[AI 제작 가격]'),
];

const List<String> _checkLabels = [
  '메뉴·가격·영업시간이 맞아요',
  '사진은 가게가 쓸 권한이 있어요',
  '게시는 가게 계정에서 직접 해요',
];

/// F5 Cora AI 제작 승인 (`NAIOrder.dc.html`). 확인 세 개를 모두 해야 "승인하고 주문"이 켜진다.
class AiOrderPage extends StatefulWidget {
  const AiOrderPage({super.key});

  @override
  State<AiOrderPage> createState() => _AiOrderPageState();
}

class _AiOrderPageState extends State<AiOrderPage> {
  // 캔버스의 처음 상태: 첫 칸만 켜져 있다.
  final List<bool> _on = [true, false, false];

  bool get _ready => _on.every((x) => x);

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
                  title: 'AI 제작',
                  onBack: () => g9Back(context, 'NStoreAI.dc.html'),
                ),
                const SizedBox(height: 4),
                _preview(),
                _factsBox(pal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Column(
                    children: [
                      for (var i = 0; i < _checkLabels.length; i++)
                        _check(pal, i),
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
                  child: G9Button(
                    label: '수정 요청',
                    size: 15,
                    weight: FontWeight.w500,
                    background: pal.soft,
                    foreground: pal.text,
                    onTap: () => demoGo(context, 'NStoreAI.dc.html'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: _ready
                      ? G9Button(
                          label: '승인하고 주문',
                          background: G9Palette.lime,
                          foreground: G9Palette.limeInk,
                          onTap: () => demoGo(context, 'NStoreHome.dc.html'),
                        )
                      : G9Button.disabled(
                          label: '모두 확인해 주세요',
                          background: pal.card,
                          foreground: pal.sub,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// AI가 만든 카드뉴스 첫 장 미리보기.
  Widget _preview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF6E3C8),
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DemoPhoto(DemoImages.forBlob(_ramenBlob), x: 50, y: 45),
          ),
          const G9PhotoShade(
            height: 120,
            colors: [
              Color.fromRGBO(23, 24, 28, 0),
              Color.fromRGBO(23, 24, 28, 0.7),
            ],
          ),
          const G9PhotoChip('Cora AI 제작 · 사람 크리에이터 아님'),
          Positioned(
            left: 18,
            bottom: 14,
            child: Text(
              '카드뉴스 3장 · 초안 2',
              style: g9Text(
                20,
                G9Palette.onPhoto,
                weight: FontWeight.w900,
                letterSpacing: -0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사용한 자료, 게시 계정, 가격.
  Widget _factsBox(G9Palette pal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _facts.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: pal.line)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_facts[i].$1, style: g9Text(13, pal.sub)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _facts[i].$2,
                      textAlign: TextAlign.right,
                      style: g9Text(15, pal.text, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 확인 칸 한 줄. 줄 전체가 누르는 자리다.
  Widget _check(G9Palette pal, int i) {
    final on = _on[i];
    return Semantics(
      checked: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _on[i] = !on),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? G9Palette.lime : pal.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DemoSvg(
                    _tickSvg,
                    color: on ? G9Palette.limeInk : Colors.transparent,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _checkLabels[i],
                    style: g9Text(14, pal.text, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

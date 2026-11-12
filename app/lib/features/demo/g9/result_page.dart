import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/demo_ui.dart';
import 'g9_common.dart';

const String _onecupBlob = '/_blob/2c6508f8caadc5c0466b315d99cbda6b';

/// G1 7일 결과 · 사장님 (`NResult.dc.html`)
class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = G9Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G9Header(
                  pal: pal,
                  title: '7일 결과',
                  // 직접 연 화면이면 A9를 쌓지 않고 새로 시작한다(g9Back은 push라 G1이 아래에 남는다).
                  onBack: () => context.canPop()
                      ? demoBack(context)
                      : demoReset(context, 'NStoreHome.dc.html'),
                ),
                const SizedBox(height: 4),
                _hero(),
                _compare(pal),
                _payouts(pal),
                _sourceLink(context, pal),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: G9Button(
                        label: '새 오퍼',
                        height: 52,
                        size: 15,
                        weight: FontWeight.w500,
                        background: pal.soft,
                        foreground: pal.text,
                        onTap: () => demoGo(context, 'NOffer.dc.html'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: G9Button(
                        label: '영상 받기',
                        height: 52,
                        size: 15,
                        weight: FontWeight.w500,
                        background: pal.soft,
                        foreground: pal.text,
                        onTap: () => demoGo(context, 'NAIOrder.dc.html'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                G9Button(
                  label: '하루 한 컵과 다시 만나기',
                  background: G9Palette.lime,
                  foreground: G9Palette.limeInk,
                  onTap: () => demoGo(context, 'NBudget.dc.html'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 하루 한 컵이 올린 릴스 사진과 조회수.
  Widget _hero() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 236,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E3D3),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DemoPhoto(DemoImages.forBlob(_onecupBlob), x: 50, y: 30),
          ),
          const G9PhotoShade(
            height: 160,
            colors: [
              Color.fromRGBO(23, 24, 28, 0),
              Color.fromRGBO(23, 24, 28, 0.72),
            ],
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '하루 한 컵 · 릴스 · 11월 4일 게시',
                  style: g9Text(13, G9Palette.onPhotoSub),
                ),
                const SizedBox(height: 2),
                Text(
                  '12,500회',
                  style: g9Text(
                    30,
                    G9Palette.onPhoto,
                    weight: FontWeight.w900,
                    letterSpacing: -0.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 우리 가게 평소 게시물 대비 배수와 두 줄 막대.
  Widget _compare(G9Palette pal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('우리 가게 평소 게시물 대비', style: g9Text(13, pal.sub)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '3.1배',
                style: g9Text(
                  40,
                  pal.text,
                  weight: FontWeight.w900,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(width: 8),
              Text('평소 약 4,000회', style: g9Text(13, pal.sub)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              return Column(
                children: [
                  _barRow(w, '평소', 0.32, pal.sub, pal.line),
                  const SizedBox(height: 6),
                  _barRow(w, '이번', 1, pal.text, pal.barNow),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 캔버스의 막대 줄: 이름 칸 44px + 간격 8px + 막대(가로 [fraction] × 줄 너비).
  /// CSS flex는 넘치면 이름 칸과 막대를 크기에 비례해 줄이므로("이번" 줄은 100%라 넘친다) 같은 계산으로 맞춘다.
  Widget _barRow(
    double rowWidth,
    String name,
    double fraction,
    Color nameColor,
    Color barColor,
  ) {
    const labelBasis = 44.0;
    const gap = 8.0;
    var label = labelBasis;
    var bar = rowWidth * fraction;
    final over = label + gap + bar - rowWidth;
    if (over > 0) {
      final total = label + bar;
      label -= over * label / total;
      bar -= over * bar / total;
    }
    return Row(
      children: [
        SizedBox(
          width: label,
          child: Text(name, style: g9Text(12, nameColor), maxLines: 1),
        ),
        const SizedBox(width: gap),
        Container(
          width: bar,
          height: 10,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  Widget _payouts(G9Palette pal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _payout(pal, '크리에이터 지급', '25,000원')),
            const SizedBox(width: 8),
            Expanded(child: _payout(pal, '사장님께 환불', '35,000원')),
          ],
        ),
      ),
    );
  }

  Widget _payout(G9Palette pal, String term, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: g9Text(12, pal.sub)),
          const SizedBox(height: 4),
          Text(value, style: g9Text(18, pal.text, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// 밑줄이 있는 작은 링크: 캔버스의 `<a>`에 `text-decoration`이 없어 기본 밑줄이 그대로 남는다.
  Widget _sourceLink(BuildContext context, G9Palette pal) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, 'NMetrics.dc.html'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Text(
          '집계 출처와 계산 보기',
          style: g9Text(12, pal.sub, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}

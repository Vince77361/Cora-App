import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

/// A8 가게 결제 (NPay)
class PayPage extends StatefulWidget {
  const PayPage({super.key});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  static const _methods = ['카드', '계좌이체', '간편결제'];
  static const _shieldSvg =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"></path></svg>';

  int _method = 0;

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const G6Header(title: '결제', fallback: 'NStoreHome.dc.html'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3E3D3),
                          shape: BoxShape.circle,
                        ),
                        child: const DemoPhoto(DemoImages.onecup, x: 50, y: 25),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '하루 한 컵이\n오퍼를 수락했어요',
                          style: g6Text(
                            22,
                            p.text,
                            weight: FontWeight.w900,
                            ls: -0.04,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(p, '콘텐츠', '릴스 1편'),
                      const SizedBox(height: 12),
                      _row(p, '식사권 40,000원 · 2인', '방문 때 가게에서 제공', right: true),
                      const SizedBox(height: 12),
                      _row(p, '조회수 수당 (최대)', '60,000원'),
                      const SizedBox(height: 12),
                      _row(p, '서비스 수수료', '[수수료]'),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: p.line)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '지금 결제할 금액',
                              style: g6Text(
                                14,
                                p.text,
                                weight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '60,000원+',
                              style: g6Text(
                                26,
                                p.text,
                                weight: FontWeight.w900,
                                ls: -0.04,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '최대 60,000원, 실제는 조회수만큼, 남으면 7일 집계 후 환불해요.',
                        style: g6Text(12, p.sub, height: 1.6),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _methods.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _method = i),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == _method
                                    ? (p.dark
                                          ? const Color(0xFF33363D)
                                          : p.selBg)
                                    : p.unselBg,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                _methods[i],
                                style: g6Text(
                                  14,
                                  p.dark || i != _method ? p.unselFg : p.selFg,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: DemoSvg(_shieldSvg, color: p.sub, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '결제 금액은 Cora가 보관하다가, 콘텐츠가 올라오고 조회수가 집계되면 크리에이터에게 지급해요.',
                          style: g6Text(13, p.sub, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        G6BottomBar(
          child: G6PillButton(
            label: '결제하고 보관 맡기기',
            bg: G6Palette.lime,
            fg: G6Palette.onLime,
            onTap: () => demoGo(context, 'NStoreHome.dc.html'),
          ),
        ),
      ],
    );
  }

  Widget _row(G6Palette p, String label, String value, {bool right = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: g6Text(14, p.sub)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: right ? TextAlign.right : TextAlign.start,
            style: g6Text(14, p.text, weight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 07 진행 단계 (`Progress.dc.html`). 2 / 6 완료, 3단계가 지금 단계.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  static const String _check =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G1Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8DDCB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: p.dark ? g1Lime : g1Olive,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: DemoPhoto(
                            DemoImages.forBlob(
                              '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
                            ),
                            x: 62,
                            y: 42,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '콘텐츠 방향을 함께 잡아요.',
                              style: g1Text(22, 900, p.text, ls: -0.03),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '서윤의 작은 취향과 모아 스튜디오',
                              style: g1Text(13, 400, p.sub),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('함께 만들 콘텐츠', style: g1Text(12, 500, p.text)),
                      const SizedBox(height: 4),
                      Text(
                        '“출근 전 30초, 오늘의 손목 루틴”',
                        style: g1Text(17, 700, p.text),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('진행 단계', style: g1Text(15, 700, p.text)),
                      Text('2 / 6 완료', style: g1Text(13, 500, p.text)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      color: p.line,
                      alignment: Alignment.centerLeft,
                      child: const FractionallySizedBox(
                        widthFactor: 0.33,
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(color: g1Olive),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _done(p, '서로 관심 확인'),
                      _done(p, '조건 검토 의사 표시'),
                      _current(p),
                      _pending(p, 4, '기획안 검토·제작', true),
                      _pending(p, 5, '광고 표시·초안 검토', true),
                      _pending(p, 6, '게시·성과 확인', false),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    '상대의 동의와 최종 계약을 확인한 뒤 제작을 시작해요.',
                    style: g1Text(12, 400, p.sub),
                  ),
                ),
              ],
            ),
          ),
        ),
        g1BottomNav(context, 3),
      ],
    );
  }

  Widget _rowBox(G1Palette p, Widget child, {required bool border}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: p.line)) : null,
      ),
      child: child,
    );
  }

  Widget _done(G1Palette p, String label) {
    return _rowBox(
      p,
      Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: g1Olive,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const DemoSvg(_check, size: 16),
          ),
          const SizedBox(width: 14),
          Text(label, style: g1Text(15, 700, p.sub)),
        ],
      ),
      border: true,
    );
  }

  /// 지금 단계는 좌우로 12px 더 넓은 면이 깔린다(`margin: 4px -12px`).
  Widget _current(G1Palette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -12,
            right: -12,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: g1Lime,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('3', style: g1Text(14, 700, g1OnLime)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('양쪽 조건 확정·계약', style: g1Text(15, 700, p.text)),
                      Text('상대의 동의를 기다리고 있어요', style: g1Text(12, 400, p.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pending(G1Palette p, int n, String label, bool border) {
    return _rowBox(
      p,
      Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$n', style: g1Text(14, 500, p.sub)),
          ),
          const SizedBox(width: 14),
          Text(label, style: g1Text(15, 500, p.text)),
        ],
      ),
      border: border,
    );
  }
}

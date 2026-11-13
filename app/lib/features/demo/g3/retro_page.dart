import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g3_common.dart';

/// 15 회고·재협업 (`Retro.dc.html`)
class RetroPage extends StatefulWidget {
  const RetroPage({super.key});

  @override
  State<RetroPage> createState() => _RetroPageState();
}

class _RetroPageState extends State<RetroPage> {
  static const _goodL = ['촬영 방식의 자유', '빠른 피드백', '정확한 제품 정보', '정산 약속'];
  static const _badL = ['배송 기간', '제품 사용 기간', '수정 횟수', '소통 속도'];

  final Set<int> _good = {0, 1};
  final Set<int> _bad = {0, 1};

  void _toggle(Set<int> set, int i) {
    setState(() {
      if (!set.remove(i)) set.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.text),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          G3HeaderButton(
                            svg: g3CloseSvg,
                            color: p.text,
                            label: '닫기',
                            fallback: 'Review.dc.html',
                          ),
                          Text(
                            '상대에게 보이지 않는 회고',
                            style: TextStyle(fontSize: 12, color: p.sub),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _card(p),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '이 브랜드와 다시 만날래요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: G3Pill(
                        label: '이번만 할래요',
                        background: p.dark
                            ? const Color(0xFF2A2D33)
                            : const Color(0xFFF2F3F5),
                        color: p.dark ? const Color(0xFFF2F3F5) : g3Ink,
                        height: 56,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        onTap: () => demoGo(context, 'CreatorDiscover.dc.html'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: G3Pill(
                        label: '새 제안 만들기',
                        background: const Color(0xFFC6FF3D),
                        color: const Color(0xFF1F2A00),
                        height: 56,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        onTap: () => demoGo(context, 'NBudget.dc.html'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '회고는 나만 봐요. 새 제안은 지난 합의를 고치지 않고 새로 만들어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.5, color: p.sub),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(G3Palette p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1417181C),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '모아 스튜디오',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: g3Ls(24, -0.04),
                  color: p.text,
                ),
              ),
              Text('게시 완료', style: TextStyle(fontSize: 12, color: p.sub)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: p.dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 170,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF2E5B43),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DemoPhoto(DemoImages.moaStudio, x: 62, y: 45),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xEBC6FF3D),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_good.length}개',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: g3Ls(24, -0.04),
                            height: 1,
                            color: p.dark
                                ? const Color(0xFFE4FFB0)
                                : const Color(0xFF1F2A00),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '잘 맞은 점',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: p.dark
                                ? const Color(0xFFE4FFB0)
                                : const Color(0xFF1F2A00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '잘 맞았던 점',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.sub,
            ),
          ),
          const SizedBox(height: 8),
          _chips(p, _goodL, _good),
          const SizedBox(height: 16),
          Text(
            '다음엔 바꾸고 싶은 점',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.sub,
            ),
          ),
          const SizedBox(height: 8),
          _chips(p, _badL, _bad),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _fact(p, '다음에 가능한 날', '12월 1일부터')),
              const SizedBox(width: 8),
              Expanded(child: _fact(p, '다음 희망 제작비', '40만 원')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips(G3Palette p, List<String> labels, Set<int> on) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < labels.length; i++)
          Semantics(
            button: true,
            selected: on.contains(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(on, i),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on.contains(i)
                      ? (p.dark ? const Color(0xFF33363D) : p.chipOn)
                      : p.card,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: on.contains(i) && !p.dark ? p.onChipOn : p.onChipOff,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fact(G3Palette p, String dt, String dd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dt, style: TextStyle(fontSize: 12, color: p.sub)),
          const SizedBox(height: 2),
          Text(
            dd,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
}

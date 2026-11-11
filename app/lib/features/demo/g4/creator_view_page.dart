import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// B5 크리에이터 프로필 (`NCreatorView.dc.html`). 하트로 관심 표시를 켜고 끌 수 있다.
class CreatorViewPage extends StatefulWidget {
  const CreatorViewPage({super.key});

  @override
  State<CreatorViewPage> createState() => _CreatorViewPageState();
}

class _CreatorViewPageState extends State<CreatorViewPage> {
  static const _heart =
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';
  static const _likedHeart =
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="#C6FF3D" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';

  static const _photos = [
    [50.0, 12.0],
    [60.0, 50.0],
    [40.0, 88.0],
    [20.0, 30.0],
    [80.0, 60.0],
    [50.0, 95.0],
  ];

  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 56,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: G4HeaderButton(
                        svg: G4Icons.back,
                        label: '뒤로',
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: G4Colors.photoBg,
                          shape: BoxShape.circle,
                        ),
                        child: const DemoPhoto(
                          DemoImages.minCloset,
                          x: 50,
                          y: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '민의 옷장 기록',
                              style: g4Style(
                                22,
                                weight: FontWeight.w900,
                                color: c.text,
                                em: -0.04,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@min.closet, 코디·액세서리',
                              style: g4Style(13, color: c.sub),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '#얼굴출연가능 #솔직후기',
                              style: g4Style(13, color: c.text),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Stat(c: c, label: '팔로워', value: '2,100'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(c: c, label: '받은 좋아요', value: '1,240'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(c: c, label: '완료 협업', value: '3'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    '한 벌을 고정하고 액세서리만 바꿔 보여주는 코디 릴스를 만들어요. 희망 제작비는 30만 원대예요.',
                    style: g4Style(14, color: c.text, height: 1.6),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Column(
                    children: [
                      for (var r = 0; r < 2; r++) ...[
                        if (r > 0) const SizedBox(height: 4),
                        Row(
                          children: [
                            for (var k = 0; k < 3; k++) ...[
                              if (k > 0) const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 150,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: G4Colors.photoBg,
                                    borderRadius: G4CornerRadii.forIndex(
                                      r * 3 + k,
                                      6,
                                    ),
                                  ),
                                  child: DemoPhoto(
                                    DemoImages.minCloset,
                                    x: _photos[r * 3 + k][0],
                                    y: _photos[r * 3 + k][1],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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
          child: Container(
            color: c.bg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  toggled: _liked,
                  label: '관심 표시',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _liked = !_liked),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.fill,
                        shape: BoxShape.circle,
                      ),
                      child: DemoSvg(
                        _liked ? _likedHeart : _heart,
                        color: c.text,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => demoGo(context, 'NOffer.dc.html'),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: G4Colors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '오퍼 보내기',
                        style: g4Style(
                          16,
                          weight: FontWeight.w700,
                          color: G4Colors.onLime,
                        ),
                      ),
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
}

class _Stat extends StatelessWidget {
  const _Stat({required this.c, required this.label, required this.value});

  final G4Colors c;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: g4Style(12, color: c.sub)),
          const SizedBox(height: 2),
          Text(
            value,
            style: g4Style(17, weight: FontWeight.w700, color: c.text),
          ),
        ],
      ),
    );
  }
}

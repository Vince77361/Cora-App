import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g5_common.dart';

class _Slide {
  const _Slide(this.n, this.text, this.photo);
  final String n;
  final String text;
  final bool photo;
}

class _Draft {
  const _Draft(this.label, this.captionLabel, this.caption, this.slides);
  final String label;
  final String captionLabel;
  final String caption;
  final List<_Slide> slides;
}

const List<_Draft> _drafts = [
  _Draft(
    '카드뉴스',
    '본문',
    '성수동 골목 안, 12시간 끓인 국물 한 그릇.\n오후 3시 이후엔 줄 없이 들어올 수 있어요.\n#성수라멘 #돈코츠',
    [
      _Slide('1', '12시간 끓인\n국물 한 그릇', true),
      _Slide('2', '대표 메뉴\n돈코츠 라멘\n11,000원', false),
      _Slide('3', '줄 없는 시간\n오후 3시 – 5시', false),
    ],
  ),
  _Draft(
    '릴스 대본',
    '촬영 순서',
    '0–3초  김이 오르는 그릇 클로즈업\n3–8초  면을 들어 올리는 손\n8–15초  가게 간판과 위치 자막',
    [
      _Slide('장면 1', '김이 오르는\n첫 숟가락', true),
      _Slide('장면 2', '면을 들어\n올리는 손', false),
      _Slide('장면 3', '골목 간판과\n위치 자막', false),
    ],
  ),
  _Draft(
    '블로그 글',
    '도입부',
    '성수역에서 걸어서 5분, 골목 끝에 바 좌석 18석짜리 라멘집이 있어요. 국물은 매일 아침 12시간을 끓여요.',
    [
      _Slide('제목', '성수 골목\n라멘집 한 곳', true),
      _Slide('소제목 1', '12시간\n끓인 국물', false),
      _Slide('소제목 2', '줄 없이\n먹는 시간', false),
    ],
  ),
];

/// A4 AI 콘텐츠 초안 (`NStoreAI.dc.html`)
class StoreAIPage extends StatefulWidget {
  const StoreAIPage({super.key});

  @override
  State<StoreAIPage> createState() => _StoreAIPageState();
}

class _StoreAIPageState extends State<StoreAIPage> {
  int _tab = 0;
  int _v = 0;

  @override
  Widget build(BuildContext context) {
    final pal = G5Palette.of(context);
    final d = _drafts[_tab];
    // 사진이 없는 슬라이드의 바탕·글자색. 눌러 다시 만들 때마다 번갈아 바뀐다.
    final tones = <List<Color>>[
      [const Color(0xFFF3FFD6), const Color(0xFF1F2A00)],
      pal.dark
          ? [const Color(0xFFF2F3F5), const Color(0xFF0F1012)]
          : [const Color(0xFFF8F9FA), const Color(0xFF17181C)],
    ];
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G5Header(
                  pal: pal,
                  onBack: () => demoBack(context),
                  center: G5Pill(pal: pal, child: const Text('가게 등록')),
                  right: '3 / 3',
                ),
                G5Progress(pal: pal, fraction: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가게 계정에 올릴\n초안도 만들었어요.',
                        style: g5Text(
                          26,
                          pal.text,
                          weight: FontWeight.w900,
                          height: 1.3,
                          letterSpacing: -0.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '가게 페이지 정보로 AI가 썼어요. 그대로 올려도, 고쳐서 올려도 돼요.',
                        style: g5Text(14, pal.sub, height: 1.6),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _drafts.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _tab_(pal, i),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: d.slides.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final s = d.slides[i];
                      final tone = tones[(i + _v) % 2];
                      final fg = s.photo
                          ? (pal.dark
                                ? const Color(0xFF0F1012)
                                : const Color(0xFFFFFFFF))
                          : tone[1];
                      return Container(
                        width: 200,
                        height: 250,
                        decoration: BoxDecoration(
                          color: s.photo ? const Color(0xFFF6E3C8) : tone[0],
                          borderRadius: BorderRadius.circular(22),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            if (s.photo) ...[
                              const Positioned.fill(
                                child: DemoPhoto(
                                  DemoImages.ramen,
                                  x: 50,
                                  y: 45,
                                ),
                              ),
                              const Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 140,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color.fromRGBO(23, 24, 28, 0),
                                        Color.fromRGBO(23, 24, 28, 0.8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            Positioned(
                              left: 14,
                              top: 12,
                              child: Text(
                                s.n,
                                style: g5Text(12, fg, weight: FontWeight.w500),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Text(
                                s.text,
                                style: g5Text(
                                  19,
                                  fg,
                                  weight: FontWeight.w900,
                                  height: 1.3,
                                  letterSpacing: -0.04,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: pal.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.captionLabel, style: g5Text(12, pal.sub)),
                      const SizedBox(height: 6),
                      Text(d.caption, style: g5Text(14, pal.text, height: 1.6)),
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
                  // artifact는 다크에서도 이 버튼 색을 바꾸지 않는다.
                  child: G5BigButton(
                    label: '다시 만들기',
                    background: const Color(0xFFF2F3F5),
                    foreground: G5Palette.ink,
                    size: 15,
                    weight: FontWeight.w500,
                    onTap: () => setState(() => _v++),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: G5BigButton(
                    label: '저장하고 오퍼 만들기',
                    background: G5Palette.lime,
                    foreground: G5Palette.limeInk,
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

  Widget _tab_(G5Palette pal, int i) {
    final on = i == _tab;
    final bg = pal.dark
        ? (on ? const Color(0xFFF2F3F5) : const Color(0xFF1C1E22))
        : (on ? const Color(0xFFE3E5E9) : const Color(0xFFF8F9FA));
    final fg = pal.dark
        ? (on ? const Color(0xFF0F1012) : const Color(0xFFF2F3F5))
        : const Color(0xFF17181C);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = i),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _drafts[i].label,
          style: g5Text(14, fg, weight: FontWeight.w500),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// B6 콘텐츠 올리기 (`NUpload.dc.html`). 아래 사진을 고르면 위 미리보기가 바뀌고, 해시태그는 여러 개 켤 수 있다.
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _Media {
  const _Media(this.asset, this.x, this.y, this.kind);
  final String asset;
  final double x;
  final double y;
  final String kind;
}

class _UploadPageState extends State<UploadPage> {
  static const _media = [
    _Media(DemoImages.seoyun, 50, 35, '릴스 0:30'),
    _Media(DemoImages.seoyun, 35, 50, '사진'),
    _Media(DemoImages.minCloset, 50, 12, '사진'),
    _Media(DemoImages.onecup, 50, 30, '릴스 0:24'),
    _Media(DemoImages.minCloset, 50, 85, '사진'),
  ];
  static const _cats = ['소품', '데일리룩', '액세서리', '리빙'];

  final _caption = TextEditingController(text: '출근 전 30초, 오늘의 손목 루틴');
  int _cur = 0;
  final Set<int> _on = {0, 2};

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    final cur = _media[_cur];
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G4TitleHeader(
                  title: '새 콘텐츠',
                  leading: G4HeaderButton(
                    svg: G4Icons.close,
                    label: '닫기',
                    size: 20,
                    fallback: 'NProfile.dc.html',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  height: 300,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.thumbBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DemoPhoto(cur.asset, x: cur.x, y: cur.y),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(23, 24, 28, 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            cur.kind,
                            style: g4Style(
                              12,
                              weight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64 + 6, // 선택 고리(3px)가 잘리지 않을 여유
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _media.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => _Thumb(
                      media: _media[i],
                      c: c,
                      selected: i == _cur,
                      onTap: () => setState(() => _cur = i),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.fill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('한 줄 설명', style: g4Style(12, color: c.sub)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _caption,
                        style: g4Style(15, color: c.text),
                        cursorColor: c.text,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < _cats.length; i++)
                        _Cat(
                          label: _cats[i],
                          c: c,
                          on: _on.contains(i),
                          onTap: () => setState(
                            () => _on.contains(i) ? _on.remove(i) : _on.add(i),
                          ),
                        ),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '대표 릴스 1개만 있어도 지원할 수 있어요. 좋아요를 많이 받은 콘텐츠가 카드 첫 장에 먼저 보여요.',
                    textAlign: TextAlign.center,
                    style: g4Style(12, color: c.sub),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoGo(context, 'NProfile.dc.html'),
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: G4Colors.lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '포트폴리오에 올리기',
                      style: g4Style(
                        16,
                        weight: FontWeight.w700,
                        color: G4Colors.onLime,
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

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.media,
    required this.c,
    required this.selected,
    required this.onTap,
  });

  final _Media media;
  final G4Colors c;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: selected ? 1 : 0.6,
          child: Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.thumbBg,
              borderRadius: BorderRadius.circular(14),
              // artifact는 라이트·다크 모두 #17181C 고리다(다크에서는 거의 안 보인다).
              boxShadow: selected
                  ? const [BoxShadow(color: G4Colors.ink, spreadRadius: 3)]
                  : null,
            ),
            child: DemoPhoto(media.asset, x: media.x, y: media.y),
          ),
        ),
      ),
    );
  }
}

class _Cat extends StatelessWidget {
  const _Cat({
    required this.label,
    required this.c,
    required this.on,
    required this.onTap,
  });

  final String label;
  final G4Colors c;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (c.dark) {
      bg = on ? const Color(0xFF33363D) : const Color(0xFF1C1E22);
      fg = const Color(0xFFF2F3F5);
    } else {
      bg = on ? const Color(0xFFE3E5E9) : const Color(0xFFF8F9FA);
      fg = G4Colors.ink;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '#$label',
          style: g4Style(13, weight: FontWeight.w500, color: fg),
        ),
      ),
    );
  }
}

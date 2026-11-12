import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g3_common.dart';

class _Mark {
  const _Mark(this.t, this.pos, this.who, this.text);
  final String t;
  final double pos;
  final String who;
  final String text;
}

const String _sendSvg =
    '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>';

/// 14 초안 검토 (`Review.dc.html`)
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final List<_Mark> _items = [
    const _Mark('00:03', 10, '모아 스튜디오', '도입부 손 클로즈업이 좋아요. 그대로 가주세요.'),
    const _Mark('00:08', 27, '모아 스튜디오', '제품 소재를 설명하는 자막을 한 줄 넣을 수 있을까요?'),
    const _Mark('00:18', 60, '나', '여기서 제품명을 말로 한 번 더 언급할게요.'),
  ];
  int _sel = 1;
  bool _ad = true;
  final TextEditingController _draft = TextEditingController();

  // 썸네일 줄 6칸의 object-position
  static const _thumbs = [
    [10.0, 40.0],
    [28.0, 40.0],
    [46.0, 40.0],
    [60.0, 50.0],
    [76.0, 60.0],
    [92.0, 70.0],
  ];

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _addComment() {
    final t = _draft.text.trim();
    if (t.isEmpty) return;
    final cur = _items[_sel];
    setState(() {
      _items.add(_Mark(cur.t, cur.pos, '나', t));
      _draft.clear();
      _sel = _items.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    final sel = _items[_sel];
    const lime = Color(0xFFC6FF3D);
    final trackBg = _ad
        ? lime
        : (p.dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB));
    final ctaBg = _ad ? lime : p.card;
    final ctaFg = _ad ? p.onAccent : p.sub;

    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.text),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(p),
                  _video(p, sel),
                  _strip(p, sel),
                  _list(p),
                  _inputBar(p),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  toggled: _ad,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _ad = !_ad),
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '광고 표시를 확인했어요',
                              style: TextStyle(fontSize: 15, color: p.text),
                            ),
                            Container(
                              width: 48,
                              height: 28,
                              decoration: BoxDecoration(
                                color: trackBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 3,
                                    left: _ad ? 23 : 3,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: p.dark
                                            ? const Color(0xFF0F1012)
                                            : const Color(0xFFFFFFFF),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                G3Pill(
                  label: '이 판본(v2) 게시 승인',
                  background: ctaBg,
                  color: ctaFg,
                  height: 56,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  onTap: () => demoGo(context, 'Retro.dc.html'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(G3Palette p) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: G3HeaderButton(
                  svg: g3BackSvg,
                  color: p.text,
                  label: '뒤로',
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '영상 v2 · 파일 #A12 검토',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: p.text,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '다음 단계',
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(fontSize: 12, color: p.sub),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _video(G3Palette p, _Mark sel) {
    return Container(
      height: 300,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Color(0xFFE8DDCB)),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DemoPhoto(DemoImages.seoyun, x: 50, y: 38),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: Text(
              sel.t,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFFFFFF),
                shadows: [
                  Shadow(
                    color: Color(0x66000000),
                    offset: Offset(0, 1),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 56,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xF0FFFFFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 다크에서도 말풍선 바탕이 흰색이라 글자색은 artifact 그대로다(말풍선 이름은 다크에서 #F2F3F5).
                  Text(
                    sel.who,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sel.text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: g3Ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strip(G3Palette p, _Mark sel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: SizedBox(
        height: 60,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 6,
                  height: 48,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _thumbs.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            child: DemoPhoto(
                              DemoImages.seoyun,
                              x: _thumbs[i][0],
                              y: _thumbs[i][1],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // 고른 구간 테두리(inset 4px #C6FF3D)
                Positioned(
                  top: 0,
                  left: w * sel.pos / 100 - 32,
                  width: 64,
                  height: 60,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFC6FF3D),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < _items.length; i++)
                  Positioned(
                    top: 6,
                    left: w * _items[i].pos / 100 - 22,
                    width: 44,
                    height: 48,
                    child: Semantics(
                      button: true,
                      label: '${_items[i].t} 구간 댓글 보기',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _sel = i),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(G3Palette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _sel = i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // 다크에서도 고른 줄 바탕은 #F3FFD6 그대로다.
                  color: i == _sel
                      ? const Color(0xFFF3FFD6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        _items[i].t,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: p.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _items[i].text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: i == _sel ? p.text : p.sub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputBar(G3Palette p) {
    final sel = _items[_sel];
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _draft,
              onSubmitted: (_) => _addComment(),
              cursorColor: p.text,
              style: TextStyle(fontSize: 14, color: p.text),
              decoration: InputDecoration.collapsed(
                hintText: '${sel.t} 구간에 댓글 남기기',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: '구간 댓글 남기기',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _addComment,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFC6FF3D),
                  shape: BoxShape.circle,
                ),
                child: DemoSvg(_sendSvg, color: const Color(0xFF1F2A00)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

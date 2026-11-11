import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g2_palette.dart';

/// D3 대화방: 메시지 보내기, 대화 관리 시트, 첨부 메뉴.
class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({super.key});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  static const _pin =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 4h6l-1 6 3 3H7l3-3z"></path><path d="M12 13v7"></path></svg>';
  static const _chevron =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="2.4" stroke-linecap="round"><path d="M9 5l7 7-7 7"></path></svg>';
  static const _dots =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="5" r="2"></circle><circle cx="12" cy="12" r="2"></circle><circle cx="12" cy="19" r="2"></circle></svg>';
  static const _plus =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 5v14M5 12h14"></path></svg>';
  static const _sendIcon =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>';

  bool _menu = false;
  bool _attach = false;
  final List<String> _msgs = [];
  final _draft = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggleMenu() => setState(() {
    _menu = !_menu;
    _attach = false;
  });

  void _send() {
    final t = _draft.text.trim();
    if (t.isEmpty) return;
    setState(() => _msgs.add(t));
    _draft.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G2Palette.of(context);
    final sentBg = p.dark ? const Color(0xFF0F1012) : G2Palette.lime;
    final sentFg = p.dark ? const Color(0xFFFFFFFF) : G2Palette.onLime;
    final bubbleShape = const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(6),
    );

    Widget sent(String text) => Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: sentBg, borderRadius: bubbleShape),
        child: Text(text, style: g2Text(15, color: sentFg, height: 1.5)),
      ),
    );

    return DemoFrame(
      background: p.bg,
      children: [
        // 머리글
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoBack(context),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DemoSvg(G2Icons.back, color: p.text, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: G2Palette.photoGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const DemoPhoto(DemoImages.moaStudio, x: 62, y: 40),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '모아 스튜디오',
                        style: g2Text(
                          16,
                          color: p.text,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '느린 결, 일상의 주얼리 캠페인',
                        style: g2Text(12, color: p.sub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleMenu,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DemoSvg(_dots, color: p.sub, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 합의 요약 띠
        Positioned(
          left: 16,
          right: 16,
          top: 64,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => demoGo(context, 'Agreement.dc.html'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const DemoSvg(_pin, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '릴스 1편, 35만 원 + 제품, 11월 23일 시작\n조건 버전 2 · 브랜드 확인 대기',
                      style: g2Text(13, color: p.text, height: 1.45),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const DemoSvg(_chevron, size: 16),
                ],
              ),
            ),
          ),
        ),
        // 메시지 목록
        Positioned(
          left: 0,
          right: 0,
          top: 138,
          bottom: 96,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              Center(
                child: Text('11월 10일', style: g2Text(12, color: p.sub)),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 270),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    '주얼리를 먼저 7일 정도 사용해보신 뒤, 11월 16일 이후 촬영이 가능하실까요?',
                    style: g2Text(15, color: p.text, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              sent('네, 가능해요. 대신 23일부터 시작하면 더 여유 있게 쓸 수 있어요.'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => demoGo(context, 'Proposal.dc.html'),
                  child: Container(
                    width: 220,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: ColoredBox(
                            color: G2Palette.photoCream,
                            child: DemoPhoto(DemoImages.seoyun, x: 40, y: 40),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('콘텐츠 카드', style: g2Text(12, color: p.sub)),
                              const SizedBox(height: 2),
                              Text(
                                '이런 분위기로 찍을게요',
                                style: g2Text(
                                  14,
                                  color: p.text,
                                  weight: FontWeight.w500,
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
              for (final m in _msgs) ...[const SizedBox(height: 10), sent(m)],
            ],
          ),
        ),
        // 입력줄
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _attach = !_attach),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: DemoSvg(_plus, color: p.text, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 48,
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
                            style: g2Text(15, color: p.text),
                            cursorColor: p.text,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '메시지를 입력하세요',
                              hintStyle: g2Text(15, color: p.sub),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _send,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: G2Palette.lime,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: DemoSvg(_sendIcon, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 첨부 메뉴
        if (_attach)
          Positioned(
            left: 12,
            bottom: 92,
            width: 220,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 24, 28, 0.16),
                    offset: Offset(0, 12),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuItem(p, '내 콘텐츠 카드', 'NUpload.dc.html'),
                  _menuItem(p, '조건 수정 제안', 'Agreement.dc.html'),
                ],
              ),
            ),
          ),
        // 대화 관리 시트
        if (_menu) ...[
          Positioned.fill(
            child: ColoredBox(color: const Color.fromRGBO(15, 16, 18, 0.4)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 12, bottom: 28),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: p.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  for (final label in const ['알림 끄기', '차단하기', '신고하기'])
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleMenu,
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(label, style: g2Text(16, color: p.text)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleMenu,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '닫기',
                          style: g2Text(
                            15,
                            color: p.text,
                            weight: FontWeight.w500,
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
      ],
    );
  }

  Widget _menuItem(G2Palette p, String label, String canvasFile) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, canvasFile),
      child: Container(
        height: 48,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: g2Text(15, color: p.text)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

/// C2 미가입 계정에 연락 (NOutreach)
class OutreachPage extends StatefulWidget {
  const OutreachPage({super.key});

  @override
  State<OutreachPage> createState() => _OutreachPageState();
}

class _OutreachPageState extends State<OutreachPage> {
  static const _message =
      '안녕하세요, 성수동 한그릇 라멘이에요. 면치기 일기 님의 라멘 리뷰를 보고 연락드려요. 2인 식사권과 조회수당으로 릴스 1편을 부탁드리고 싶어요. 자세한 조건은 아래 링크에서 볼 수 있어요.';
  static const _chatSvg =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 5h16v11H10l-6 4z"></path></svg>';
  static const _linkSvg =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M10 14a4 4 0 0 0 6 0l3-3a4 4 0 0 0-6-6l-1 1M14 10a4 4 0 0 0-6 0l-3 3a4 4 0 0 0 6 6l1-1"></path></svg>';

  final _controller = TextEditingController(text: _message);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    final chipBg = dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const G6Header(title: '연락하기'),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: chipBg,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '면',
                          style: g6Text(20, p.sub, weight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '면치기 일기',
                              style: g6Text(
                                17,
                                p.text,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '@noodle.diary, 팔로워 1.2만',
                              style: g6Text(13, p.sub),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '아직 Cora 미가입',
                          style: g6Text(12, p.sub, weight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '보낼 메시지',
                        style: g6Text(13, p.sub, weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 6,
                          maxLines: 6,
                          style: g6Text(15, p.text, height: 1.6),
                          cursorColor: p.text,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _info(p, _chatSvg, 'Cora 쪽지로 보내면 인스타그램 DM으로 전달돼요.'),
                      const SizedBox(height: 8),
                      _info(p, _linkSvg, '오퍼 조건과 가입 링크가 함께 가요.'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Text(
                    '답이 오기 전에는 같은 계정에 다시 보낼 수 없어요. 상대가 수신을 거부하면 목록에서 빠져요.',
                    style: g6Text(12, p.sub, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        G6BottomBar(
          child: G6PillButton(
            label: '쪽지 보내기',
            bg: G6Palette.lime,
            fg: G6Palette.onLime,
            onTap: () => demoGo(context, 'NDirectory.dc.html'),
          ),
        ),
      ],
    );
  }

  /// 아이콘 색은 라이트·다크 모두 #1F2A00(artifact 그대로).
  Widget _info(G6Palette p, String svg, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: DemoSvg(svg, color: G6Palette.onLime, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: g6Text(14, p.text, height: 1.5))),
      ],
    );
  }
}

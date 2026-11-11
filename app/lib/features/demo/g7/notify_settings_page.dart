import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E5 알림 설정 (`NNotifySettings.dc.html`)
class NotifySettingsPage extends StatefulWidget {
  const NotifySettingsPage({super.key});

  @override
  State<NotifySettingsPage> createState() => _NotifySettingsPageState();
}

class _NotifySettingsPageState extends State<NotifySettingsPage> {
  static const _items = [
    ('서로 관심', '상대도 관심을 표시하면 알려줘요'),
    ('새 오퍼와 제안', '가게나 브랜드가 오퍼를 보냈을 때'),
    ('대화 메시지', '진행 중인 협업의 새 메시지'),
    ('정산', '지급 예정, 지급 완료'),
    ('추천 소식', '새로 올라온 캠페인과 크리에이터'),
  ];
  static const _quiet = ['끄기', '밤 10시 – 아침 8시', '주말'];

  final List<bool> _on = [true, true, true, true, false];
  int _q = 1;

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G7Header(title: '알림'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    '꼭 필요한 알림만\n받을 수 있어요.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 26 * -0.045,
                      height: 1.3,
                      color: c.text,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _on[i] = !_on[i]),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 64),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _items[i].$1,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: c.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _items[i].$2,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.sub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _switch(c, _on[i]),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '방해 금지 시간',
                        style: TextStyle(fontSize: 15, color: c.text),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < _quiet.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _q = i),
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: i == _q
                                        ? (c.dark
                                              ? const Color(0xFF2A2D33)
                                              : const Color(0xFFFFFFFF))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _quiet[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: c.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _switch(G7Colors c, bool on) {
    final off = c.dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB);
    return Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: on ? G7Colors.lime : off,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 3,
            left: on ? 23 : 3,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                boxShadow: [
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
    );
  }
}

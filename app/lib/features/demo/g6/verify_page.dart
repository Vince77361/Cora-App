import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

/// E2 휴대폰 인증 (NVerify). 시연용 정적 화면: 6자리만 채우면 어떤 번호든 다음으로 넘어간다.
class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '0',
    '←',
  ];

  String _code = '4829';
  int _sent = 0;
  final _phone = TextEditingController(text: '010-0000-0003');

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _press(String k) {
    if (k.isEmpty) return;
    setState(() {
      if (k == '←') {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
      } else if (_code.length < 6) {
        _code += k;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    final ready = _code.length == 6;
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 340),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const G6Header(title: '휴대폰 인증', height: 64),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '문자로 받은\n인증번호를 넣어주세요.',
                        style: g6Text(
                          28,
                          p.text,
                          weight: FontWeight.w900,
                          ls: -0.05,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('010-****-0003로 보냈어요.', style: g6Text(14, p.sub)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('휴대폰 번호', style: g6Text(12, p.sub)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              style: g6Text(17, p.text),
                              cursorColor: p.text,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < 6; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: p.card,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                foregroundDecoration: i == _code.length
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFF17181C),
                                          width: 2,
                                        ),
                                      )
                                    : null,
                                child: Text(
                                  i < _code.length ? _code[i] : '',
                                  style: g6Text(
                                    24,
                                    p.text,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '남은 시간 ${_sent > 0 ? '3:00' : '2:41'}',
                              style: g6Text(13, p.sub),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() {
                                _code = '';
                                _sent += 1;
                              }),
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF2A2D33)
                                      : const Color(0xFFF2F3F5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '다시 보내기',
                                  style: g6Text(
                                    13,
                                    p.text,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    for (var r = 0; r < 4; r++) ...[
                      if (r > 0) const SizedBox(height: 6),
                      Row(
                        children: [
                          for (var c = 0; c < 3; c++) ...[
                            if (c > 0) const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _press(_keys[r * 3 + c]),
                                child: SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: Text(
                                      _keys[r * 3 + c],
                                      style: g6Text(
                                        22,
                                        p.text,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
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
              if (ready)
                G6PillButton(
                  label: '확인',
                  bg: G6Palette.lime,
                  fg: G6Palette.onLime,
                  onTap: () => demoGo(context, 'NRole.dc.html'),
                )
              else
                Container(
                  width: double.infinity,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '6자리를 모두 넣어주세요',
                    style: g6Text(16, p.sub, weight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

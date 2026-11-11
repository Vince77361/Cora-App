import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g6_ui.dart';

/// E1 로그인 (NLogin). 시연용 정적 화면: 어느 버튼이든 다음 화면으로 넘어간다.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => demoGo(context, 'NHelp.dc.html');
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => demoGo(context, 'NHelp.dc.html');

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    final dark = p.dark;
    final inset = MediaQuery.paddingOf(context).top;
    // artifact는 상태 막대 없는 844 판이라, 노치가 있는 기기에서는 사진 위쪽만 줄여 글자와 겹치지 않게 한다.
    final photoTop = inset > 12 ? inset : 12.0;
    final linkStyle = TextStyle(
      color: p.text,
      decoration: TextDecoration.underline,
      decorationColor: p.text,
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned(
            left: 12,
            right: 12,
            top: photoTop,
            height: 432 - photoTop,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFE8DDCB)),
                  ),
                  const Positioned.fill(
                    child: DemoPhoto(DemoImages.minCloset, x: 50, y: 25),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 220,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(23, 24, 28, 0),
                            Color.fromRGBO(23, 24, 28, 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#민의옷장기록 · 릴스 0:30',
                        style: g6Text(
                          12,
                          const Color(0xFF17181C),
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Text(
                      '팔로워 수보다 콘텐츠로 만나요.',
                      style: g6Text(15, const Color(0xFFFFFFFF), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DemoSvg(g6LogoSvg, color: p.text, size: 34),
                    const SizedBox(width: 8),
                    Text(
                      'cora',
                      style: g6Text(
                        32,
                        p.text,
                        weight: FontWeight.w900,
                        ls: -0.05,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '브랜드와 크리에이터가\n콘텐츠로 만나는 곳',
                  style: g6Text(
                    26,
                    p.text,
                    weight: FontWeight.w900,
                    ls: -0.045,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                G6PillButton(
                  label: '휴대폰 번호로 시작하기',
                  bg: G6Palette.lime,
                  fg: G6Palette.onLime,
                  onTap: () => demoGo(context, 'NVerify.dc.html'),
                ),
                const SizedBox(height: 8),
                _social(p, dark, 'K', '카카오로 계속하기'),
                const SizedBox(height: 8),
                _social(p, dark, 'N', '네이버로 계속하기'),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: g6Text(12, p.sub, height: 1.6),
                    children: [
                      const TextSpan(text: '계속하면 '),
                      TextSpan(
                        text: '이용약관',
                        style: linkStyle,
                        recognizer: _terms,
                      ),
                      const TextSpan(text: '과 '),
                      TextSpan(
                        text: '개인정보 처리방침',
                        style: linkStyle,
                        recognizer: _privacy,
                      ),
                      const TextSpan(text: '에 동의하게 돼요.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(G6Palette p, bool dark, String mark, String label) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, 'NRole.dc.html'),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
              child: Text(
                mark,
                style: g6Text(12, p.text, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: g6Text(15, p.text, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

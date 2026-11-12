import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E4 설정 (`NSettings.dc.html`)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                const G7Header(title: '설정'),
                _profileCard(context, c),
                _section(context, c, '계정', const [
                  _Row('역할 전환', 'NRole.dc.html', value: '크리에이터'),
                  _Row('연결된 계정', 'NInstagram.dc.html', value: '인스타그램'),
                  // 휴대폰 번호는 설계 결정에 따라 010-****-0003.
                  _Row('휴대폰 번호', 'NVerify.dc.html', value: '010-****-0003'),
                ]),
                _section(context, c, '협업', const [
                  _Row('알림', 'NNotifySettings.dc.html', value: '4개 켜짐'),
                  _Row('정산 계좌와 내역', 'NWallet.dc.html', value: '국민 ****12'),
                  _Row('다시 만나고 싶은 브랜드', 'NKeepList.dc.html', value: '3'),
                ]),
                _section(context, c, '도움', const [
                  _Row('고객센터', 'NHelp.dc.html'),
                  _Row('약관과 개인정보', 'NHelp.dc.html'),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _footLink(context, c, '로그아웃', 'NLogin.dc.html'),
                      const SizedBox(width: 4),
                      Text('|', style: TextStyle(fontSize: 16, color: c.line)),
                      const SizedBox(width: 4),
                      _footLink(context, c, '회원 탈퇴', 'NHelp.dc.html'),
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

  Widget _footLink(
    BuildContext context,
    G7Colors c,
    String label,
    String file,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 로그아웃은 쌓인 화면을 모두 비우고 로그인으로 간다.
      onTap: () => file == 'NLogin.dc.html'
          ? demoReset(context, file)
          : demoGo(context, file),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(label, style: TextStyle(fontSize: 13, color: c.sub)),
      ),
    );
  }

  Widget _profileCard(BuildContext context, G7Colors c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, 'NEditProfile.dc.html'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFFD9DCE6),
                shape: BoxShape.circle,
              ),
              child: DemoPhoto(
                DemoImages.forBlob('b69c53f92919508dbffde40eedb1953c'),
                x: 50,
                y: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '민의 옷장 기록',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  Text(
                    '크리에이터 · @min.closet',
                    style: TextStyle(fontSize: 13, color: c.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.dark
                    ? const Color(0xFF0F1012)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '프로필 수정',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    G7Colors c,
    String title,
    List<_Row> rows,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.sub,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                for (final r in rows)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => demoGo(context, r.file),
                    child: Container(
                      constraints: BoxConstraints(minHeight: c.dark ? 52 : 48),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: c.dark ? 6 : 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.label,
                              style: TextStyle(fontSize: 15, color: c.text),
                            ),
                          ),
                          if (r.value != null) ...[
                            Text(
                              r.value!,
                              style: TextStyle(fontSize: 13, color: c.sub),
                            ),
                          ],
                          const SizedBox(width: 10),
                          const DemoSvg(g7ChevronSvg, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.file, {this.value});
  final String label;
  final String file;
  final String? value;
}

import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E4 설정 (`NSettings.dc.html`)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    // 역할이 비어 있으면(경로로 바로 연 화면) 캔버스대로 크리에이터로 보여 준다.
    final role = demoRole.value ?? DemoRole.creator;
    final creator = role == DemoRole.creator;
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G7Header(title: '설정', fallback: 'NProfile.dc.html'),
                _profileCard(context, c, role),
                _section(context, c, '계정', [
                  _Row('역할 전환', 'NRole.dc.html', value: role.label),
                  // 인스타그램 연동은 크리에이터의 화면(B3)이다.
                  if (creator)
                    const _Row('연결된 계정', 'NInstagram.dc.html', value: '인스타그램'),
                  // 휴대폰 번호는 설계 결정에 따라 010-****-0003.
                  const _Row(
                    '휴대폰 번호',
                    'NVerify.dc.html',
                    value: '010-****-0003',
                  ),
                ]),
                _section(context, c, '협업', [
                  const _Row('알림', 'NNotifySettings.dc.html', value: '4개 켜짐'),
                  // 정산(E7)과 보관함(D5)은 크리에이터의 화면이다.
                  if (creator) ...const [
                    _Row('정산 계좌와 내역', 'NWallet.dc.html', value: '국민 ****12'),
                    _Row('다시 만나고 싶은 브랜드', 'NKeepList.dc.html', value: '3'),
                  ],
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
      onTap: () {
        if (file != 'NLogin.dc.html') return demoGo(context, file);
        // 로그아웃하면 역할도 비운다. 다음 로그인에서 A1이 다시 고르게 한다.
        demoRole.value = null;
        demoReset(context, file);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(label, style: TextStyle(fontSize: 13, color: c.sub)),
      ),
    );
  }

  Widget _profileCard(BuildContext context, G7Colors c, DemoRole role) {
    // 프로필 수정(E6)은 크리에이터의 화면이다. 사장님은 가게 페이지(A3)로, 브랜드는 열 화면이 없어 누르지 않는다.
    final (blob, name, sub, chip, file) = switch (role) {
      DemoRole.creator => (
        'b69c53f92919508dbffde40eedb1953c',
        '민의 옷장 기록',
        '크리에이터 · @min.closet',
        '프로필 수정',
        'NEditProfile.dc.html',
      ),
      DemoRole.store => (
        '05c6e2f12662029787761493c831ec3a',
        '한그릇 라멘',
        '가게 사장님',
        '가게 페이지',
        'NStorePage.dc.html',
      ),
      DemoRole.brand => (
        'b17a81a543b08af172aa89b26b5db39c',
        '모아 스튜디오',
        '브랜드',
        null,
        null,
      ),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: file == null ? null : () => demoGo(context, file),
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
              child: DemoPhoto(DemoImages.forBlob(blob), x: 50, y: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  Text(sub, style: TextStyle(fontSize: 13, color: c.sub)),
                ],
              ),
            ),
            if (chip != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: c.dark
                      ? const Color(0xFF0F1012)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
              ),
            ],
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

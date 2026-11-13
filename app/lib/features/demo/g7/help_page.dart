import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E8 고객센터 (`NHelp.dc.html`)
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const _faqs = [
    ('정산은 언제 들어오나요?', '콘텐츠가 올라오고 7일 동안 유지되면, 다음 주 수요일에 등록한 계좌로 보내드려요.'),
    (
      '팔로워가 적어도 오퍼를 받을 수 있나요?',
      '네. Cora는 팔로워 수보다 콘텐츠를 보고 연결해요. 포트폴리오를 채울수록 추천이 늘어요.',
    ),
    ('계약 조건을 바꾸고 싶어요.', '대화방에서 조건 수정 제안을 보내면, 상대가 확인한 뒤 새 버전으로 기록돼요.'),
    ('상대가 약속을 지키지 않아요.', '대화방 메뉴의 신고하기를 눌러주세요. 보관 중인 금액은 확인이 끝날 때까지 지급되지 않아요.'),
    ('계정을 삭제하고 싶어요.', '설정 아래 회원 탈퇴에서 할 수 있어요. 진행 중인 협업이 있으면 먼저 마무리해야 해요.'),
  ];
  static const _searchSvg =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-4-4"></path></svg>';

  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 130),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G7Header(title: '고객센터', fallback: 'NSettings.dc.html'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '무엇을 도와드릴까요?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 26 * -0.045,
                            color: c.text,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 14),
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            DemoSvg(_searchSvg, color: c.sub, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                cursorColor: c.text,
                                style: TextStyle(fontSize: 15, color: c.text),
                                decoration: InputDecoration(
                                  isDense: true,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hintText: '정산, 계약, 신고…',
                                  hintStyle: TextStyle(
                                    fontSize: 15,
                                    color: c.sub,
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
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _faqs.length; i++) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              setState(() => _open = _open == i ? -1 : i),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 52),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _faqs[i].$1,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: c.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _open == i ? '−' : '+',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFFA0A4AD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_open == i)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _faqs[i].$2,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: c.sub,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                  child: GestureDetector(
                    onTap: () => demoGo(context, 'NHelp.dc.html'),
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.button,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '약관 보기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: GestureDetector(
                    onTap: () => demoGo(context, 'NChatThread.dc.html'),
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: G7Colors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '1:1 문의하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: G7Colors.onLime,
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
    );
  }
}

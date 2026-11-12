import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g5_common.dart';

const String _checkSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#1F2A00" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';

/// A2 가게 링크 입력 (`NStoreLink.dc.html`)
class StoreLinkPage extends StatefulWidget {
  const StoreLinkPage({super.key});

  @override
  State<StoreLinkPage> createState() => _StoreLinkPageState();
}

class _StoreLinkPageState extends State<StoreLinkPage> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = G5Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G5Header(
                  pal: pal,
                  onBack: () => demoBack(context),
                  center: const SizedBox.shrink(),
                  right: '1 / 3',
                ),
                G5Progress(pal: pal, fraction: 0.33),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가게 링크만 넣으면\n소개 페이지를 만들어 드려요.',
                        style: g5Text(
                          28,
                          pal.text,
                          weight: FontWeight.w900,
                          height: 1.3,
                          letterSpacing: -0.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '사진, 메뉴, 영업시간을 링크에서 가져와요. 2개 이상 넣으면 더 정확해요.',
                        style: g5Text(15, pal.sub, height: 1.6),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: Column(
                    children: [
                      _linkCard(
                        pal,
                        '네이버 지도',
                        '사진 12장, 메뉴 8개 찾음',
                        'naver.me/[가게 링크]',
                      ),
                      const SizedBox(height: 10),
                      _linkCard(
                        pal,
                        '캐치테이블',
                        '영업시간 찾음',
                        'app.catchtable.co.kr/[가게 링크]',
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _focus.requestFocus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: pal.card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '인스타그램 · 선택',
                                style: g5Text(
                                  13,
                                  pal.sub,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                focusNode: _focus,
                                keyboardType: TextInputType.url,
                                cursorColor: pal.text,
                                style: g5Text(15, pal.text),
                                decoration: InputDecoration(
                                  isDense: true,
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                  hintText: 'instagram.com/가게계정',
                                  // 브라우저 기본 placeholder 색.
                                  hintStyle: g5Text(
                                    15,
                                    const Color(0xFF757575),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Text(
                    '가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.',
                    style: g5Text(13, pal.sub, height: 1.6),
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
            child: G5BigButton(
              label: '가게 페이지 만들기',
              background: G5Palette.lime,
              foreground: G5Palette.limeInk,
              onTap: () => demoGo(context, 'NStorePage.dc.html'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkCard(G5Palette pal, String name, String found, String url) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: g5Text(13, pal.text, weight: FontWeight.w500)),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DemoSvg(_checkSvg, size: 14),
                    const SizedBox(width: 4),
                    Flexible(child: Text(found, style: g5Text(12, pal.text))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: g5Text(15, pal.text),
          ),
        ],
      ),
    );
  }
}

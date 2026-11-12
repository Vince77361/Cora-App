import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_role_nav.dart';
import '../shared/demo_ui.dart';
import 'g5_common.dart';

class _Row {
  const _Row({
    required this.name,
    required this.meta,
    this.blob,
    this.pos = 50,
    this.initial = '',
    required this.lightBg,
    required this.darkBg,
    required this.cta,
    required this.href,
    required this.hot,
  });

  final String name;
  final String meta;
  final String? blob;
  final double pos;
  final String initial;
  final Color lightBg;
  final Color darkBg;
  final String cta;
  final String href;
  final bool hot;
}

const String _onecupBlob = '/_blob/2c6508f8caadc5c0466b315d99cbda6b';
const String _minBlob = '/_blob/b69c53f92919508dbffde40eedb1953c';

const List<List<_Row>> _lists = [
  [
    _Row(
      name: '하루 한 컵',
      meta: '리빙 릴스, 팔로워 640명, 오늘 지원',
      blob: _onecupBlob,
      pos: 25,
      lightBg: Color(0xFFF3E3D3),
      darkBg: Color(0xFFF3E3D3),
      cta: '오퍼 보내기',
      href: 'NOffer.dc.html',
      hot: true,
    ),
    _Row(
      name: '성수 한 끼',
      meta: '맛집 릴스, 팔로워 4,800명, 어제 지원',
      initial: '성',
      lightBg: Color(0xFFF8F9FA),
      darkBg: Color(0xFF1C1E22),
      cta: '프로필',
      href: 'NCreatorView.dc.html',
      hot: false,
    ),
    _Row(
      name: '면치기 일기',
      meta: '라멘 리뷰, 팔로워 1.2만, 2일 전 지원',
      initial: '면',
      lightBg: Color(0xFFF8F9FA),
      darkBg: Color(0xFF1C1E22),
      cta: '프로필',
      href: 'NCreatorView.dc.html',
      hot: false,
    ),
  ],
  [
    _Row(
      name: '하루 한 컵',
      meta: '수락함, 결제를 기다려요',
      blob: _onecupBlob,
      pos: 25,
      lightBg: Color(0xFFF3E3D3),
      darkBg: Color(0xFFF3E3D3),
      cta: '결제하기',
      href: 'NPay.dc.html',
      hot: true,
    ),
    _Row(
      name: '국물 수집가',
      meta: '미가입, 쪽지 보냄',
      initial: '국',
      lightBg: Color(0xFFF8F9FA),
      darkBg: Color(0xFF1C1E22),
      cta: '보기',
      href: 'NOutreach.dc.html',
      hot: false,
    ),
    _Row(
      name: '민의 옷장 기록',
      meta: '거절함',
      blob: _minBlob,
      pos: 12,
      lightBg: Color(0xFFD9DCE6),
      darkBg: Color(0xFFD9DCE6),
      cta: '다시 찾기',
      href: 'NReels.dc.html',
      hot: false,
    ),
  ],
];

const List<String> _tabLabels = ['지원한 크리에이터 5', '보낸 오퍼 3'];

/// A9 사장님 홈 (`NStoreHome.dc.html`)
class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pal = G5Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, pal),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _stat(pal, '새 지원', '5', pal.text)),
                        const SizedBox(width: 8),
                        Expanded(child: _stat(pal, '보낸 오퍼', '3', pal.sub)),
                        const SizedBox(width: 8),
                        // 협업 줄이 따로 없어 "진행 중" 칸이 G1 7일 결과의 입구다(소유자 결정).
                        Expanded(
                          child: _stat(
                            pal,
                            '진행 중',
                            '1',
                            pal.sub,
                            onTap: () => demoGo(context, 'NResult.dc.html'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _shortcut(
                            context,
                            pal,
                            '지원자 추천',
                            '3명 보고 좋아요',
                            'NApplicants.dc.html',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shortcut(
                            context,
                            pal,
                            '이번 주 가게 게시물',
                            'AI 초안 2개 준비',
                            'NStoreAI.dc.html',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoGo(context, 'NSwitchReport.dc.html'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: pal.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '체험단 계약이 한 달 남았어요 · 비교 보기',
                          style: g5Text(13, pal.text),
                        ),
                        Text('›', style: g5Text(13, pal.sub)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabLabels.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _tabButton(pal, i),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Column(
                    children: [
                      for (final r in _lists[_tab]) _row(context, pal, r),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 다크 파일은 꺼진 칸이 #8B9099다(공용 demoRoleNav는 이 색을 받지 않아 같은 메뉴를 직접 만든다).
        DemoBottomNav(
          items: demoRoleNavItems(demoRole.value ?? DemoRole.store, 0),
          inactiveColor: pal.dark ? const Color(0xFF8B9099) : null,
          darkShadowOpacity: 0.12,
        ),
      ],
    );
  }

  Widget _header(BuildContext context, G5Palette pal) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF6E3C8),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: const DemoPhoto(DemoImages.ramen, x: 50, y: 50),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('사장님 홈', style: g5Text(12, pal.sub)),
                  Text(
                    '한그릇 라멘',
                    style: g5Text(18, pal.text, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => demoGo(context, 'NStorePage.dc.html'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Text(
                  '가게 페이지',
                  style: g5Text(13, pal.text, weight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    G5Palette pal,
    String term,
    String value,
    Color termColor, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: g5Text(12, termColor)),
          const SizedBox(height: 2),
          Text(value, style: g5Text(24, pal.text, weight: FontWeight.w900)),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  Widget _shortcut(
    BuildContext context,
    G5Palette pal,
    String label,
    String value,
    String file,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, file),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: g5Text(12, pal.sub)),
            const SizedBox(height: 2),
            Text(value, style: g5Text(15, pal.text, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(G5Palette pal, int i) {
    final on = i == _tab;
    final bg = pal.dark
        ? (on ? const Color(0xFF33363D) : const Color(0xFF1C1E22))
        : (on ? const Color(0xFFE3E5E9) : const Color(0xFFF8F9FA));
    final fg = pal.dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = i),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _tabLabels[i],
          style: g5Text(13, fg, weight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, G5Palette pal, _Row r) {
    final ctaBg = r.hot ? G5Palette.lime : pal.card;
    final ctaFg = r.hot ? G5Palette.limeInk : pal.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pal.dark ? r.darkBg : r.lightBg,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: r.blob != null
                ? SizedBox.expand(
                    child: DemoPhoto(
                      DemoImages.forBlob(r.blob!),
                      x: 50,
                      y: r.pos,
                    ),
                  )
                : Text(
                    r.initial,
                    style: g5Text(16, pal.text, weight: FontWeight.w500),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: g5Text(15, pal.text, weight: FontWeight.w500),
                ),
                Text(r.meta, style: g5Text(12, pal.sub)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => demoGo(context, r.href),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ctaBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                r.cta,
                style: g5Text(13, ctaFg, weight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

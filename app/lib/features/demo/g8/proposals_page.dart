import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_ui.dart';
import 'g8_common.dart';

class _Row {
  const _Row({
    required this.name,
    required this.sub,
    required this.badge,
    required this.href,
    required this.photo,
    required this.avBg,
    this.hot = false,
  });

  final String name;
  final String sub;
  final String badge;

  /// 눌렀을 때 가는 화면. 비어 있으면 아무 일도 하지 않는다.
  final String? href;
  final String photo;
  final Color avBg;

  /// 내가 응답할 차례인 줄: 라임 배지.
  final bool hot;
}

class _Group {
  const _Group(this.title, this.dot, this.darkDot, this.rows);

  final String title;
  final Color dot;
  final Color darkDot;
  final List<_Row> rows;
}

const Color _onecupBg = Color(0xFFF3E3D3);
const Color _minBg = Color(0xFFD9DCE6);
const Color _seoyunBg = Color(0xFFE8DDCB);

const List<List<_Group>> _data = [
  [
    _Group('내가 응답할 차례', Color(0xFFC6FF3D), Color(0xFFC6FF3D), [
      _Row(
        name: '하루 한 컵',
        sub: '역제안 · 판본 2 · 카드뉴스 1편',
        badge: '응답하기',
        href: 'Agreement.dc.html',
        photo: DemoImages.onecup,
        avBg: _onecupBg,
        hot: true,
      ),
    ]),
    _Group('상대 대기', Color(0xFFA0A4AD), Color(0xFFA0A4AD), [
      _Row(
        name: '민의 옷장 기록',
        sub: '판본 1 · 릴스 1편 · 2일 안에 답이 와요',
        badge: '대기',
        href: 'NReviewSend.dc.html',
        photo: DemoImages.minCloset,
        avBg: _minBg,
      ),
      _Row(
        name: '서윤의 작은 취향',
        sub: '판본 1 · 릴스 1편',
        badge: '대기',
        href: 'NReviewSend.dc.html',
        photo: DemoImages.seoyun,
        avBg: _seoyunBg,
      ),
    ]),
  ],
  [
    _Group('종료', Color(0xFFE6E8EB), Color(0xFF2A2D33), [
      _Row(
        name: '서윤의 작은 취향',
        sub: '합의 완료 · 계약으로 이동',
        badge: '완료',
        href: 'NContract.dc.html',
        photo: DemoImages.seoyun,
        avBg: _seoyunBg,
      ),
      _Row(
        name: '하루 한 컵',
        sub: '일정이 맞지 않아 종료',
        badge: '종료',
        href: 'NKeepList.dc.html',
        photo: DemoImages.onecup,
        avBg: _onecupBg,
      ),
    ]),
  ],
];

const List<String> _tabLabels = ['진행 중 3', '종료 2'];

/// 사장님: 캔버스 그대로지만 "합의 완료" 줄은 계약서(D4)가 아니라 결제(A8)로 간다
/// (가게 흐름 개정 설계 F3: "합의 완료 · 계약으로 이동"을 누르면 사장님은 결제로). 다른 역할 화면(D5)으로 가던
/// "일정이 맞지 않아 종료" 줄은 사장님에게 갈 곳이 없어 아무 일도 하지 않는다.
final List<List<_Group>> _storeData = [
  _data[0],
  [
    _Group('종료', const Color(0xFFE6E8EB), const Color(0xFF2A2D33), [
      const _Row(
        name: '서윤의 작은 취향',
        sub: '합의 완료 · 계약으로 이동',
        badge: '완료',
        href: 'NPay.dc.html',
        photo: DemoImages.seoyun,
        avBg: _seoyunBg,
      ),
      const _Row(
        name: '하루 한 컵',
        sub: '일정이 맞지 않아 종료',
        badge: '종료',
        href: null,
        photo: DemoImages.onecup,
        avBg: _onecupBg,
      ),
    ]),
  ],
];

const Color _ramenBg = Color(0xFFF6E3C8);

/// 크리에이터: 상대는 가게다. 이름 줄만 가게로 바꾸고 줄 구성(문구)은 캔버스와 같다. 크리에이터가 F6으로 보낸 판본 2는
/// 가게의 응답을 기다리므로 "상대 대기"에 있고, "합의 완료" 줄은 크리에이터의 협업 화면(A7)으로 간다.
const List<List<_Group>> _creatorData = [
  [
    _Group('상대 대기', Color(0xFFA0A4AD), Color(0xFFA0A4AD), [
      _Row(
        name: '한그릇 라멘',
        sub: '판본 2 · 릴스 1편 · 2일 안에 답이 와요',
        badge: '대기',
        href: 'NReviewSend.dc.html',
        photo: DemoImages.ramen,
        avBg: _ramenBg,
      ),
    ]),
  ],
  [
    _Group('종료', Color(0xFFE6E8EB), Color(0xFF2A2D33), [
      _Row(
        name: '한그릇 라멘',
        sub: '합의 완료 · 계약으로 이동',
        badge: '완료',
        href: 'NEscrow.dc.html',
        photo: DemoImages.ramen,
        avBg: _ramenBg,
      ),
    ]),
  ],
];

const List<String> _creatorTabLabels = ['진행 중 1', '종료 1'];

/// 브랜드: 상대는 크리에이터다. 가게의 "하루 한 컵 역제안(카드뉴스)" 줄 대신, 판본 2를 보낸 서윤의 작은 취향(12 브랜드 시점)이
/// 내가 응답할 차례에 있다. 민의 옷장 기록은 F2로 보낸 판본 1을 기다린다. 크리에이터의 보관함(D5)으로 가던 종료 줄은 갈 곳이 없다.
const List<List<_Group>> _brandData = [
  [
    _Group('내가 응답할 차례', Color(0xFFC6FF3D), Color(0xFFC6FF3D), [
      _Row(
        name: '서윤의 작은 취향',
        sub: '수정 제안 · 판본 2 · 릴스 1편',
        badge: '응답하기',
        href: 'Agreement.dc.html',
        photo: DemoImages.seoyun,
        avBg: _seoyunBg,
        hot: true,
      ),
    ]),
    _Group('상대 대기', Color(0xFFA0A4AD), Color(0xFFA0A4AD), [
      _Row(
        name: '민의 옷장 기록',
        sub: '판본 1 · 릴스 1편 · 2일 안에 답이 와요',
        badge: '대기',
        href: 'NReviewSend.dc.html',
        photo: DemoImages.minCloset,
        avBg: _minBg,
      ),
    ]),
  ],
  [
    _Group('종료', Color(0xFFE6E8EB), Color(0xFF2A2D33), [
      _Row(
        name: '하루 한 컵',
        sub: '일정이 맞지 않아 종료',
        badge: '종료',
        href: null,
        photo: DemoImages.onecup,
        avBg: _onecupBg,
      ),
    ]),
  ],
];

const List<String> _brandTabLabels = ['진행 중 2', '종료 1'];

/// F3 제안함 (`NProposals.dc.html`)
class ProposalsPage extends StatefulWidget {
  const ProposalsPage({super.key});

  @override
  State<ProposalsPage> createState() => _ProposalsPageState();
}

class _ProposalsPageState extends State<ProposalsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pal = G8Palette.of(context);
    final role = demoRole.value;
    final data = switch (role) {
      DemoRole.store => _storeData,
      DemoRole.creator => _creatorData,
      DemoRole.brand => _brandData,
      _ => _data,
    };
    final labels = switch (role) {
      DemoRole.creator => _creatorTabLabels,
      DemoRole.brand => _brandTabLabels,
      _ => _tabLabels,
    };
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G8Header(
                  pal: pal,
                  onBack: () =>
                      demoBack(context, fallback: 'NStoreHome.dc.html'),
                  center: Text(
                    '제안함',
                    style: g8Text(16, pal.text, weight: FontWeight.w500),
                  ),
                ),
                _tabs(pal, labels),
                for (final g in data[_tab]) _group(context, pal, g),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabs(G8Palette pal, List<String> labels) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(child: _tabButton(pal, labels, i)),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(G8Palette pal, List<String> labels, int i) {
    final on = i == _tab;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = i),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? pal.raised : const Color(0x00000000),
          borderRadius: BorderRadius.circular(999),
          boxShadow: on
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 24, 28, 0.10),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          labels[i],
          style: g8Text(14, pal.text, weight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _group(BuildContext context, G8Palette pal, _Group g) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: pal.dark ? g.darkDot : g.dot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  g.title,
                  style: g8Text(13, pal.sub, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          for (var i = 0; i < g.rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _row(context, pal, g.rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, G8Palette pal, _Row r) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: r.href == null ? null : () => demoGo(context, r.href!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: r.avBg, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: DemoPhoto(r.photo, x: 50, y: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: g8Text(15, pal.text, weight: FontWeight.w700),
                  ),
                  Text(r.sub, style: g8Text(12, pal.sub)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: r.hot ? G8Palette.lime : pal.raised,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                r.badge,
                style: g8Text(
                  12,
                  r.hot ? G8Palette.limeInk : pal.sub,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

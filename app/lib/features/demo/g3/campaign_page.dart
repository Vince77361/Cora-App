import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g3_common.dart';

/// D1 캠페인 상세 · 크리에이터 (`NCampaign.dc.html`)
class CampaignPage extends StatelessWidget {
  const CampaignPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    // 사진이 화면 맨 위까지 닿는 화면이라 상태 표시줄 높이만큼 사진을 늘리고 뒤로 버튼을 내린다.
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.bg,
      body: DefaultTextStyle.merge(
        style: TextStyle(color: p.text),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 96,
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 260 + top,
                      child: _hero(context, top),
                    ),
                    // 본문 판은 사진을 24px 덮는다(margin-top: -24px).
                    Padding(
                      padding: EdgeInsets.only(top: 236 + top),
                      child: _sheet(p),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: p.bg,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: G3Pill(
                        label: '넘기기',
                        background: p.card,
                        color: p.text,
                        height: 56,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        onTap: () => demoGo(context, 'Pass.dc.html'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 16,
                      child: G3Pill(
                        label: '관심 보내기',
                        background: p.accent,
                        color: p.onAccent,
                        height: 56,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        onTap: () => demoGo(context, 'Proposal.dc.html'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, double top) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Color(0xFF2E5B43)),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DemoPhoto(DemoImages.moaStudio, x: 62, y: 50),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0017181C), Color(0xCC17181C)],
                ),
              ),
            ),
          ),
          Positioned(left: 10, top: 10 + top, child: _backCircle(context)),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '모아 스튜디오, 느린 결 일상의 주얼리',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE4E6EA)),
                ),
                const SizedBox(height: 2),
                Text(
                  '나만의 아침 루틴 속 작은 포인트',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: g3Ls(24, -0.04),
                    height: 1.25,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backCircle(BuildContext context) {
    return Semantics(
      button: true,
      label: '뒤로',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => demoBack(context),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xE6FFFFFF),
            shape: BoxShape.circle,
          ),
          child: const DemoSvg(g3CampaignBackSvg, color: g3Ink, size: 22),
        ),
      ),
    );
  }

  Widget _sheet(G3Palette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '30만 원',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: g3Ls(32, -0.05),
                  color: p.text,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '+ 제품 제공, 릴스 1편',
                style: TextStyle(fontSize: 15, color: p.sub),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '나와 잘 맞는 이유',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '손·소품 중심 표현을 원하고, 대본 낭독 없이 평소 방식의 사용 장면을 좋아해요. 내 협업 원칙과 3개가 겹쳐요.',
                  style: TextStyle(fontSize: 15, height: 1.6, color: p.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _listCard(p, '꼭 담을 것', const [
                    '소재 정보',
                    '광고 표시',
                    '제품명 정확히',
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _listCard(p, '요구하지 않아요', const [
                    '얼굴 출연',
                    '정해진 대사',
                    '대본 낭독',
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _fact(p, '일정', '11월 16일 이후')),
              const SizedBox(width: 8),
              Expanded(child: _fact(p, '제품 사용', '7일 먼저 사용')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listCard(G3Palette p, String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: p.sub,
            ),
          ),
          const SizedBox(height: 6),
          for (final it in items)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  height: 14 * 1.6,
                  child: Align(
                    alignment: const Alignment(-0.1, 0),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.text,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    it,
                    style: TextStyle(fontSize: 14, height: 1.6, color: p.text),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _fact(G3Palette p, String dt, String dd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dt, style: TextStyle(fontSize: 12, color: p.sub)),
          const SizedBox(height: 2),
          Text(
            dd,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
}

const String g3CampaignBackSvg =
    '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

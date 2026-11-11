import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'campaign_page.dart' show g3CampaignBackSvg;
import 'g3_common.dart';

/// D2 가게 오퍼 상세 · 크리에이터 (`NStoreView.dc.html`)
class StoreViewPage extends StatefulWidget {
  const StoreViewPage({super.key});

  @override
  State<StoreViewPage> createState() => _StoreViewPageState();
}

class _StoreViewPageState extends State<StoreViewPage> {
  bool _applied = false;

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.bg,
      body: DefaultTextStyle.merge(
        style: TextStyle(color: p.text),
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                // 아래 고정 영역(지원하기 / 지원했어요 상태 막대)에 가리지 않게 비운다.
                padding: const EdgeInsets.only(bottom: 120),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 280 + top,
                      child: _hero(context, p, top),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 256 + top),
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
                child: _applied ? _appliedBar(p) : _applyBar(context, p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyBar(BuildContext context, G3Palette p) {
    return Row(
      children: [
        Expanded(
          flex: 10,
          child: G3Pill(
            label: '가게 정보',
            background: p.card,
            color: p.text,
            height: 56,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            onTap: () => demoGo(context, 'NStorePage.dc.html'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 16,
          child: G3Pill(
            label: '지원하기',
            background: p.accent,
            color: p.onAccent,
            height: 56,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            onTap: () => setState(() => _applied = true),
          ),
        ),
      ],
    );
  }

  Widget _appliedBar(G3Palette p) {
    // 다크에서는 상태 막대 바탕이 #0F1012(화면 바탕과 같음), 글자 #FFFFFF, 취소 버튼 rgba(255,255,255,0.14).
    final boxBg = p.dark ? const Color(0xFF0F1012) : p.card;
    final boxFg = p.dark ? const Color(0xFFFFFFFF) : g3Ink;
    final cancelBg = p.dark ? const Color(0x24FFFFFF) : const Color(0xFFFFFFFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '지원했어요. 사장님이 고르면 오퍼가 도착해요.',
              style: TextStyle(fontSize: 14, height: 1.5, color: boxFg),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _applied = false),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cancelBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: boxFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, G3Palette p, double top) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Color(0xFFF6E3C8)),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DemoPhoto(DemoImages.ramen, x: 50, y: 45),
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
          Positioned(
            left: 10,
            top: 10 + top,
            child: Semantics(
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
                  child: const DemoSvg(
                    g3CampaignBackSvg,
                    color: g3Ink,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 18 + top,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xEBFFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              // 다크에서도 알약 바탕이 흰색이다. 글자색은 artifact 그대로 상속값(다크 #F2F3F5).
              child: Text(
                '소상공인',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: p.text,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '라멘집, 성수동',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE4E6EA)),
                ),
                const SizedBox(height: 2),
                Text(
                  '한그릇 라멘',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: g3Ls(26, -0.04),
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

  Widget _sheet(G3Palette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '릴스 1편을 만들어 줄\n크리에이터를 찾아요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: g3Ls(22, -0.04),
              height: 1.35,
              color: p.text,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('보상', style: TextStyle(fontSize: 12, color: p.text)),
                const SizedBox(height: 4),
                Text(
                  '2인 식사권 + 조회 1회당 10원',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '조회수당은 최대 10만 원',
                  style: TextStyle(fontSize: 13, color: p.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _fact(p, '찍기 좋은 시간', '오후 3시 – 5시')),
              const SizedBox(width: 8),
              Expanded(child: _fact(p, '지원 조건', '팔로워 무관')),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.',
            style: TextStyle(fontSize: 14, height: 1.6, color: p.sub),
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

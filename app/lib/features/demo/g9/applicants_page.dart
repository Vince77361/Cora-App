import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g9_common.dart';

class _Applicant {
  const _Applicant({
    required this.name,
    required this.meta,
    required this.pitch,
    required this.why,
    required this.blob,
  });

  final String name;
  final String meta;
  final String pitch;
  final String why;
  final String blob;
}

const List<_Applicant> _items = [
  _Applicant(
    name: '하루 한 컵',
    meta: '걸어서 8분 · 팔로워 640',
    pitch: '김 오르는 첫 숟가락을 슬로모션으로 찍을게요',
    why: '카페·식당 릴스 9개 · 가게 사진과 분위기가 비슷해요 · 평균 2시간 안에 답장',
    blob: '/_blob/2c6508f8caadc5c0466b315d99cbda6b',
  ),
  _Applicant(
    name: '민의 옷장 기록',
    meta: '걸어서 15분 · 팔로워 2,100',
    pitch: '출근 전 라멘 한 그릇, 손만 나오게 찍을게요',
    why: '데일리 릴스 · 얼굴 출연 없이 찍어요 · 지난 협업 평소 대비 2.4배',
    blob: '/_blob/b69c53f92919508dbffde40eedb1953c',
  ),
  _Applicant(
    name: '서윤의 작은 취향',
    meta: '지하철 2정거장 · 팔로워 8,200',
    pitch: '바 좌석 18석의 조용한 오후를 담을게요',
    why: '소품·분위기 릴스 · 답장이 빨라요',
    blob: '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
  ),
];

const String _heartSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="#1F2A00"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';

/// G2 지원자 추천 3명 (`NApplicants.dc.html`)
class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pal = G9Palette.of(context);
    final it = _items[_i];
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              G9Header(
                pal: pal,
                title: '새 지원 5',
                onBack: () => g9Back(context, 'NStoreHome.dc.html'),
                right: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoGo(context, 'NReels.dc.html'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Text('탐색', style: g9Text(13, pal.sub)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '지원한 5명 중 가게와 잘 맞는 3명이에요. 팔로워 수는 점수에 넣지 않아요.',
                  style: g9Text(13, pal.sub),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 100,
          bottom: 112,
          child: _card(it),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              G9Button(
                label: '넘기기',
                size: 15,
                weight: FontWeight.w500,
                background: pal.soft,
                foreground: pal.text,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                onTap: () => setState(() => _i = (_i + 1) % _items.length),
              ),
              const SizedBox(width: 12),
              G9Button(
                label: '좋아요하고 오퍼',
                background: G9Palette.lime,
                foreground: G9Palette.limeInk,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                leading: const DemoSvg(_heartSvg, size: 20),
                onTap: () => demoGo(context, 'NOffer.dc.html'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 추천 카드: 대표 릴스 사진 위에 한 줄 제안과 이유, 이름·거리·팔로워.
  Widget _card(_Applicant it) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E3D3),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 24, 28, 0.14),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DemoPhoto(DemoImages.forBlob(it.blob), x: 50, y: 30),
          ),
          const G9PhotoShade(
            height: 380,
            colors: [
              Color.fromRGBO(23, 24, 28, 0),
              Color.fromRGBO(23, 24, 28, 0.55),
              Color.fromRGBO(23, 24, 28, 0.86),
            ],
            stops: [0, 0.45, 1],
          ),
          G9PhotoChip('대표 릴스 · 추천 ${_i + 1} / 3'),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“${it.pitch}”',
                  style: g9Text(
                    26,
                    G9Palette.onPhoto,
                    weight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  it.why,
                  style: g9Text(14, G9Palette.onPhotoSub, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '${it.name} · ${it.meta}',
                  style: g9Text(13, G9Palette.onPhotoSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

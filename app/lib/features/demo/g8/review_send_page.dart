import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_ui.dart';
import 'g8_common.dart';

const List<(String, String)> _rows = [
  ('모집', '한그릇 라멘 · 첫 숟가락 릴스'),
  ('결과물', '릴스 1편 · 30초 안팎'),
  ('제공 혜택', '식사권 40,000원 · 2인'),
  ('고정 현금', '없음'),
  ('조회수 수당', '1,000회당 2,000원 · 1인 최대 60,000원'),
  ('사용권', '가게 계정 재게시 3개월'),
  ('최대 현금 부담', '60,000원'),
];

/// 크리에이터가 F6 "내 방식으로 제안"에서 넘어오면 받는 사람은 가게다(가게 흐름 개정 설계 F2).
/// 값은 F6의 희망 보상 "식사권 + 3만 원"(고정 현금 3만 원, 조회수 수당 없음)이고, 최대 현금 부담은 고정 현금과 같다.
const List<(String, String)> _creatorRows = [
  ('모집', '한그릇 라멘 · 첫 숟가락 릴스'),
  ('결과물', '릴스 1편 · 30초 안팎'),
  ('제공 혜택', '식사권 40,000원 · 2인'),
  ('고정 현금', '30,000원'),
  ('조회수 수당', '없음'),
  ('사용권', '가게 계정 재게시 3개월'),
  ('최대 현금 부담', '30,000원'),
];

/// F2 제안 보내기 전 검토 (`NReviewSend.dc.html`)
class ReviewSendPage extends StatelessWidget {
  const ReviewSendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = G8Palette.of(context);
    final creator = demoRole.value == DemoRole.creator;
    final rows = creator ? _creatorRows : _rows;
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G8Header(
                  pal: pal,
                  onBack: () => demoBack(context),
                  center: const G8Pill('제안 만들기'),
                  right: '3 / 3',
                ),
                G8Progress(pal: pal, fraction: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    '받는 사람과 조건을\n한 번 더 확인해요.',
                    style: g8Text(
                      26,
                      pal.text,
                      weight: FontWeight.w900,
                      height: 1.3,
                      letterSpacing: -0.045,
                    ),
                  ),
                ),
                _recipient(pal, creator),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  decoration: BoxDecoration(
                    color: pal.card,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        G8KeyValueRow(
                          pal: pal,
                          term: rows[i].$1,
                          value: rows[i].$2,
                          first: i == 0,
                          bold: i == rows.length - 1,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Text(
                    // 가게의 판본 1(기본 조건) 다음이라 크리에이터의 제안은 판본 2다.
                    creator
                        ? '보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 2로 고정되고, 이용료 [수수료]는 별도예요.'
                        : '보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 1로 고정되고, 이용료 [수수료]는 별도예요.',
                    style: g8Text(12, pal.sub, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        G8BottomBar(
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: G8BigButton(
                  label: '고치기',
                  onTap: () => demoGo(context, 'NBudget.dc.html'),
                  background: pal.button,
                  foreground: pal.text,
                  size: 15,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 16,
                child: G8BigButton(
                  label: '이 조건으로 보내기',
                  onTap: () => demoGo(context, 'NProposals.dc.html'),
                  background: G8Palette.lime,
                  foreground: G8Palette.limeInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 받는 사람 카드: 받는 사람 사진, 이름, 고른 작품 사진. 크리에이터가 보낼 때 받는 사람은 가게다.
  Widget _recipient(G8Palette pal, bool creator) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: creator
                  ? const Color(0xFFF6E3C8)
                  : const Color(0xFFF3E3D3),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: DemoPhoto(
              creator ? DemoImages.ramen : DemoImages.onecup,
              x: 50,
              y: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('받는 사람', style: g8Text(12, pal.sub)),
                Text(
                  creator ? '한그릇 라멘' : '하루 한 컵',
                  style: g8Text(16, pal.text, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF6E3C8),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: const DemoPhoto(DemoImages.onecup, x: 50, y: 60),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_ui.dart';
import 'g2_palette.dart';

/// D4 최종 계약: 세 가지를 모두 확인해야 계약할 수 있다.
class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  static const _labels = [
    '합의한 조건 버전 2를 확인했어요',
    '광고 표시 의무를 지킬게요',
    '콘텐츠는 브랜드 계정 재게시에만 쓰여요',
  ];
  // 사장님의 사용권은 "가게 계정 재게시"다(공통 모델 7장).
  static const _storeLabels = [
    '합의한 조건 버전 2를 확인했어요',
    '광고 표시 의무를 지킬게요',
    '콘텐츠는 가게 계정 재게시에만 쓰여요',
  ];
  final List<bool> _on = [true, true, false];

  @override
  Widget build(BuildContext context) {
    final p = G2Palette.of(context);
    final ready = _on.every((x) => x);
    // 사장님에게 계약 상대는 크리에이터이고 보상은 식사권·고정 현금·조회수 수당이다(F2 캔버스의 값).
    final store = demoRole.value == DemoRole.store;
    final labels = store ? _storeLabels : _labels;

    Widget term(String k, String v) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: g2Text(12, color: p.sub)),
          const SizedBox(height: 2),
          Text(
            v,
            style: g2Text(15, color: p.text, weight: FontWeight.w500),
          ),
        ],
      ),
    );

    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => demoBack(context),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: DemoSvg(
                                    G2Icons.back,
                                    color: p.text,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '협업 계약',
                            textAlign: TextAlign.center,
                            style: g2Text(
                              16,
                              color: p.text,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '합의한 버전 2로\n계약해요.',
                        style: g2Text(
                          26,
                          color: p.text,
                          weight: FontWeight.w900,
                          spacingEm: -0.045,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '양쪽이 모두 동의하면 계약이 체결되고 제작이 시작돼요.',
                        style: g2Text(14, color: p.sub),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              color: G2Palette.photoCream,
                              shape: BoxShape.circle,
                            ),
                            child: const DemoPhoto(
                              DemoImages.seoyun,
                              x: 55,
                              y: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '서윤의 작은 취향',
                            style: g2Text(
                              14,
                              color: p.text,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Container(height: 2, color: p.line)),
                          const SizedBox(width: 10),
                          Text(
                            store ? '한그릇 라멘' : '모아 스튜디오',
                            style: g2Text(
                              14,
                              color: p.text,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 36,
                            height: 36,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: store
                                  ? const Color(0xFFF6E3C8)
                                  : G2Palette.photoGreen,
                              shape: BoxShape.circle,
                            ),
                            child: store
                                ? const DemoPhoto(
                                    DemoImages.ramen,
                                    x: 50,
                                    y: 25,
                                  )
                                : const DemoPhoto(
                                    DemoImages.moaStudio,
                                    x: 62,
                                    y: 40,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          term('제작물', store ? '릴스 1편' : '일상형 릴스 1편'),
                          const SizedBox(width: 8),
                          store
                              ? term('제공 혜택', '식사권 40,000원 · 2인')
                              : term('제작비', '350,000원 + 제품'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          store
                              ? term('조회수 수당', '1,000회당 2,000원')
                              : term('제작 시작', '11월 23일'),
                          const SizedBox(width: 8),
                          store
                              ? term('최대 현금 부담', '60,000원')
                              : term('지급', '게시 후 7일 이내'),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
                  child: Column(
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        _check(p, labels, i),
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
          child: Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  store
                      ? '크리에이터 동의를 기다리고 있어요. 계약서는 체결 후 보관함에 저장돼요.'
                      : '브랜드 동의를 기다리고 있어요. 계약서는 체결 후 보관함에 저장돼요.',
                  textAlign: TextAlign.center,
                  style: g2Text(12, color: p.sub),
                ),
                const SizedBox(height: 10),
                if (ready)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // 사장님에게는 진행 단계(07)가 없다. 합의한 오퍼는 결제(A8)로 이어진다.
                    onTap: () => demoGo(
                      context,
                      store ? 'NPay.dc.html' : 'Progress.dc.html',
                    ),
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: G2Palette.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '동의하고 계약하기',
                        style: g2Text(
                          16,
                          color: G2Palette.onLime,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '모두 확인하면 계약할 수 있어요',
                      style: g2Text(16, color: p.sub, weight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _check(G2Palette p, List<String> labels, int i) {
    final on = _on[i];
    final box = p.dark
        ? (on ? const Color(0xFFF2F3F5) : const Color(0xFF2A2D33))
        : (on ? G2Palette.lime : const Color(0xFFE6E8EB));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _on[i] = !_on[i]),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: box,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: DemoSvg(
                  '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>',
                  color: on ? G2Palette.onLime : Colors.transparent,
                  size: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labels[i],
                style: g2Text(15, color: p.text, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

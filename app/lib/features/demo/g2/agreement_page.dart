import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g2_palette.dart';

/// 12 조건 합의·변경 기록.
class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = G2Palette.of(context);
    final chipBg = p.dark
        ? const Color.fromRGBO(255, 255, 255, 0.06)
        : const Color.fromRGBO(255, 255, 255, 0.7);

    Widget changed(String k, String v, String old) => Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: g2Text(12, color: p.text)),
          const SizedBox(height: 4),
          Text(
            v,
            style: g2Text(
              18,
              color: p.text,
              weight: FontWeight.w700,
              spacingEm: -0.02,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: old,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const TextSpan(text: '에서 변경'),
              ],
            ),
            style: g2Text(12, color: p.text),
          ),
        ],
      ),
    );

    Widget plain(String k, String v) => Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: g2Text(12, color: p.sub)),
          const SizedBox(height: 4),
          Text(
            v,
            style: g2Text(16, color: p.text, weight: FontWeight.w500),
          ),
        ],
      ),
    );

    Widget grid(List<Widget> cells) {
      final rows = <Widget>[];
      for (var i = 0; i < cells.length; i += 2) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cells[i]),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < cells.length
                      ? cells[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
        if (i + 2 < cells.length) rows.add(const SizedBox(height: 8));
      }
      return Column(children: rows);
    }

    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        GestureDetector(
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
                        const SizedBox(width: 4),
                        Text(
                          '조건 합의',
                          style: g2Text(
                            17,
                            color: p.text,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 합의 상태
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '버전 2',
                            style: g2Text(
                              20,
                              color: p.text,
                              weight: FontWeight.w900,
                              spacingEm: -0.03,
                            ),
                          ),
                          Text(
                            '브랜드 확인 대기 중',
                            style: g2Text(
                              14,
                              color: p.sub,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: G2Palette.lime,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: DemoSvg(
                                        G2Icons.check,
                                        color: G2Palette.onLime,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '나 · 확인함',
                                    style: g2Text(
                                      14,
                                      color: p.text,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: p.line,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '브랜드 · 대기',
                                    style: g2Text(14, color: p.sub),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '대화에서 정한 조건',
                        style: g2Text(
                          22,
                          color: p.text,
                          weight: FontWeight.w900,
                          spacingEm: -0.03,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '초록색은 이번 버전에서 바뀐 조건이에요.',
                        style: g2Text(13, color: p.sub),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: grid([
                    changed('제작비', '350,000원', '300,000원'),
                    changed('제작 시작', '11월 23일', '11월 16일'),
                    plain('제작물', '일상형 릴스 1편'),
                    plain('제품 제공', '포함'),
                    plain('수정 범위', '기획안 기준 1회'),
                    plain('활용 권한', '브랜드 계정 재게시만'),
                    plain('지급 조건', '게시 후 7일 이내'),
                    plain('광고 표시', '영상·게시물에 명확히'),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '변경 기록',
                        style: g2Text(
                          14,
                          color: p.sub,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 46,
                            child: Text(
                              '버전 1',
                              style: g2Text(14, color: p.sub),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('브랜드의 최초 제안', style: g2Text(14, color: p.sub)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 46,
                            child: Text(
                              '버전 2',
                              style: g2Text(
                                14,
                                color: p.text,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '내가 제작비·일정 수정 제안',
                            style: g2Text(14, color: p.text),
                          ),
                        ],
                      ),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: p.bg,
              boxShadow: [
                BoxShadow(
                  color: p.dark
                      ? const Color.fromRGBO(0, 0, 0, 0.45)
                      : const Color.fromRGBO(23, 24, 28, 0.06),
                  offset: const Offset(0, -8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => demoGo(context, 'Terms.dc.html'),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '수정 제안',
                            style: g2Text(
                              15,
                              color: p.text,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 14,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => demoGo(context, 'NContract.dc.html'),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: G2Palette.lime,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '계약서 미리 보기',
                            style: g2Text(
                              15,
                              color: G2Palette.onLime,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '합의 기록과 최종 계약 체결은 별도예요.',
                  textAlign: TextAlign.center,
                  style: g2Text(12, color: p.sub),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

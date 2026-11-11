import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E7 정산 (`NWallet.dc.html`)
/// 맨 아래 "수수료 [수수료]와 원천징수 3.3%…" 줄은 설계 결정에 따라 그리지 않는다.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  static const _rows = [
    ('한그릇 라멘 · 릴스 1편', '조회수 4,320회분', '43,200원', '지급 예정'),
    ('한그릇 라멘 · 릴스 1편', '2인 식사권', '식사권', '사용 완료'),
    ('모아 스튜디오 · 릴스 1편', '11월 2일 지급', '350,000원', '지급 완료'),
    ('하루 한 컵 · 카드뉴스', '게시 확인 중', '100,000원', '보관 중'),
  ];

  Widget _stat(G7Colors c, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.sub)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G7Header(title: '정산'),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 지급 예정 · 11월 18일 수요일',
                        style: TextStyle(fontSize: 13, color: c.sub),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '43,200원',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 36 * -0.05,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: '국민은행 ****12 ',
                                style: TextStyle(fontSize: 14, color: c.text),
                                children: [
                                  TextSpan(
                                    text: '민서연',
                                    style: TextStyle(color: c.sub),
                                  ),
                                ],
                              ),
                            ),
                            // artifact는 다크에서도 흰 바탕에 어두운 글자다.
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '계좌 변경',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF17181C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _stat(c, '이번 달 받은 금액', '350,000원')),
                        const SizedBox(width: 8),
                        Expanded(child: _stat(c, 'Cora가 보관 중', '100,000원')),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Text(
                    '내역',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.sub,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      for (final r in _rows)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.$1,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: c.text,
                                      ),
                                    ),
                                    Text(
                                      r.$2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: c.sub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    r.$3,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: c.text,
                                    ),
                                  ),
                                  Text(
                                    r.$4,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.sub,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
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

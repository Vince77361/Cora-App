import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g3_common.dart';

class _Keep {
  const _Keep({
    required this.name,
    required this.status,
    required this.date,
    required this.fee,
    required this.asset,
    required this.initial,
    required this.bg,
    required this.done,
  });

  final String name;
  final String status;
  final String date;
  final String fee;
  final String? asset;
  final String initial;
  final Color bg;
  final bool done;
}

/// D5 다시 만나고 싶은 브랜드 (`NKeepList.dc.html`)
class KeepListPage extends StatefulWidget {
  const KeepListPage({super.key});

  @override
  State<KeepListPage> createState() => _KeepListPageState();
}

class _KeepListPageState extends State<KeepListPage> {
  static const _labels = ['전체', '완료한 협업', '무산된 상대'];
  static const _items = [
    _Keep(
      name: '모아 스튜디오',
      status: '협업 완료, 비공개 회고 저장됨',
      date: '12월 1일부터',
      fee: '40만 원',
      asset: DemoImages.moaStudio,
      initial: '',
      bg: Color(0xFF2E5B43),
      done: true,
    ),
    _Keep(
      name: '결 리빙',
      status: '일정이 맞지 않아 무산',
      date: '12월 중순',
      fee: '40만 원',
      asset: null,
      initial: '결',
      bg: Color(0xFFE7DDEE),
      done: false,
    ),
    _Keep(
      name: '오늘의 잔',
      status: '예산이 맞지 않아 무산',
      date: '언제든',
      fee: '25만 원',
      asset: null,
      initial: '잔',
      bg: Color(0xFFF6E7C8),
      done: false,
    ),
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    final rows = _items
        .where((x) => _tab == 0 || (_tab == 1 ? x.done : !x.done))
        .toList();
    return DemoFrame(
      background: p.bg,
      children: [
        Positioned.fill(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.text),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: G3HeaderButton(
                                svg: g3BackSvg,
                                color: p.text,
                                label: '뒤로',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '보관함',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: p.text,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 60),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '다시 만나고 싶은 브랜드',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: g3Ls(26, -0.045),
                            height: 1.3,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '일정이나 예산 때문에 무산된 상대도 여기에 남아요.',
                          style: TextStyle(fontSize: 14, color: p.sub),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        for (var i = 0; i < _labels.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Semantics(
                            button: true,
                            selected: i == _tab,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _tab = i),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: i == _tab ? p.chipOn : p.card,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _labels[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: i == _tab ? p.onChipOn : p.onChipOff,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _row(context, p, rows[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, G3Palette p, _Keep r) {
    // 라이트: 완료 #F2F3F5 / 무산 #FFFFFF, 글자 #17181C. 다크: 완료 #F2F3F5(글자 #0F1012) / 무산 #0F1012(글자 #F2F3F5).
    final ctaBg = p.dark
        ? (r.done ? const Color(0xFFF2F3F5) : const Color(0xFF0F1012))
        : (r.done ? const Color(0xFFF2F3F5) : const Color(0xFFFFFFFF));
    final ctaFg = p.dark
        ? (r.done ? const Color(0xFF0F1012) : const Color(0xFFF2F3F5))
        : g3Ink;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: r.bg, shape: BoxShape.circle),
                child: r.asset != null
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: DemoPhoto(r.asset!, x: 62, y: 40),
                      )
                    : Text(
                        r.initial,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: p.text,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    Text(
                      r.status,
                      style: TextStyle(fontSize: 12, color: p.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kv(p, '가능한 날', r.date),
              const SizedBox(width: 16),
              _kv(p, '희망 제작비', r.fee),
            ],
          ),
          const SizedBox(height: 12),
          G3Pill(
            label: '재협업 메시지 만들기',
            background: ctaBg,
            color: ctaFg,
            height: 46,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            onTap: () => demoGo(context, 'NChatThread.dc.html'),
          ),
        ],
      ),
    );
  }

  Widget _kv(G3Palette p, String k, String v) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 13, color: p.text),
        children: [
          TextSpan(
            text: k,
            style: TextStyle(color: p.sub),
          ),
          TextSpan(text: ' $v'),
        ],
      ),
    );
  }
}

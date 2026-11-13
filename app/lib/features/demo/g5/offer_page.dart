import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g5_common.dart';

class _Fmt {
  const _Fmt(this.label, this.sub, this.icon);
  final String label;
  final String sub;
  final String icon;
}

class _Reward {
  const _Reward(this.label, this.sub, this.summary);
  final String label;
  final String sub;
  final String summary;
}

const List<_Fmt> _fmts = [
  _Fmt(
    '쇼츠',
    '유튜브 60초',
    'M8 4h8a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3zM10 9l5 3-5 3z',
  ),
  _Fmt(
    '릴스',
    '인스타그램 30초',
    'M7 3h10a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V7a4 4 0 0 1 4-4zM3 9h18M10 12l5 3-5 3z',
  ),
  _Fmt('카드뉴스', '인스타그램 3–5장', 'M4 5h12v12H4zM8 9h12v12H8'),
  _Fmt('블로그 글', '사진 포함 후기', 'M5 4h14v16H5zM8 8h8M8 12h8M8 16h5'),
];

const List<_Reward> _rewards = [
  _Reward('제공 혜택만', '식사권 40,000원 · 2인', '식사권 40,000원 · 2인'),
  _Reward('고정 현금', '정한 금액을 한 번에 · 선택', '고정 현금 (금액 입력)'),
  _Reward(
    '제공 혜택 + 조회수 수당 · 추천',
    '1,000회당 2,000원 · 1인 최대 60,000원',
    '식사권 40,000원 · 2인\n+ 1,000회당 2,000원, 최대 60,000원',
  ),
];

String _checkSvg(Color c) {
  final hex = '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  return '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';
}

String _fmtIcon(String d) =>
    '<svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="$d"></path></svg>';

/// A5 오퍼 보내기 · 3단계 (`NOffer.dc.html`)
class OfferPage extends StatefulWidget {
  const OfferPage({super.key});

  @override
  State<OfferPage> createState() => _OfferPageState();
}

class _OfferPageState extends State<OfferPage> {
  int _step = 0;
  int _fmt = 1;
  int _rw = 2;
  late final TapGestureRecognizer _detail = TapGestureRecognizer()
    ..onTap = () => demoGo(context, 'NBudget.dc.html');

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  void _prev() {
    // 첫 단계에서는 실제 앱처럼 이 화면을 떠난다(캔버스는 미리보기라 꺼진 모양이었다).
    if (_step > 0) {
      setState(() => _step--);
    } else {
      demoBack(context, fallback: 'NStoreHome.dc.html');
    }
  }

  void _next() {
    if (_step < 2) setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final pal = G5Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G5Header(
                  pal: pal,
                  onBack: _prev,
                  backOpacity: 1,
                  center: const SizedBox.shrink(),
                  right: '${_step + 1} / 3',
                ),
                G5Progress(pal: pal, fraction: [0.33, 0.67, 1.0][_step]),
                if (_step == 0) ..._stepFormat(pal),
                if (_step == 1) ..._stepReward(pal),
                if (_step == 2) ..._stepConfirm(pal),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: _step < 2
                ? G5BigButton(
                    label: '다음',
                    onTap: _next,
                    background: G5Palette.lime,
                    foreground: G5Palette.limeInk,
                  )
                : G5BigButton(
                    label: '검토하고 보내기',
                    onTap: () => demoGo(context, 'NReviewSend.dc.html'),
                    background: G5Palette.lime,
                    foreground: G5Palette.limeInk,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _heading(G5Palette pal, String title, String sub, {TextSpan? link}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: g5Text(
              28,
              pal.text,
              weight: FontWeight.w900,
              height: 1.3,
              letterSpacing: -0.05,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(text: sub, children: [?link]),
            style: g5Text(14, pal.sub),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color fg, Color dot, Color check}) _opt(G5Palette pal, bool on) {
    if (pal.dark) {
      return (
        bg: on ? const Color(0xFF33363D) : const Color(0xFF1C1E22),
        fg: const Color(0xFFF2F3F5),
        dot: on ? G5Palette.lime : const Color(0xFF2A2D33),
        check: G5Palette.limeInk,
      );
    }
    return (
      bg: on ? const Color(0xFFE3E5E9) : const Color(0xFFF8F9FA),
      fg: const Color(0xFF17181C),
      dot: on ? G5Palette.lime : const Color(0xFFE6E8EB),
      check: G5Palette.limeInk,
    );
  }

  List<Widget> _stepFormat(G5Palette pal) {
    Widget card(int i) {
      final o = _opt(pal, i == _fmt);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _fmt = i),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: o.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DemoSvg(_fmtIcon(_fmts[i].icon), color: o.fg, size: 26),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmts[i].label,
                    style: g5Text(17, o.fg, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmts[i].sub,
                    style: g5Text(12, o.fg.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return [
      _heading(pal, '어떤 콘텐츠를\n부탁할까요?', '크리에이터가 올릴 형식을 하나 골라요.'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: card(0)),
                const SizedBox(width: 10),
                Expanded(child: card(1)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: card(2)),
                const SizedBox(width: 10),
                Expanded(child: card(3)),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _stepReward(G5Palette pal) {
    Widget card(int i) {
      final o = _opt(pal, i == _rw);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _rw = i),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: o.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rewards[i].label,
                      style: g5Text(17, o.fg, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rewards[i].sub,
                      style: g5Text(13, o.fg.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: o.dot, shape: BoxShape.circle),
                child: i == _rw ? DemoSvg(_checkSvg(o.check), size: 13) : null,
              ),
            ],
          ),
        ),
      );
    }

    return [
      _heading(
        pal,
        '어떻게\n보상할까요?',
        '가게 등록 때 정한 기본값이에요. 최대 현금 부담 60,000원, 조회수가 적으면 남은 돈은 돌려드려요. ',
        link: TextSpan(
          text: '자세히 설정',
          recognizer: _detail,
          style: TextStyle(
            color: pal.text,
            decoration: TextDecoration.underline,
            decorationColor: pal.text,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          children: [
            for (var i = 0; i < _rewards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              card(i),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _stepConfirm(G5Palette pal) {
    Widget tile(
      String term,
      String value, {
      double size = 16,
      FontWeight w = FontWeight.w500,
      Color? termColor,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(term, style: g5Text(12, termColor ?? pal.sub)),
            const SizedBox(height: 4),
            Text(value, style: g5Text(size, pal.text, weight: w)),
          ],
        ),
      );
    }

    final shield =
        '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"></path></svg>';
    return [
      _heading(pal, '이 오퍼를\n보낼까요?', '상대가 수락하면 그때 결제해요.'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile('가게', '한그릇 라멘')),
                  const SizedBox(width: 8),
                  Expanded(child: tile('콘텐츠', '${_fmts[_fmt].label} 1편')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: tile(
                '보상',
                _rewards[_rw].summary,
                size: 18,
                w: FontWeight.w700,
                termColor: pal.text,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: DemoSvg(shield, color: pal.sub, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '결제한 금액은 Cora가 보관하고, 콘텐츠가 올라온 뒤 크리에이터에게 지급해요.',
                style: g5Text(13, pal.sub, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../chat/presentation/widgets/chat_glyphs.dart';
import '../../../chat/presentation/widgets/chat_header.dart'
    show ChatIconButton;
import '../terms_text.dart';
import 'canvas_text.dart';

/// 12의 `최대 현금 부담` 줄(Agreement): 위 여백 0, 아래 10, 안쪽 10/14, 모서리 14, `surface`, 13px. 왼쪽은 보조색,
/// 오른쪽 값은 700이다. 수정 제안 화면도 같은 줄로 금액을 보인다.
class MaxCashRow extends StatelessWidget {
  const MaxCashRow({super.key, required this.value, this.bottomGap = 10});

  final String value;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Semantics(
        container: true,
        label: '${AgreementTexts.maxCash} $value',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AgreementTexts.maxCash,
                    style: canvasText(13, FontWeight.w400, c.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: canvasText(13, FontWeight.w700, c.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 12 머리 상자(`합의 상태`): 안쪽 16, 모서리 16, `surface`, 세로 12. 첫 줄은 `버전 n`(20/900)과 상태(14/500, 보조색),
/// 둘째 줄은 확인 표시 칸 둘(높이 40, 안쪽 0/12, 모서리 10)이다.
class AgreementStatusBox extends StatelessWidget {
  const AgreementStatusBox({
    super.key,
    required this.version,
    required this.status,
    required this.myLine,
    required this.myConfirmed,
    required this.otherLine,
    required this.otherConfirmed,
  });

  final int version;
  final String status;
  final String myLine;
  final bool myConfirmed;
  final String otherLine;
  final bool otherConfirmed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Semantics(
        container: true,
        label: '합의 상태',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '버전 $version',
                      style: canvasText(
                        20,
                        FontWeight.w900,
                        c.text,
                        spacingEm: -0.03,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        status,
                        textAlign: TextAlign.end,
                        style: canvasText(14, FontWeight.w500, c.textSecondary),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _PartyCell(line: myLine, done: myConfirmed),
                    ),
                    Expanded(
                      child: _PartyCell(line: otherLine, done: otherConfirmed),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartyCell extends StatelessWidget {
  const _PartyCell({required this.line, required this.done});

  final String line;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.agreementCell,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: 8,
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? c.accent : c.line,
                      ),
                      child: done
                          ? Center(
                              child: CustomPaint(
                                size: const Size.square(12),
                                painter: _CheckPainter(c.onAccent),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // 좁은 칸에서 `크리에이터 · 확인함`이 `확인 / 함`으로 갈라지지 않게, 넘치면 한 줄로 줄인다.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      line,
                      maxLines: 1,
                      style: canvasText(
                        14,
                        done ? FontWeight.w500 : FontWeight.w400,
                        done ? c.text : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 확인 표시 `M5 12l5 5 9-10`(24칸, 두께 3.4, 둥근 끝).
class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(5 * s, 12 * s)
      ..lineTo(10 * s, 17 * s)
      ..lineTo(19 * s, 7 * s);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

/// 조건 칸 하나(캔버스 `dl`의 한 칸): 안쪽 14, 모서리 14, `surface`, 최소 높이 76. 안 바뀐 칸은 이름이 보조색,
/// 값이 16/500이고, 바뀐 칸은 이름과 값이 `text` 색이며 값이 18/700이고 그 아래 `{이전 값}에서 변경`(12)이 붙는다.
class TermsCell extends StatelessWidget {
  const TermsCell({
    super.key,
    required this.name,
    required this.value,
    this.previousValue,
  });

  final String name;
  final String value;

  /// 이번 판본에서 바뀐 항목의 이전 값. 있으면 바뀐 칸이다.
  final String? previousValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final changed = previousValue != null;
    return MergeSemantics(
      child: Semantics(
        label: changed ? '$name, $value, $previousValue에서 변경' : '$name, $value',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: canvasText(
                        12,
                        FontWeight.w400,
                        changed ? c.text : c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: changed
                          ? canvasText(
                              18,
                              FontWeight.w700,
                              c.text,
                              spacingEm: -0.02,
                            )
                          : canvasText(16, FontWeight.w500, c.text),
                    ),
                    if (changed) ...[
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: previousValue,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const TextSpan(text: '에서 변경'),
                          ],
                        ),
                        style: canvasText(12, FontWeight.w400, c.text),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 조건 칸을 두 칸씩 한 줄로 놓는다(CSS grid 두 열, 칸 사이 8). 한 줄의 두 칸은 높이가 같다.
class TermsGrid extends StatelessWidget {
  const TermsGrid({super.key, required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        for (var i = 0; i < cells.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Expanded(child: cells[i]),
                Expanded(
                  child: i + 1 < cells.length
                      ? cells[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 변경 기록(캔버스 `ol`): 줄 사이 6, 14px. 가장 새 판본 줄만 `버전 n`이 500이고 글자색 `text`이며, 지난 줄은 보조색이다.
/// 번호 칸은 46(글자를 키우면 따라 넓어진다)이고 번호와 글 사이는 10이다. 캔버스처럼 오래된 판본이 위다.
class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.lines});

  /// 오래된 것부터. 마지막이 가장 새 판본이다.
  final List<({int version, String text})> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        for (var i = 0; i < lines.length; i++)
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 46),
                  child: Text(
                    '버전 ${lines[i].version}',
                    style: canvasText(
                      14,
                      i == lines.length - 1 ? FontWeight.w500 : FontWeight.w400,
                      i == lines.length - 1 ? c.text : c.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    lines[i].text,
                    style: canvasText(
                      14,
                      FontWeight.w400,
                      i == lines.length - 1 ? c.text : c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 머리(캔버스 `header`): 높이 60, 좌우 8, 칸 사이 4. 뒤로 가기(44), 제목(17/700). 계약 전이면 오른쪽 끝에 점 셋(캔버스
/// 밖)이 `협의 그만두기` 메뉴를 연다.
class AgreementHeader extends StatelessWidget {
  const AgreementHeader({
    super.key,
    required this.onBack,
    this.title = AgreementTexts.title,
    this.onMenu,
  });

  final VoidCallback onBack;
  final String title;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          spacing: 4,
          children: [
            ChatIconButton(
              label: '뒤로',
              onTap: onBack,
              child: ChatGlyphIcon(
                ChatGlyph.chevronBack,
                size: 24,
                color: c.text,
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: canvasText(17, FontWeight.w700, c.text),
                ),
              ),
            ),
            if (onMenu != null)
              ChatIconButton(
                label: AgreementTexts.menu,
                onTap: onMenu!,
                child: ChatGlyphIcon(
                  ChatGlyph.dots,
                  size: 22,
                  color: c.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

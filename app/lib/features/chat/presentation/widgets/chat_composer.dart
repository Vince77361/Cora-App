import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../chat_text.dart';
import 'chat_glyphs.dart';

/// 입력 줄(캔버스 D3): 안쪽 위 10·좌우 12·아래 28, 칸 사이 8. 왼쪽 더하기 원(48), 가운데 알약 입력란(높이 48,
/// 안쪽 왼쪽 16·오른쪽 6), 그 안 오른쪽 라임 보내기 원(38).
///
/// 1,000자를 넘기면 보내기가 꺼지고 `1,000자까지 보낼 수 있어요.`가 입력란 위에 뜬다. [closedText]가 있으면
/// 입력란 자리에 그 글만 보인다(상대가 수락하기 전, 차단한 방, 닫힌 방). [attachOpen]은 더하기 메뉴가 열려 있는지다.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    this.onAttach,
    this.attachOpen = false,
    this.notice,
    this.closedText,
    this.onChanged,
  });

  final ValueChanged<String> onSend;

  /// null이면 더하기 버튼이 없다(보낼 카드도, 조건 수정 제안도 없을 때).
  final VoidCallback? onAttach;
  final bool attachOpen;

  /// 방금 한 일이 실패했을 때 입력란 위에 보일 문구.
  final String? notice;
  final String? closedText;

  /// 글이 바뀔 때(실패 문구를 지우는 데 쓴다).
  final VoidCallback? onChanged;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _tooLong => _controller.text.runes.length > ChatTexts.messageMax;

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty || _tooLong) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 키보드가 올라오면 홈 막대 자리가 필요 없어 아래 여백을 줄인다.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final closed = widget.closedText;
    final notice = _tooLong ? ChatTexts.tooLong : widget.notice;
    return ColoredBox(
      color: c.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, keyboardUp ? 10 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notice != null && closed == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    notice,
                    style: CoraTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
            if (closed != null)
              _ClosedBar(text: closed)
            else
              Row(
                spacing: 8,
                children: [
                  if (widget.onAttach != null)
                    Semantics(
                      container: true,
                      button: true,
                      expanded: widget.attachOpen,
                      label: ChatTexts.attachLabel,
                      onTap: widget.onAttach,
                      child: ExcludeSemantics(
                        child: CoraPressable(
                          onTap: widget.onAttach,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.surface,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(
                              dimension: 48,
                              child: Center(
                                child: ChatGlyphIcon(
                                  ChatGlyph.plus,
                                  size: 20,
                                  color: c.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: _field(c)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(CoraColors c) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            spacing: 6,
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: ChatTexts.composerLabel,
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged?.call();
                    },
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 5,
                    cursorColor: c.text,
                    style: CoraTextStyles.bodyLarge.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: c.text,
                    ),
                    decoration: InputDecoration(
                      hintText: ChatTexts.composerHint,
                      hintStyle: CoraTextStyles.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                enabled: !_tooLong,
                label: ChatTexts.sendLabel,
                onTap: _tooLong ? null : _send,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: _tooLong ? null : _send,
                    child: Opacity(
                      opacity: _tooLong ? 0.4 : 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 38,
                          child: Center(
                            child: ChatGlyphIcon(
                              ChatGlyph.arrow,
                              size: 16,
                              color: c.onAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 입력란 자리에 놓이는 안내(캔버스에 없는 모양): 입력란과 같은 알약에 14px 글을 가운데로.
class _ClosedBar extends StatelessWidget {
  const _ClosedBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: text,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 글 끝에 이어 붙은 누르는 글자(NStoreLink의 `직접 입력`, NStoreAI의 `다시 만들기`).
///
/// 캔버스에서는 문장 안의 `<a>`·`<button>`이라 글과 함께 줄바꿈된다. 위젯을 끼우면 줄바꿈이
/// 달라지므로 같은 글 안의 한 구간으로 만들고 그 구간에만 누르기를 단다. [onTap]이 null이면 눌러도
/// 아무 일도 없고 글자만 남는다.
class InlineActionText extends StatefulWidget {
  const InlineActionText({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
    required this.style,
    required this.actionStyle,
  });

  /// 앞의 글. 누르는 글자 앞에 이어 붙는다.
  final String text;

  /// 누르는 글자.
  final String action;
  final VoidCallback? onTap;
  final TextStyle style;
  final TextStyle actionStyle;

  @override
  State<InlineActionText> createState() => _InlineActionTextState();
}

class _InlineActionTextState extends State<InlineActionText> {
  // 구간이 다시 만들어질 때마다 새로 만들면 새는 것이 생기므로 하나를 쓰고 끝에 정리한다.
  late final TapGestureRecognizer _tap = TapGestureRecognizer();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tap.onTap = widget.onTap;
    return Text.rich(
      TextSpan(
        text: widget.text,
        style: widget.style,
        children: [
          TextSpan(
            text: widget.action,
            style: widget.actionStyle,
            recognizer: widget.onTap == null ? null : _tap,
          ),
        ],
      ),
    );
  }
}

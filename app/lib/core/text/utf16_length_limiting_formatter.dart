import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

/// 글자 수를 UTF-16 단위(`String.length`)로 제한한다. Flutter의 `LengthLimitingTextInputFormatter`는
/// 글자 묶음(grapheme)으로 세지만, 서버는 `reason.length`처럼 UTF-16 단위로 세서 이모지가 섞이면
/// 앱이 받아 준 입력을 서버가 400으로 거절한다. 같은 단위로 세어 그 차이를 없앤다.
///
/// 넘치면 글자 묶음 경계에서 자른다(이모지의 서로게이트 짝이나 이어 붙은 이모지 가운데에서 자르지 않는다).
class Utf16LengthLimitingFormatter extends TextInputFormatter {
  const Utf16LengthLimitingFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxLength) return newValue;
    final kept = StringBuffer();
    var used = 0;
    for (final grapheme in newValue.text.characters) {
      if (used + grapheme.length > maxLength) break;
      kept.write(grapheme);
      used += grapheme.length;
    }
    return TextEditingValue(
      text: kept.toString(),
      selection: TextSelection.collapsed(offset: used),
    );
  }
}

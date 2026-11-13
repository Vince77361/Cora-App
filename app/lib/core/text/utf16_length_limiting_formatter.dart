import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

/// 글자 수를 UTF-16 단위(`String.length`)로 제한한다. Flutter의 `LengthLimitingTextInputFormatter`는
/// 글자 묶음(grapheme)으로 세지만, 서버는 `reason.length`처럼 UTF-16 단위로 세서 이모지가 섞이면
/// 앱이 받아 준 입력을 서버가 400으로 거절한다. 같은 단위로 세어 그 차이를 없앤다.
///
/// 넘치면 방금 넣은 글만 글자 묶음 경계에서 줄인다(이모지의 서로게이트 짝이나 이어 붙은 이모지
/// 가운데에서 자르지 않는다). 커서 뒤의 글과 앞의 옛 글은 그대로 두므로, 가득 찬 글의 가운데에
/// 한 글자를 넣으면 넣은 글자만 받아 주지 않고(옛 값과 커서 유지) 끝 글자를 지우지 않는다.
class Utf16LengthLimitingFormatter extends TextInputFormatter {
  const Utf16LengthLimitingFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length <= maxLength) return newValue;
    final caret = newValue.selection.isCollapsed
        ? newValue.selection.baseOffset
        : -1;
    final after = caret < 0 || caret > text.length
        ? null
        : text.substring(caret);
    // 방금 넣은 글을 가려낼 수 있는 때(커서 뒤가 옛 글의 끝과 같을 때)만 그 글을 줄인다.
    // 아니면 앞에서부터 남긴다.
    if (after == null || !oldValue.text.endsWith(after)) {
      final kept = _prefixWithin(text, maxLength);
      return TextEditingValue(
        text: kept,
        selection: TextSelection.collapsed(offset: kept.length),
      );
    }
    final oldHead = oldValue.text.substring(
      0,
      oldValue.text.length - after.length,
    );
    var keep = 0;
    while (keep < oldHead.length &&
        keep < caret &&
        oldHead.codeUnitAt(keep) == text.codeUnitAt(keep)) {
      keep++;
    }
    // 서로게이트 짝 가운데에서 가르지 않는다.
    if (keep > 0 && _isHighSurrogate(text.codeUnitAt(keep - 1))) keep--;
    final room = maxLength - keep - after.length;
    // 옛 글이 이미 한도를 넘어 있으면(불러온 값 등) 더 늘리지 않는다.
    if (room < 0) return oldValue;
    final inserted = _prefixWithin(text.substring(keep, caret), room);
    return TextEditingValue(
      text: text.substring(0, keep) + inserted + after,
      selection: TextSelection.collapsed(offset: keep + inserted.length),
    );
  }

  /// [text]의 앞쪽을 글자 묶음 경계에서 UTF-16 [limit] 단위 안으로 남긴다.
  static String _prefixWithin(String text, int limit) {
    final kept = StringBuffer();
    var used = 0;
    for (final grapheme in text.characters) {
      if (used + grapheme.length > limit) break;
      kept.write(grapheme);
      used += grapheme.length;
    }
    return kept.toString();
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
}

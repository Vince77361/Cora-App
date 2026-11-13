import 'package:cora/core/text/utf16_length_limiting_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _typed(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  const empty = TextEditingValue.empty;

  test('leaves text alone while it fits in the UTF-16 length', () {
    final formatter = Utf16LengthLimitingFormatter(200);
    final value = _typed('가' * 200);
    expect(formatter.formatEditUpdate(empty, value), value);
  });

  test('counts an emoji as two units like the server does', () {
    final formatter = Utf16LengthLimitingFormatter(200);
    final out = formatter.formatEditUpdate(empty, _typed('😀' * 101));
    expect(out.text, '😀' * 100);
    expect(out.text.length, 200);
    expect(out.selection, const TextSelection.collapsed(offset: 200));
  });

  test('never cuts an emoji in the middle of its surrogate pair', () {
    final formatter = Utf16LengthLimitingFormatter(200);
    final out = formatter.formatEditUpdate(empty, _typed('a' * 199 + '😀'));
    expect(out.text, 'a' * 199);
  });

  test('keeps a joined emoji sequence whole or drops it', () {
    final formatter = Utf16LengthLimitingFormatter(10);
    const family = '👨‍👩‍👧'; // 8 units
    final out = formatter.formatEditUpdate(empty, _typed('$family$family'));
    expect(out.text, family);
  });
}

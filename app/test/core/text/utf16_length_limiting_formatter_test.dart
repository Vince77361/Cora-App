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

  /// [before]|[after] 가운데에서 [typed]를 넣은 값(커서는 넣은 글 바로 뒤)을 만든다.
  (TextEditingValue, TextEditingValue) insertAt(
    String before,
    String after,
    String typed,
  ) => (
    TextEditingValue(
      text: before + after,
      selection: TextSelection.collapsed(offset: before.length),
    ),
    TextEditingValue(
      text: before + typed + after,
      selection: TextSelection.collapsed(offset: before.length + typed.length),
    ),
  );

  test('refuses a character typed in the middle of a full text', () {
    final formatter = Utf16LengthLimitingFormatter(200);
    final (old, typed) = insertAt('가' * 100, '나' * 100, '다');
    final out = formatter.formatEditUpdate(old, typed);
    // 끝 글자를 지우지 않고 옛 값과 커서를 그대로 둔다.
    expect(out.text, old.text);
    expect(out.selection, const TextSelection.collapsed(offset: 100));
  });

  test('refuses an emoji typed in the middle of a full text', () {
    final formatter = Utf16LengthLimitingFormatter(200);
    final (old, typed) = insertAt('가' * 50, '나' * 150, '😀');
    final out = formatter.formatEditUpdate(old, typed);
    expect(out.text, old.text);
    expect(out.selection, const TextSelection.collapsed(offset: 50));
  });

  test('keeps only what fits of a paste in the middle and keeps the rest', () {
    final formatter = Utf16LengthLimitingFormatter(200);
    final (old, typed) = insertAt('가' * 100, '나' * 98, '다라마바사');
    final out = formatter.formatEditUpdate(old, typed);
    expect(out.text, '${'가' * 100}다라${'나' * 98}');
    expect(out.text.length, 200);
    // 커서는 받아들인 글 바로 뒤다.
    expect(out.selection, const TextSelection.collapsed(offset: 102));
  });

  test('does not split an emoji pasted in the middle', () {
    final formatter = Utf16LengthLimitingFormatter(10);
    final (old, typed) = insertAt('abcd', 'efgh', '😀😀');
    final out = formatter.formatEditUpdate(old, typed);
    expect(out.text, 'abcd😀efgh');
    expect(out.selection, const TextSelection.collapsed(offset: 6));
  });

  test('replacing a selection never gets refused for being too long', () {
    final formatter = Utf16LengthLimitingFormatter(10);
    final old = TextEditingValue(
      text: 'a' * 10,
      selection: const TextSelection(baseOffset: 2, extentOffset: 6),
    );
    final replaced = TextEditingValue(
      text: '${'a' * 2}b${'a' * 4}',
      selection: const TextSelection.collapsed(offset: 3),
    );
    expect(formatter.formatEditUpdate(old, replaced), replaced);
  });

  test('cuts from the front when the caret is unknown', () {
    final formatter = Utf16LengthLimitingFormatter(5);
    final out = formatter.formatEditUpdate(
      empty,
      const TextEditingValue(text: 'abcdefg'),
    );
    expect(out.text, 'abcde');
    expect(out.selection, const TextSelection.collapsed(offset: 5));
  });
}

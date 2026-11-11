/// 받침에 따라 갈리는 조사 짝. 서버의 `api/src/notifications/josa.ts`와 같은 네 쌍이다.
enum JosaPair {
  iGa('이', '가'),
  gwaWa('과', '와'),
  eulReul('을', '를'),
  eunNeun('은', '는');

  const JosaPair(this.withFinal, this.withoutFinal);

  /// 받침이 있을 때와 없을 때의 조사.
  final String withFinal;
  final String withoutFinal;
}

// 숫자를 한글로 읽었을 때 마지막 글자에 받침이 있는지: 영·일·삼·육·칠·팔은 있고 이·사·오·구는 없다.
const _digitHasFinal = {
  '0': true,
  '1': true,
  '2': false,
  '3': true,
  '4': false,
  '5': false,
  '6': true,
  '7': true,
  '8': true,
  '9': false,
};

/// 받침이 있으면 true, 없으면 false, 한글도 숫자도 아니면 null.
bool? _hasFinalConsonant(String word) {
  final trimmed = word.trimRight();
  if (trimmed.isEmpty) return null;
  // 한글 음절과 숫자는 모두 UTF-16 한 칸이라 마지막 코드 단위만 보면 된다.
  final code = trimmed.codeUnitAt(trimmed.length - 1);
  if (code >= 0xAC00 && code <= 0xD7A3) return (code - 0xAC00) % 28 != 0;
  return _digitHasFinal[String.fromCharCode(code)];
}

/// [word] 뒤에 받침에 맞는 조사만 돌려준다(`하루 한 컵` → `이`). 서버 josa와 같은 규칙이다:
/// 마지막 글자가 한글이면 받침으로, 숫자면 읽는 소리의 받침으로 정하고, 판단할 수 없는
/// 글자(영문 등)면 `이(가)`처럼 둘 다 쓴다.
///
/// 서버의 `josa`는 단어까지 붙여 돌려주지만, 화면은 단어와 조사를 다른 글자 모양으로
/// 쓸 수 있어서 조사만 따로 돌려주는 [josaOf]도 둔다.
String josaOf(String word, JosaPair pair) {
  final hasFinal = _hasFinalConsonant(word);
  if (hasFinal == null) return '${pair.withFinal}(${pair.withoutFinal})';
  return hasFinal ? pair.withFinal : pair.withoutFinal;
}

/// [word] 뒤에 받침에 맞는 조사를 붙인다(`하루 한 컵` → `하루 한 컵이`).
String josa(String word, JosaPair pair) => '$word${josaOf(word, pair)}';

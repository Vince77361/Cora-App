import 'dart:math';

/// 무작위 UUID v4(`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`). 메시지를 보낼 때 앱이 만드는 중복 방지 값
/// (`clientId`)에 쓴다. 같은 값으로 다시 보내도 서버가 새 메시지를 만들지 않으므로, 추측할 수 없을
/// 필요는 없지만 서로 겹치지 않아야 해서 `Random.secure`를 쓴다. 패키지를 들이지 않으려고 직접 만든다.
String uuidV4([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  // 버전 4, 변형 10xx(RFC 4122).
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10, 16).join()}';
}

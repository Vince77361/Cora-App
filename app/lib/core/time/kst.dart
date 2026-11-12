/// 한국 표준시(UTC+9, 서머타임 없음). 날짜 표시는 휴대폰의 시간대가 아니라 이 시간으로 센다
/// (지급일 수요일 10:00 KST가 해외 기기에서 화요일로 보이지 않게).
const _kstOffset = Duration(hours: 9);

/// [at]을 한국 시간으로 옮긴 값. 반환값은 UTC 표시지만 연·월·일·시 칸이 한국 시계 값이다.
DateTime toKst(DateTime at) => at.toUtc().add(_kstOffset);

/// `11월 18일`(한국 시간 기준).
String kstMonthDay(DateTime at) {
  final kst = toKst(at);
  return '${kst.month}월 ${kst.day}일';
}

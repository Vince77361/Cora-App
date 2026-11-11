/// 로그인·휴대폰 인증 화면이 캔버스에 없는 상태에서 보여 주는 문구.
abstract final class AuthMessages {
  /// 인증번호가 틀렸을 때. E2의 남은 시간 줄 자리에 잠깐 보인다.
  static const wrongCode = '인증번호가 맞지 않아요.';

  /// 네트워크 등 그 밖의 실패. E1은 약관 줄 자리에, E2는 남은 시간 줄 자리에 보인다.
  static const tryLater = '잠시 후 다시 시도해 주세요.';

  /// 실패 안내를 보여 주는 시간. 지나면 원래 문구(E1은 약관, E2는 남은 시간)로 돌아간다.
  static const noticeDuration = Duration(seconds: 3);
}

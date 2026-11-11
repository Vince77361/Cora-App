import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, GoTrueClient;

import '../domain/auth_repository.dart';
import 'sign_in_adapter.dart';

/// 개발용 계정 하나로 로그인한다. (이메일, 비밀번호)를 받아 Supabase에 이메일 로그인하고,
/// 계정이 없으면 만들어서 로그인한다.
typedef DevAccountSignIn =
    Future<void> Function({required String email, required String password});

/// 가짜 로그인 어댑터. 앱이 가짜인지 모르게 같은 화면 뒤에서 개발용 계정으로 로그인시킨다.
///
/// - 인증번호 요청은 아무것도 보내지 않는다.
/// - 인증번호는 고정값 [devCode]만 통과한다.
/// - 휴대폰 번호는 개발 대역 010-0000-XXXX만 받는다. 다른 번호는 번호 형식 실패
///   (`AuthFailure.unknown('invalid_phone')`)로 돌려보내고, 화면에는 기존 실패 문구
///   `잠시 후 다시 시도해 주세요.`가 보인다.
/// - 휴대폰 번호마다, 그리고 카카오·네이버마다 고정된 개발용 계정(이메일)으로 로그인한다.
///
/// **개발용 Supabase 프로젝트에서만 쓴다.** 비밀번호는 번호(또는 `kakao`·`naver`)로 정해지는
/// 값이라 비밀이 아니다. 운영에서 이 어댑터가 선택되면 앱이 시작을 거부한다
/// (`assertAuthAdapterStartable`). 실제 로그인(휴대폰 OTP·카카오·네이버)은 9번 계획의
/// 다른 어댑터가 맡는다.
class FakeSignInAdapter implements SignInAdapter {
  FakeSignInAdapter({required DevAccountSignIn signInDevAccount})
    : _signIn = signInDevAccount;

  /// Supabase 이메일 로그인으로 개발용 계정에 들어가는 어댑터.
  FakeSignInAdapter.supabase(GoTrueClient auth)
    : _signIn = (({required email, required password}) =>
          _signInOrCreate(auth, email: email, password: password));

  final DevAccountSignIn _signIn;

  /// 가짜 인증이 받아 주는 유일한 인증번호.
  static const devCode = '000000';

  /// 개발용 계정 이메일의 도메인. 실제로 메일이 가지 않는 예약 도메인이어야 한다.
  static const devEmailDomain = 'example.com';

  // 개발 전용 상수. 계정마다 달라지게 키(번호 등)를 붙인다. 비밀이 아니다.
  static const _devPasswordBase = 'cora-dev-only';

  // 개발 전용 번호 대역 010-0000-XXXX만 받는다. 아무 번호나 받으면 실제 사람의 번호로
  // 개발 Supabase에 계정이 만들어진다(시드 계정 010-0000-0001/2/3도 이 대역이다).
  static final _phonePattern = RegExp(r'^0100000\d{4}$');

  @override
  Future<void> requestPhoneCode(String phoneDigits) async {
    // 일부러 아무것도 보내지 않는다. 실제 문자 발송은 9번 계획의 실제 어댑터가 한다.
  }

  @override
  Future<void> verifyPhoneCode({
    required String phoneDigits,
    required String code,
  }) async {
    if (code != devCode) throw const AuthFailure.invalidCode();
    if (!_phonePattern.hasMatch(phoneDigits)) {
      throw const AuthFailure.unknown('invalid_phone');
    }
    await _signInAs('phone-$phoneDigits');
  }

  @override
  Future<void> signInWithKakao() => _signInAs('kakao');

  @override
  Future<void> signInWithNaver() => _signInAs('naver');

  Future<void> _signInAs(String key) => _signIn(
    email: '$key@$devEmailDomain',
    password: '$_devPasswordBase-$key',
  );

  static Future<void> _signInOrCreate(
    GoTrueClient auth, {
    required String email,
    required String password,
  }) async {
    try {
      await auth.signInWithPassword(email: email, password: password);
      return;
    } on AuthException catch (error) {
      // 계정이 아직 없으면 이 오류가 온다. 그 밖의 오류는 그대로 올려 보낸다.
      if (error.code != 'invalid_credentials') rethrow;
    }
    final response = await auth.signUp(email: email, password: password);
    // 이메일 인증이 켜진 프로젝트면 세션 없이 돌아온다. 개발용 프로젝트는 꺼 두어야 한다.
    if (response.session == null) {
      throw const AuthFailure.unknown('session_missing_after_sign_up');
    }
  }
}

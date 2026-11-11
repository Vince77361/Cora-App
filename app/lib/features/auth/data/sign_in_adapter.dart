/// "어떻게 로그인하는가"만 맡는 어댑터. 세션을 지키고 갱신하고 지우는 일은
/// `SupabaseAuthRepository`가 하고, 이 어댑터는 로그인 한 번이 성공하면 Supabase에
/// 세션이 생기게 하는 데까지만 책임진다.
///
/// 지금은 가짜 구현(`FakeSignInAdapter`)뿐이고, 실제 구현(Supabase 휴대폰 OTP·카카오·네이버)은
/// 9번 계획에서 같은 자리에 들어온다. 화면과 저장소는 어느 쪽인지 모른다.
///
/// 실패는 `AuthFailure`로 던져도 되고, SDK 오류를 그대로 던져도 저장소가 `AuthFailure`로
/// 바꾼다.
abstract class SignInAdapter {
  Future<void> requestPhoneCode(String phoneDigits);

  Future<void> verifyPhoneCode({
    required String phoneDigits,
    required String code,
  });

  Future<void> signInWithKakao();

  Future<void> signInWithNaver();
}

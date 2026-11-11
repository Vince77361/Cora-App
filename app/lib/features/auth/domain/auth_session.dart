/// 로그인한 사용자의 세션. API 요청에 붙일 토큰을 담는다. 불변 값이다.
class AuthSession {
  const AuthSession({required this.userId, required this.accessToken});

  /// Supabase Auth의 사용자 ID(토큰의 `sub`).
  final String userId;

  /// API 요청의 `Authorization: Bearer`에 붙이는 토큰. 갱신되면 값이 바뀐다.
  final String accessToken;

  // 토큰 갱신도 세션이 바뀐 것으로 본다. 그래야 갱신된 토큰이 구독자에게 전달된다.
  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.accessToken == accessToken;

  @override
  int get hashCode => Object.hash(userId, accessToken);

  // 로그나 오류 문구에 토큰이 새지 않게 토큰은 빼고 보여 준다.
  @override
  String toString() => 'AuthSession(userId: $userId)';
}

import 'dart:async';

import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:cora/features/auth/domain/auth_session.dart';

/// 손으로 쓴 가짜 인증 저장소. 세션을 직접 바꾸고 로그인의 성공과 실패를 정한다.
class FakeAuthRepository implements AuthRepository {
  /// [session]을 주면 이미 로그인된 상태로 시작한다(저장된 세션으로 다시 켠 앱).
  FakeAuthRepository({this._session});

  static const signedInSession = AuthSession(
    userId: 'user-1',
    accessToken: 'token-1',
  );

  /// [verifyPhoneCode]가 받아 주는 인증번호. 다른 값은 `AuthFailure.invalidCode`.
  static const acceptedCode = '000000';

  final _changes = StreamController<AuthSession?>.broadcast();
  AuthSession? _session;

  /// 로그인이 성공했을 때 생기는 세션.
  AuthSession sessionAfterSignIn = signedInSession;

  /// null이 아니면 다음 인증번호 확인·카카오·네이버 로그인이 이 오류를 던진다.
  Object? signInError;

  /// null이 아니면 다음 인증번호 요청이 이 오류를 던진다.
  Object? requestCodeError;

  /// 설정하면 로그인(인증번호 확인 포함)이 이 Completer가 끝날 때까지 기다린다(진행 중 상태 확인용).
  Completer<void>? holdSignIn;

  /// 설정하면 인증번호 요청이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdRequest;

  /// true이면 지금 세션의 액세스 토큰이 만료된 것이다. [validAccessToken]이 갱신을 기다린 뒤
  /// [sessionAfterRefresh]로 바꾸고 false로 돌린다(저장된 세션으로 켠 직후 흉내).
  bool expired = false;

  /// 갱신이 끝난 뒤의 세션.
  AuthSession sessionAfterRefresh = const AuthSession(
    userId: 'user-1',
    accessToken: 'token-refreshed',
  );

  /// 실제로 갱신이 시작된 횟수. 동시에 부른 갱신은 SDK처럼 하나로 합쳐진다.
  int refreshCalls = 0;

  Future<void>? _refreshing;

  /// 인증번호를 요청한 번호(요청 순서대로).
  final phoneCodeRequests = <String>[];

  /// 인증번호 확인을 시도한 (번호, 인증번호).
  final verifyAttempts = <(String, String)>[];
  int kakaoCalls = 0;
  int naverCalls = 0;
  int signOutCalls = 0;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<String?> validAccessToken() async {
    if (expired) {
      if (_refreshing == null) {
        refreshCalls++;
        _refreshing = _refresh();
      }
      await _refreshing;
    }
    return _session?.accessToken;
  }

  Future<void> _refresh() async {
    // 갱신이 한 박자 걸리는 동안 다른 요청이 끼어들 수 있게 일부러 늦춘다.
    await Future<void>.delayed(Duration.zero);
    expired = false;
    _refreshing = null;
    if (_session != null) setSession(sessionAfterRefresh);
  }

  @override
  Stream<AuthSession?> watchSession() => Stream.multi((controller) {
    controller.add(_session);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  /// 세션을 바꾸고 구독자에게 알린다(토큰 갱신, 다른 계정 로그인 흉내).
  void setSession(AuthSession? session) {
    _session = session;
    _changes.add(session);
  }

  /// 서버나 다른 기기에서 세션이 끝난 것처럼 만든다.
  void endSession() => setSession(null);

  @override
  Future<void> requestPhoneCode(String phoneDigits) async {
    phoneCodeRequests.add(phoneDigits);
    final hold = holdRequest;
    if (hold != null) await hold.future;
    final error = requestCodeError;
    if (error != null) throw error;
  }

  @override
  Future<void> verifyPhoneCode({
    required String phoneDigits,
    required String code,
  }) async {
    verifyAttempts.add((phoneDigits, code));
    await _complete(codeToCheck: code);
  }

  @override
  Future<void> signInWithKakao() async {
    kakaoCalls++;
    await _complete();
  }

  @override
  Future<void> signInWithNaver() async {
    naverCalls++;
    await _complete();
  }

  Future<void> _complete({String? codeToCheck}) async {
    final hold = holdSignIn;
    if (hold != null) await hold.future;
    if (codeToCheck != null && codeToCheck != acceptedCode) {
      throw const AuthFailure.invalidCode();
    }
    final error = signInError;
    if (error != null) throw error;
    setSession(sessionAfterSignIn);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    // 세션이 한 박자 늦게 사라져도 401 처리기가 로그아웃을 한 번만 부르는지 보려고 일부러 늦춘다.
    await Future<void>.value();
    setSession(null);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_repository_provider.dart';

/// E2를 떠나면(뒤로 가기) 입력과 타이머를 함께 버리도록 autoDispose로 둔다.
final phoneVerifyViewModelProvider =
    AsyncNotifierProvider.autoDispose<PhoneVerifyViewModel, PhoneVerifyState>(
      PhoneVerifyViewModel.new,
    );

/// 캔버스에 없는 안내. 남은 시간 줄 자리에 잠깐 보인다.
enum PhoneVerifyNotice { wrongCode, tryLater }

/// E2 화면의 상태. 불변이다.
@immutable
class PhoneVerifyState {
  const PhoneVerifyState({
    this.phone = '',
    this.sent = false,
    this.code = '',
    this.remaining = Duration.zero,
    this.busy = false,
    this.notice,
  });

  /// 하이픈 없는 휴대폰 번호(최대 11자리, 010으로 시작).
  final String phone;

  /// 인증번호를 보낸 뒤인지. 보낸 뒤에는 키패드가 인증번호 칸을 채운다.
  final bool sent;

  /// 입력한 인증번호(최대 6자리).
  final String code;

  /// 인증번호가 만료되기까지 남은 시간. 보내기 전에는 0.
  final Duration remaining;

  /// 인증번호를 요청하거나 확인하는 중. 이 동안 입력과 버튼이 꺼진다.
  final bool busy;

  final PhoneVerifyNotice? notice;

  static const phoneLength = 11;
  static const codeLength = 6;

  bool get phoneComplete => phone.length == phoneLength;
  bool get codeComplete => code.length == codeLength;

  PhoneVerifyState copyWith({
    String? phone,
    bool? sent,
    String? code,
    Duration? remaining,
    bool? busy,
    PhoneVerifyNotice? notice,
    bool clearNotice = false,
  }) {
    return PhoneVerifyState(
      phone: phone ?? this.phone,
      sent: sent ?? this.sent,
      code: code ?? this.code,
      remaining: remaining ?? this.remaining,
      busy: busy ?? this.busy,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

/// E2(휴대폰 인증)의 동작. 화면의 키패드 하나로 번호와 인증번호를 차례로 받는다.
///
/// 번호 11자리가 차면 자동으로 인증번호를 요청하고 3분 타이머를 시작한다. 인증번호 6자리가
/// 차면 `확인`으로 로그인한다. 성공하면 세션이 바뀌고 라우터가 화면을 옮기므로 여기서
/// 이동하지 않는다.
class PhoneVerifyViewModel extends AsyncNotifier<PhoneVerifyState> {
  /// 인증번호 유효 시간.
  static const codeLifetime = Duration(minutes: 3);

  /// 안내 문구를 보여 주는 시간.
  static const noticeDuration = Duration(seconds: 3);

  static const _prefix = '010';

  Timer? _ticker;
  Timer? _noticeTimer;
  DateTime? _expiresAt;

  @override
  FutureOr<PhoneVerifyState> build() {
    ref.onDispose(_cancelTimers);
    return const PhoneVerifyState();
  }

  PhoneVerifyState get _current => state.value ?? const PhoneVerifyState();

  void _emit(PhoneVerifyState next) => state = AsyncData(next);

  /// 키패드의 숫자 키.
  void pressDigit(String digit) {
    final s = _current;
    if (s.busy) return;
    if (!s.sent) {
      if (s.phone.length >= PhoneVerifyState.phoneLength) return;
      // 010으로 시작하는 번호만 받는다. 앞 세 자리가 어긋나는 키는 무시한다.
      if (s.phone.length < _prefix.length && digit != _prefix[s.phone.length]) {
        return;
      }
      final phone = s.phone + digit;
      _clearNotice();
      _emit(s.copyWith(phone: phone, clearNotice: true));
      if (phone.length == PhoneVerifyState.phoneLength) unawaited(_request());
    } else {
      if (s.code.length >= PhoneVerifyState.codeLength) return;
      _clearNotice();
      _emit(s.copyWith(code: s.code + digit, clearNotice: true));
    }
  }

  /// 키패드의 `←`. 보낸 뒤에는 인증번호를, 보내기 전에는 번호를 한 자리 지운다.
  void backspace() {
    final s = _current;
    if (s.busy) return;
    _clearNotice();
    if (s.sent) {
      if (s.code.isEmpty) return;
      _emit(
        s.copyWith(
          code: s.code.substring(0, s.code.length - 1),
          clearNotice: true,
        ),
      );
    } else {
      if (s.phone.isEmpty) return;
      _emit(
        s.copyWith(
          phone: s.phone.substring(0, s.phone.length - 1),
          clearNotice: true,
        ),
      );
    }
  }

  /// 휴대폰 번호 칸을 눌렀다. 보낸 상태와 인증번호를 비우고 번호를 고칠 수 있게 한다.
  void editPhone() {
    final s = _current;
    if (s.busy || !s.sent) return;
    _cancelTimers();
    _expiresAt = null;
    _emit(PhoneVerifyState(phone: s.phone));
  }

  /// `다시 보내기`. 번호가 다 찼을 때만 한다.
  Future<void> resend() async {
    final s = _current;
    if (s.busy || !s.phoneComplete) return;
    await _request();
  }

  Future<void> _request() async {
    final phone = _current.phone;
    _clearNotice();
    _emit(_current.copyWith(busy: true, clearNotice: true));
    try {
      await ref.read(authRepositoryProvider).requestPhoneCode(phone);
    } catch (_) {
      // 실패의 종류는 저장소가 디버그 로그로 남긴다. 번호나 인증번호는 어디에도 남기지 않는다.
      if (!ref.mounted) return;
      _emit(_current.copyWith(busy: false));
      _showNotice(PhoneVerifyNotice.tryLater);
      return;
    }
    if (!ref.mounted) return;
    _expiresAt = ref.read(clockProvider).now().add(codeLifetime);
    _emit(
      _current.copyWith(
        busy: false,
        sent: true,
        code: '',
        remaining: codeLifetime,
        clearNotice: true,
      ),
    );
    _startTicker();
  }

  /// `확인`. 인증번호 6자리가 찼을 때만 한다.
  Future<void> submit() async {
    final s = _current;
    if (s.busy || !s.sent || !s.codeComplete) return;
    _clearNotice();
    _emit(s.copyWith(busy: true, clearNotice: true));
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneCode(phoneDigits: s.phone, code: s.code);
      // 성공하면 라우터가 이 화면을 치워 이 ViewModel이 먼저 사라질 수 있다.
      if (ref.mounted) _emit(_current.copyWith(busy: false));
    } catch (error) {
      if (!ref.mounted) return;
      if (error is AuthFailure && error.kind == AuthFailureKind.invalidCode) {
        // 틀린 인증번호는 다시 쓸 수 없으므로 칸을 비운다.
        _emit(_current.copyWith(busy: false, code: ''));
        _showNotice(PhoneVerifyNotice.wrongCode);
      } else {
        // 네트워크 등은 입력을 그대로 두어 `확인`을 다시 누르면 된다.
        _emit(_current.copyWith(busy: false));
        _showNotice(PhoneVerifyNotice.tryLater);
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // 남은 시간은 매번 시계를 보고 다시 계산한다(타이머 호출이 밀려도 어긋나지 않는다).
  void _tick() {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return;
    final left = expiresAt.difference(ref.read(clockProvider).now());
    if (left <= Duration.zero) {
      _ticker?.cancel();
      _emit(_current.copyWith(remaining: Duration.zero));
    } else {
      _emit(_current.copyWith(remaining: left));
    }
  }

  void _showNotice(PhoneVerifyNotice notice) {
    _noticeTimer?.cancel();
    _emit(_current.copyWith(notice: notice));
    _noticeTimer = Timer(noticeDuration, () {
      if (ref.mounted) _emit(_current.copyWith(clearNotice: true));
    });
  }

  void _clearNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
  }

  void _cancelTimers() {
    _ticker?.cancel();
    _ticker = null;
    _noticeTimer?.cancel();
    _noticeTimer = null;
  }
}

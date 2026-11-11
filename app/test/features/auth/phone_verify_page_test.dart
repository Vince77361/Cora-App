import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/time/clock.dart';
import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:cora/features/auth/presentation/pages/login_page.dart';
import 'package:cora/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';
import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';

const _phone = '01012342841';
const _tryLater = '잠시 후 다시 시도해 주세요.';
const _wrongCode = '인증번호가 맞지 않아요.';
const _notReady = '6자리를 모두 넣어주세요';

late FakeAuthRepository _auth;
late FakeClock _clock;

/// E1에서 `휴대폰 번호로 시작하기`를 눌러 E2에 들어간다.
Future<void> _openVerify(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  void Function()? small,
}) async {
  _auth = auth ?? FakeAuthRepository();
  _clock = FakeClock();
  if (small != null) {
    small();
  } else {
    usePhone(tester);
  }
  await pumpCoraApp(
    tester,
    auth: _auth,
    overrides: [clockProvider.overrideWithValue(_clock)],
  );
  await tester.tap(find.text('휴대폰 번호로 시작하기'));
  await tester.pumpAndSettle();
  expect(find.byType(PhoneVerifyPage), findsOneWidget);
}

/// 접근성 이름이 [label]인 Semantics. 접근성 트리를 켜지 않고도 찾는다.
Finder _labeled(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

Finder _key(String label) => find.descendant(
  of: find.byKey(PhoneVerifyPage.keypadKey),
  matching: find.text(label),
);

Future<void> _press(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(_key(digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(_labeled('지우기'));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// 시계와 타이머를 함께 [by]만큼 보낸다.
Future<void> _elapse(WidgetTester tester, Duration by) async {
  _clock.advance(by);
  await tester.pump(by);
}

String _codeBoxes(WidgetTester tester) => [
  for (var i = 0; i < 6; i++)
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(PhoneVerifyPage.codeBoxKey(i)),
            matching: find.byType(Text),
          ),
        )
        .data!,
].join();

String _phoneValue(WidgetTester tester) => tester
    .widget<Text>(
      find
          .descendant(
            of: find.byKey(PhoneVerifyPage.phoneFieldKey),
            matching: find.byType(Text),
          )
          .last,
    )
    .data!;

/// 인증번호를 보낸 상태까지 간다.
Future<void> _sendCode(WidgetTester tester) async {
  await _press(tester, _phone);
  expect(_auth.phoneCodeRequests, [_phone]);
}

void main() {
  testWidgets('E2 starts empty with the canvas copy', (tester) async {
    await _openVerify(tester);

    expect(find.text('휴대폰 인증'), findsOneWidget);
    expect(find.text('문자로 받은\n인증번호를 넣어주세요.'), findsOneWidget);
    expect(find.text('휴대폰 번호'), findsOneWidget);
    expect(find.text(_notReady), findsOneWidget);
    expect(find.text('확인'), findsNothing);
    expect(find.text('다시 보내기'), findsOneWidget);
    // 보내기 전에는 설명 문구가 비어 있다.
    expect(find.textContaining('보냈어요'), findsNothing);
    expect(_codeBoxes(tester), '');
    // 키패드: 1~9, 0, 지우기.
    for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
      expect(_key(key), findsOneWidget, reason: key);
    }
    expect(_labeled('지우기'), findsOneWidget);
    expect(_labeled('뒤로'), findsOneWidget);
  });

  testWidgets('E2 lays out like the canvas at 390 x 844', (tester) async {
    await loadAppFonts();
    await _openVerify(tester, small: () => useCanvasPhone(tester));

    final title = tester.getRect(find.text('휴대폰 인증'));
    expect(title.center.dx, closeTo(195, 0.5));
    final back = tester.getRect(find.byKey(PhoneVerifyPage.backKey));
    expect(back, const Rect.fromLTWH(8, 10, 44, 44));
    final phone = tester.getRect(find.byKey(PhoneVerifyPage.phoneFieldKey));
    expect(phone.left, 16);
    expect(phone.right, 374);
    final boxes = [
      for (var i = 0; i < 6; i++)
        tester.getRect(find.byKey(PhoneVerifyPage.codeBoxKey(i))),
    ];
    for (final box in boxes) {
      expect(box.height, 60);
      expect(box.width, closeTo((358 - 5 * 8) / 6, 0.01));
    }
    expect(boxes[1].left - boxes[0].right, closeTo(8, 0.01));
    expect(boxes.first.top - phone.bottom, closeTo(10, 0.5));
    final keypad = tester.getRect(find.byKey(PhoneVerifyPage.keypadKey));
    expect(keypad.left, 16);
    expect(keypad.right, 374);
    expect(tester.getSize(_key('5')).height, lessThanOrEqualTo(50));
    // 키패드 아래 14, 버튼 58, 버튼 아래 32.
    final button = tester.getRect(find.text(_notReady));
    expect(button.bottom, lessThan(844 - 32));
    expect(844 - 32 - keypad.bottom, closeTo(58 + 14, 0.5));
  });

  testWidgets('typing 11 digits requests the code once and starts 3:00', (
    tester,
  ) async {
    await _openVerify(tester);

    await _press(tester, _phone.substring(0, 10));
    expect(_auth.phoneCodeRequests, isEmpty);
    expect(find.textContaining('보냈어요'), findsNothing);

    await _press(tester, _phone.substring(10));

    expect(_auth.phoneCodeRequests, [_phone]);
    expect(_phoneValue(tester), '010-1234-2841');
    expect(find.text('010-****-2841로 보냈어요.'), findsOneWidget);
    expect(find.text('남은 시간 3:00'), findsOneWidget);
    // 키패드는 이제 인증번호 칸을 채운다.
    await _press(tester, '12');
    expect(_codeBoxes(tester), '12');
    expect(_phoneValue(tester), '010-1234-2841');
    expect(_auth.phoneCodeRequests, hasLength(1));
  });

  testWidgets('the phone number must start with 010', (tester) async {
    await _openVerify(tester);

    await _press(tester, '5');
    expect(_phoneValue(tester), '');
    await _press(tester, '01');
    expect(_phoneValue(tester), '01');
    await _press(tester, '1');
    expect(_phoneValue(tester), '01');
    await _press(tester, '0');
    expect(_phoneValue(tester), '010');
  });

  testWidgets('a full code turns the disabled button into 확인', (tester) async {
    await _openVerify(tester);
    await _sendCode(tester);

    await _press(tester, '00000');
    expect(find.text(_notReady), findsOneWidget);
    expect(find.text('확인'), findsNothing);

    await _press(tester, '0');
    expect(find.text('확인'), findsOneWidget);
    expect(find.text(_notReady), findsNothing);
    // 6자리가 넘게는 들어가지 않는다.
    await _press(tester, '7');
    expect(_codeBoxes(tester), '000000');
  });

  testWidgets('the right code signs in and lands on /role', (tester) async {
    await _openVerify(tester);
    await _sendCode(tester);
    await _press(tester, FakeAuthRepository.acceptedCode);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(_auth.verifyAttempts, [(_phone, FakeAuthRepository.acceptedCode)]);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('a wrong code shows a message and clears the boxes', (
    tester,
  ) async {
    await _openVerify(tester);
    await _sendCode(tester);
    await _press(tester, '123456');

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneVerifyPage), findsOneWidget);
    expect(find.text(_wrongCode), findsOneWidget);
    expect(find.textContaining('남은 시간'), findsNothing);
    expect(_codeBoxes(tester), '');
    expect(find.text(_notReady), findsOneWidget);

    // 잠깐 보여 준 뒤 타이머 줄로 돌아온다.
    await _elapse(tester, const Duration(seconds: 4));
    expect(find.text(_wrongCode), findsNothing);
    expect(find.text('남은 시간 2:56'), findsOneWidget);
  });

  testWidgets('a network failure while verifying keeps the code', (
    tester,
  ) async {
    await _openVerify(tester);
    await _sendCode(tester);
    await _press(tester, FakeAuthRepository.acceptedCode);
    _auth.signInError = const AuthFailure.network();

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text(_tryLater), findsOneWidget);
    expect(_codeBoxes(tester), FakeAuthRepository.acceptedCode);

    _auth.signInError = null;
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('confirm is off while verifying', (tester) async {
    await _openVerify(tester);
    await _sendCode(tester);
    await _press(tester, FakeAuthRepository.acceptedCode);
    final hold = Completer<void>();
    _auth.holdSignIn = hold;

    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(_auth.verifyAttempts, hasLength(1));

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('a failed request keeps the number and 다시 보내기 retries', (
    tester,
  ) async {
    await _openVerify(tester);
    _auth.requestCodeError = const AuthFailure.network();

    await _press(tester, _phone);

    expect(_auth.phoneCodeRequests, [_phone]);
    expect(find.text(_tryLater), findsOneWidget);
    expect(find.textContaining('보냈어요'), findsNothing);
    expect(_phoneValue(tester), '010-1234-2841');

    _auth.requestCodeError = null;
    await tester.tap(find.text('다시 보내기'));
    await tester.pumpAndSettle();

    expect(_auth.phoneCodeRequests, [_phone, _phone]);
    expect(find.text(_tryLater), findsNothing);
    expect(find.text('010-****-2841로 보냈어요.'), findsOneWidget);
    expect(find.text('남은 시간 3:00'), findsOneWidget);
  });

  testWidgets('다시 보내기 requests again, resets 3:00 and clears the code', (
    tester,
  ) async {
    await _openVerify(tester);
    await _sendCode(tester);
    await _press(tester, '123');
    await _elapse(tester, const Duration(seconds: 59));
    expect(find.text('남은 시간 2:01'), findsOneWidget);

    await tester.tap(find.text('다시 보내기'));
    await tester.pumpAndSettle();

    expect(_auth.phoneCodeRequests, [_phone, _phone]);
    expect(find.text('남은 시간 3:00'), findsOneWidget);
    expect(_codeBoxes(tester), '');
  });

  testWidgets('the timer counts down with the clock and stops at 0:00', (
    tester,
  ) async {
    await _openVerify(tester);
    await _sendCode(tester);
    expect(find.text('남은 시간 3:00'), findsOneWidget);

    await _elapse(tester, const Duration(seconds: 1));
    expect(find.text('남은 시간 2:59'), findsOneWidget);
    await _elapse(tester, const Duration(seconds: 19));
    expect(find.text('남은 시간 2:40'), findsOneWidget);

    await _elapse(tester, const Duration(minutes: 5));
    expect(find.text('남은 시간 0:00'), findsOneWidget);
    await _elapse(tester, const Duration(seconds: 30));
    expect(find.text('남은 시간 0:00'), findsOneWidget);
  });

  testWidgets('the delete key removes the last code digit, then phone digits', (
    tester,
  ) async {
    await _openVerify(tester);

    await _press(tester, '0101');
    await _back(tester);
    expect(_phoneValue(tester), '010');
    await _back(tester, 5);
    expect(_phoneValue(tester), '');

    await _press(tester, _phone);
    await _press(tester, '1234');
    await _back(tester);
    expect(_codeBoxes(tester), '123');
    await _back(tester, 3);
    expect(_codeBoxes(tester), '');
    // 코드가 비어도 번호는 지워지지 않는다.
    await _back(tester);
    expect(_phoneValue(tester), '010-1234-2841');
  });

  testWidgets('tapping the phone field resets so the number can be fixed', (
    tester,
  ) async {
    await _openVerify(tester);
    await _sendCode(tester);
    await _press(tester, '123');

    await tester.tap(find.byKey(PhoneVerifyPage.phoneFieldKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('보냈어요'), findsNothing);
    expect(_codeBoxes(tester), '');
    expect(find.textContaining('남은 시간'), findsNothing);
    expect(_phoneValue(tester), '010-1234-2841');

    await _back(tester);
    await _press(tester, '9');

    expect(_auth.phoneCodeRequests, [_phone, '01012342849']);
    expect(find.text('010-****-2849로 보냈어요.'), findsOneWidget);
    expect(find.text('남은 시간 3:00'), findsOneWidget);
  });

  testWidgets('the back arrow returns to E1 and a new visit starts fresh', (
    tester,
  ) async {
    await _openVerify(tester);
    await _sendCode(tester);

    await tester.tap(find.byKey(PhoneVerifyPage.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(PhoneVerifyPage), findsNothing);

    await tester.tap(find.text('휴대폰 번호로 시작하기'));
    await tester.pumpAndSettle();
    expect(_phoneValue(tester), '');
    expect(find.textContaining('보냈어요'), findsNothing);
  });

  testWidgets('system back returns to E1', (tester) async {
    await _openVerify(tester);

    await systemBack(tester);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('E2 can be opened directly without a session', (tester) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    routerOf(tester).go(AppRoutes.loginVerify);
    await tester.pumpAndSettle();

    expect(find.byType(PhoneVerifyPage), findsOneWidget);
    // 뒤에 E1이 있어 뒤로 갈 수 있다.
    expect(routerOf(tester).canPop(), isTrue);
  });

  testWidgets('E2 does not overflow at 360 x 640 with 1.3x text', (
    tester,
  ) async {
    await _openVerify(tester, small: () => useSmallPhoneWithLargeText(tester));

    expect(tester.takeException(), isNull);
    await _sendCode(tester);
    await _press(tester, FakeAuthRepository.acceptedCode);
    expect(find.text('확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
    _auth.signInError = const AuthFailure.network();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text(_tryLater), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E2 uses the canvas light values', (tester) async {
    await _openVerify(tester);
    await _sendCode(tester);
    final c = CoraColors.light;

    expect(_boxFill(tester, PhoneVerifyPage.phoneFieldKey), c.surface);
    expect(_boxFill(tester, PhoneVerifyPage.codeBoxKey(3)), c.surface);
    expect(_boxFill(tester, PhoneVerifyPage.resendKey), c.subtleAction);
    // 지금 입력할 칸(첫 칸)만 안쪽 테두리 2.
    expect(_ring(tester, PhoneVerifyPage.codeBoxKey(0)), c.focusRing);
    expect(_ring(tester, PhoneVerifyPage.codeBoxKey(1)), isNull);
    await _press(tester, '1');
    expect(_ring(tester, PhoneVerifyPage.codeBoxKey(0)), isNull);
    expect(_ring(tester, PhoneVerifyPage.codeBoxKey(1)), c.focusRing);
  });

  testWidgets('E2 uses the canvas dark values', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _openVerify(tester);
    await _sendCode(tester);
    final c = CoraColors.dark;

    expect(tester.takeException(), isNull);
    expect(
      _boxFill(tester, PhoneVerifyPage.phoneFieldKey),
      const Color(0xFF1C1E22),
    );
    expect(_boxFill(tester, PhoneVerifyPage.codeBoxKey(3)), c.surface);
    expect(
      _boxFill(tester, PhoneVerifyPage.resendKey),
      const Color(0xFF2A2D33),
    );
    // 캔버스는 다크에서도 #17181C를 쓴다.
    expect(
      _ring(tester, PhoneVerifyPage.codeBoxKey(0)),
      const Color(0xFF17181C),
    );
    // 확인 버튼은 다크에서도 라임.
    await _press(tester, '123456');
    final confirm = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text('확인'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect((confirm.decoration as BoxDecoration).color, c.accent);
  });
}

Color? _boxFill(WidgetTester tester, Key key) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

/// 칸 안쪽 테두리 색. 테두리가 없으면 null.
Color? _ring(WidgetTester tester, Key key) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.border != null) {
      final side = (decoration.border! as Border).top;
      expect(side.width, 2);
      return side.color;
    }
  }
  return null;
}

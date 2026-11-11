import 'dart:async';

import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:cora/features/auth/presentation/pages/dev_login_page.dart';
import 'package:cora/features/auth/presentation/pages/login_unavailable_page.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import 'fake_auth_repository.dart';

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, '이메일'),
    'dev@example.com',
  );
  await tester.enterText(find.widgetWithText(TextField, '비밀번호'), 'secret1');
}

CoraPrimaryButton _loginButton(WidgetTester tester) =>
    tester.widget(find.widgetWithText(CoraPrimaryButton, '로그인'));

void main() {
  testWidgets('shows email and password fields and both actions', (
    tester,
  ) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(find.widgetWithText(TextField, '이메일'), findsOneWidget);
    expect(find.widgetWithText(TextField, '비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('개발용 계정 만들기'), findsOneWidget);
    expect(find.text('이메일이나 비밀번호를 확인해 주세요.'), findsNothing);
  });

  testWidgets('hides the password', (tester) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    final password = tester.widget<TextField>(
      find.widgetWithText(TextField, '비밀번호'),
    );
    expect(password.obscureText, isTrue);
  });

  testWidgets('shows the error copy when sign in fails', (tester) async {
    final auth = FakeAuthRepository()
      ..signInError = const AuthFailure('invalid_credentials');
    await pumpCoraApp(tester, auth: auth);
    await _fill(tester);

    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(find.text('이메일이나 비밀번호를 확인해 주세요.'), findsOneWidget);
    // SDK의 원문 오류는 화면에 보이지 않는다.
    expect(find.textContaining('invalid_credentials'), findsNothing);
    expect(find.byType(DevLoginPage), findsOneWidget);
  });

  testWidgets('shows the same error copy when creating the account fails', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signInError = const AuthFailure('user_already_exists');
    await pumpCoraApp(tester, auth: auth);
    await _fill(tester);

    await tester.tap(find.text('개발용 계정 만들기'));
    await tester.pumpAndSettle();

    expect(auth.signUpCalls, 1);
    expect(find.text('이메일이나 비밀번호를 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('creating a dev account lands on /role', (tester) async {
    final auth = FakeAuthRepository();
    await pumpCoraApp(tester, auth: auth);
    await _fill(tester);

    await tester.tap(find.text('개발용 계정 만들기'));
    await tester.pumpAndSettle();

    expect(auth.signUpCalls, 1);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('disables the buttons while submitting', (tester) async {
    final auth = FakeAuthRepository()..holdSignIn = Completer<void>();
    await pumpCoraApp(tester, auth: auth);
    await _fill(tester);

    await tester.tap(find.text('로그인'));
    await tester.pump();

    expect(_loginButton(tester).onPressed, isNull);
    await tester.tap(find.text('로그인'));
    await tester.tap(find.text('개발용 계정 만들기'));
    await tester.pump();
    expect(auth.signInCalls, 1);
    expect(auth.signUpCalls, 0);

    auth.holdSignIn!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('submitting the password field signs in', (tester) async {
    final auth = FakeAuthRepository();
    await pumpCoraApp(tester, auth: auth);
    await _fill(tester);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
  });

  testWidgets('lays out at 1.3x text on a 360x640 phone', (tester) async {
    useSmallPhoneWithLargeText(tester);
    final auth = FakeAuthRepository()
      ..signInError = const AuthFailure('invalid_credentials');
    await pumpCoraApp(tester, auth: auth);
    await _fill(tester);
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('이메일이나 비밀번호를 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('stays scrollable with the keyboard open at 1.3x text', (
    tester,
  ) async {
    useSmallPhoneWithLargeText(tester);
    // 화면 아래 300을 키보드가 가린다.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('개발용 계정 만들기'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('개발용 계정 만들기'), findsOneWidget);
  });

  testWidgets('renders in the dark theme without errors', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    final context = tester.element(find.byType(DevLoginPage));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prod login copy lays out at 1.3x text on a 360x640 phone', (
    tester,
  ) async {
    useSmallPhoneWithLargeText(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository(), env: CoraEnv.prod);

    expect(find.byType(LoginUnavailablePage), findsOneWidget);
    expect(find.text(LoginUnavailablePage.message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_logo.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:cora/features/auth/presentation/pages/login_page.dart';
import 'package:cora/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:cora/features/dev/presentation/pages/motion_gallery_page.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';

const _tryLater = '잠시 후 다시 시도해 주세요.';
const _terms = '계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요.';

Color? _fillOf(WidgetTester tester, Finder of) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)).first,
  );
  return (box.decoration as BoxDecoration).color;
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  CoraEnv env = CoraEnv.dev,
}) async {
  usePhone(tester);
  await pumpCoraApp(tester, auth: auth ?? FakeAuthRepository(), env: env);
}

void main() {
  testWidgets('E1 shows the photo, title, three buttons and the terms line', (
    tester,
  ) async {
    await _pumpLogin(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.login);
    expect(find.text('#민의옷장기록 · 릴스 0:30'), findsOneWidget);
    expect(find.text('팔로워 수보다 콘텐츠로 만나요.'), findsOneWidget);
    expect(find.text('cora'), findsOneWidget);
    expect(find.text('브랜드와 크리에이터가\n콘텐츠로 만나는 곳'), findsOneWidget);
    expect(find.text('휴대폰 번호로 시작하기'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('네이버로 계속하기'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text(_terms, findRichText: true), findsOneWidget);
    // 이메일 로그인은 없다.
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('이메일'), findsNothing);
  });

  testWidgets('E1 lays out like the canvas at 390 x 844', (tester) async {
    await loadAppFonts();
    useCanvasPhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    // 사진 상자: 좌우·위 12, 높이 420.
    final photo = tester.getRect(find.byKey(LoginPage.photoKey));
    expect(photo, const Rect.fromLTWH(12, 12, 366, 420));
    // 로고와 제목 블록은 사진 아래 28(캔버스 top 460), 좌우 24.
    final logo = tester.getRect(find.byType(CoraLogo));
    expect(logo.left, 24);
    expect(logo.top, 460);
    // 아래 버튼: 좌우 16, 높이 58·56·56, 간격 8, 맨 아래가 화면 아래에서 32.
    final phone = tester.getRect(find.byType(CoraPrimaryButton));
    final kakao = tester.getRect(find.byKey(LoginPage.kakaoKey));
    final naver = tester.getRect(find.byKey(LoginPage.naverKey));
    expect([phone.left, phone.right], [16, 374]);
    expect(phone.height, 58);
    expect(kakao.height, 56);
    expect(naver.height, 56);
    expect(kakao.top - phone.bottom, 8);
    expect(naver.top - kakao.bottom, 8);
    final terms = tester.getRect(find.text(_terms, findRichText: true));
    expect(terms.bottom, closeTo(844 - 32, 0.5));
    expect(terms.top - naver.bottom, closeTo(6, 0.5));
  });

  testWidgets('the photo box shrinks on a short screen but stays under 420', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920); // 360 x 640
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    final photo = tester.getRect(find.byKey(LoginPage.photoKey));
    expect(photo.height, lessThan(420));
    expect(photo.height, greaterThan(100));
    expect(photo.left, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E1 uses the canvas light values', (tester) async {
    await _pumpLogin(tester);
    final c = CoraColors.light;

    expect(_fillOf(tester, find.byType(CoraPrimaryButton)), c.accent);
    expect(_fillOf(tester, find.byKey(LoginPage.kakaoKey)), c.surface);
    expect(_fillOf(tester, find.byKey(LoginPage.naverKey)), c.surface);
    expect(_fillOf(tester, find.byKey(LoginPage.photoKey)), c.photoPlaceholder);
    final chip = find.ancestor(
      of: find.text('#민의옷장기록 · 릴스 0:30'),
      matching: find.byType(DecoratedBox),
    );
    expect(
      (tester.widget<DecoratedBox>(chip.first).decoration as BoxDecoration)
          .color,
      c.photoChip,
    );
  });

  testWidgets('E1 uses the canvas dark values', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpLogin(tester);
    final c = CoraColors.dark;

    expect(tester.takeException(), isNull);
    // 주 버튼은 다크에서도 라임(#C6FF3D), 소셜 버튼은 #1C1E22.
    expect(_fillOf(tester, find.byType(CoraPrimaryButton)), c.accent);
    expect(
      _fillOf(tester, find.byKey(LoginPage.kakaoKey)),
      const Color(0xFF1C1E22),
    );
    expect(_fillOf(tester, find.byKey(LoginPage.naverKey)), c.surface);
    // 소셜 버튼의 동그라미는 다크 바탕(#0F1012).
    final circle = find.ancestor(
      of: find.text('K'),
      matching: find.byType(DecoratedBox),
    );
    expect(
      (tester.widget<DecoratedBox>(circle.first).decoration as BoxDecoration)
          .color,
      const Color(0xFF0F1012),
    );
    // 사진 상자와 알약은 다크에서도 같다.
    expect(
      _fillOf(tester, find.byKey(LoginPage.photoKey)),
      const Color(0xFFE8DDCB),
    );
  });

  testWidgets('the terms links are underlined and do nothing yet', (
    tester,
  ) async {
    await _pumpLogin(tester);

    final terms = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(LoginPage.termsKey),
        matching: find.byType(RichText),
      ),
    );
    final links = <String, TextDecoration?>{};
    terms.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        links[span.text!] = span.style?.decoration;
      }
      return true;
    });
    expect(links['이용약관'], TextDecoration.underline);
    expect(links['개인정보 처리방침'], TextDecoration.underline);

    // 눌러도 이동하지 않는다(E8 고객센터가 생기면 연결).
    await tester.tapAt(
      tester.getTopLeft(find.byKey(LoginPage.termsKey)) + const Offset(60, 8),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('the phone button opens E2 and back returns to E1', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('휴대폰 번호로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneVerifyPage), findsOneWidget);
    expect(find.text('휴대폰 인증'), findsOneWidget);

    await tester.tap(find.byKey(PhoneVerifyPage.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneVerifyPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('kakao signs in and lands on /role', (tester) async {
    final auth = FakeAuthRepository();
    await _pumpLogin(tester, auth: auth);

    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();

    expect(auth.kakaoCalls, 1);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('naver signs in and lands on /role', (tester) async {
    final auth = FakeAuthRepository();
    await _pumpLogin(tester, auth: auth);

    await tester.tap(find.text('네이버로 계속하기'));
    await tester.pumpAndSettle();

    expect(auth.naverCalls, 1);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('all three buttons are off while signing in', (tester) async {
    final hold = Completer<void>();
    final auth = FakeAuthRepository()..holdSignIn = hold;
    await _pumpLogin(tester, auth: auth);

    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pump();
    await tester.tap(find.text('카카오로 계속하기'));
    await tester.tap(find.text('네이버로 계속하기'));
    await tester.tap(find.text('휴대폰 번호로 시작하기'));
    await tester.pumpAndSettle();

    expect(auth.kakaoCalls, 1);
    expect(auth.naverCalls, 0);
    expect(find.byType(PhoneVerifyPage), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('a failed sign in shows a retry message and re-enables', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signInError = const AuthFailure.network();
    await _pumpLogin(tester, auth: auth);

    await tester.tap(find.text('네이버로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.text(_tryLater), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);

    auth.signInError = null;
    await tester.tap(find.text('네이버로 계속하기'));
    await tester.pumpAndSettle();

    expect(auth.naverCalls, 2);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('long pressing the logo opens the gallery in dev only', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.longPress(find.byType(CoraLogo));
    await tester.pumpAndSettle();
    expect(find.byType(MotionGalleryPage), findsOneWidget);
  });

  testWidgets('long pressing the logo does nothing in prod', (tester) async {
    await _pumpLogin(tester, env: CoraEnv.prod);

    await tester.longPress(find.byType(CoraLogo));
    await tester.pumpAndSettle();
    expect(find.byType(MotionGalleryPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('E1 does not overflow at 360 x 640 with 1.3x text', (
    tester,
  ) async {
    useSmallPhoneWithLargeText(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 실패 문구가 떠도 넘치지 않는다.
    final auth = FakeAuthRepository()
      ..signInError = const AuthFailure.network();
    await pumpCoraApp(tester, auth: auth);
    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();
    expect(find.text(_tryLater), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E1 reads the buttons to a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpLogin(tester);

    expect(
      tester.getSemantics(find.text('카카오로 계속하기')),
      matchesSemantics(
        label: '카카오로 계속하기',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}

import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/network/api_client_provider.dart';
import 'package:cora/core/network/timeout_http_client.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_logo.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_select_card.dart';
import 'package:cora/features/auth/presentation/pages/login_page.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/creator_profile/presentation/pages/creator_profile_setup_page.dart';
import 'package:cora/features/onboarding/data/api_me_repository.dart';
import 'package:cora/features/onboarding/domain/me_repository_provider.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/onboarding/presentation/pages/role_home_placeholder_page.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_links_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../creator_profile/fake_creator_profile_repository.dart';
import 'fake_me_repository.dart';

const _storeTitle = '가게를 알리고 싶어요';
const _brandTitle = '브랜드 제품을 알리고 싶어요';
const _creatorTitle = '콘텐츠를 만들고 싶어요';
const _serverDown = '서버에 연결하지 못했어요.';

FakeAuthRepository _signedIn() =>
    FakeAuthRepository(session: FakeAuthRepository.signedInSession);

Future<void> _pumpA1(
  WidgetTester tester, {
  FakeMeRepository? me,
  FakeAuthRepository? auth,
}) async {
  usePhone(tester);
  await pumpCoraApp(
    tester,
    auth: auth ?? _signedIn(),
    me: me,
    // 크리에이터를 고르면 프로필 유무를 조회한다.
    overrides: [
      creatorProfileRepositoryProvider.overrideWithValue(
        FakeCreatorProfileRepository(),
      ),
    ],
  );
}

Finder _card(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(CoraSelectCard));

Color? _cardColor(WidgetTester tester, String title) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(of: _card(title), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

Color? _dotColor(WidgetTester tester, String title) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: _card(title),
      matching: find.byKey(CoraSelectCard.dotKey),
    ),
  );
  return (box.decoration as BoxDecoration).color;
}

TextStyle _styleOf(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text).text.style!;

Color? _buttonColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(CoraPrimaryButton),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('shows the canvas copy for all three roles', (tester) async {
    await _pumpA1(tester);

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
    expect(find.text('cora'), findsOneWidget);
    expect(find.text('어떤 일로\n오셨나요?'), findsOneWidget);
    expect(find.text('고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.'), findsOneWidget);
    expect(find.text('일을 맡기는 쪽'), findsNWidgets(2));
    expect(find.text('일을 하는 쪽'), findsOneWidget);
    expect(find.text(_storeTitle), findsOneWidget);
    expect(find.text('식당, 미용실, 공방 같은 동네 가게'), findsOneWidget);
    expect(find.text(_brandTitle), findsOneWidget);
    expect(find.text('쇼핑몰, 제조사, 브랜드 담당자'), findsOneWidget);
    expect(find.text(_creatorTitle), findsOneWidget);
    expect(find.text('팔로워가 적어도 누구나 시작할 수 있어요'), findsOneWidget);
  });

  testWidgets('starts with the store card selected and its button', (
    tester,
  ) async {
    await _pumpA1(tester);
    final c = CoraColors.light;

    expect(_cardColor(tester, _storeTitle), c.notifyTabSelected);
    expect(_cardColor(tester, _brandTitle), c.roleCardIdle);
    expect(_dotColor(tester, _storeTitle), c.accent);
    expect(_dotColor(tester, _creatorTitle), c.line);
    expect(find.text('가게 링크로 시작하기'), findsOneWidget);
  });

  testWidgets('starts with the saved role selected when re-picking', (
    tester,
  ) async {
    await _pumpA1(tester, me: FakeMeRepository(role: UserRole.brand));
    routerOf(tester).go(AppRoutes.role);
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(find.text('크리에이터 둘러보기'), findsOneWidget);
    expect(_cardColor(tester, _brandTitle), CoraColors.light.notifyTabSelected);
  });

  testWidgets('button label follows the selected role', (tester) async {
    await _pumpA1(tester);
    expect(find.text('가게 링크로 시작하기'), findsOneWidget);

    await tester.tap(find.text(_creatorTitle));
    await tester.pumpAndSettle();
    expect(find.text('내 협업 원칙 정하기'), findsOneWidget);
    expect(find.text('가게 링크로 시작하기'), findsNothing);
    expect(
      _cardColor(tester, _creatorTitle),
      CoraColors.light.notifyTabSelected,
    );
    expect(_cardColor(tester, _storeTitle), CoraColors.light.background);

    await tester.tap(find.text(_brandTitle));
    await tester.pumpAndSettle();
    expect(find.text('크리에이터 둘러보기'), findsOneWidget);
  });

  testWidgets('confirming saves the role and opens the home for that role', (
    tester,
  ) async {
    final me = FakeMeRepository();
    await _pumpA1(tester, me: me);

    await tester.tap(find.text(_creatorTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 협업 원칙 정하기'));
    await tester.pumpAndSettle();

    expect(me.savedRole, UserRole.creator);
    // 프로필이 아직 없는 크리에이터는 프로필 만들기 화면으로 간다.
    expect(find.byType(CreatorProfileSetupPage), findsOneWidget);
    expect(find.byType(RoleSelectPage), findsNothing);
    expect(currentPath(tester), AppRoutes.creatorProfileSetup);
  });

  testWidgets('the button is off while saving and a second tap saves once', (
    tester,
  ) async {
    final me = FakeMeRepository()..holdSave = Completer<void>();
    await _pumpA1(tester, me: me);

    await tester.tap(find.text('가게 링크로 시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(CoraPrimaryButton), warnIfMissed: false);
    await tester.pump();

    expect(me.updateCalls, 1);
    expect(find.byType(RoleSelectPage), findsOneWidget);

    me.holdSave!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(StoreLinksPage), findsOneWidget);
  });

  testWidgets('shows an error with retry when the server is unreachable', (
    tester,
  ) async {
    final me = FakeMeRepository()..failFetch = true;
    await _pumpA1(tester, me: me);

    expect(find.text(_serverDown), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text(_storeTitle), findsNothing);
    expect(find.byType(LoginPage), findsNothing);

    me.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text(_storeTitle), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
    expect(me.fetchCalls, 2);
  });

  testWidgets('shows an error with retry when the server never answers', (
    tester,
  ) async {
    usePhone(tester);
    // 서버가 연결은 받았지만 응답을 주지 않는다.
    final http = FakeHttpClient()..gate = Completer<void>();
    await tester.pumpWidget(
      coraAppWith(
        _signedIn(),
        overrides: [httpClientProvider.overrideWithValue(http)],
        meRepositoryOverride: meRepositoryProvider.overrideWith(
          (ref) => ApiMeRepository(ref.watch(apiClientProvider)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 기다리는 동안은 빈 첫 화면이다.
    expect(find.text('다시 시도'), findsNothing);

    await tester.pump(apiRequestTimeout);
    await tester.pumpAndSettle();

    expect(find.text(_serverDown), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('a user with a saved role goes home after a successful retry', (
    tester,
  ) async {
    final me = FakeMeRepository(role: UserRole.brand)..failFetch = true;
    await _pumpA1(tester, me: me);
    expect(find.text('다시 시도'), findsOneWidget);

    me.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('브랜드 홈'), findsOneWidget);
  });

  testWidgets('keeps the selection and shows a message when saving fails', (
    tester,
  ) async {
    final me = FakeMeRepository()..failSave = true;
    await _pumpA1(tester, me: me);

    await tester.tap(find.text(_brandTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('크리에이터 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(find.text(_serverDown), findsOneWidget);
    expect(find.text('크리에이터 둘러보기'), findsOneWidget);
    expect(_cardColor(tester, _brandTitle), CoraColors.light.notifyTabSelected);

    // 다시 누르면 저장된다. 고르기만 해도 안내는 사라진다.
    me.failSave = false;
    await tester.tap(find.text('크리에이터 둘러보기'));
    await tester.pumpAndSettle();
    expect(find.text('브랜드 홈'), findsOneWidget);
  });

  testWidgets('the failure message goes away when another role is picked', (
    tester,
  ) async {
    final me = FakeMeRepository()..failSave = true;
    await _pumpA1(tester, me: me);

    await tester.tap(find.text('가게 링크로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text(_serverDown), findsOneWidget);

    await tester.tap(find.text(_creatorTitle));
    await tester.pumpAndSettle();
    expect(find.text(_serverDown), findsNothing);
  });

  testWidgets('does not show A1 or a home while /me is loading', (
    tester,
  ) async {
    usePhone(tester);
    final me = FakeMeRepository()..holdFetch = Completer<void>();
    await tester.pumpWidget(coraAppWith(_signedIn(), me: me));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(RoleSelectPage), findsNothing, reason: 'frame $frame');
      expect(find.byType(RoleHomePlaceholderPage), findsNothing);
      expect(find.byType(LoginPage), findsNothing);
    }
    expect(currentPath(tester), AppRoutes.splash);

    me.holdFetch!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectPage), findsOneWidget);
    // 라우터와 화면이 요청을 따로 보내지 않는다.
    expect(me.fetchCalls, 1);
  });

  testWidgets('skips role selection when a role is already saved', (
    tester,
  ) async {
    usePhone(tester);
    final me = FakeMeRepository(role: UserRole.store);
    await tester.pumpWidget(coraAppWith(_signedIn(), me: me));
    for (var frame = 0; frame < 30; frame++) {
      expect(find.byType(RoleSelectPage), findsNothing, reason: 'frame $frame');
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();

    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.storeOnboardingLinks);
    expect(me.fetchCalls, 1);
  });

  testWidgets('does not overflow at 1.3x text scale on a small phone', (
    tester,
  ) async {
    useSmallPhoneWithLargeText(tester);
    await pumpCoraApp(tester, auth: _signedIn());

    expect(tester.takeException(), isNull);
    // 카드 목록은 스크롤되고, 맨 아래로 내리면 마지막 카드가 고정 버튼 위에 온다.
    final scroll = find.byType(SingleChildScrollView);
    await tester.drag(scroll, const Offset(0, -2000));
    await tester.pumpAndSettle();

    final lastCard = tester.getRect(_card(_creatorTitle));
    final button = tester.getRect(find.byType(CoraPrimaryButton));
    expect(lastCard.bottom, lessThanOrEqualTo(button.top));
    expect(button.bottom, 640 - 32);
    expect(button.left, 16);
    expect(tester.takeException(), isNull);

    // 목록의 맨 위에는 로고가 다시 보인다.
    await tester.drag(scroll, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(CoraLogo)).top, greaterThanOrEqualTo(0));
  });

  testWidgets('the bottom button clears the home indicator', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(top: 177, bottom: 102);
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.reset);
    await pumpCoraApp(tester, auth: _signedIn());

    final button = tester.getRect(find.byType(CoraPrimaryButton));
    // 화면은 393 x 852다. 홈 표시줄 34가 32보다 크므로 34를 비운다(E1과 같은 규칙).
    expect(button.bottom, closeTo(852 - 34, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('A1 lays out like the canvas at 390 x 844', (tester) async {
    await loadAppFonts();
    useCanvasPhone(tester);
    await pumpCoraApp(tester, auth: _signedIn());

    // 위 여백 72, 좌우 24. 로고 → 36 → 제목 → 12 → 설명 → 32 → 카드.
    final logo = tester.getRect(find.byType(CoraLogo));
    expect(logo.left, 24);
    expect(logo.top, 72);
    final title = tester.getRect(find.text('어떤 일로\n오셨나요?'));
    expect(title.left, 24);
    expect(title.top, closeTo(logo.bottom + 36, 0.5));
    // 제목 32px, 줄 높이 1.25, 두 줄.
    expect(title.height, closeTo(80, 0.5));
    final description = tester.getRect(
      find.text('고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.'),
    );
    expect(description.left, 24);
    expect(description.top, closeTo(title.bottom + 12, 0.5));

    final store = tester.getRect(_card(_storeTitle));
    final brand = tester.getRect(_card(_brandTitle));
    final creator = tester.getRect(_card(_creatorTitle));
    expect(store.top, closeTo(description.bottom + 32, 0.5));
    for (final card in [store, brand, creator]) {
      expect([card.left, card.right], [16, 374]);
      expect(card.height, greaterThanOrEqualTo(92));
    }
    expect(brand.top - store.bottom, closeTo(10, 0.01));
    expect(creator.top - brand.bottom, closeTo(10, 0.01));

    // 캔버스 NRole을 같은 글꼴로 브라우저에 그려 잰 값(390 x 844): 제목 145.5, 설명 237.5,
    // 카드 317.5 / 435 / 552.5(높이 107.5), 아래 버튼 754. Flutter는 글자 줄 높이를 정수
    // 픽셀로 맞춰서(로고 38, 카드 108) 줄이 쌓일수록 최대 1.5까지 어긋난다. 엔진의 글자 배치
    // 차이라 허용치를 둔다.
    expect(title.top, closeTo(145.5, 1));
    expect(description.top, closeTo(237.5, 1));
    expect(store.top, closeTo(317.5, 1));
    expect(brand.top, closeTo(435, 1.5));
    expect(creator.top, closeTo(552.5, 2));
    for (final card in [store, brand, creator]) {
      expect(card.height, closeTo(107.5, 1));
    }
    // 아래 버튼: 좌우 16, 높이 58, 맨 아래가 화면 아래에서 32.
    final button = tester.getRect(find.byType(CoraPrimaryButton));
    expect([button.left, button.right], [16, 374]);
    expect(button.height, 58);
    expect(button.bottom, 844 - 32);
    expect(button.top, 754);
    expect(creator.bottom, lessThan(button.top));

    // 카드 안: 안쪽 여백 18·20, 원 24가 오른쪽 끝에서 20.
    final dot = tester.getRect(
      find.descendant(
        of: _card(_storeTitle),
        matching: find.byKey(CoraSelectCard.dotKey),
      ),
    );
    expect(dot.size, const Size(24, 24));
    expect(dot.right, closeTo(store.right - 20, 0.01));
    expect(dot.center.dy, closeTo(store.center.dy, 0.01));
    final overline = tester.getRect(find.text('일을 맡기는 쪽').first);
    expect(overline.left, closeTo(store.left + 20, 0.01));
    expect(overline.top, closeTo(store.top + 18, 0.01));
  });

  testWidgets('A1 uses the canvas light values', (tester) async {
    await _pumpA1(tester);
    final c = CoraColors.light;

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
      anyOf(isNull, c.background),
    );
    expect(_buttonColor(tester), c.accent);
    final label = _styleOf(tester, find.text('가게 링크로 시작하기'));
    expect(label.color, const Color(0xFF1F2A00));
    expect(label.fontSize, 16);
    expect(label.fontWeight, FontWeight.w700);
    final title = _styleOf(tester, find.text('어떤 일로\n오셨나요?'));
    expect(title.color, c.text);
    expect(title.fontSize, 32);
    expect(title.fontWeight, FontWeight.w900);
    expect(
      _styleOf(tester, find.text('고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.')).color,
      c.textSecondary,
    );
  });

  testWidgets('renders in dark theme with the canvas dark values', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpA1(tester);
    final c = CoraColors.dark;

    expect(tester.takeException(), isNull);
    // 선택한 카드(DarkNRole 2026-11-12): #33363D 바탕에 밝은 글자(#F2F3F5), 원은 라임(#C6FF3D).
    expect(_cardColor(tester, _storeTitle), const Color(0xFF33363D));
    expect(
      _styleOf(tester, find.text(_storeTitle)).color,
      const Color(0xFFF2F3F5),
    );
    expect(_dotColor(tester, _storeTitle), const Color(0xFFC6FF3D));
    // 고르지 않은 카드: #2A2D33 바탕에 밝은 글자, 원도 #2A2D33.
    expect(_cardColor(tester, _brandTitle), const Color(0xFF2A2D33));
    expect(
      _styleOf(tester, find.text(_brandTitle)).color,
      const Color(0xFFF2F3F5),
    );
    expect(_dotColor(tester, _brandTitle), const Color(0xFF2A2D33));
    // 아래 버튼: 다크에서도 라임(#C6FF3D)에 #1F2A00 글자, 굵기 700(DarkNRole).
    expect(_buttonColor(tester), const Color(0xFFC6FF3D));
    final label = _styleOf(tester, find.text('가게 링크로 시작하기'));
    expect(label.color, const Color(0xFF1F2A00));
    expect(label.fontWeight, FontWeight.w700);
    // 설명 #A0A4AD, 로고 글자 #F2F3F5.
    expect(
      _styleOf(tester, find.text('고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.')).color,
      const Color(0xFFA0A4AD),
    );
    expect(_styleOf(tester, find.text('cora')).color, c.text);
    expect(_styleOf(tester, find.text('cora')).color, const Color(0xFFF2F3F5));
  });
}

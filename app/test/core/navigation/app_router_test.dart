import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/navigation/cora_transitions.dart';
import 'package:cora/core/navigation/role_entry.dart';
import 'package:cora/core/ui/cora_coming_soon_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:cora/features/auth/presentation/pages/login_page.dart';
import 'package:cora/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:cora/core/ui/cora_logo.dart';
import 'package:cora/features/dev/presentation/pages/motion_gallery_page.dart';
import 'package:cora/features/creator_profile/domain/creator_profile.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/onboarding/presentation/pages/role_home_placeholder_page.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_page.dart';
import 'package:cora/core/network/api_client_provider.dart';
import 'package:cora_api/api.dart' hide UserRole;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/fake_auth_repository.dart';
import '../../features/creator_profile/fake_creator_profile_repository.dart';
import '../../features/onboarding/fake_me_repository.dart';
import '../../support/fake_http_client.dart';
import '../../support/pump_cora_app.dart';

List<String> _paths(List<RouteBase> routes) => [
  for (final route in routes) ...[
    if (route is GoRoute) route.path,
    ..._paths(route.routes),
  ],
];

Future<void> _openGallery(WidgetTester tester) async {
  // 개발 빌드에서 E1의 로고를 길게 누르면 열린다(E1 모양은 바뀌지 않는다).
  await tester.longPress(find.byType(CoraLogo));
  await tester.pumpAndSettle();
  expect(find.byType(MotionGalleryPage), findsOneWidget);
}

Future<void> _openDemo(WidgetTester tester, String label) async {
  final row = find.text(label);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('닫기'), findsOneWidget, reason: label);
}

/// 프로필이 이미 있는 크리에이터(진입 경로가 `/creator`).
Override _creatorWithProfile() =>
    creatorProfileRepositoryProvider.overrideWithValue(
      FakeCreatorProfileRepository(
        profile: const CreatorProfile(displayName: '서윤', regionSido: '서울특별시'),
      ),
    );

void main() {
  testWidgets('redirects to /login when there is no session', (tester) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(find.byType(LoginPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.login);
  });

  testWidgets('redirects any location to /login without a session', (
    tester,
  ) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    routerOf(tester).go(AppRoutes.role);
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('redirects from /login to /role once signed in', (tester) async {
    final auth = FakeAuthRepository();
    await pumpCoraApp(tester, auth: auth);

    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();

    expect(auth.kakaoCalls, 1);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('sends a signed-in user away from /login', (tester) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    );

    routerOf(tester).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('returns to /login when the API answers 401', (tester) async {
    final fakeHttp = FakeHttpClient()
      ..statusCode = 401
      ..body = unauthenticatedBody;
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(
      tester,
      auth: fake,
      overrides: [httpClientProvider.overrideWithValue(fakeHttp)],
    );
    expect(find.byType(RoleSelectPage), findsOneWidget);

    // 서버가 지금 세션의 토큰을 거부한다. 요청한 쪽은 오류를 받고, 앱은 로그인 화면으로 간다.
    await expectLater(
      UsersApi(containerOf(tester).read(apiClientProvider)).getMe(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 401)),
    );
    await tester.pumpAndSettle();

    expect(fake.signOutCalls, 1);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RoleSelectPage), findsNothing);
  });

  testWidgets('returns to /login when the session ends', (tester) async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(tester, auth: fake);
    expect(find.byType(RoleSelectPage), findsOneWidget);

    fake.endSession();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RoleSelectPage), findsNothing);
  });

  testWidgets('logging out from a home returns to /login', (tester) async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(
      tester,
      auth: fake,
      me: FakeMeRepository(role: UserRole.brand),
    );

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(fake.signOutCalls, 1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('sends a signed-in user with a role from /login to their home', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpCoraApp(
      tester,
      auth: auth,
      me: FakeMeRepository(role: UserRole.creator),
      overrides: [_creatorWithProfile()],
    );

    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.byType(CoraComingSoonPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.creator);
  });

  testWidgets('keeps /role reachable when a role exists', (tester) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      me: FakeMeRepository(role: UserRole.brand),
    );
    expect(currentPath(tester), AppRoutes.brand);

    routerOf(tester).go(AppRoutes.role);
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('keeps a user on the home of their own role only', (
    tester,
  ) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      me: FakeMeRepository(role: UserRole.store),
    );

    routerOf(tester).go(AppRoutes.creatorOffers);
    await tester.pumpAndSettle();

    expect(currentPath(tester), AppRoutes.storeComingSoon('가게 홈'));
    expect(find.text('가게 홈'), findsOneWidget);
  });

  testWidgets('sends a user without a role from a home to /role', (
    tester,
  ) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    );

    routerOf(tester).go(AppRoutes.store);
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('sends any location to /login when the session ends at a home', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(
      tester,
      auth: fake,
      me: FakeMeRepository(role: UserRole.brand),
    );

    fake.endSession();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RoleHomePlaceholderPage), findsNothing);
  });

  testWidgets('a cold start with a stored session never shows /login', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraAppWith(
        FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      ),
    );
    for (var frame = 0; frame < 30; frame++) {
      expect(find.byType(LoginPage), findsNothing, reason: 'frame $frame');
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
  });

  testWidgets('keeps one router across auth changes', (tester) async {
    final fake = FakeAuthRepository();
    await pumpCoraApp(tester, auth: fake);
    final before = routerOf(tester);

    fake.setSession(FakeAuthRepository.signedInSession);
    await tester.pumpAndSettle();
    fake.endSession();
    await tester.pumpAndSettle();

    expect(identical(routerOf(tester), before), isTrue);
  });

  testWidgets('prod build still shows E1 without the dev entry point', (
    tester,
  ) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository(), env: CoraEnv.prod);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('모션'), findsNothing);
  });

  testWidgets('/login/verify is open without a session', (tester) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    routerOf(tester).go(AppRoutes.loginVerify);
    await tester.pumpAndSettle();

    expect(find.byType(PhoneVerifyPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.loginVerify);
  });

  testWidgets('sends a signed-in user away from /login/verify', (tester) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    );

    routerOf(tester).go(AppRoutes.loginVerify);
    await tester.pumpAndSettle();

    expect(find.byType(PhoneVerifyPage), findsNothing);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('prod build does not register /dev/motion', (tester) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      env: CoraEnv.prod,
    );
    final router = routerOf(tester);
    expect(_paths(router.configuration.routes), isNot(contains('/dev/motion')));

    router.go(AppRoutes.devMotion);
    await tester.pumpAndSettle();

    expect(find.byType(MotionGalleryPage), findsNothing);
    expect(find.byType(RoleSelectPage), findsOneWidget);
  });

  testWidgets('dev build registers /dev/motion', (tester) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(
      _paths(routerOf(tester).configuration.routes),
      contains('/dev/motion'),
    );
  });

  testWidgets('E1 logo long press opens the motion gallery without a session', (
    tester,
  ) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    await _openGallery(tester);
  });

  // iOS 가장자리 밀기는 테마의 플랫폼을 바꿔야 해서 motion_gallery_page_test.dart에서 본다.
  testWidgets('system back closes a gallery demo before leaving the gallery', (
    tester,
  ) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());
    await _openGallery(tester);
    await _openDemo(tester, 'push 전환');

    await systemBack(tester);

    expect(find.text('닫기'), findsNothing);
    expect(find.byType(MotionGalleryPage), findsOneWidget);

    await systemBack(tester);

    expect(find.byType(MotionGalleryPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  group('role entry', () {
    FakeAuthRepository signedIn() =>
        FakeAuthRepository(session: FakeAuthRepository.signedInSession);

    Override resolver(RoleEntryResolver fn) =>
        roleEntryResolverProvider.overrideWithValue(fn);

    Duration pushedDuration(WidgetTester tester, Type page) {
      final route = ModalRoute.of(tester.element(find.byType(page)))!;
      return route.transitionDuration;
    }

    testWidgets(
      'the default resolver sends the store to coming soon and the brand home',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final ref = container.read(Provider((ref) => ref));
        expect(
          await defaultRoleEntryResolver(ref, UserRole.store),
          '/store/coming-soon/${Uri.encodeComponent('가게 홈')}',
        );
        expect(await defaultRoleEntryResolver(ref, UserRole.brand), '/brand');
      },
    );

    testWidgets(
      'the default resolver sends a creator by whether a profile exists',
      (tester) async {
        Future<String> resolve(FakeCreatorProfileRepository repo) async {
          final container = ProviderContainer(
            overrides: [
              creatorProfileRepositoryProvider.overrideWithValue(repo),
            ],
          );
          addTearDown(container.dispose);
          final ref = container.read(Provider((ref) => ref));
          return defaultRoleEntryResolver(ref, UserRole.creator);
        }

        expect(
          await resolve(FakeCreatorProfileRepository()),
          AppRoutes.creatorProfileSetup,
        );
        expect(
          await resolve(
            FakeCreatorProfileRepository(
              profile: const CreatorProfile(
                displayName: '서윤',
                regionSido: '서울특별시',
              ),
            ),
          ),
          AppRoutes.creator,
        );
      },
    );

    testWidgets(
      'a creator whose profile lookup fails goes to the role screen',
      (tester) async {
        usePhone(tester);
        await pumpCoraApp(
          tester,
          auth: signedIn(),
          me: FakeMeRepository(role: UserRole.creator),
          overrides: [
            creatorProfileRepositoryProvider.overrideWithValue(
              FakeCreatorProfileRepository()..failFetch = true,
            ),
          ],
        );

        expect(currentPath(tester), AppRoutes.role);
      },
    );

    testWidgets('a Korean title survives the path encoding', (tester) async {
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.store),
      );

      routerOf(tester).go(AppRoutes.storeComingSoon('사장님 홈 & 소개'));
      await tester.pumpAndSettle();

      expect(find.text('사장님 홈 & 소개'), findsOneWidget);
      expect(find.text('준비 중이에요.'), findsOneWidget);
    });

    testWidgets('the store resolver decides where /login and a cold start go', (
      tester,
    ) async {
      usePhone(tester);
      final calls = <UserRole>[];
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.store),
        overrides: [
          resolver((ref, role) async {
            calls.add(role);
            return AppRoutes.storeOnboardingLinks;
          }),
        ],
      );

      expect(calls, [UserRole.store]);
      expect(currentPath(tester), AppRoutes.storeOnboardingLinks);
      expect(find.byType(CoraComingSoonPage), findsOneWidget);
    });

    testWidgets(
      'opening /store follows the resolver and stays when it says /store',
      (tester) async {
        usePhone(tester);
        var target = AppRoutes.storeOnboardingTerms;
        await pumpCoraApp(
          tester,
          auth: signedIn(),
          me: FakeMeRepository(role: UserRole.store),
          overrides: [resolver((ref, role) async => target)],
        );
        expect(currentPath(tester), AppRoutes.storeOnboardingTerms);

        target = AppRoutes.store;
        routerOf(tester).go(AppRoutes.store);
        await tester.pumpAndSettle();
        expect(currentPath(tester), AppRoutes.store);
      },
    );

    testWidgets('a creator without a profile lands on the setup route', (
      tester,
    ) async {
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.creator),
        overrides: [
          resolver((ref, role) async => AppRoutes.creatorProfileSetup),
        ],
      );
      expect(currentPath(tester), AppRoutes.creatorProfileSetup);
    });

    testWidgets('inner role screens are left alone', (tester) async {
      usePhone(tester);
      var calls = 0;
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.store),
        overrides: [
          resolver((ref, role) async {
            calls++;
            return AppRoutes.store;
          }),
        ],
      );
      final before = calls;

      routerOf(tester).go(AppRoutes.storePage);
      await tester.pumpAndSettle();

      expect(currentPath(tester), AppRoutes.storePage);
      expect(calls, before);
    });

    testWidgets('another role screen is sent to the own entry', (tester) async {
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.creator),
        overrides: [resolver((ref, role) async => AppRoutes.creator)],
      );

      routerOf(tester).go(AppRoutes.storePage);
      await tester.pumpAndSettle();

      expect(currentPath(tester), AppRoutes.creator);
    });

    testWidgets(
      'a failing resolver falls back to /role instead of a blank screen',
      (tester) async {
        usePhone(tester);
        await pumpCoraApp(
          tester,
          auth: signedIn(),
          me: FakeMeRepository(role: UserRole.store),
          overrides: [
            resolver((ref, role) async => throw StateError('network down')),
          ],
        );

        expect(currentPath(tester), AppRoutes.role);
        expect(find.byType(RoleSelectPage), findsOneWidget);
      },
    );

    testWidgets('picking a role in A1 pushes the entry screen in', (
      tester,
    ) async {
      usePhone(tester);
      await pumpCoraApp(tester, auth: signedIn());

      await tester.tap(find.text('가게를 알리고 싶어요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('가게 링크로 시작하기'));
      await tester.pumpAndSettle();

      expect(find.byType(CoraComingSoonPage), findsOneWidget);
      expect(
        pushedDuration(tester, CoraComingSoonPage),
        CoraMotion.pushDuration,
      );
    });

    testWidgets('a cold start shows the entry screen with a fade', (
      tester,
    ) async {
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.store),
      );

      expect(find.byType(CoraComingSoonPage), findsOneWidget);
      expect(
        pushedDuration(tester, CoraComingSoonPage),
        CoraMotion.fadeDuration,
      );
    });

    testWidgets('signing in shows the entry screen with a fade', (
      tester,
    ) async {
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: FakeAuthRepository(),
        me: FakeMeRepository(role: UserRole.creator),
        overrides: [_creatorWithProfile()],
      );

      await tester.tap(find.text('카카오로 계속하기'));
      await tester.pumpAndSettle();

      expect(
        pushedDuration(tester, CoraComingSoonPage),
        CoraMotion.fadeDuration,
      );
    });

    testWidgets('pushing an entry route with stacked slides it in', (
      tester,
    ) async {
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: signedIn(),
        me: FakeMeRepository(role: UserRole.store),
      );

      unawaited(
        routerOf(
          tester,
        ).push(AppRoutes.storeComingSoon('오퍼'), extra: AppRoutes.stacked),
      );
      await tester.pumpAndSettle();

      expect(find.text('오퍼'), findsOneWidget);
      expect(
        pushedDuration(tester, CoraComingSoonPage),
        CoraMotion.pushDuration,
      );
    });

    testWidgets('every route of the store and creator flows is registered', (
      tester,
    ) async {
      await pumpCoraApp(tester, auth: FakeAuthRepository());
      final paths = _paths(routerOf(tester).configuration.routes);
      expect(
        paths,
        containsAll([
          '/store/onboarding/links',
          '/store/onboarding/page',
          '/store/onboarding/edit',
          '/store/onboarding/drafts',
          '/store/onboarding/terms',
          '/store',
          '/store/page',
          '/store/drafts',
          '/store/offers/new/:creatorId',
          '/store/coming-soon/:title',
          '/creator/profile/setup',
          '/creator',
          '/creator/stores/:id',
          '/creator/offers',
        ]),
      );
    });
  });
}

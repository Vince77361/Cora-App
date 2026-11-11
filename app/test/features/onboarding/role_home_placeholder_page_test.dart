import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/auth/presentation/pages/login_page.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_links_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_me_repository.dart';

FakeAuthRepository _signedIn() =>
    FakeAuthRepository(session: FakeAuthRepository.signedInSession);

void main() {
  testWidgets('the brand role opens the brand home placeholder', (
    tester,
  ) async {
    usePhone(tester);
    await pumpCoraApp(
      tester,
      auth: _signedIn(),
      me: FakeMeRepository(role: UserRole.brand),
    );

    expect(find.text('브랜드 홈'), findsOneWidget);
    expect(currentPath(tester), AppRoutes.brand);
    expect(find.text('역할 다시 고르기'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('re-picking a role starts from the current role and saves', (
    tester,
  ) async {
    usePhone(tester);
    final me = FakeMeRepository(role: UserRole.brand);
    await pumpCoraApp(tester, auth: _signedIn(), me: me);
    expect(find.text('브랜드 홈'), findsOneWidget);

    await tester.tap(find.text('역할 다시 고르기'));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
    expect(find.text('크리에이터 둘러보기'), findsOneWidget);

    await tester.tap(find.text('가게를 알리고 싶어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('가게 링크로 시작하기'));
    await tester.pumpAndSettle();

    expect(me.savedRole, UserRole.store);
    expect(find.byType(StoreLinksPage), findsOneWidget);
  });

  testWidgets('logging out from a home returns to /login', (tester) async {
    usePhone(tester);
    final auth = _signedIn();
    await pumpCoraApp(
      tester,
      auth: auth,
      me: FakeMeRepository(role: UserRole.brand),
    );

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('signing in again as a new user asks for a role again', (
    tester,
  ) async {
    usePhone(tester);
    final me = FakeMeRepository(role: UserRole.brand);
    await pumpCoraApp(tester, auth: _signedIn(), me: me);
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    me.role = null;
    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(me.fetchCalls, 2);
  });
}

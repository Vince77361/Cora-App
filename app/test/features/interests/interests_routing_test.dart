import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/presentation/pages/interests_page.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import '../notifications/fake_notification_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import '../store_home/store_home_harness.dart' show topPath;
import 'fake_interests_repository.dart';

/// 로그인한 브랜드로 실제 앱을 띄운다(프로필과 진행 중인 캠페인이 있어 첫 화면은 발견 01이다).
Future<void> _pumpBrand(
  WidgetTester tester, {
  FakeInterestsRepository? interests,
  FakeDiscoveryRepository? discovery,
  List<Override> overrides = const [],
}) async {
  usePhone(tester);
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.brand),
    overrides: [
      interestsRepositoryProvider.overrideWithValue(
        interests ?? FakeInterestsRepository(),
      ),
      if (discovery != null)
        discoveryRepositoryProvider.overrideWithValue(discovery),
      ...overrides,
    ],
  );
}

AppNotification matchNotification(String id, String collaborationId) =>
    AppNotification(
      id: id,
      tab: NotificationTab.matching,
      text: '$id 문구',
      actorName: '서윤의 작은 취향',
      actorPhotoUrl: null,
      glyph: null,
      targetKind: 'MATCH',
      targetId: collaborationId,
      createdAt: DateTime.utc(2026, 11, 11, 11),
      read: false,
    );

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(CoraBottomNav), matching: find.text(label));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the brand menu opens the interests screen in place', (
    tester,
  ) async {
    await _pumpBrand(
      tester,
      interests: FakeInterestsRepository(cards: [brandCard('c1', name: '서윤')]),
    );
    expect(topPath(tester), AppRoutes.brand);

    await tester.tap(_navLabel('관심'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.brandInterests);
    expect(find.byType(InterestsPage), findsOneWidget);
    expect(find.text('관심·보류'), findsOneWidget);
    expect(find.text('저장 1'), findsOneWidget);

    // 발견 메뉴는 제자리에서 돌아온다.
    await tester.tap(_navLabel('발견'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.brand);
  });

  testWidgets('the creator menu opens the creator interests screen with no '
      'comparison', (tester) async {
    await pumpCreatorApp(
      tester,
      overrides: [
        interestsRepositoryProvider.overrideWithValue(
          FakeInterestsRepository(cards: [campaignCard('k1', name: '모아 스튜디오')]),
        ),
      ],
    );

    await tester.tap(_navLabel('관심'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creatorInterests);
    expect(find.byType(InterestsPage), findsOneWidget);
    expect(find.text('모아 스튜디오'), findsOneWidget);
    expect(find.textContaining('비교'), findsNothing);
    // 준비 중 자리 화면이 아니다.
    expect(find.text('준비 중이에요.'), findsNothing);
  });

  testWidgets('the saved tab link of the discovery toast opens the saved tab', (
    tester,
  ) async {
    await _pumpBrand(
      tester,
      interests: FakeInterestsRepository(
        cards: [
          brandCard('c3', name: '하루 한 컵', state: InterestState.held),
          brandCard('c2', name: '민의 옷장 기록'),
        ],
      ),
    );

    routerOf(tester).push(AppRoutes.brandSaved);
    await tester.pumpAndSettle();
    expect(find.text('저장 2'), findsOneWidget);

    routerOf(tester).push('${AppRoutes.brandInterests}?tab=held');
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsNothing);
  });

  testWidgets('the match toast link opens the match sheet over the list', (
    tester,
  ) async {
    final interests = FakeInterestsRepository(
      cards: [brandCard('c1', name: '서윤', state: InterestState.mutual)],
      match: matchInfo(collaborationId: 'collab-c1'),
    );
    await _pumpBrand(tester, interests: interests);

    routerOf(tester).push(AppRoutes.brandMatch('collab-c1'));
    await tester.pumpAndSettle();

    expect(interests.matchesFetched, ['collab-c1']);
    expect(find.text('서로를 골랐어요.'), findsOneWidget);
    expect(find.text('받은 제안 보기 · 1건'), findsOneWidget);
    // 시트를 닫으면 03을 연 발견으로 돌아간다.
    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.brand);
  });

  testWidgets('the mutual interest notification opens the brand match sheet', (
    tester,
  ) async {
    final interests = FakeInterestsRepository(
      cards: [brandCard('c1', name: '서윤', state: InterestState.mutual)],
      match: matchInfo(collaborationId: 'collab-c1'),
    );
    await _pumpBrand(
      tester,
      interests: interests,
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(
            items: [matchNotification('n1', 'collab-c1')],
          ),
        ),
      ],
    );

    routerOf(tester).push('/notifications');
    await tester.pumpAndSettle();
    await tester.tap(find.text('n1 문구'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.brandInterests);
    expect(find.text('서로를 골랐어요.'), findsOneWidget);
  });

  testWidgets('the compare route without two different candidates goes back '
      'to the list', (tester) async {
    await _pumpBrand(tester);

    routerOf(tester).push('${AppRoutes.brandInterests}/compare?a=c1');
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.brandInterests);

    routerOf(tester).push(AppRoutes.brandCompare('c1', 'c1'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.brandInterests);
  });

  testWidgets('the compare route opens the comparison for two candidates', (
    tester,
  ) async {
    final interests = FakeInterestsRepository(
      cards: [
        brandCard('c1', name: '서윤'),
        brandCard('c2', name: '민'),
      ],
    );
    await _pumpBrand(tester, interests: interests);

    routerOf(tester).push(AppRoutes.brandInterests);
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 2명 비교하기'));
    await tester.pumpAndSettle();

    // 비교 응답이 없는 가짜라 읽지 못했다고 보이지만, 두 후보를 목록 순서로 물었다.
    expect(topPath(tester), AppRoutes.brandComparePattern);
    expect(interests.compared, [(a: 'c1', b: 'c2')]);
    expect(find.text('후보 비교'), findsOneWidget);
  });

  testWidgets('the brand profile menu still opens the placeholder profile', (
    tester,
  ) async {
    await _pumpBrand(tester);
    await tester.tap(_navLabel('관심'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('프로필'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.brandProfile);
  });
}

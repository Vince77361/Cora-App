import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/presentation/pages/brand_discovery_page.dart';
import 'package:cora/features/discovery/presentation/pages/preview_discovery_page.dart';
import 'package:cora/features/discovery/presentation/widgets/discovery_toast.dart';
import 'package:cora/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import 'fake_discovery_repository.dart';

const _hint = '역할을 고르면 관심을 보낼 수 있어요.';

FakeDiscoveryRepository _three() => FakeDiscoveryRepository()
  ..previewCards = [
    previewCard('c1', name: '서윤의 작은 취향'),
    previewCard(
      'c2',
      name: '민의 옷장 기록',
      headline: '같은 니트, 세 가지 액세서리',
      tags: const ['니트'],
    ),
    previewCard('c3', name: '하루 한 컵', headline: null, tags: const []),
  ];

/// 역할이 없는 로그인 사용자로 앱을 띄워 A1에서 `등록 없이 먼저 둘러보기`를 연다.
Future<void> _openPreview(
  WidgetTester tester,
  FakeDiscoveryRepository repo,
) async {
  usePhone(tester);
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(),
    overrides: [discoveryRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.tap(find.text('등록 없이 먼저 둘러보기'));
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, String name, Offset by) async {
  await tester.drag(find.text(name), by);
  await tester.pumpAndSettle();
}

/// 위에 쌓인 화면의 경로(`push`로 연 화면도 센다).
String _topLocation(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.last.matchedLocation;

void _expectBackOnRolePage(WidgetTester tester, {required bool hint}) {
  expect(find.byType(RoleSelectPage), findsOneWidget);
  expect(find.byType(PreviewDiscoveryPage), findsNothing);
  expect(_topLocation(tester), AppRoutes.role);
  expect(find.text(_hint), hint ? findsOneWidget : findsNothing);
}

/// 저장소에 쓰기나 되돌리기가 하나도 가지 않았다.
void _expectNothingSaved(FakeDiscoveryRepository repo) {
  expect(repo.decisions, isEmpty);
  expect(repo.reasons, isEmpty);
  expect(repo.undoCalls, 0);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'the role page shows the browse-first link and opens the preview',
    (tester) async {
      final repo = _three();
      await _openPreview(tester, repo);

      expect(find.byType(PreviewDiscoveryPage), findsOneWidget);
      expect(_topLocation(tester), AppRoutes.browse);
      expect(repo.previewFetchCalls, 1);
      expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
      expect(find.text('서윤의 작은 취향'), findsOneWidget);
      expect(find.text('출근 전 30초, 오늘의 손목 루틴'), findsOneWidget);
      expect(find.text('30만 원대'), findsWidgets);
      expect(find.text('#얼굴출연없음'), findsOneWidget);
      // 머리: 로고, 알약 `둘러보는 중`, 오른쪽 `역할 고르기`.
      expect(find.text('cora'), findsOneWidget);
      expect(find.text('둘러보는 중'), findsOneWidget);
      expect(find.text('역할 고르기'), findsOneWidget);
      expect(find.text('브랜드'), findsNothing);
    },
  );

  testWidgets('passing in the preview shows the next card and saves nothing', (
    tester,
  ) async {
    final repo = _three();
    await _openPreview(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));

    expect(find.text('운영자 추천 2 / 3'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsNothing);

    // 넘김 버튼도 같다. 알림 문구와 02 시트는 뜨지 않는다.
    await tester.tap(find.bySemanticsLabel('넘기기'));
    await tester.pumpAndSettle();
    expect(find.text('운영자 추천 3 / 3'), findsOneWidget);
    expect(find.byType(DiscoveryToastBanner), findsNothing);
    expect(find.text('이유 남기기'), findsNothing);
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);
    _expectNothingSaved(repo);
    expect(find.byType(PreviewDiscoveryPage), findsOneWidget);
  });

  testWidgets(
    'swiping right in the preview snaps back and returns to the role page',
    (tester) async {
      final repo = _three();
      await _openPreview(tester, repo);

      final card = find.text('서윤의 작은 취향');
      final home = tester.getCenter(card);
      final gesture = await tester.startGesture(home);
      // 처음 움직임은 끌기로 알아보는 데 쓰이므로 두 번에 나눠 움직인다.
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(270, 0));
      await tester.pump();
      final released = tester.getCenter(card).dx;
      expect(released, greaterThan(home.dx + 150));
      await gesture.up();

      // 카드는 화면 밖으로 날아가지 않고 놓은 자리에서 제자리로 돌아온다. 다 멈추기 전에는 아직
      // 둘러보기 화면이고, 멈춘 뒤에 A1로 간다.
      var frames = 0;
      while (find.byType(PreviewDiscoveryPage).evaluate().isNotEmpty &&
          frames++ < 200) {
        await tester.pump(const Duration(milliseconds: 16));
        if (card.evaluate().isEmpty) break;
        final rect = tester.getRect(card);
        expect(rect.center.dx, lessThanOrEqualTo(released + 0.5));
        expect(rect.left, lessThan(390));
      }
      await tester.pumpAndSettle();

      _expectBackOnRolePage(tester, hint: true);
      _expectNothingSaved(repo);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('swiping up returns to the role page with the hint', (
    tester,
  ) async {
    final repo = _three();
    await _openPreview(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(0, -400));

    _expectBackOnRolePage(tester, hint: true);
    _expectNothingSaved(repo);
  });

  testWidgets(
    'the like and hold buttons return to the role page with the hint',
    (tester) async {
      final repo = _three();
      await _openPreview(tester, repo);

      await tester.tap(find.bySemanticsLabel('하트'));
      await tester.pumpAndSettle();
      _expectBackOnRolePage(tester, hint: true);

      await tester.tap(find.text('등록 없이 먼저 둘러보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('저장'));
      await tester.pumpAndSettle();
      _expectBackOnRolePage(tester, hint: true);
      _expectNothingSaved(repo);
    },
  );

  testWidgets('the undo button is dimmed and does nothing in the preview', (
    tester,
  ) async {
    final repo = _three();
    await _openPreview(tester, repo);

    await tester.tap(find.bySemanticsLabel('되돌리기'));
    await tester.pumpAndSettle();

    expect(find.byType(PreviewDiscoveryPage), findsOneWidget);
    _expectNothingSaved(repo);
  });

  testWidgets('the hint disappears after three seconds', (tester) async {
    await _openPreview(tester, _three());
    await tester.tap(find.bySemanticsLabel('하트'));
    await tester.pumpAndSettle();
    expect(find.text(_hint), findsOneWidget);

    await tester.pump(DiscoveryToastBanner.duration);
    await tester.pumpAndSettle();

    expect(find.text(_hint), findsNothing);
  });

  testWidgets('tapping a preview card does not open the creator detail', (
    tester,
  ) async {
    final repo = _three();
    await _openPreview(tester, repo);

    await tester.tap(find.text('서윤의 작은 취향'));
    await tester.pumpAndSettle();

    _expectBackOnRolePage(tester, hint: true);
    expect(find.textContaining('잘 맞는 점'), findsNothing);
    _expectNothingSaved(repo);
  });

  testWidgets('the bottom menu tabs other than discover return to the role '
      'page with the hint', (tester) async {
    await _openPreview(tester, _three());

    // `발견`은 제자리다.
    Finder tab(String label) => find.descendant(
      of: find.byType(CoraBottomNav),
      matching: find.text(label),
    );
    await tester.tap(tab('발견'));
    await tester.pumpAndSettle();
    expect(find.byType(PreviewDiscoveryPage), findsOneWidget);

    await tester.tap(tab('관심'));
    await tester.pumpAndSettle();
    _expectBackOnRolePage(tester, hint: true);
  });

  testWidgets('the choose-role link in the header returns without the hint', (
    tester,
  ) async {
    await _openPreview(tester, _three());

    await tester.tap(find.text('역할 고르기'));
    await tester.pumpAndSettle();

    _expectBackOnRolePage(tester, hint: false);
  });

  testWidgets('the preview never shows an instagram handle or a notification '
      'bell', (tester) async {
    await _openPreview(tester, _three());

    expect(find.byType(NotificationBell), findsNothing);
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('인스타'), findsNothing);
    expect(find.bySemanticsLabel('되돌리기'), findsOneWidget);
  });

  testWidgets('shows the end-of-preview state with the choose-role button', (
    tester,
  ) async {
    final repo = _three();
    await _openPreview(tester, repo);
    for (final name in ['서윤의 작은 취향', '민의 옷장 기록', '하루 한 컵']) {
      await _swipe(tester, name, const Offset(-300, 0));
    }

    expect(find.text('여기까지 둘러봤어요.'), findsOneWidget);
    expect(find.text('역할을 고르면 나에게 맞는 추천을 받아요.'), findsOneWidget);
    expect(find.byType(CoraStateView), findsOneWidget);
    _expectNothingSaved(repo);

    await tester.tap(
      find.descendant(
        of: find.byType(CoraStateView),
        matching: find.text('역할 고르기'),
      ),
    );
    await tester.pumpAndSettle();
    _expectBackOnRolePage(tester, hint: false);
  });

  testWidgets('shows the empty state when there are no cards', (tester) async {
    final repo = FakeDiscoveryRepository();
    await _openPreview(tester, repo);

    expect(find.text('아직 둘러볼 크리에이터가 없어요.'), findsOneWidget);
    expect(find.text('운영자 추천 1 / 0'), findsNothing);

    // 머리의 `역할 고르기`와 빈 상태 단추 둘 다 A1로 간다.
    await tester.tap(
      find.descendant(
        of: find.byType(CoraStateView),
        matching: find.text('역할 고르기'),
      ),
    );
    await tester.pumpAndSettle();
    _expectBackOnRolePage(tester, hint: false);
  });

  testWidgets('shows the load-failed state and retries', (tester) async {
    final repo = _three()..failPreview = true;
    await _openPreview(tester, repo);

    expect(find.text('추천을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.'), findsOneWidget);

    repo.failPreview = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
    expect(repo.previewFetchCalls, 2);
  });

  testWidgets('a user with a role is sent to their own first screen instead of '
      'the preview', (tester) async {
    final repo = _three();
    usePhone(tester);
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      me: FakeMeRepository(role: UserRole.brand),
      overrides: [discoveryRepositoryProvider.overrideWithValue(repo)],
    );
    expect(find.byType(BrandDiscoveryPage), findsOneWidget);

    routerOf(tester).go(AppRoutes.browse);
    await tester.pumpAndSettle();

    expect(find.byType(PreviewDiscoveryPage), findsNothing);
    expect(find.byType(BrandDiscoveryPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.brand);
    expect(repo.previewFetchCalls, 0);
  });

  testWidgets('a signed-out user cannot open the preview', (tester) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    routerOf(tester).go(AppRoutes.browse);
    await tester.pumpAndSettle();

    expect(find.byType(PreviewDiscoveryPage), findsNothing);
    expect(currentPath(tester), AppRoutes.login);
  });

  testWidgets('uses the dark tokens for the choose-role link in dark mode', (
    tester,
  ) async {
    usePhone(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      me: FakeMeRepository(),
      overrides: [discoveryRepositoryProvider.overrideWithValue(_three())],
    );
    final browse = tester.widget<Text>(find.text('등록 없이 먼저 둘러보기'));
    expect(browse.style?.color, CoraColors.dark.textSecondary);

    await tester.tap(find.text('등록 없이 먼저 둘러보기'));
    await tester.pumpAndSettle();

    final link = tester.widget<Text>(find.text('역할 고르기'));
    expect(link.style?.color, CoraColors.dark.textSecondary);
  });
}

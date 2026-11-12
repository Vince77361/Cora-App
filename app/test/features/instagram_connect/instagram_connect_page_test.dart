import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/instagram_connect/domain/instagram_connection.dart';
import 'package:cora/features/instagram_connect/domain/instagram_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_instagram_repository.dart';

Future<void> _open(
  WidgetTester tester,
  FakeInstagramRepository repo, {
  CoraEnv env = CoraEnv.dev,
  bool smallPhoneLargeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    instagram: repo,
    env: env,
    smallPhoneLargeText: smallPhoneLargeText,
  );
  routerOf(tester).push(AppRoutes.creatorInstagram);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('asks to connect instagram', (tester) async {
    await _open(tester, FakeInstagramRepository());

    expect(topPath(tester), AppRoutes.creatorInstagram);
    expect(find.text('인스타그램을\n연동해 주세요'), findsOneWidget);
    expect(find.text('조회수를 세고, 내 게시물만 제출할 수 있게 해요.'), findsOneWidget);
    expect(find.text('인스타그램 연동하기'), findsOneWidget);
  });

  testWidgets('connects through the fake connect screen in a dev build', (
    tester,
  ) async {
    final repo = FakeInstagramRepository();
    await _open(tester, repo);

    await tester.tap(find.text('인스타그램 연동하기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.devFakeInstagram);
    expect(find.text('개발용 인스타그램 연결'), findsOneWidget);
    // 아이디를 비워 두면 연결할 수 없다.
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();
    expect(repo.completed, isEmpty);

    await tester.enterText(find.byType(TextField), 'haru_cup');
    await tester.pump();
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();

    expect(repo.completed, ['haru_cup']);
    expect(topPath(tester), AppRoutes.creatorInstagram);
    expect(find.text('@haru_cup 연동됨'), findsOneWidget);
    expect(find.text('인스타그램 연동하기'), findsNothing);
  });

  testWidgets('shows the connected account when already connected', (
    tester,
  ) async {
    await _open(
      tester,
      FakeInstagramRepository(
        connection: const InstagramConnection(
          handle: 'haru_cup',
          followers: 1200,
        ),
      ),
    );

    expect(find.text('@haru_cup 연동됨'), findsOneWidget);
    expect(find.text('인스타그램 연동하기'), findsNothing);
  });

  testWidgets('shows the server message and stays usable when it fails', (
    tester,
  ) async {
    final repo = FakeInstagramRepository()
      ..failComplete = const InstagramFailure(
        message: '이미 다른 계정에 연결된 인스타그램 아이디예요.',
      );
    await _open(tester, repo);

    await tester.tap(find.text('인스타그램 연동하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'taken');
    await tester.pump();
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 다른 계정에 연결된 인스타그램 아이디예요.'), findsOneWidget);
    expect(topPath(tester), AppRoutes.devFakeInstagram);

    repo.failComplete = null;
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();
    expect(find.text('@taken 연동됨'), findsOneWidget);
  });

  testWidgets('shows a generic message when the server gives none', (
    tester,
  ) async {
    final repo = FakeInstagramRepository()
      ..failComplete = const InstagramFailure();
    await _open(tester, repo);

    await tester.tap(find.text('인스타그램 연동하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'haru_cup');
    await tester.pump();
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();

    expect(find.text('연동하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('does not open the fake screen outside a dev environment', (
    tester,
  ) async {
    final repo = FakeInstagramRepository();
    await _open(tester, repo, env: CoraEnv.prod);

    await tester.tap(find.text('인스타그램 연동하기'));
    await tester.pumpAndSettle();

    // 실제 인스타그램 승인은 9번 계획에서 붙인다: 주소만 받고 안내를 보인다.
    expect(repo.beginCalls, 1);
    expect(topPath(tester), AppRoutes.creatorInstagram);
    // 실패가 아니라 아직 열리지 않았다는 중립 안내다.
    expect(find.text('인스타그램 연동은 곧 열려요.'), findsOneWidget);
    expect(find.text('연동하지 못했어요. 다시 시도해 주세요.'), findsNothing);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    final repo = FakeInstagramRepository()..failFetch = true;
    await _open(tester, repo);

    expect(find.text('인스타그램 연동 상태를 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('인스타그램 연동하기'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _open(tester, FakeInstagramRepository(), smallPhoneLargeText: true);

    expect(tester.takeException(), isNull);
    expect(find.text('인스타그램 연동하기'), findsOneWidget);
  });
}

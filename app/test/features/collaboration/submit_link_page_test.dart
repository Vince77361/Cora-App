import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../store_browse/creator_app_harness.dart';
import 'collaboration_harness.dart';
import 'fake_collaboration_repository.dart';

const _id = 'c0ffee11-aaaa-bbbb-cccc-000000000001';
const _link = 'https://www.instagram.com/reel/abc?views=4320';

Future<FakeCollaborationRepository> _openSubmit(
  WidgetTester tester, {
  CollaborationFailure? fail,
}) async {
  final repo = FakeCollaborationRepository(active: [collaboration()])
    ..failAction = fail;
  await pumpCollaboration(tester, repo: repo, clock: FakeClock());
  await tester.tap(find.text('콘텐츠 링크 제출'));
  await tester.pumpAndSettle();
  expect(topPath(tester), AppRoutes.creatorCollaborationSubmit(_id));
  return repo;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('submits a link and moves to counting', (tester) async {
    final repo = await _openSubmit(tester);

    expect(find.text('올린 콘텐츠의\n링크를 붙여 주세요'), findsOneWidget);
    expect(find.text('콘텐츠 링크'), findsOneWidget);
    expect(find.text('제출한 뒤에는 고칠 수 없어요.'), findsOneWidget);
    // 비어 있으면 제출할 수 없다.
    await tester.tap(find.text('제출하기'));
    await tester.pumpAndSettle();
    expect(repo.submitted, isEmpty);

    await tester.enterText(find.byType(TextField), _link);
    await tester.pump();
    await tester.tap(find.text('제출하기'));
    await tester.pumpAndSettle();

    expect(repo.submitted, [(id: _id, url: _link)]);
    // A7로 돌아오고 집계 중으로 바뀐다.
    expect(topPath(tester), AppRoutes.creatorCollaboration(_id));
    expect(find.text('집계 중이에요 · 7일 남음'), findsOneWidget);
    expect(find.text('4,320회'), findsNothing);
  });

  testWidgets('starts typing when the label of the field is tapped', (
    tester,
  ) async {
    await _openSubmit(tester);

    await tester.tap(find.text('콘텐츠 링크'));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('shows the server message for a link that is not mine', (
    tester,
  ) async {
    final repo = await _openSubmit(
      tester,
      fail: const CollaborationFailure(
        conflict: true,
        message: '내 계정의 게시물만 제출할 수 있어요.',
      ),
    );

    await tester.enterText(find.byType(TextField), _link);
    await tester.pump();
    await tester.tap(find.text('제출하기'));
    await tester.pumpAndSettle();

    expect(find.text('내 계정의 게시물만 제출할 수 있어요.'), findsOneWidget);
    expect(repo.submitted, isEmpty);
    expect(topPath(tester), AppRoutes.creatorCollaborationSubmit(_id));

    // 고쳐서 다시 낼 수 있다(화면이 멈추지 않는다).
    repo.failAction = null;
    await tester.tap(find.text('제출하기'));
    await tester.pumpAndSettle();
    expect(repo.submitted, hasLength(1));
  });

  testWidgets('shows the format message from the server', (tester) async {
    await _openSubmit(
      tester,
      fail: const CollaborationFailure(message: '링크 형식을 확인해 주세요.'),
    );

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    await tester.tap(find.text('제출하기'));
    await tester.pumpAndSettle();

    expect(find.text('링크 형식을 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('shows a generic message when the server gives none', (
    tester,
  ) async {
    await _openSubmit(tester, fail: const CollaborationFailure());

    await tester.enterText(find.byType(TextField), _link);
    await tester.pump();
    await tester.tap(find.text('제출하기'));
    await tester.pumpAndSettle();

    expect(find.text('제출하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });
}

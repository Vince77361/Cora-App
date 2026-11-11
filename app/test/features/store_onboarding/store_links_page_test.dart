import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_edit_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_links_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

Finder _field(SourceLinkKind kind) =>
    find.byKey(ValueKey('storeLinks.${kind.name}'));

VoidCallback? _createAction(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(find.byType(CoraPrimaryButton)).onPressed;

Future<void> _type(
  WidgetTester tester,
  SourceLinkKind kind,
  String text,
) async {
  await tester.enterText(_field(kind), text);
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the canvas copy on the link step', (tester) async {
    await pumpStoreApp(tester);

    expect(currentPath(tester), AppRoutes.storeOnboardingLinks);
    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(find.text('가게 등록'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('가게 링크만 넣으면\n소개 페이지를 만들어 드려요.'), findsOneWidget);
    expect(
      find.text('사진, 메뉴, 영업시간을 링크에서 가져와요. 2개 이상 넣으면 더 정확해요.'),
      findsOneWidget,
    );
    expect(find.text('네이버 지도'), findsOneWidget);
    expect(find.text('캐치테이블'), findsOneWidget);
    expect(find.text('인스타그램 · 선택'), findsOneWidget);
    expect(find.text('가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.'), findsOneWidget);
    expect(find.text('가게 페이지 만들기'), findsOneWidget);
  });

  testWidgets('create button is disabled until one link is entered', (
    tester,
  ) async {
    await pumpStoreApp(tester);
    expect(_createAction(tester), isNull);

    await _type(tester, SourceLinkKind.naverMap, 'naver.me/abc');

    expect(_createAction(tester), isNotNull);
  });

  testWidgets('shows a hint under a link on the wrong host', (tester) async {
    await pumpStoreApp(tester);

    await _type(tester, SourceLinkKind.naverMap, 'https://example.com/shop');
    // 입력 칸을 떠나면(다음 칸으로) 안내가 나온다. 입력하는 도중에는 깜빡이지 않는다.
    expect(find.text('네이버 지도 링크가 맞는지 확인해 주세요.'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(find.text('네이버 지도 링크가 맞는지 확인해 주세요.'), findsOneWidget);
    expect(_createAction(tester), isNull);

    await _type(tester, SourceLinkKind.naverMap, 'https://naver.me/abc');
    expect(find.text('네이버 지도 링크가 맞는지 확인해 주세요.'), findsNothing);
    expect(_createAction(tester), isNotNull);
  });

  testWidgets('hints use the service name of each field', (tester) async {
    await pumpStoreApp(tester);

    await _type(tester, SourceLinkKind.catchtable, 'https://naver.me/abc');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await _type(tester, SourceLinkKind.instagram, 'https://example.com/x');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('캐치테이블 링크가 맞는지 확인해 주세요.'), findsOneWidget);
    expect(find.text('인스타그램 링크가 맞는지 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('goes to the store page after analysis', (tester) async {
    final stores = FakeStoreRepository();
    await pumpStoreApp(tester, stores: stores);

    await _type(tester, SourceLinkKind.naverMap, 'naver.me/abc');
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    // 주소 앞에 https://를 붙여 서버가 받는 모양으로 보낸다.
    expect(stores.analyzed.single.single.url, 'https://naver.me/abc');
    expect(stores.analyzed.single.single.kind, SourceLinkKind.naverMap);
    expect(topPath(tester), AppRoutes.storeOnboardingPage);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('shows the progress label and ignores taps while analyzing', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..holdAnalyze = Completer<void>();
    await pumpStoreApp(tester, stores: stores);

    await _type(tester, SourceLinkKind.naverMap, 'naver.me/abc');
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pump();

    expect(find.text('가게 정보를 가져오는 중이에요'), findsOneWidget);
    expect(find.text('가게 페이지 만들기'), findsNothing);
    expect(_createAction(tester), isNull);
    await tester.tap(find.byType(CoraPrimaryButton), warnIfMissed: false);
    await tester.pump();
    expect(stores.analyzed, hasLength(1));

    stores.holdAnalyze!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
  });

  testWidgets('offers manual entry when analysis fails', (tester) async {
    final stores = FakeStoreRepository()..analysisFails = true;
    await pumpStoreApp(tester, stores: stores);

    await _type(tester, SourceLinkKind.naverMap, 'naver.me/fail');
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(find.text('정보를 가져오지 못했어요. 직접 입력할 수 있어요.'), findsOneWidget);
    expect(find.text('직접 입력하기'), findsOneWidget);

    await tester.tap(find.text('직접 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreEditPage), findsOneWidget);
    expect(find.text('가게 정보 고치기'), findsOneWidget);
  });

  testWidgets('editing a link after a failed analysis brings the button back', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..analysisFails = true;
    await pumpStoreApp(tester, stores: stores);
    await _type(tester, SourceLinkKind.naverMap, 'naver.me/fail');
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    await _type(tester, SourceLinkKind.naverMap, 'naver.me/other');

    expect(find.text('가게 페이지 만들기'), findsOneWidget);
    expect(find.text('직접 입력하기'), findsNothing);
    expect(find.text('가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.'), findsOneWidget);
  });

  testWidgets('keeps the input and says so when the server is unreachable', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..failAnalyze = true;
    await pumpStoreApp(tester, stores: stores);
    await _type(tester, SourceLinkKind.naverMap, 'naver.me/abc');

    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(find.text('서버에 연결하지 못했어요.'), findsOneWidget);
    expect(find.text('naver.me/abc'), findsOneWidget);
    expect(_createAction(tester), isNotNull);
  });

  testWidgets('shows the found summary when coming back from the page', (
    tester,
  ) async {
    await pumpStoreApp(tester, stores: FakeStoreRepository());
    await _type(tester, SourceLinkKind.naverMap, 'naver.me/abc');
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(find.text('네이버 지도 찾음'), findsOneWidget);
    expect(find.text('naver.me/abc'), findsOneWidget);
  });

  testWidgets('no summary shows once the link text is changed', (tester) async {
    final stores = FakeStoreRepository(store: sampleStore());
    await pumpStoreApp(tester, stores: stores);
    // 가게가 있으면 진입이 가게 페이지다. A2는 그 위가 아니라 뒤로 가기로 연다.
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('사진 12장, 메뉴 8개 찾음'), findsOneWidget);

    await _type(tester, SourceLinkKind.naverMap, 'naver.me/changed');

    expect(find.text('사진 12장, 메뉴 8개 찾음'), findsNothing);
  });

  testWidgets('uses the canvas colors in light and dark', (tester) async {
    Color? boxColor() =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .ancestor(
                            of: find.text('네이버 지도'),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color;

    await pumpStoreApp(tester);
    expect(boxColor(), CoraColors.light.surface);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(boxColor(), CoraColors.dark.surface);
  });
}

import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
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
    final semantics = tester.ensureSemantics();
    await pumpStoreApp(tester);

    expect(currentPath(tester), AppRoutes.storeOnboardingLinks);
    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(find.text('가게 등록'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^가게 등록')), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('가게 링크 하나면 돼요.'), findsOneWidget);
    expect(
      find.text(
        '네이버 지도, 캐치테이블, 인스타그램, 체험단 후기 글 중 무엇이든 괜찮아요. 가입 없이 먼저 볼 수 있어요.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        '가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('링크가 없거나 안 열리면 직접 입력', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('가게 페이지 만들기'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'A2 shows the four link fields in canvas order and the new wording',
    (tester) async {
      await pumpStoreApp(tester);

      final labels = [
        '네이버 지도',
        '캐치테이블',
        '체험단 후기 글 · 선택 · 인스타 게시물로 바꿔 드려요',
        '인스타그램 · 선택',
      ];
      final tops = [
        for (final label in labels) tester.getTopLeft(find.text(label)).dy,
      ];
      expect([...tops]..sort(), tops);
      expect(tops.toSet(), hasLength(4));
      expect(find.text('blog.naver.com/[후기 글]'), findsOneWidget);
      expect(find.text('instagram.com/가게계정'), findsOneWidget);
    },
  );

  testWidgets('A2 enables the button with a single link', (tester) async {
    await pumpStoreApp(tester);
    expect(_createAction(tester), isNull);

    await _type(tester, SourceLinkKind.catchtable, 'app.catchtable.co.kr/abc');

    expect(_createAction(tester), isNotNull);
  });

  testWidgets('A2 accepts a naver blog url as a review post', (tester) async {
    final stores = FakeStoreRepository();
    await pumpStoreApp(tester, stores: stores);

    await _type(tester, SourceLinkKind.reviewPost, 'blog.naver.com/shop/123');
    expect(_createAction(tester), isNotNull);
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(stores.analyzed.single.single.kind, SourceLinkKind.reviewPost);
    expect(
      stores.analyzed.single.single.url,
      'https://blog.naver.com/shop/123',
    );
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
  });

  testWidgets('A2 rejects a review post on another host', (tester) async {
    await pumpStoreApp(tester);

    await _type(tester, SourceLinkKind.reviewPost, 'https://example.com/post');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(find.text('체험단 후기 글 링크가 맞는지 확인해 주세요.'), findsOneWidget);
    expect(_createAction(tester), isNull);
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

  testWidgets('keeps the input and says so when the server is unreachable', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..failAnalyze = true;
    await pumpStoreApp(tester, stores: stores);
    await _type(tester, SourceLinkKind.naverMap, 'naver.me/abc');

    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreLinksPage), findsOneWidget);
    expect(
      find.textContaining('서버에 연결하지 못했어요.', findRichText: true),
      findsOneWidget,
    );
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

  testWidgets('underlines the manual entry link with the text color', (
    tester,
  ) async {
    TextSpan link() {
      final rich = tester.widget<RichText>(
        find.textContaining('링크가 없거나 안 열리면 직접 입력', findRichText: true),
      );
      TextSpan? found;
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text == '링크가 없거나 안 열리면 직접 입력') {
          found = span;
        }
        return true;
      });
      return found!;
    }

    await pumpStoreApp(tester);
    expect(link().style?.decoration, TextDecoration.underline);
    expect(link().style?.decorationColor, CoraColors.light.text);
    expect(CoraColors.light.text, const Color(0xFF17181C));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    expect(link().style?.decoration, TextDecoration.underline);
    expect(link().style?.decorationColor, CoraColors.dark.text);
    expect(CoraColors.dark.text, const Color(0xFFF2F3F5));
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

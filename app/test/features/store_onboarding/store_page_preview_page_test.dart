import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_secondary_button.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_edit_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_share_launcher.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

Future<FakeStoreRepository> _pumpPage(
  WidgetTester tester, [
  FakeStoreRepository? stores,
  FakeShareLauncher? share,
]) async {
  final repo = stores ?? FakeStoreRepository(store: sampleStore());
  await pumpStoreApp(tester, stores: repo, share: share);
  return repo;
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

/// 공유 글자(`공유`)의 불투명도. 켜지면 1, 등록 중이면 흐리다.
double _shareOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text('공유'), matching: find.byType(Opacity)).first,
    )
    .opacity;

MyStore _published({String? publicUrl = 'cora.page/l/hangeureut-ramen'}) =>
    sampleStore(
      status: StoreStatus.published,
      step: StoreOnboardingStep.done,
      publicUrl: publicUrl,
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('resumes on the store page for a store saved at PAGE', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(currentPath(tester), AppRoutes.storeOnboardingPage);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
  });

  testWidgets('shows the canvas copy and the auto-filled values', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(find.text('가게 등록'), findsNothing);
    expect(find.bySemanticsLabel('가게 등록'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('링크에서 자동으로 만들었어요'), findsOneWidget);
    expect(find.text('라멘집, 성수동'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    for (final label in ['대표 메뉴', '영업시간', '좌석', '찍기 좋은 시간']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('돈코츠 라멘 11,000원'), findsOneWidget);
    expect(find.text('11:30 – 21:00'), findsOneWidget);
    expect(find.text('18석, 바 좌석'), findsOneWidget);
    expect(find.text('오후 3시 – 5시'), findsOneWidget);
    expect(find.text('이런 가게가 맞나요? · 탭해서 고치기'), findsOneWidget);
    expect(find.text('고치기'), findsOneWidget);
    // 옛 버튼과 옛 소개 상자의 제목은 없다.
    expect(find.text('정보 고치기'), findsNothing);
    expect(find.text('이대로 다음'), findsNothing);
    expect(find.text('크리에이터에게 보여줄 소개'), findsNothing);
    expect(find.text('업종 분류'), findsNothing);
  });

  testWidgets('shows "아직 없어요" for empty fields', (tester) async {
    final store = MyStore(
      id: 'store-1',
      status: StoreStatus.draft,
      onboardingStep: StoreOnboardingStep.page,
      industry: IndustryCategory.foodCafe,
      name: '한그릇 라멘',
      regionSido: '서울특별시',
    );
    await _pumpPage(tester, FakeStoreRepository(store: store));

    expect(find.text('아직 없어요'), findsNWidgets(4));
  });

  testWidgets('has no auto-filled chip when the analysis read nothing', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore(sourceLinks: const [])),
    );
    expect(find.text('링크에서 자동으로 만들었어요'), findsNothing);
  });

  testWidgets(
    'A3 shows the public address and keeps share off until published',
    (tester) async {
      final share = FakeShareLauncher();
      await _pumpPage(tester, null, share);

      expect(
        find.textContaining(
          'cora.page/l/hangeureut-ramen · 공개 페이지',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('공유'), findsOneWidget);
      expect(_shareOpacity(tester), lessThan(1));

      await tester.tap(find.text('공유'));
      await tester.pumpAndSettle();
      expect(share.shared, isEmpty);
    },
  );

  testWidgets('A3 hides the address row while the store has no name yet', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore(name: null, publicUrl: null)),
    );

    expect(find.text('공유'), findsNothing);
    expect(find.textContaining('공개 페이지', findRichText: true), findsNWidgets(1));
  });

  testWidgets('A3 shares the public address of a published store', (
    tester,
  ) async {
    final share = FakeShareLauncher();
    await _pumpPage(tester, FakeStoreRepository(store: _published()), share);
    routerOf(tester).push(AppRoutes.storePage);
    await tester.pumpAndSettle();

    expect(_shareOpacity(tester), 1);
    await tester.tap(find.text('공유'));
    await tester.pumpAndSettle();

    expect(share.shared, ['https://cora.page/l/hangeureut-ramen']);
  });

  testWidgets('A3 does not break when the share sheet cannot open', (
    tester,
  ) async {
    final share = FakeShareLauncher()..fail = true;
    await _pumpPage(tester, FakeStoreRepository(store: _published()), share);
    routerOf(tester).push(AppRoutes.storePage);
    await tester.pumpAndSettle();

    await tester.tap(find.text('공유'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
  });

  testWidgets('A3 writes the tags and customer phrases in one line', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(
      find.text(
        '#진한국물 #바좌석 #조용한오후 · 손님들이 자주 한 말: “국물이 진해요”, “혼밥하기 좋아요”. 공개 페이지에는 크리에이터 지원하기 버튼이 보여요.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'A3 leaves only the sentence when the store has no tags or phrases',
    (tester) async {
      await _pumpPage(
        tester,
        FakeStoreRepository(
          store: sampleStore(tags: const [], customerPhrases: const []),
        ),
      );

      expect(find.text('공개 페이지에는 크리에이터 지원하기 버튼이 보여요.'), findsOneWidget);
    },
  );

  testWidgets('A3 writes only what the store has when one of them is missing', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore(customerPhrases: const [])),
    );
    expect(
      find.text('#진한국물 #바좌석 #조용한오후. 공개 페이지에는 크리에이터 지원하기 버튼이 보여요.'),
      findsOneWidget,
    );
  });

  testWidgets('A3 edits a field in place from its row', (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.text('영업시간'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOnboardingEdit);
    expect(find.byType(StoreEditPage), findsOneWidget);
    final hours = tester.widget<TextField>(
      find.byKey(const ValueKey('storeEdit.hours')),
    );
    expect(hours.focusNode!.hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('뒤로').last);
    await tester.pumpAndSettle();
    expect(find.byType(StoreEditPage), findsNothing);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
  });

  testWidgets('A3 opens each of the four rows with the cursor in that field', (
    tester,
  ) async {
    const rows = {
      '대표 메뉴': 'signatureMenu',
      '좌석': 'seats',
      '찍기 좋은 시간': 'bestShootingTime',
    };
    for (final row in rows.entries) {
      await _pumpPage(tester);
      await tester.tap(find.text(row.key));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(ValueKey('storeEdit.${row.value}')),
      );
      expect(field.focusNode!.hasFocus, isTrue, reason: row.key);
    }
  });

  testWidgets('A3 edits the tags, phrases and recruit line in a sheet', (
    tester,
  ) async {
    final stores = await _pumpPage(tester);

    await tester.tap(find.text('고치기'));
    await tester.pumpAndSettle();

    expect(find.text('이런 가게가 맞나요?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('tagsSheet.tags')),
      '#진한국물, 혼밥 #진한국물',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tagsSheet.phrases')),
      '국물이 진해요\n\n 혼밥하기 좋아요 ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tagsSheet.recruitLine')),
      '조용한 오후에 찍어 주세요',
    );
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final edit = stores.edits.single;
    expect(edit.tags, ['진한국물', '혼밥']);
    expect(edit.customerPhrases, ['국물이 진해요', '혼밥하기 좋아요']);
    expect(edit.recruitLine, '조용한 오후에 찍어 주세요');
    expect(find.text('이런 가게가 맞나요?'), findsNothing);
    expect(
      find.textContaining('#진한국물 #혼밥 · 손님들이 자주 한 말', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('A3 opens the same sheet from the whole intro box', (
    tester,
  ) async {
    await _pumpPage(tester);

    await tester.tap(find.textContaining('#진한국물'));
    await tester.pumpAndSettle();

    expect(find.text('이런 가게가 맞나요?'), findsOneWidget);
  });

  testWidgets('A3 sheet blocks too many tags or too long phrases', (
    tester,
  ) async {
    await _pumpPage(tester);
    await tester.tap(find.text('고치기'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('tagsSheet.tags')),
      '가 나 다 라 마 바',
    );
    await tester.pump();
    expect(find.text('꼬리표는 5개까지, 하나에 10자까지 쓸 수 있어요.'), findsOneWidget);
    expect(
      tester
          .widget<CoraPrimaryButton>(
            find.widgetWithText(CoraPrimaryButton, '저장'),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const ValueKey('tagsSheet.tags')), '가 나');
    await tester.enterText(
      find.byKey(const ValueKey('tagsSheet.phrases')),
      '스물한 글자가 넘는 아주아주아주아주 긴 손님 문구예요',
    );
    await tester.pump();
    expect(find.text('자주 한 말은 3개까지, 하나에 20자까지 쓸 수 있어요.'), findsOneWidget);
  });

  testWidgets('A3 sheet says so and keeps the values when saving fails', (
    tester,
  ) async {
    final stores = FakeStoreRepository(store: sampleStore())..failUpdate = true;
    await _pumpPage(tester, stores);
    await tester.tap(find.text('고치기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('tagsSheet.recruitLine')),
      '한 줄',
    );
    await tester.pump();

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('한 줄'), findsOneWidget);
  });

  testWidgets('A3 offers AI drafts and creator recruiting', (tester) async {
    await _pumpPage(tester);

    expect(find.text('AI로 직접 제작'), findsOneWidget);
    expect(find.text('크리에이터 모집'), findsOneWidget);
    expect(find.byType(CoraSecondaryButton), findsOneWidget);
    expect(find.byType(CoraPrimaryButton), findsOneWidget);
  });

  testWidgets('"AI로 직접 제작" moves the saved step to drafts and opens A4', (
    tester,
  ) async {
    final stores = await _pumpPage(tester);

    await tester.tap(find.text('AI로 직접 제작'));
    await tester.pumpAndSettle();

    expect(stores.advanced, [StoreOnboardingStep.drafts]);
    expect(topPath(tester), AppRoutes.storeOnboardingDrafts);
  });

  testWidgets('"크리에이터 모집" moves the saved step to terms and opens it', (
    tester,
  ) async {
    final stores = await _pumpPage(tester);

    await tester.tap(find.text('크리에이터 모집'));
    await tester.pumpAndSettle();

    expect(stores.advanced, [StoreOnboardingStep.terms]);
    expect(topPath(tester), AppRoutes.storeOnboardingTerms);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('stays on the page and says so when saving the step fails', (
    tester,
  ) async {
    final stores = await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore())..failAdvance = true,
    );

    await tester.tap(find.text('크리에이터 모집'));
    await tester.pumpAndSettle();

    expect(stores.advanced, [StoreOnboardingStep.terms]);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  for (final label in ['AI로 직접 제작', '크리에이터 모집']) {
    testWidgets('"$label" without a name says so and opens the edit sheet', (
      tester,
    ) async {
      final stores = await _pumpPage(
        tester,
        FakeStoreRepository(store: sampleStore(name: null)),
      );
      expect(find.text('가게 이름을 넣어 주세요.'), findsNothing);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(stores.advanced, isEmpty);
      expect(topPath(tester), AppRoutes.storeOnboardingEdit);
      await tester.tap(find.bySemanticsLabel('뒤로').last);
      await tester.pumpAndSettle();
      expect(find.text('가게 이름을 넣어 주세요.'), findsOneWidget);
    });

    testWidgets('"$label" without a region says so and opens the edit sheet', (
      tester,
    ) async {
      final stores = await _pumpPage(
        tester,
        FakeStoreRepository(store: sampleStore(regionSido: null)),
      );

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(stores.advanced, isEmpty);
      expect(topPath(tester), AppRoutes.storeOnboardingEdit);
      await tester.tap(find.bySemanticsLabel('뒤로').last);
      await tester.pumpAndSettle();
      expect(find.text('가게 지역을 골라 주세요.'), findsOneWidget);
      expect(find.text('가게 이름을 넣어 주세요.'), findsNothing);
    });
  }

  testWidgets('the owner-home store page has the same page without the step', (
    tester,
  ) async {
    final stores = FakeStoreRepository(store: _published());
    await _pumpPage(tester, stores);
    routerOf(tester).push(AppRoutes.storePage);
    await tester.pumpAndSettle();

    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    expect(find.text('2 / 3'), findsNothing);
    expect(find.text('AI로 직접 제작'), findsOneWidget);

    await tester.tap(find.text('AI로 직접 제작'));
    await tester.pumpAndSettle();
    // 공개된 가게는 등록 단계를 다시 올리지 않는다.
    expect(stores.advanced, isEmpty);
    expect(topPath(tester), AppRoutes.storeDrafts);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpPage(tester);

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('고치기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the canvas colors in light and dark', (tester) async {
    await _pumpPage(tester);
    final light = CoraColors.light;
    expect(_textColor(tester, '고치기'), light.onSoftAction);
    expect(_textColor(tester, '대표 메뉴'), light.textSecondary);
    expect(light.subtleAction, const Color(0xFFF2F3F5));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    final dark = CoraColors.dark;
    expect(_textColor(tester, '고치기'), dark.onSoftAction);
    expect(dark.onSoftAction, const Color(0xFFE4FFB0));
    expect(_textColor(tester, '대표 메뉴'), dark.textSecondary);
    expect(dark.subtleAction, const Color(0xFF2A2D33));
    expect(_textColor(tester, 'AI로 직접 제작'), dark.onSubtleAction);
  });
}

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_edit_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

Future<FakeStoreRepository> _pumpPage(
  WidgetTester tester, [
  FakeStoreRepository? stores,
]) async {
  final repo = stores ?? FakeStoreRepository(store: sampleStore());
  await pumpStoreApp(tester, stores: repo);
  return repo;
}

VoidCallback? _nextAction(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(find.byType(CoraPrimaryButton)).onPressed;

Color? _textColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

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

    expect(find.text('가게 등록'), findsOneWidget);
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
    expect(find.text('업종 분류'), findsOneWidget);
    expect(find.text('맛집·카페'), findsOneWidget);
    expect(find.text('서울특별시 성동구'), findsOneWidget);
    expect(find.text('크리에이터에게 보여줄 소개'), findsOneWidget);
    expect(find.text('고치기'), findsOneWidget);
    expect(find.text('정보 고치기'), findsOneWidget);
    expect(find.text('이대로 다음'), findsOneWidget);
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

    // 대표 메뉴·영업시간·좌석·찍기 좋은 시간 네 칸과 소개 글.
    expect(find.text('아직 없어요'), findsNWidgets(5));
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

  testWidgets('blocks next when the store name is empty', (tester) async {
    await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore(name: null)),
    );

    expect(find.text('가게 이름을 넣어 주세요.'), findsOneWidget);
    expect(_nextAction(tester), isNull);
  });

  testWidgets('blocks next when the store region is empty', (tester) async {
    await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore(regionSido: null)),
    );

    expect(find.text('가게 지역을 골라 주세요.'), findsOneWidget);
    expect(find.text('가게 이름을 넣어 주세요.'), findsNothing);
    expect(_nextAction(tester), isNull);
  });

  testWidgets('moves the saved step to drafts on next', (tester) async {
    final stores = await _pumpPage(tester);

    await tester.tap(find.text('이대로 다음'));
    await tester.pumpAndSettle();

    expect(stores.advanced, [StoreOnboardingStep.drafts]);
    expect(topPath(tester), AppRoutes.storeOnboardingDrafts);
  });

  testWidgets('stays on the page and says so when saving the step fails', (
    tester,
  ) async {
    final stores = await _pumpPage(
      tester,
      FakeStoreRepository(store: sampleStore())..failAdvance = true,
    );

    await tester.tap(find.text('이대로 다음'));
    await tester.pumpAndSettle();

    expect(stores.advanced, [StoreOnboardingStep.drafts]);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(_nextAction(tester), isNotNull);
  });

  testWidgets('"정보 고치기" opens the edit sheet and back returns', (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.text('정보 고치기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOnboardingEdit);
    expect(find.byType(StoreEditPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('뒤로').last);
    await tester.pumpAndSettle();
    expect(find.byType(StoreEditPage), findsNothing);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
  });

  testWidgets('"고치기" opens the edit sheet with the cursor in the intro', (
    tester,
  ) async {
    await _pumpPage(tester);

    await tester.tap(find.text('고치기'));
    await tester.pumpAndSettle();

    final intro = tester.widget<TextField>(
      find.byKey(const ValueKey('storeEdit.intro')),
    );
    expect(intro.focusNode!.hasFocus, isTrue);
  });

  testWidgets('uses the canvas colors in light and dark', (tester) async {
    await _pumpPage(tester);
    final light = CoraColors.light;
    expect(_textColor(tester, '고치기'), light.onSoftAction);
    expect(_textColor(tester, '대표 메뉴'), light.textSecondary);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    final dark = CoraColors.dark;
    expect(_textColor(tester, '고치기'), dark.onSoftAction);
    expect(dark.onSoftAction, const Color(0xFFE4FFB0));
    expect(_textColor(tester, '대표 메뉴'), dark.textSecondary);
  });
}

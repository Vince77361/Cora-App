import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_secondary_button.dart';
import 'package:cora/features/store_onboarding/domain/content_draft.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/pages/content_drafts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_content_draft_repository.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

Future<({FakeStoreRepository stores, FakeContentDraftRepository drafts})>
_pumpDrafts(
  WidgetTester tester, {
  FakeContentDraftRepository? drafts,
  MyStore? store,
}) async {
  final stores = FakeStoreRepository(
    store: store ?? sampleStore(step: StoreOnboardingStep.drafts),
  );
  final repo = drafts ?? FakeContentDraftRepository();
  await pumpStoreApp(tester, stores: stores, drafts: repo);
  return (stores: stores, drafts: repo);
}

VoidCallback? _regenerateAction(WidgetTester tester) => tester
    .widget<CoraSecondaryButton>(find.byType(CoraSecondaryButton))
    .onPressed;

Color? _tabColor(WidgetTester tester, String label) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    ),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration)
        .color;

Color? _fill(WidgetTester tester, Finder inside) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(of: inside, matching: find.byType(DecoratedBox))
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('resumes on the drafts step for a store saved at DRAFTS', (
    tester,
  ) async {
    await _pumpDrafts(tester);

    expect(currentPath(tester), AppRoutes.storeOnboardingDrafts);
    expect(find.byType(ContentDraftsPage), findsOneWidget);
  });

  testWidgets('opens from the store page and shows 3 / 3', (tester) async {
    await pumpStoreApp(
      tester,
      stores: FakeStoreRepository(store: sampleStore()),
    );

    await tester.tap(find.text('이대로 다음'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOnboardingDrafts);
    expect(find.byType(ContentDraftsPage), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('shows the canvas copy with the card news tab first', (
    tester,
  ) async {
    await _pumpDrafts(tester);

    expect(find.text('가게 등록'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('가게 계정에 올릴\n초안도 만들었어요.'), findsOneWidget);
    expect(
      find.text('가게 페이지 정보로 AI가 썼어요. 그대로 올려도, 고쳐서 올려도 돼요.'),
      findsOneWidget,
    );
    expect(find.text('카드뉴스'), findsOneWidget);
    expect(find.text('릴스 대본'), findsOneWidget);
    expect(find.text('블로그 글'), findsOneWidget);
    expect(find.text('12시간 끓인\n국물 한 그릇'), findsOneWidget);
    expect(find.text('본문'), findsOneWidget);
    expect(find.textContaining('성수동 골목 안'), findsOneWidget);
    expect(find.text('복사'), findsOneWidget);
    expect(find.text('다시 만들기'), findsOneWidget);
    expect(find.text('저장하고 오퍼 만들기'), findsOneWidget);
  });

  testWidgets('switches the slides and body with the tab', (tester) async {
    await _pumpDrafts(tester);

    await tester.tap(find.text('릴스 대본'));
    await tester.pumpAndSettle();

    expect(find.text('촬영 순서'), findsOneWidget);
    expect(find.text('김이 오르는\n첫 숟가락'), findsOneWidget);
    expect(find.text('본문'), findsNothing);
  });

  testWidgets('regenerates only the visible draft tab', (tester) async {
    final env = await _pumpDrafts(tester);

    await tester.tap(find.text('릴스 대본'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 만들기'));
    await tester.pumpAndSettle();

    expect(env.drafts.regenerated, [ContentDraftKind.reelsScript]);
    expect(find.textContaining('다시 만듦 1'), findsOneWidget);
    // 다른 탭은 그대로다.
    await tester.tap(find.text('카드뉴스'));
    await tester.pumpAndSettle();
    expect(find.textContaining('다시 만듦'), findsNothing);
    expect(find.text('복사'), findsOneWidget);
  });

  testWidgets('disables regenerate when none are left today', (tester) async {
    await _pumpDrafts(
      tester,
      drafts: FakeContentDraftRepository(drafts: sampleDrafts(left: 0)),
    );

    expect(find.text('오늘은 더 만들 수 없어요.'), findsOneWidget);
    expect(_regenerateAction(tester), isNull);
  });

  testWidgets('locks regenerate when the server says the limit is reached', (
    tester,
  ) async {
    final env = await _pumpDrafts(
      tester,
      drafts: FakeContentDraftRepository()..limitReached = true,
    );
    expect(find.text('오늘은 더 만들 수 없어요.'), findsNothing);

    await tester.tap(find.text('다시 만들기'));
    await tester.pumpAndSettle();

    expect(env.drafts.regenerated, [ContentDraftKind.cardNews]);
    expect(find.text('오늘은 더 만들 수 없어요.'), findsOneWidget);
    expect(_regenerateAction(tester), isNull);
  });

  testWidgets('keeps the draft and says so when regenerating fails', (
    tester,
  ) async {
    await _pumpDrafts(
      tester,
      drafts: FakeContentDraftRepository()..failRegenerate = true,
    );

    await tester.tap(find.text('다시 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('다시 만들지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('성수동 골목 안'), findsOneWidget);
    expect(_regenerateAction(tester), isNotNull);
  });

  testWidgets('copies the body text', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpDrafts(tester);

    await tester.tap(find.text('복사'));
    await tester.pump();

    expect(copied, sampleDrafts().first.body);
    expect(find.text('복사했어요.'), findsOneWidget);
    await tester.pump(ContentDraftsPage.copiedFor);
    expect(find.text('복사했어요.'), findsNothing);
    expect(find.text('복사'), findsOneWidget);
  });

  testWidgets('"저장하고 오퍼 만들기" moves the step to terms and opens it', (
    tester,
  ) async {
    final env = await _pumpDrafts(tester);

    await tester.tap(find.text('저장하고 오퍼 만들기'));
    await tester.pumpAndSettle();

    expect(env.stores.advanced, [StoreOnboardingStep.terms]);
    expect(topPath(tester), AppRoutes.storeOnboardingTerms);
  });

  testWidgets('stays and says so when saving the step fails', (tester) async {
    final env = await _pumpDrafts(tester);
    env.stores.failAdvance = true;

    await tester.tap(find.text('저장하고 오퍼 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(ContentDraftsPage), findsOneWidget);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('shows a retry when the drafts cannot be loaded', (tester) async {
    final drafts = FakeContentDraftRepository()..failFetch = true;
    await _pumpDrafts(tester, drafts: drafts);

    expect(find.text('초안을 불러오지 못했어요.'), findsOneWidget);
    drafts.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('카드뉴스'), findsOneWidget);
  });

  testWidgets('shows a waiting line while the drafts are written', (
    tester,
  ) async {
    final drafts = FakeContentDraftRepository()..holdFetch = Completer<void>();
    await _pumpDrafts(tester, drafts: drafts);

    expect(find.text('AI가 초안을 쓰는 중이에요.'), findsOneWidget);
    drafts.holdFetch!.complete();
    await tester.pumpAndSettle();
    expect(find.text('카드뉴스'), findsOneWidget);
  });

  testWidgets('the drafts opened from the owner home drop the step and CTA', (
    tester,
  ) async {
    await pumpStoreApp(
      tester,
      stores: FakeStoreRepository(
        store: sampleStore(
          status: StoreStatus.published,
          step: StoreOnboardingStep.done,
        ),
      ),
    );
    routerOf(tester).push(AppRoutes.storeDrafts);
    await tester.pumpAndSettle();

    expect(find.byType(ContentDraftsPage), findsOneWidget);
    expect(find.text('3 / 3'), findsNothing);
    expect(find.text('저장하고 오퍼 만들기'), findsNothing);
    expect(find.text('다시 만들기'), findsOneWidget);
    expect(find.text('카드뉴스'), findsOneWidget);
  });

  // 캔버스: 사진 없는 슬라이드의 톤은 (장면 번호 + 다시 만든 횟수) % 2로 고른다.
  testWidgets('uses the canvas tab and slide colors in light and dark', (
    tester,
  ) async {
    const menu = '대표 메뉴\n돈코츠 라멘\n11,000원';
    const quiet = '줄 없는 시간\n오후 3시 – 5시';
    await _pumpDrafts(tester);
    // 세 번째 장면은 가로 목록 밖이라 밀어서 연다.
    await tester.drag(
      find.byKey(const ValueKey('drafts.slides.cardNews')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(_tabColor(tester, '카드뉴스'), const Color(0xFFE3E5E9));
    expect(_tabColor(tester, '릴스 대본'), const Color(0xFFF8F9FA));
    expect(_fill(tester, find.text(menu)), const Color(0xFFF8F9FA));
    expect(_fill(tester, find.text(quiet)), const Color(0xFFF3FFD6));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    expect(_tabColor(tester, '카드뉴스'), const Color(0xFFF2F3F5));
    expect(_tabColor(tester, '릴스 대본'), const Color(0xFF1C1E22));
    expect(
      tester.renderObject<RenderParagraph>(find.text('카드뉴스')).text.style?.color,
      const Color(0xFF0F1012),
    );
    expect(_fill(tester, find.text(menu)), const Color(0xFFF2F3F5));
    expect(_fill(tester, find.text(quiet)), const Color(0xFFF3FFD6));
    // 사진 장면의 글자는 다크에서 #0F1012다(캔버스 그대로).
    await tester.drag(
      find.byKey(const ValueKey('drafts.slides.cardNews')),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('12시간 끓인\n국물 한 그릇'))
          .text
          .style
          ?.color,
      const Color(0xFF0F1012),
    );
  });

  testWidgets('swaps the slide tones each time a draft is regenerated', (
    tester,
  ) async {
    const menu = '대표 메뉴\n돈코츠 라멘\n11,000원';
    await _pumpDrafts(tester);
    expect(_fill(tester, find.text(menu)), const Color(0xFFF8F9FA));

    await tester.tap(find.text('다시 만들기'));
    await tester.pumpAndSettle();

    expect(_fill(tester, find.text(menu)), const Color(0xFFF3FFD6));
  });
}

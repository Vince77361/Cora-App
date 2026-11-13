import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_secondary_button.dart';
import 'package:cora/core/ui/cora_coming_soon_page.dart';
import 'package:cora/features/store_home/presentation/pages/store_home_page.dart';
import 'package:cora/features/store_home/presentation/viewmodels/store_home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// 설명 끝의 `다시 만들기` 구간.
FinderBase<TextRangeContext> _regenerate() =>
    find.textRange.ofSubstring('다시 만들기');

Future<void> _tapRegenerate(WidgetTester tester) =>
    tester.tapOnText(_regenerate());

/// `다시 만들기`는 글 안의 한 구간이라, 누를 수 있는지는 그 구간의 눌림 처리기로 본다.
bool _canRegenerate(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.textContaining('다시 만들기', findRichText: true),
  );
  TextSpan? action;
  rich.text.visitChildren((span) {
    if (span is TextSpan && span.text == '다시 만들기') action = span;
    return true;
  });
  return action!.recognizer != null;
}

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

    await tester.tap(find.text('AI로 직접 제작'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOnboardingDrafts);
    expect(find.byType(ContentDraftsPage), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('shows the canvas copy with the card news tab first', (
    tester,
  ) async {
    await _pumpDrafts(tester);

    expect(find.text('가게 등록'), findsNothing);
    expect(find.bySemanticsLabel('가게 등록'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('가게 계정에 올릴\n초안도 만들었어요.'), findsOneWidget);
    expect(
      find.textContaining(
        '가게 페이지 정보로 AI가 썼어요. 그대로 올려도, 고쳐서 올려도 돼요. 다시 만들기',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('카드뉴스'), findsOneWidget);
    expect(find.text('릴스 대본'), findsOneWidget);
    expect(find.text('블로그 글'), findsOneWidget);
    expect(find.text('12시간 끓인\n국물 한 그릇'), findsOneWidget);
    expect(find.text('본문'), findsOneWidget);
    expect(find.textContaining('성수동 골목 안'), findsOneWidget);
    expect(find.text('복사'), findsOneWidget);
    expect(find.text('가게 계정에 올리기'), findsOneWidget);
    expect(find.text('오퍼 만들기'), findsOneWidget);
    // 옛 `저장하고 오퍼 만들기`와 아래 `다시 만들기` 버튼은 없다.
    expect(find.text('저장하고 오퍼 만들기'), findsNothing);
    expect(find.byType(CoraSecondaryButton), findsOneWidget);
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
    await _tapRegenerate(tester);
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
    expect(_canRegenerate(tester), isFalse);
  });

  testWidgets('locks regenerate when the server says the limit is reached', (
    tester,
  ) async {
    final env = await _pumpDrafts(
      tester,
      drafts: FakeContentDraftRepository()..limitReached = true,
    );
    expect(find.text('오늘은 더 만들 수 없어요.'), findsNothing);

    await _tapRegenerate(tester);
    await tester.pumpAndSettle();

    expect(env.drafts.regenerated, [ContentDraftKind.cardNews]);
    expect(find.text('오늘은 더 만들 수 없어요.'), findsOneWidget);
    expect(_canRegenerate(tester), isFalse);
  });

  testWidgets('keeps the draft and says so when regenerating fails', (
    tester,
  ) async {
    await _pumpDrafts(
      tester,
      drafts: FakeContentDraftRepository()..failRegenerate = true,
    );

    await _tapRegenerate(tester);
    await tester.pumpAndSettle();

    expect(find.text('다시 만들지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('성수동 골목 안'), findsOneWidget);
    expect(_canRegenerate(tester), isTrue);
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

  testWidgets('A4 leads to the recruit terms during onboarding', (
    tester,
  ) async {
    final env = await _pumpDrafts(tester);

    await tester.tap(find.text('오퍼 만들기'));
    await tester.pumpAndSettle();

    expect(env.stores.advanced, [StoreOnboardingStep.terms]);
    expect(topPath(tester), AppRoutes.storeOnboardingTerms);
  });

  testWidgets('stays and says so when saving the step fails', (tester) async {
    final env = await _pumpDrafts(tester);
    env.stores.failAdvance = true;

    await tester.tap(find.text('오퍼 만들기'));
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

  testWidgets(
    'can still go on to the terms step when the drafts fail to load',
    (tester) async {
      final env = await _pumpDrafts(
        tester,
        drafts: FakeContentDraftRepository()..failFetch = true,
      );

      expect(find.text('초안을 불러오지 못했어요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('오퍼 만들기'), findsOneWidget);

      await tester.tap(find.text('오퍼 만들기'));
      await tester.pumpAndSettle();

      expect(env.stores.advanced, [StoreOnboardingStep.terms]);
      expect(topPath(tester), AppRoutes.storeOnboardingTerms);
    },
  );

  testWidgets('"가게 계정에 올리기" opens the coming-soon page', (tester) async {
    await _pumpDrafts(tester);

    await tester.tap(find.text('가게 계정에 올리기'));
    await tester.pumpAndSettle();

    expect(find.byType(CoraComingSoonPage), findsOneWidget);
    expect(find.text('가게 계정에 올리기'), findsOneWidget);
    expect(find.text('준비 중이에요.'), findsOneWidget);
  });

  testWidgets(
    'the home-opened drafts have the offer button even when they fail',
    (tester) async {
      await pumpStoreApp(
        tester,
        stores: FakeStoreRepository(
          store: sampleStore(
            status: StoreStatus.published,
            step: StoreOnboardingStep.done,
          ),
        ),
        drafts: FakeContentDraftRepository()..failFetch = true,
      );
      routerOf(tester).push(AppRoutes.storeDrafts);
      await tester.pumpAndSettle();

      expect(find.text('초안을 불러오지 못했어요.'), findsOneWidget);
      expect(find.text('오퍼 만들기'), findsOneWidget);
    },
  );

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

  testWidgets('the drafts opened from the owner home drop the step', (
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
    expect(find.text('오퍼 만들기'), findsOneWidget);
    expect(find.textContaining('다시 만들기', findRichText: true), findsOneWidget);
    expect(find.text('카드뉴스'), findsOneWidget);
  });

  testWidgets('"오퍼 만들기" on the owner home drafts opens the applicants tab', (
    tester,
  ) async {
    final stores = FakeStoreRepository(
      store: sampleStore(
        status: StoreStatus.published,
        step: StoreOnboardingStep.done,
      ),
    );
    await pumpStoreApp(tester, stores: stores);
    routerOf(tester).push(AppRoutes.storeDrafts);
    await tester.pumpAndSettle();

    await tester.tap(find.text('오퍼 만들기'));
    await tester.pumpAndSettle();

    // 공개된 가게는 등록 단계를 다시 올리지 않고 사장님 홈의 지원자 탭으로 간다.
    expect(stores.advanced, isEmpty);
    expect(find.byType(StoreHomePage), findsOneWidget);
    expect(find.byType(ContentDraftsPage), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StoreHomePage)),
    );
    expect(
      container.read(storeHomeViewModelProvider).value?.tab,
      StoreHomeTab.applicants,
    );
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

    expect(_tabColor(tester, '카드뉴스'), const Color(0xFF33363D));
    expect(_tabColor(tester, '릴스 대본'), const Color(0xFF1C1E22));
    expect(
      tester.renderObject<RenderParagraph>(find.text('카드뉴스')).text.style?.color,
      const Color(0xFFF2F3F5),
    );
    expect(_fill(tester, find.text(menu)), const Color(0xFF1C1E22));
    expect(
      tester.renderObject<RenderParagraph>(find.text(menu)).text.style?.color,
      const Color(0xFFF2F3F5),
    );
    expect(_fill(tester, find.text(quiet)), const Color(0xFFF3FFD6));
    // 사진 장면의 글자는 다크에서 #2A2D33이다(캔버스 그대로).
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
      const Color(0xFF2A2D33),
    );
  });

  testWidgets('swaps the slide tones each time a draft is regenerated', (
    tester,
  ) async {
    const menu = '대표 메뉴\n돈코츠 라멘\n11,000원';
    await _pumpDrafts(tester);
    expect(_fill(tester, find.text(menu)), const Color(0xFFF8F9FA));

    await _tapRegenerate(tester);
    await tester.pumpAndSettle();

    expect(_fill(tester, find.text(menu)), const Color(0xFFF3FFD6));
  });
}

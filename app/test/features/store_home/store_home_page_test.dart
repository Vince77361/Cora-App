import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/applicant_picks/domain/applicant_pick.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/presentation/pages/send_offer_page.dart';
import 'package:cora/features/store_home/domain/applicant.dart';
import 'package:cora/features/store_home/presentation/pages/store_applicants_page.dart';
import 'package:cora/features/store_home/presentation/pages/store_home_page.dart';
import 'package:cora/features/store_home/presentation/pages/store_me_page.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../applicant_picks/fake_applicant_picks_repository.dart';
import '../store_onboarding/fake_store_repository.dart';
import 'fake_store_home_repository.dart';
import 'store_home_harness.dart';

const _fix = '고치기';
const _all = '전체 둘러보기';

FakeApplicantPicksRepository _emptyPicks() => FakeApplicantPicksRepository(
  picks: sampleAllPicks(),
  source: PicksSource.all,
);

void main() {
  setUpAll(loadAppFonts);

  group('header and recruit box', () {
    testWidgets('shows the header and the recruit box with the reward line '
        'and a fix button that opens the terms screen', (tester) async {
      await pumpStoreHome(tester);

      expect(currentPath(tester), AppRoutes.store);
      expect(find.byType(StoreHomePage), findsOneWidget);
      expect(find.text('사장님 홈'), findsOneWidget);
      expect(find.text('한그릇 라멘'), findsOneWidget);
      expect(find.text('가게 페이지'), findsOneWidget);
      expect(find.text('크리에이터 모집'), findsOneWidget);
      expect(find.text('식사권 2인 + 조회수 수당'), findsOneWidget);
      expect(find.text('1,000회당 2,000원, 최대 60,000원'), findsOneWidget);

      await tester.tap(find.text(_fix));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeOnboardingTerms);
    });

    testWidgets('joins every reward element in the headline', (tester) async {
      await pumpStoreHome(
        tester,
        stores: FakeStoreRepository(
          store: sampleStore(
            status: StoreStatus.published,
            step: StoreOnboardingStep.done,
            defaultTerms: const OfferTerms(
              format: ContentFormat.reels,
              reward: Reward(
                voucher: Voucher(name: '식사권', value: 40000, people: 2),
                fixedCash: 30000,
              ),
            ),
          ),
        ),
      );

      expect(find.text('식사권 2인 + 고정 현금 30,000원'), findsOneWidget);
      // 조회수 수당이 없으면 둘째 줄도 없다.
      expect(find.textContaining('1,000회당'), findsNothing);
    });

    testWidgets('shows the unpublished state with 모집 조건 정하기', (tester) async {
      await pumpStoreHome(
        tester,
        stores: FakeStoreRepository(
          store: sampleStore(
            status: StoreStatus.published,
            step: StoreOnboardingStep.done,
          ),
        ),
      );

      expect(find.text('모집 조건을 정하고 공개해요'), findsOneWidget);
      expect(find.text('추천 3명'), findsNothing);
      expect(find.text(_fix), findsNothing);

      await tester.tap(find.text('모집 조건 정하기'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeOnboardingTerms);
    });
  });

  group('when applicants exist', () {
    testWidgets('shows the new-applications row and three applicants with 지원 '
        'chips', (tester) async {
      await pumpStoreHome(tester);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('새 지원'), findsOneWidget);
      expect(find.text('지원자 보기'), findsOneWidget);
      expect(find.text('추천 3명'), findsOneWidget);
      expect(find.text('지원한 3명 중 가게와 잘 맞는 3명이에요.'), findsOneWidget);
      expect(find.text('하루 한 컵'), findsOneWidget);
      expect(find.text('성수 한 끼'), findsOneWidget);
      expect(find.text('면치기 일기'), findsOneWidget);
      expect(find.text('리빙 릴스\n오늘 지원'), findsOneWidget);
      expect(find.text('맛집 릴스\n어제 지원'), findsOneWidget);
      expect(find.text('라멘 리뷰\n2일 전 지원'), findsOneWidget);
      expect(find.text('지원'), findsNWidgets(3));
      expect(find.text('제안하기'), findsNWidgets(3));
      // 사진이 없으면 이름의 첫 글자.
      expect(find.text('하'), findsOneWidget);
      expect(find.text('성'), findsOneWidget);
      expect(find.text('면'), findsOneWidget);
      expect(find.text('마음에 드는 분이 없나요?'), findsOneWidget);
      expect(find.text(_all), findsOneWidget);
      expect(find.textContaining('아직 지원이 없어요'), findsNothing);
    });

    testWidgets('says the real number of applicants from the summary, even '
        'when more than three applied', (tester) async {
      final home = FakeStoreHomeRepository(
        applicants: [
          ...sampleApplicants(),
          for (var i = 0; i < 2; i++)
            Applicant(
              applicationId: 'x$i',
              creator: CreatorSummary(userId: 'x$i', displayName: '추가 $i'),
              appliedAt: DateTime.utc(2026, 11, 8),
            ),
        ],
      );
      await pumpStoreHome(tester, home: home);

      expect(find.text('5'), findsOneWidget);
      expect(find.text('지원한 5명 중 가게와 잘 맞는 3명이에요.'), findsOneWidget);
    });

    testWidgets('opens the applicants screen from 지원자 보기', (tester) async {
      await pumpStoreHome(tester);

      await tester.tap(find.text('지원자 보기'));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storeApplicants);
      expect(find.byType(StoreApplicantsPage), findsOneWidget);
    });

    testWidgets('opens the offer form with the creator from 제안하기', (
      tester,
    ) async {
      await pumpStoreHome(tester);

      await tester.tap(find.text('제안하기').at(1));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storeOfferNew('c2'));
      expect(find.byType(SendOfferPage), findsOneWidget);
      expect(find.bySemanticsLabel('성수 한 끼에게 오퍼'), findsOneWidget);
    });
  });

  group('when nobody applied', () {
    testWidgets('shows 아직 지원이 없어요 and three Cora creators without '
        'chips', (tester) async {
      await pumpStoreHome(
        tester,
        home: FakeStoreHomeRepository(),
        picks: _emptyPicks(),
      );

      expect(find.text('아직 지원이 없어요'), findsOneWidget);
      expect(find.text('새 지원이 오면 알려드려요'), findsOneWidget);
      expect(find.text('지원자 보기'), findsNothing);
      expect(find.text('새 지원'), findsNothing);
      expect(find.text('추천 3명'), findsOneWidget);
      expect(find.text('Cora 크리에이터 중 가게와 잘 맞는 3명이에요.'), findsOneWidget);
      expect(find.text('지원'), findsNothing);
      expect(find.text('리빙 릴스\n팔로워 640'), findsOneWidget);
      expect(find.text('일상형 릴스\n팔로워 3,100'), findsOneWidget);
      expect(find.text('코디 릴스\n팔로워 1.8만'), findsOneWidget);
      expect(find.text('제안하기'), findsNWidgets(3));
      expect(find.text(_all), findsOneWidget);
    });

    testWidgets('goes by the answer source, not by the applicant count', (
      tester,
    ) async {
      // 지원 줄은 있어도 프로필이 모두 지워졌으면 서버는 전체에서 뽑고 `totalNew`는 0보다 크다.
      await pumpStoreHome(
        tester,
        picks: FakeApplicantPicksRepository(
          picks: sampleAllPicks(),
          totalNew: 2,
          source: PicksSource.all,
        ),
      );

      expect(find.text('아직 지원이 없어요'), findsOneWidget);
      expect(find.text('Cora 크리에이터 중 가게와 잘 맞는 3명이에요.'), findsOneWidget);
      expect(find.text('지원'), findsNothing);
    });

    testWidgets('opens the offer form from a creator who never applied', (
      tester,
    ) async {
      await pumpStoreHome(
        tester,
        home: FakeStoreHomeRepository(),
        picks: _emptyPicks(),
      );

      await tester.tap(find.text('제안하기').first);
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storeOfferNew('c1'));
      expect(find.byType(SendOfferPage), findsOneWidget);
      expect(find.bySemanticsLabel('하루 한 컵에게 오퍼'), findsOneWidget);
    });
  });

  testWidgets('has no count tiles, tabs or shortcuts anymore', (tester) async {
    await pumpStoreHome(tester);

    for (final gone in [
      '보낸 오퍼',
      '진행 중',
      '지원자 추천',
      '이번 주 가게 게시물',
      '지원한 크리에이터 3',
      '보낸 오퍼 0',
      '오퍼 보내기',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });

  testWidgets('keeps the home whole when the picks cannot be read', (
    tester,
  ) async {
    await pumpStoreHome(
      tester,
      picks: FakeApplicantPicksRepository()..failFetch = true,
    );

    expect(find.text('추천 3명'), findsNothing);
    expect(find.text('크리에이터 모집'), findsOneWidget);
    expect(find.text(_all), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('whole browse', () {
    testWidgets('opens 전체 둘러보기 from the button', (tester) async {
      await pumpStoreHome(tester);

      await tester.ensureVisible(find.text(_all));
      await tester.tap(find.text(_all));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storeDiscover);
    });

    testWidgets('scrolls to the top from the 홈 menu', (tester) async {
      await pumpStoreHome(tester, smallPhoneLargeText: true);
      final list = find.byType(ListView);
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      double offset() => tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(offset(), greaterThan(0));

      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();

      expect(offset(), 0);
      expect(topPath(tester), AppRoutes.store);
    });
  });

  testWidgets('refreshes the summary and the picks on pull', (tester) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants());
    final picks = FakeApplicantPicksRepository(
      picks: sampleAppliedPicks(),
      totalNew: 3,
    );
    await pumpStoreHome(tester, home: home, picks: picks);
    expect(find.text('지원한 3명 중 가게와 잘 맞는 3명이에요.'), findsOneWidget);
    final homeBefore = home.fetchCalls;
    final picksBefore = picks.fetchCalls;

    home.applicants = [...sampleApplicants().take(1)];
    picks.picks = sampleAppliedPicks().take(1).toList();
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(home.fetchCalls, greaterThan(homeBefore));
    expect(picks.fetchCalls, greaterThan(picksBefore));
    expect(find.text('지원한 1명 중 가게와 잘 맞는 1명이에요.'), findsOneWidget);
    expect(find.text('성수 한 끼'), findsNothing);
  });

  testWidgets('keeps what is shown when a refresh fails', (tester) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants());
    await pumpStoreHome(tester, home: home);

    home.failFetch = true;
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('지원자 보기'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);
  });

  testWidgets('store home shows the shared loading state before data arrives', (
    tester,
  ) async {
    final hold = Completer<void>();
    final home = FakeStoreHomeRepository(applicants: sampleApplicants())
      ..holdFetch = hold;
    await pumpStoreHome(tester, home: home);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('불러오는 중'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.text('불러오는 중'), findsNothing);
    expect(find.text('추천 3명'), findsOneWidget);
  });

  testWidgets('store home shows the shared failed state with its own title', (
    tester,
  ) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants())
      ..failFetch = true;
    await pumpStoreHome(tester, home: home);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('사장님 홈을 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    home.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('추천 3명'), findsOneWidget);
  });

  group('bottom menu', () {
    testWidgets(
      'the offer tab in the store bottom nav opens the proposal box',
      (tester) async {
        await pumpStoreHome(tester);

        await tester.tap(find.text('오퍼').last);
        await tester.pumpAndSettle();

        expect(topPath(tester), AppRoutes.storeProposals);
        expect(find.text('제안함'), findsOneWidget);
      },
    );

    testWidgets('opens the whole browse screen from the 찾기 menu', (
      tester,
    ) async {
      await pumpStoreHome(tester);

      await tester.tap(find.text('찾기'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeDiscover);
    });

    testWidgets('the AI writing tab opens the drafts', (tester) async {
      await pumpStoreHome(tester);

      await tester.tap(find.text('AI 글'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeDrafts);
    });
  });

  group('my store', () {
    testWidgets('the store photo opens my store', (tester) async {
      await pumpStoreHome(tester);

      await tester.tap(find.bySemanticsLabel('내 가게'));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storeMe);
      expect(find.byType(StoreMePage), findsOneWidget);
      for (final label in ['가게 페이지', '보관함', '설정', '로그아웃']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('한그릇 라멘'), findsOneWidget);
    });

    testWidgets('archive and settings are placeholders', (tester) async {
      await pumpStoreHome(tester);
      await tester.tap(find.bySemanticsLabel('내 가게'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('보관함'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeComingSoon('보관함'));
    });

    testWidgets('signing out leaves for the login screen', (tester) async {
      await pumpStoreHome(tester);
      await tester.tap(find.bySemanticsLabel('내 가게'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), AppRoutes.login);
    });

    testWidgets(
      'the store page link opens the page with the two next buttons',
      (tester) async {
        await pumpStoreHome(tester);

        await tester.tap(find.text('가게 페이지'));
        await tester.pumpAndSettle();

        expect(topPath(tester), AppRoutes.storePage);
        expect(find.byType(StorePagePreviewPage), findsOneWidget);
        expect(find.text('AI로 직접 제작'), findsOneWidget);
        expect(find.text('크리에이터 모집'), findsOneWidget);
        expect(find.text('정보 고치기'), findsNothing);
        expect(find.text('이대로 다음'), findsNothing);
        // 단계 머리글(`2 / 3`)이 없다.
        expect(find.text('2 / 3'), findsNothing);
      },
    );
  });

  testWidgets('uses the dark tokens in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpStoreHome(tester);

    Finder box(Color color) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == color,
    );
    // 모집 상자와 둘러보기 상자는 다크의 `surface`, `고치기`는 #33363D, `지원자 보기`·`제안하기`는 라임이다.
    expect(box(CoraColors.dark.surface), findsAtLeastNWidgets(2));
    expect(box(CoraColors.light.surface), findsNothing);
    expect(box(CoraColors.dark.notifyTabSelected), findsWidgets);
    expect(box(CoraColors.dark.highlightAction), findsNWidgets(4));
    expect(CoraColors.dark.highlightAction, const Color(0xFFC6FF3D));
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpStoreHome(tester, smallPhoneLargeText: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow with long names at 1.3x text scale', (
    tester,
  ) async {
    await pumpStoreHome(
      tester,
      smallPhoneLargeText: true,
      picks: FakeApplicantPicksRepository(
        picks: [
          ApplicantPick(
            applicationId: 'a1',
            appliedAt: DateTime.utc(2026, 11, 11),
            creator: const PickCreator(
              userId: 'c1',
              displayName: '아주아주아주 긴 활동 이름의 크리에이터',
              contentFocus: '아주아주 긴 분야 이름의 릴스',
            ),
          ),
        ],
        totalNew: 1,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/store_home/presentation/pages/store_home_page.dart';
import 'package:cora/features/store_home/presentation/pages/store_me_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../payment/fake_payment_repository.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_home_repository.dart';
import 'store_home_harness.dart';

FakeStoreHomeRepository _homeWithSent() => FakeStoreHomeRepository(
  applicants: sampleApplicants(),
  sent: [
    sentOffer(id: 'w1', name: '하루 한 컵', view: OfferView.waiting),
    sentOffer(
      id: 'p1',
      name: '국물 수집가',
      view: OfferView.accepted,
      paymentDaysLeft: 3,
    ),
    sentOffer(id: 'd1', name: '민의 옷장 기록', view: OfferView.declined),
  ],
);

Future<void> _openSentTab(WidgetTester tester) async {
  await tester.tap(find.text('보낸 오퍼 3'));
  await tester.pumpAndSettle();
}

Future<void> _openSentTabOf(WidgetTester tester, int count) async {
  await tester.tap(find.text('보낸 오퍼 $count'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the three counts', (tester) async {
    await pumpStoreHome(tester, home: _homeWithSent());

    expect(currentPath(tester), AppRoutes.store);
    expect(find.byType(StoreHomePage), findsOneWidget);
    expect(find.text('사장님 홈'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('가게 페이지'), findsOneWidget);
    for (final label in ['새 지원', '보낸 오퍼', '진행 중']) {
      expect(find.text(label), findsOneWidget);
    }
    // 새 지원 3, 보낸 오퍼 3, 진행 중 1(수락한 오퍼).
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    for (final label in ['릴스로 찾기', '리스트 검색', '빠른 입찰']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('지원한 크리에이터 3'), findsOneWidget);
    expect(find.text('보낸 오퍼 3'), findsOneWidget);
  });

  testWidgets('lists the applicants with when they applied', (tester) async {
    await pumpStoreHome(tester);

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('리빙 릴스, 오늘 지원'), findsOneWidget);
    expect(find.text('맛집 릴스, 어제 지원'), findsOneWidget);
    expect(find.text('라멘 리뷰, 2일 전 지원'), findsOneWidget);
    // 지원자 줄의 버튼은 모두 `오퍼 보내기`다.
    expect(find.text('오퍼 보내기'), findsNWidgets(3));
    // 사진이 없으면 이름의 첫 글자.
    expect(find.text('성'), findsOneWidget);
    expect(find.text('면'), findsOneWidget);
  });

  testWidgets('shows the empty message on each tab', (tester) async {
    await pumpStoreHome(tester, home: FakeStoreHomeRepository());

    expect(find.text('아직 지원한 크리에이터가 없어요. 가게가 공개되면 지원이 도착해요.'), findsOneWidget);
    await tester.tap(find.text('보낸 오퍼 0'));
    await tester.pumpAndSettle();
    expect(find.text('아직 보낸 오퍼가 없어요.'), findsOneWidget);
    expect(find.text('아직 지원한 크리에이터가 없어요. 가게가 공개되면 지원이 도착해요.'), findsNothing);
  });

  testWidgets('shows the sent offers with their state and action', (
    tester,
  ) async {
    await pumpStoreHome(tester, home: _homeWithSent());
    await _openSentTab(tester);

    expect(find.text('답을 기다려요'), findsOneWidget);
    expect(find.text('수락함, 결제를 기다려요 · 3일 남음'), findsOneWidget);
    expect(find.text('거절함'), findsOneWidget);
    expect(find.text('결제하기'), findsOneWidget);
    expect(find.text('다시 찾기'), findsOneWidget);
    expect(find.text('오퍼 보내기'), findsNothing);
  });

  testWidgets('opens send offer for an applicant', (tester) async {
    await pumpStoreHome(tester);

    await tester.tap(find.text('오퍼 보내기').first);
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOfferNew('c1'));
  });

  testWidgets('opens the payment screen from an accepted offer', (
    tester,
  ) async {
    await pumpStoreHome(
      tester,
      home: FakeStoreHomeRepository(
        sent: [
          sentOffer(
            id: 'p1',
            name: '국물 수집가',
            view: OfferView.accepted,
            collaborationId: 'col-1',
            paymentDaysLeft: 3,
          ),
        ],
      ),
      overrides: [
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
      ],
    );
    await _openSentTabOf(tester, 1);

    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storePay('col-1'));
    expect(find.text('지금 결제할 금액'), findsOneWidget);
  });

  testWidgets('opens the find-again placeholder from a declined offer', (
    tester,
  ) async {
    await pumpStoreHome(tester, home: _homeWithSent());
    await _openSentTab(tester);

    await tester.tap(find.text('다시 찾기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeComingSoon('다시 찾기'));
    expect(find.text('준비 중이에요.'), findsOneWidget);
  });

  testWidgets('opens a placeholder for each shortcut', (tester) async {
    await pumpStoreHome(tester);

    await tester.tap(find.text('릴스로 찾기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeComingSoon('릴스로 찾기'));
  });

  group('cancel', () {
    testWidgets('cancels a waiting offer after confirmation', (tester) async {
      final home = _homeWithSent();
      await pumpStoreHome(tester, home: home);
      await _openSentTab(tester);

      await tester.tap(find.text('하루 한 컵'));
      await tester.pumpAndSettle();
      // 시트: 조건 요약과 `오퍼 취소`.
      expect(find.text('하루 한 컵에게 보낸 오퍼'), findsOneWidget);
      expect(find.text('릴스 1편'), findsOneWidget);
      expect(find.text('오퍼 취소'), findsOneWidget);

      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();
      expect(find.text('이 오퍼를 취소할까요?'), findsOneWidget);
      expect(find.text('그대로 두기'), findsOneWidget);
      expect(home.cancelled, isEmpty);

      await tester.tap(find.text('취소하기'));
      await tester.pumpAndSettle();
      expect(home.cancelled, ['w1']);
      expect(find.text('이 오퍼를 취소할까요?'), findsNothing);
      expect(find.text('취소했어요'), findsOneWidget);
    });

    testWidgets('keeps the offer when the owner backs out', (tester) async {
      final home = _homeWithSent();
      await pumpStoreHome(tester, home: home);
      await _openSentTab(tester);

      await tester.tap(find.text('하루 한 컵'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('그대로 두기'));
      await tester.pumpAndSettle();

      expect(home.cancelled, isEmpty);
      expect(find.text('이 오퍼를 취소할까요?'), findsNothing);
      expect(find.text('답을 기다려요'), findsOneWidget);
    });

    testWidgets('also opens for an accepted offer, but not a declined one', (
      tester,
    ) async {
      await pumpStoreHome(tester, home: _homeWithSent());
      await _openSentTab(tester);

      await tester.tap(find.text('민의 옷장 기록'));
      await tester.pumpAndSettle();
      expect(find.text('오퍼 취소'), findsNothing);

      await tester.tap(find.text('국물 수집가'));
      await tester.pumpAndSettle();
      expect(find.text('오퍼 취소'), findsOneWidget);
    });

    testWidgets('says so when the offer was already handled', (tester) async {
      final home = _homeWithSent()..conflictOnCancel = true;
      await pumpStoreHome(tester, home: home);
      await _openSentTab(tester);

      await tester.tap(find.text('하루 한 컵'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소하기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 처리된 오퍼예요.'), findsOneWidget);
      expect(find.text('이 오퍼를 취소할까요?'), findsOneWidget);
    });

    testWidgets('says so when cancelling fails', (tester) async {
      final home = _homeWithSent()..failCancel = true;
      await pumpStoreHome(tester, home: home);
      await _openSentTab(tester);

      await tester.tap(find.text('하루 한 컵'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소하기'));
      await tester.pumpAndSettle();

      expect(find.text('취소하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    });
  });

  testWidgets('refreshes counts and lists on pull', (tester) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants());
    await pumpStoreHome(tester, home: home);
    expect(find.text('지원한 크리에이터 3'), findsOneWidget);
    final before = home.fetchCalls;

    home.applicants = [...sampleApplicants().take(1)];
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(home.fetchCalls, greaterThan(before));
    expect(find.text('지원한 크리에이터 1'), findsOneWidget);
    expect(find.text('성수 한 끼'), findsNothing);
  });

  testWidgets('keeps what is shown when a refresh fails', (tester) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants());
    await pumpStoreHome(tester, home: home);

    home.failFetch = true;
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('지원한 크리에이터 3'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants())
      ..failFetch = true;
    await pumpStoreHome(tester, home: home);

    expect(find.text('사장님 홈을 불러오지 못했어요.'), findsOneWidget);
    home.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵'), findsOneWidget);
  });

  group('bottom menu', () {
    testWidgets('offer tab opens the sent list', (tester) async {
      await pumpStoreHome(tester, home: _homeWithSent());
      expect(find.text('오퍼 보내기'), findsNWidgets(3));

      await tester.tap(find.text('오퍼').last);
      await tester.pumpAndSettle();

      expect(find.text('답을 기다려요'), findsOneWidget);
      expect(find.text('오퍼 보내기'), findsNothing);

      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
      expect(find.text('오퍼 보내기'), findsNWidgets(3));
    });

    testWidgets('find and chat are placeholders', (tester) async {
      await pumpStoreHome(tester);

      await tester.tap(find.text('찾기'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeComingSoon('찾기'));
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

    testWidgets('the store page link opens the page with one edit button', (
      tester,
    ) async {
      await pumpStoreHome(tester);

      await tester.tap(find.text('가게 페이지'));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storePage);
      expect(find.byType(StorePagePreviewPage), findsOneWidget);
      expect(find.text('정보 고치기'), findsOneWidget);
      expect(find.text('이대로 다음'), findsNothing);
      // 단계 머리글(`2 / 3`)이 없다.
      expect(find.text('2 / 3'), findsNothing);
    });
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
    // 숫자 칸 세 개는 다크의 `surface`, 선택된 탭(과 첫 바로가기)은 밝은 회색.
    expect(box(CoraColors.dark.surface), findsAtLeastNWidgets(3));
    expect(box(CoraColors.light.surface), findsNothing);
    expect(box(CoraColors.dark.surfaceSelected), findsWidgets);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpStoreHome(
      tester,
      home: _homeWithSent(),
      smallPhoneLargeText: true,
    );
    expect(tester.takeException(), isNull);

    await _openSentTab(tester);
    expect(tester.takeException(), isNull);
  });
}

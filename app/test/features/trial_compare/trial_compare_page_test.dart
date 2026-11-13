import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/store_home/presentation/viewmodels/store_home_view_model.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';
import 'package:cora/features/trial_compare/presentation/pages/trial_compare_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart';
import 'fake_trial_compare_repository.dart';
import 'trial_compare_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('G3 shows four rows and only the owner input notice', (
    tester,
  ) async {
    await pumpTrialCompare(tester);

    expect(find.byType(TrialComparePage), findsOneWidget);
    expect(find.text('지난 3개월 비교'), findsOneWidget);
    expect(
      find.text('체험단 계약이 12월 10일에 끝나요. 다시 계약하기 전에 비교해 보세요.'),
      findsOneWidget,
    );
    expect(find.text('같은 3개월,\n무엇이 남았나요?'), findsOneWidget);
    for (final label in ['체험단', 'Cora']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final row in ['들어간 돈', '생긴 콘텐츠', '평소 대비 반응', '누가 왔나']) {
      expect(find.text(row), findsOneWidget);
    }
    for (final cell in [
      '월 300,000원 × 3',
      '오퍼 4건 · 152,000원',
      '블로그 글 9개',
      '릴스 4편',
      '확인 어려움',
      '평균 2.6배',
      '플랫폼이 선정',
      '지원자 중 직접 좋아요',
    ]) {
      expect(find.text(cell), findsOneWidget, reason: cell);
    }
    expect(find.text('체험단 금액은 사장님이 입력한 값이에요.'), findsOneWidget);
    // 이 계획에서는 AI 제작 계획이 넣는 줄과 캔버스의 가상 예시 문구를 뺀다.
    expect(find.text('가게 계정에 남은 것'), findsNothing);
    expect(find.textContaining('가게 계정 게시물'), findsNothing);
    expect(find.textContaining('숫자는 가상 예시예요'), findsNothing);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('다음 달은 Cora로 오퍼 보내기'), findsOneWidget);
  });

  testWidgets('G3 says nothing yet when Cora has no content or reaction', (
    tester,
  ) async {
    await pumpTrialCompare(
      tester,
      trial: FakeTrialCompareRepository(
        comparison: sampleComparison(
          contentByFormat: const [],
          averageMultiplierTenths: null,
          offerCount: 0,
        ),
      ),
    );

    expect(find.text('아직 없어요'), findsNWidgets(2));
    expect(find.text('오퍼 0건 · 152,000원'), findsOneWidget);
  });

  testWidgets('G3 hides the home banner for seven days after later', (
    tester,
  ) async {
    final stores = storeWithTrial();
    final trial = FakeTrialCompareRepository(stores: stores);
    await pumpTrialCompare(tester, stores: stores, trial: trial);
    expect(
      containerOf(tester).read(myStoreViewModelProvider).value!.trialBanner,
      TrialBannerKind.compare,
    );

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    expect(trial.snoozed, 1);
    expect(topPath(tester), AppRoutes.store);
    expect(
      containerOf(tester).read(myStoreViewModelProvider).value!.trialBanner,
      isNull,
    );
    expect(find.text('체험단 계약이 한 달 남았어요 · 비교 보기'), findsNothing);
  });

  testWidgets('G3 stays and says so when hiding the banner fails', (
    tester,
  ) async {
    final stores = storeWithTrial();
    final trial = FakeTrialCompareRepository(stores: stores)..failSnooze = true;
    await pumpTrialCompare(tester, stores: stores, trial: trial);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    expect(find.byType(TrialComparePage), findsOneWidget);
    expect(find.text('잠시 문제가 생겼어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets(
    'G3 sends the next month offer through the picks when somebody applied',
    (tester) async {
      await pumpTrialCompare(
        tester,
        home: FakeStoreHomeRepository(applicants: sampleApplicants()),
      );

      await tester.tap(find.text('다음 달은 Cora로 오퍼 보내기'));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.storeApplicantPicks);
      expect(find.text('좋아요하고 오퍼'), findsOneWidget);
    },
  );

  testWidgets('G3 goes to the applicants tab when nobody applied yet', (
    tester,
  ) async {
    await pumpTrialCompare(tester, home: FakeStoreHomeRepository());

    await tester.tap(find.text('다음 달은 Cora로 오퍼 보내기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.store);
    expect(
      containerOf(tester).read(storeHomeViewModelProvider).value!.tab,
      StoreHomeTab.applicants,
    );
  });

  testWidgets('G3 asks for the contract info when there is none', (
    tester,
  ) async {
    await pumpTrialCompare(
      tester,
      trial: FakeTrialCompareRepository()..notFound = true,
    );

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('체험단 계약 정보가 없어요.'), findsOneWidget);
    await tester.tap(find.text('계약 정보 넣기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeTrialInfo);
  });

  testWidgets('G3 offers a retry when loading fails', (tester) async {
    final trial = FakeTrialCompareRepository()..failFetch = true;
    await pumpTrialCompare(tester, trial: trial);

    expect(find.text('비교를 불러오지 못했어요.'), findsOneWidget);
    trial.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('들어간 돈'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpTrialCompare(tester, smallPhoneLargeText: true);

    expect(find.text('들어간 돈'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('다음 달은 Cora로 오퍼 보내기'), findsOneWidget);
  });
}

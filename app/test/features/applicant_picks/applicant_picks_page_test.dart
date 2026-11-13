import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/applicant_picks/domain/applicant_pick.dart';
import 'package:cora/features/applicant_picks/presentation/applicant_picks_text.dart';
import 'package:cora/features/applicant_picks/presentation/pages/applicant_picks_page.dart';
import 'package:cora/features/store_home/presentation/viewmodels/store_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/store_home_harness.dart';
import 'applicant_picks_harness.dart';
import 'fake_applicant_picks_repository.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'G2 shows one pick at a time with the pitch, reasons and district',
    (tester) async {
      await pumpApplicantPicks(
        tester,
        picks: FakeApplicantPicksRepository(totalNew: 5),
      );

      expect(find.byType(ApplicantPicksPage), findsOneWidget);
      expect(find.text('새 지원 5'), findsOneWidget);
      expect(find.text('탐색'), findsOneWidget);
      expect(
        find.text('지원한 5명 중 가게와 잘 맞는 3명이에요. 팔로워 수는 점수에 넣지 않아요.'),
        findsOneWidget,
      );
      expect(find.text('대표 릴스 · 추천 1 / 3'), findsOneWidget);
      expect(find.text('“김 오르는 첫 숟가락을 슬로모션으로 찍을게요”'), findsOneWidget);
      expect(find.text('같은 구·군 · 카페·식당 릴스 9개'), findsOneWidget);
      expect(find.text('하루 한 컵 · 성동구 · 팔로워 640'), findsOneWidget);
      expect(find.text('넘기기'), findsOneWidget);
      expect(find.text('좋아요하고 오퍼'), findsOneWidget);
      // 다음 추천은 아직 보이지 않는다.
      expect(find.textContaining('민의 옷장 기록'), findsNothing);
    },
  );

  testWidgets(
    'G2 skips a pick and shows the all seen state after the last one',
    (tester) async {
      final repo = FakeApplicantPicksRepository(totalNew: 3);
      await pumpApplicantPicks(tester, picks: repo);

      await tester.tap(find.text('넘기기'));
      await tester.pumpAndSettle();
      expect(find.text('대표 릴스 · 추천 2 / 3'), findsOneWidget);
      expect(find.text('민의 옷장 기록 · 마포구 · 팔로워 2,100'), findsOneWidget);

      await tester.tap(find.text('넘기기'));
      await tester.pumpAndSettle();
      expect(find.text('대표 릴스 · 추천 3 / 3'), findsOneWidget);
      await tester.tap(find.text('넘기기'));
      await tester.pumpAndSettle();

      expect(repo.skipped, ['a1', 'a2', 'a3']);
      expect(find.byType(CoraStateView), findsOneWidget);
      expect(find.text('추천을 모두 봤어요.'), findsOneWidget);
      expect(find.text('지원자 목록에서 나머지를 볼 수 있어요.'), findsOneWidget);
      expect(find.text('넘기기'), findsNothing);

      // 지원자 목록 보기: 사장님 홈의 지원자 탭으로 간다.
      await tester.tap(find.text('지원자 목록 보기'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.store);
      expect(
        containerOf(tester).read(storeHomeViewModelProvider).value!.tab,
        StoreHomeTab.applicants,
      );
    },
  );

  testWidgets('G2 stays on the pick when skipping fails', (tester) async {
    final repo = FakeApplicantPicksRepository()..failSkip = true;
    await pumpApplicantPicks(tester, picks: repo);

    await tester.tap(find.text('넘기기'));
    await tester.pumpAndSettle();

    expect(find.text('대표 릴스 · 추천 1 / 3'), findsOneWidget);
    expect(find.text('넘기지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('G2 opens A5 for the liked creator', (tester) async {
    await pumpApplicantPicks(tester);

    await tester.tap(find.text('넘기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('좋아요하고 오퍼'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOfferNew('c2'));
  });

  testWidgets('G2 hides followers for a creator without instagram', (
    tester,
  ) async {
    await pumpApplicantPicks(
      tester,
      picks: FakeApplicantPicksRepository(
        picks: const [
          ApplicantPick(
            applicationId: 'a9',
            creator: PickCreator(
              userId: 'c9',
              displayName: '국물 수집가',
              regionSido: '서울특별시',
              regionSigungu: '성동구',
            ),
            pitch: '국물 맛을 담아요',
          ),
        ],
      ),
    );

    expect(find.text('국물 수집가 · 성동구'), findsOneWidget);
    expect(find.textContaining(RegExp(r'팔로워 \d')), findsNothing);
  });

  testWidgets(
    'G2 says the intro with the real count when fewer than three applied',
    (tester) async {
      await pumpApplicantPicks(
        tester,
        picks: FakeApplicantPicksRepository(
          picks: samplePicks().take(2).toList(),
        ),
      );

      expect(find.text('새 지원 2'), findsOneWidget);
      expect(find.text('대표 릴스 · 추천 1 / 2'), findsOneWidget);
      expect(
        find.text('지원한 2명 중 가게와 잘 맞는 2명이에요. 팔로워 수는 점수에 넣지 않아요.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('G2 says nobody applied yet when there is no new application', (
    tester,
  ) async {
    await pumpApplicantPicks(
      tester,
      picks: FakeApplicantPicksRepository(picks: const [], totalNew: 0),
    );

    expect(find.text('새 지원 0'), findsOneWidget);
    expect(find.text('아직 지원한 크리에이터가 없어요.'), findsOneWidget);
    expect(find.text('추천을 모두 봤어요.'), findsNothing);
  });

  testWidgets('G2 opens the find tab placeholder from the header', (
    tester,
  ) async {
    await pumpApplicantPicks(tester);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();

    expect(topPath(tester), startsWith('/store/coming-soon/'));
  });

  testWidgets('G2 offers a retry when loading fails', (tester) async {
    final repo = FakeApplicantPicksRepository()..failFetch = true;
    await pumpApplicantPicks(tester, picks: repo);

    expect(find.text('지원자 추천을 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('대표 릴스 · 추천 1 / 3'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpApplicantPicks(tester, smallPhoneLargeText: true);

    expect(find.text('좋아요하고 오퍼'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('writes the pick lines like the canvas', () {
    final pick = samplePicks().first;
    expect(picksTitle(5), '새 지원 5');
    expect(picksChip(index: 0, total: 3), '대표 릴스 · 추천 1 / 3');
    expect(pickReasons(pick), '같은 구·군 · 카페·식당 릴스 9개');
    expect(pickMeta(pick), '하루 한 컵 · 성동구 · 팔로워 640');
    // 한 줄이 없으면 주로 만드는 콘텐츠를 그대로 보인다.
    const noPitch = ApplicantPick(
      applicationId: 'a',
      creator: PickCreator(
        userId: 'c',
        displayName: '이름',
        contentFocus: '맛집 릴스',
        regionSido: '부산광역시',
      ),
    );
    expect(pickPitch(noPitch), '맛집 릴스');
    expect(pickMeta(noPitch), '이름 · 부산광역시');
    expect(pickReasons(noPitch), isNull);
  });
}

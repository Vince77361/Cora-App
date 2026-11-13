import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/store_home/presentation/viewmodels/store_home_view_model.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_onboarding/fake_store_repository.dart';
import '../trial_compare/trial_compare_harness.dart';
import 'store_home_harness.dart';

const _compare = '체험단 계약이 한 달 남았어요 · 비교 보기';
const _hint = '체험단 계약 정보를 넣으면 비교해 드려요.';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('A9 shows the compare banner only when the server says so', (
    tester,
  ) async {
    await pumpTrialCompare(tester, open: false);

    expect(find.text(_compare), findsOneWidget);
    expect(find.text(_hint), findsNothing);
    // 체험단 줄은 바로가기 둘 아래, 탭 위에 있다.
    final banner = tester.getTopLeft(find.text(_compare)).dy;
    expect(banner, greaterThan(tester.getBottomLeft(find.text('지원자 추천')).dy));
    expect(banner, lessThan(tester.getTopLeft(find.text('지원한 크리에이터 3')).dy));

    await tester.tap(find.text(_compare));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeTrialCompare);
    expect(find.text('들어간 돈'), findsOneWidget);
  });

  testWidgets('A9 has no trial line when the server sends none', (
    tester,
  ) async {
    await pumpTrialCompare(
      tester,
      stores: storeWithTrial(banner: null),
      open: false,
    );

    expect(find.text(_compare), findsNothing);
    expect(find.text(_hint), findsNothing);
  });

  testWidgets('A9 shows the trial hint once and opens the info screen', (
    tester,
  ) async {
    final stores = FakeStoreRepository(
      store: sampleStore(
        status: StoreStatus.published,
        step: StoreOnboardingStep.done,
        trialBanner: TrialBannerKind.hint,
      ),
    );
    final trial = await pumpTrialCompare(tester, stores: stores, open: false);

    expect(find.text(_hint), findsOneWidget);
    expect(find.text(_compare), findsNothing);
    // 한 번 보이면 서버에 봤다고 알린다(다음에 홈을 열 때부터 나오지 않는다).
    expect(trial.hintsSeen, 1);

    // 탭을 바꾸고 다시 읽어도 또 알리지 않고, 이 화면의 줄은 그대로 눌린다.
    containerOf(tester)
        .read(storeHomeViewModelProvider.notifier)
        .selectTab(StoreHomeTab.sentOffers);
    await tester.pump();
    await containerOf(
      tester,
    ).read(storeHomeViewModelProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(trial.hintsSeen, 1);

    await tester.tap(find.text(_hint));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeTrialInfo);
  });

  testWidgets('A9 stays whole when telling the server about the hint fails', (
    tester,
  ) async {
    final stores = FakeStoreRepository(
      store: sampleStore(
        status: StoreStatus.published,
        step: StoreOnboardingStep.done,
        trialBanner: TrialBannerKind.hint,
      ),
    );
    // 가짜가 던지게 하는 대신 저장소 없이(기본값이 던진다) 띄워도 홈은 그대로다.
    await pumpStoreHome(tester, stores: stores, overrides: const <Override>[]);

    expect(find.text(_hint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

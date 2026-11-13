import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/store_home/presentation/pages/store_me_page.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';
import 'package:cora/features/trial_compare/presentation/pages/trial_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/store_home_harness.dart';
import '../store_onboarding/fake_store_repository.dart';
import 'trial_compare_harness.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(MergeSemantics),
  ),
  matching: find.byType(TextField),
);

Future<void> _openFromMyStore(WidgetTester tester) async {
  routerOf(tester).push(AppRoutes.storeMe);
  await tester.pumpAndSettle();
  await tester.tap(find.text('체험단 계약 정보'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('saves the trial info from my store', (tester) async {
    final stores = FakeStoreRepository(
      store: sampleStore(
        status: StoreStatus.published,
        step: StoreOnboardingStep.done,
      ),
    );
    final trial = await pumpTrialCompare(tester, stores: stores, open: false);
    await _openFromMyStore(tester);

    expect(find.byType(TrialInfoPage), findsOneWidget);
    expect(topPath(tester), AppRoutes.storeTrialInfo);
    for (final label in ['월 계약 금액', '계약 종료일', '석 달 동안 받은 글 수']) {
      expect(find.text(label), findsOneWidget);
    }
    // 아직 저장한 정보가 없어서 `지우기`가 없고, 칸을 다 채우기 전에는 `저장`을 누를 수 없다.
    expect(find.text('지우기'), findsNothing);

    await tester.enterText(_field('월 계약 금액'), '300000');
    await tester.enterText(_field('계약 종료일'), '20261210');
    await tester.pump();
    expect(
      tester.widget<TextField>(_field('계약 종료일')).controller!.text,
      '2026-12-10',
    );
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(trial.saved, isEmpty);

    await tester.enterText(_field('석 달 동안 받은 글 수'), '9');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(trial.saved, [
      TrialInfo(
        monthlyFee: 300000,
        endsOn: DateTime(2026, 12, 10),
        postCount: 9,
      ),
    ]);
    // 저장하고 내 가게로 돌아오며, 내 가게의 계약 정보가 서버 값으로 바뀐다.
    expect(find.byType(StoreMePage), findsOneWidget);
    expect(
      containerOf(tester).read(myStoreViewModelProvider).value!.trialInfo,
      isNotNull,
    );
  });

  testWidgets('does not save a date that is not on the calendar', (
    tester,
  ) async {
    final trial = await pumpTrialCompare(tester, open: false);
    await _openFromMyStore(tester);

    await tester.enterText(_field('월 계약 금액'), '300000');
    await tester.enterText(_field('계약 종료일'), '20260230');
    await tester.enterText(_field('석 달 동안 받은 글 수'), '9');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(trial.saved, isEmpty);
    expect(find.byType(TrialInfoPage), findsOneWidget);
  });

  testWidgets('shows the saved info and clears it', (tester) async {
    final trial = await pumpTrialCompare(tester, open: false);
    await _openFromMyStore(tester);

    expect(
      tester.widget<TextField>(_field('월 계약 금액')).controller!.text,
      '300000',
    );
    expect(
      tester.widget<TextField>(_field('계약 종료일')).controller!.text,
      '2026-12-10',
    );
    expect(
      tester.widget<TextField>(_field('석 달 동안 받은 글 수')).controller!.text,
      '9',
    );

    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();

    expect(trial.deleted, 1);
    expect(
      containerOf(tester).read(myStoreViewModelProvider).value!.trialInfo,
      isNull,
    );
  });

  testWidgets('says so and keeps the input when saving fails', (tester) async {
    final trial = await pumpTrialCompare(tester, open: false);
    trial.failSave = true;
    await _openFromMyStore(tester);

    await tester.enterText(_field('월 계약 금액'), '250000');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byType(TrialInfoPage), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('월 계약 금액')).controller!.text,
      '250000',
    );
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpTrialCompare(tester, smallPhoneLargeText: true, open: false);
    await _openFromMyStore(tester);

    expect(find.text('저장'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

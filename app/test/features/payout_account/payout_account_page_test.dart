import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/features/payout_account/domain/payout_account.dart';
import 'package:cora/features/payout_account/domain/payout_account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_payout_account_repository.dart';

Future<void> _open(
  WidgetTester tester,
  FakePayoutAccountRepository repo, {
  bool smallPhoneLargeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    smallPhoneLargeText: smallPhoneLargeText,
    payoutAccounts: repo,
  );
  routerOf(tester).push(AppRoutes.creatorPayoutAccount);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester) async {
  await tester.tap(find.text('은행'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('국민'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('payout-number')),
    '1234567890112',
  );
  await tester.enterText(find.byKey(const ValueKey('payout-holder')), '민서연');
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('registers a payout account and shows only the last two digits', (
    tester,
  ) async {
    final repo = FakePayoutAccountRepository();
    await _open(tester, repo);

    expect(topPath(tester), AppRoutes.creatorPayoutAccount);
    expect(find.text('지급받을 계좌를\n알려 주세요'), findsOneWidget);
    expect(find.text('계좌번호'), findsOneWidget);
    expect(find.text('예금주'), findsOneWidget);
    // 다 채우기 전에는 등록할 수 없다.
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();
    expect(repo.saved, isEmpty);

    await _fill(tester);
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(repo.saved, [
      (bankCode: '004', accountNumber: '1234567890112', holderName: '민서연'),
    ]);
    // 서버가 뒤 4자리를 줘도 화면은 뒤 2자리만 보인다.
    expect(find.text('국민은행 ****12'), findsOneWidget);
    expect(find.textContaining('0112'), findsNothing);
    expect(find.textContaining('1234567890'), findsNothing);
    expect(find.text('민서연'), findsOneWidget);
    expect(find.text('바꾸기'), findsOneWidget);
    expect(find.text('등록하기'), findsNothing);
  });

  testWidgets('shows the registered account and lets me change it', (
    tester,
  ) async {
    final repo = FakePayoutAccountRepository(
      account: const PayoutAccount(
        bankCode: '004',
        bankFullName: '국민은행',
        accountLast4: '0112',
        holderName: '민서연',
      ),
    );
    await _open(tester, repo);

    expect(find.text('국민은행 ****12'), findsOneWidget);
    expect(find.text('지급받을 계좌를\n알려 주세요'), findsNothing);

    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();

    expect(find.text('지급받을 계좌를\n알려 주세요'), findsOneWidget);
    expect(find.text('등록하기'), findsOneWidget);
  });

  testWidgets('lists the banks to pick from', (tester) async {
    await _open(tester, FakePayoutAccountRepository());

    await tester.tap(find.text('은행'));
    await tester.pumpAndSettle();

    for (final name in ['국민', '신한', '우리']) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('shows an error and stays usable when the server fails', (
    tester,
  ) async {
    // 키가 없는 개발 서버: 500이라 서버 문구 없이 실패한다.
    final repo = FakePayoutAccountRepository()
      ..failSave = const PayoutAccountFailure();
    await _open(tester, repo);

    await _fill(tester);
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(find.text('계좌를 등록하지 못했어요. 잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('등록하기'), findsOneWidget);
    expect(topPath(tester), AppRoutes.creatorPayoutAccount);

    // 입력은 그대로 남아 있고 다시 누를 수 있다.
    repo.failSave = null;
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();
    expect(find.text('국민은행 ****12'), findsOneWidget);
    expect(find.text('계좌를 등록하지 못했어요. 잠시 뒤 다시 시도해 주세요.'), findsNothing);
  });

  testWidgets('shows the server message for a rejected account', (
    tester,
  ) async {
    final repo = FakePayoutAccountRepository()
      ..failSave = const PayoutAccountFailure(message: '지원하지 않는 은행이에요.');
    await _open(tester, repo);

    await _fill(tester);
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(find.text('지원하지 않는 은행이에요.'), findsOneWidget);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    final repo = FakePayoutAccountRepository()..failFetch = true;
    await _open(tester, repo);

    expect(find.text('지급 계좌를 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('지급받을 계좌를\n알려 주세요'), findsOneWidget);
  });

  testWidgets('uses the dark tokens for the registered account box', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _open(
      tester,
      FakePayoutAccountRepository(
        account: const PayoutAccount(
          bankCode: '004',
          bankFullName: '국민은행',
          accountLast4: '0112',
          holderName: '민서연',
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == CoraColors.dark.surface,
      ),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _open(
      tester,
      FakePayoutAccountRepository(),
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('등록하기'), findsOneWidget);
  });
}

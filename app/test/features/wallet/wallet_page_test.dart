import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:cora/features/wallet/domain/wallet.dart';
import 'package:cora/features/wallet/presentation/pages/wallet_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../payout_account/fake_payout_account_repository.dart';
import '../store_browse/creator_app_harness.dart' show topPath;
import 'fake_wallet_repository.dart';
import 'wallet_harness.dart';

Color? _buttonColor(WidgetTester tester) =>
    (tester
                .widget<Container>(
                  find.byKey(const ValueKey('wallet-account-button')),
                )
                .decoration
            as BoxDecoration)
        .color;

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text).first).style!.color!;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the canvas wallet numbers and four rows', (tester) async {
    await pumpWallet(tester, repo: FakeWalletRepository(wallet: canvasWallet));

    expect(topPath(tester), NotificationRoutes.wallet);
    expect(find.byType(WalletPage), findsOneWidget);
    for (final text in [
      '정산',
      '다음 지급 예정 · 11월 18일 수요일',
      '43,200원',
      '계좌 변경',
      '이번 달 받은 금액',
      '350,000원',
      'Cora가 보관 중',
      '100,000원',
      '내역',
      '조회수 4,320회분',
      '지급 예정',
      '2인 식사권',
      '식사권',
      '사용 완료',
      '모아 스튜디오 · 릴스 1편',
      '11월 2일 지급',
      '지급 완료',
      '하루 한 컵 · 카드뉴스 1편',
      '게시 확인 중',
      '보관 중',
    ]) {
      expect(find.textContaining(text), findsWidgets, reason: text);
    }
    // 계좌 줄: 은행 전체 이름 + 뒤 2자리 + 예금주(보조색).
    expect(find.textContaining('국민은행 ****12'), findsOneWidget);
    expect(find.textContaining('민서연'), findsOneWidget);
    expect(find.text('한그릇 라멘 · 릴스 1편'), findsNWidgets(2));
    // 수수료·원천징수 안내 줄은 그리지 않는다(소유자 결정).
    expect(find.textContaining('원천징수'), findsNothing);
    expect(find.textContaining('수수료'), findsNothing);
  });

  testWidgets('keeps the account change button white in light and dark', (
    tester,
  ) async {
    await pumpWallet(tester, repo: FakeWalletRepository(wallet: canvasWallet));
    expect(_buttonColor(tester), const Color(0xFFFFFFFF));
    expect(_textColor(tester, '계좌 변경'), const Color(0xFF17181C));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    // 다크에서도 흰 바탕에 검은 글자다.
    expect(_buttonColor(tester), const Color(0xFFFFFFFF));
    expect(_textColor(tester, '계좌 변경'), const Color(0xFF17181C));
    // 큰 상자는 다크 surface, 보조 글자는 #A0A4AD.
    expect(_textColor(tester, '이번 달 받은 금액'), const Color(0xFFA0A4AD));
    expect(_textColor(tester, '350,000원'), const Color(0xFFF2F3F5));
  });

  testWidgets('uses the canvas sizes in the big box and rows', (tester) async {
    await pumpWallet(tester, repo: FakeWalletRepository(wallet: canvasWallet));

    final amount = tester.widget<Text>(find.text('43,200원').first);
    expect(amount.style!.fontSize, 36);
    expect(amount.style!.fontWeight, FontWeight.w900);
    expect(amount.style!.letterSpacing, closeTo(-1.8, 0.001));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('wallet-account-button')))
          .height,
      36,
    );
  });

  testWidgets('asks for an account when none is registered', (tester) async {
    final accounts = FakePayoutAccountRepository();
    final repo = FakeWalletRepository(
      wallet: const Wallet(entries: [], heldAmount: 0, receivedThisMonth: 0),
    );
    await pumpWallet(tester, repo: repo, payoutAccounts: accounts);

    expect(find.text('지급받을 계좌를 등록해 주세요.'), findsOneWidget);
    expect(find.text('계좌 등록'), findsOneWidget);
    expect(find.text('계좌 변경'), findsNothing);
    // 다음 지급이 없으면 머리와 금액이 바뀐다.
    expect(find.text('다음 지급 예정 없음'), findsOneWidget);
    expect(find.text('0원'), findsNWidgets(3));

    await tester.tap(find.text('계좌 등록'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorPayoutAccount);
  });

  testWidgets('opens the account screen and reloads when coming back', (
    tester,
  ) async {
    final repo = FakeWalletRepository(wallet: canvasWallet);
    await pumpWallet(tester, repo: repo);
    expect(repo.fetchCalls, 1);

    await tester.tap(find.text('계좌 변경'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorPayoutAccount);

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(topPath(tester), NotificationRoutes.wallet);
    expect(repo.fetchCalls, 2);
  });

  testWidgets('says so when there are no rows yet', (tester) async {
    await pumpWallet(tester, repo: FakeWalletRepository());

    expect(find.text('내역'), findsOneWidget);
    expect(find.text('아직 내역이 없어요.'), findsOneWidget);
  });

  testWidgets('shows an error with retry when the wallet cannot be loaded', (
    tester,
  ) async {
    final repo = FakeWalletRepository(wallet: canvasWallet)..failFetch = true;
    await pumpWallet(tester, repo: repo);

    expect(find.text('정산 내역을 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('43,200원'), findsWidgets);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpWallet(
      tester,
      repo: FakeWalletRepository(wallet: canvasWallet),
      smallPhoneLargeText: true,
    );
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

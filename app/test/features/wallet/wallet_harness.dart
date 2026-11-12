import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:cora/features/wallet/domain/wallet_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../payout_account/fake_payout_account_repository.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import 'fake_wallet_repository.dart';

/// 로그인한 크리에이터로 앱을 띄우고 정산(E7)을 연다.
Future<void> pumpWallet(
  WidgetTester tester, {
  required FakeWalletRepository repo,
  FakePayoutAccountRepository? payoutAccounts,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpCreatorApp(
    tester,
    payoutAccounts: payoutAccounts,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [walletRepositoryProvider.overrideWithValue(repo), ...overrides],
  );
  routerOf(tester).push(NotificationRoutes.wallet);
  await tester.pumpAndSettle();
}

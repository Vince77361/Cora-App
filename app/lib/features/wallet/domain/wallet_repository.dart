import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet.dart';

/// 크리에이터의 정산 현황을 읽는 포트.
abstract class WalletRepository {
  Future<Wallet> fetch();
}

/// 서버에 닿지 못했거나 서버가 거절했다. 화면은 일반 문구를 쓴다.
class WalletFailure implements Exception {
  const WalletFailure();

  @override
  String toString() => 'WalletFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) =>
      throw UnimplementedError('walletRepositoryProvider must be overridden'),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/wallet.dart';
import '../../domain/wallet_repository.dart';

/// 정산 화면(E7)의 데이터. 화면을 열 때마다 서버에서 새로 읽고(계좌를 바꾸고 돌아오면 `invalidate`),
/// 앱은 숫자를 계산하지 않는다.
///
/// Riverpod의 자동 재시도는 끈다(읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final walletViewModelProvider =
    AsyncNotifierProvider.autoDispose<WalletViewModel, Wallet>(
      WalletViewModel.new,
      retry: (_, _) => null,
    );

class WalletViewModel extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(walletRepositoryProvider).fetch();
  }
}

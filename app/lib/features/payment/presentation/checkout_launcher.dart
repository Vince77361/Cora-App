import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/app_routes.dart';

/// 결제창을 연다. 창이 닫히면 돌려준다(결과는 알려 주지 않는다: 결제가 됐는지는 창이 아니라
/// 서버가 PG에서 받은 통지로 정해지고, 앱은 닫힌 뒤 서버에 묻는다).
abstract class CheckoutLauncher {
  /// [checkoutUrl]은 서버가 준 결제창 주소. [amount]는 가짜 결제창이 금액을 보이려고 쓰는 값이다
  /// (실제 PG 결제창은 주소 안에 금액이 있어 쓰지 않는다).
  Future<void> open(String checkoutUrl, {int? amount});
}

/// 서버의 가짜 결제 어댑터가 주는 주소(`cora-dev://fake-pay?paymentId=…`)에서 결제 ID를 읽는다.
/// 이 모양이 아니면 null.
String? fakeCheckoutPaymentId(String checkoutUrl) {
  final uri = Uri.tryParse(checkoutUrl);
  if (uri == null || uri.scheme != 'cora-dev' || uri.host != 'fake-pay') {
    return null;
  }
  final id = uri.queryParameters['paymentId'];
  return id == null || id.isEmpty ? null : id;
}

/// 앱 안의 가짜 결제창([AppRoutes.devFakeCheckout])을 라우터로 연다. 다른 주소(실제 PG 결제창)는
/// 9번 계획에서 붙이므로 아직 [UnimplementedError]다.
class RouterCheckoutLauncher implements CheckoutLauncher {
  RouterCheckoutLauncher(this._ref);

  final Ref _ref;

  @override
  Future<void> open(String checkoutUrl, {int? amount}) async {
    final paymentId = fakeCheckoutPaymentId(checkoutUrl);
    final config = _ref.read(appConfigProvider);
    // 운영 빌드에서는 컴파일 시점에 false라 가짜 결제창으로 가는 코드가 바이너리에서 빠진다.
    if (paymentId == null || !(kDevScreensCompiledIn && config.isDev)) {
      throw UnimplementedError('이 결제창 주소는 아직 열 수 없습니다(9번 계획에서 PG 결제창을 붙입니다).');
    }
    final location = Uri(
      path: AppRoutes.devFakeCheckout,
      queryParameters: {
        'paymentId': paymentId,
        if (amount != null) 'amount': '$amount',
      },
    ).toString();
    await _ref.read(appRouterProvider).push<void>(location);
  }
}

/// 기본은 앱 안의 가짜 결제창. 테스트가 가짜로 바꿔 끼운다.
final checkoutLauncherProvider = Provider<CheckoutLauncher>(
  RouterCheckoutLauncher.new,
);

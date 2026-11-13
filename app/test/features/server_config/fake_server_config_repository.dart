import 'dart:async';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/server_config/domain/server_config.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';

/// 서버 `REWARD_POLICY`와 기본 수수료율(10%)과 같은 값. 서버 값을 바꾸면 이 값과 서버 테스트가 함께 바뀐다.
const sampleServerConfig = ServerConfig(
  reward: RewardLimits(
    viewRate: StepRange(min: 1000, max: 5000, step: 500, defaultValue: 2000),
    perViewCap: StepRange(
      min: 10000,
      max: 300000,
      step: 10000,
      defaultValue: 60000,
    ),
    fixedCash: FixedCashLimits(
      storeMax: 1000000,
      brandMax: 10000000,
      step: 10000,
      presets: [0, 30000, 50000, 100000],
    ),
    voucher: VoucherDefaults(
      name: '식사권',
      value: 40000,
      people: 2,
      maxPeople: 10,
    ),
    usageRightsDefault: UsageRights.storeRepost3m,
    countingDays: 7,
  ),
  feeRates: FeeRates(storeOffer: 10, brandContract: 10, bid: 10),
);

/// 손으로 쓴 가짜 서버 설정 저장소.
class FakeServerConfigRepository implements ServerConfigRepository {
  FakeServerConfigRepository({this.config = sampleServerConfig});

  ServerConfig config;

  /// true이면 [fetch]가 [ServerConfigFailure]를 던진다.
  bool fail = false;

  /// 설정하면 [fetch]가 이 Completer가 끝날 때까지 기다린다(불러오는 중 화면을 본다).
  Completer<void>? hold;

  int fetchCalls = 0;

  @override
  Future<ServerConfig> fetch() async {
    fetchCalls++;
    await hold?.future;
    if (fail) throw const ServerConfigFailure();
    return config;
  }
}

import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/server_config/data/api_server_config_repository.dart';
import 'package:cora/features/server_config/domain/server_config.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/server_config/presentation/viewmodels/server_config_view_model.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';
import 'fake_server_config_repository.dart';

const _configJson = {
  'feeRates': {'storeOffer': 10, 'brandContract': 12, 'bid': 8},
  'reward': {
    'countingDays': 7,
    'fixedCash': {
      'maxByCommissioner': {'store': 1000000, 'brand': 10000000},
      'presets': [0, 30000, 50000, 100000],
      'step': 10000,
    },
    'perViewCap': {
      'default': 60000,
      'max': 300000,
      'min': 10000,
      'step': 10000,
    },
    'usageRightsDefault': 'STORE_REPOST_3M',
    'viewRate': {'default': 2000, 'max': 5000, 'min': 1000, 'step': 500},
    'voucher': {
      'defaultName': '식사권',
      'defaultPeople': 2,
      'defaultValue': 40000,
      'maxPeople': 10,
      'minValue': 1000,
      'maxValue': 1000000,
    },
  },
};

ApiServerConfigRepository _repo(FakeHttpClient fake) =>
    ApiServerConfigRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

void main() {
  group('ApiServerConfigRepository', () {
    test('reads the ranges and fee rates from GET /config', () async {
      final fake = FakeHttpClient()..body = jsonEncode(_configJson);

      final config = await _repo(fake).fetch();

      expect(fake.requests.single.url.path, '/config');
      expect(config.reward.viewRate.values, [
        1000,
        1500,
        2000,
        2500,
        3000,
        3500,
        4000,
        4500,
        5000,
      ]);
      expect(config.reward.perViewCap.values.first, 10000);
      expect(config.reward.perViewCap.values.last, 300000);
      expect(config.reward.fixedCash.presets, [0, 30000, 50000, 100000]);
      expect(config.reward.fixedCash.storeMax, 1000000);
      expect(config.reward.fixedCash.brandMax, 10000000);
      expect(config.reward.voucher.maxPeople, 10);
      expect(config.reward.voucher.minValue, 1000);
      expect(config.reward.voucher.maxValue, 1000000);
      expect(config.reward.usageRightsDefault, UsageRights.storeRepost3m);
      expect(config.reward.countingDays, 7);
      expect(config.feeRates.storeOffer, 10);
      expect(config.feeRates.brandContract, 12);
      expect(config.feeRates.bid, 8);
    });

    test('builds the default terms from the defaults in the config', () async {
      final fake = FakeHttpClient()..body = jsonEncode(_configJson);

      final terms = (await _repo(fake).fetch()).defaultTerms;

      expect(terms.format, ContentFormat.reels);
      expect(
        terms.reward,
        const Reward(
          voucher: Voucher(name: '식사권', value: 40000, people: 2),
          viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      );
      expect(terms.reward.maxCashBurden, 60000);
      expect(terms.usageRights, UsageRights.storeRepost3m);
    });

    test('turns any failure into a ServerConfigFailure', () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body = '{"error":{"code":"INTERNAL","message":"x","details":null}}';

      await expectLater(
        _repo(fake).fetch(),
        throwsA(isA<ServerConfigFailure>()),
      );
    });
  });

  group('StepRange', () {
    test('knows which values are on its steps', () {
      const range = StepRange(
        min: 1000,
        max: 5000,
        step: 500,
        defaultValue: 2000,
      );
      expect(range.contains(2500), isTrue);
      expect(range.contains(2400), isFalse);
      expect(range.contains(5500), isFalse);
      expect(range.contains(500), isFalse);
    });
  });

  group('serverConfigViewModelProvider', () {
    test('reads once and keeps the value', () async {
      final repo = FakeServerConfigRepository();
      final container = ProviderContainer(
        overrides: [serverConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final first = await container.read(serverConfigViewModelProvider.future);
      final second = await container.read(serverConfigViewModelProvider.future);

      expect(first, same(second));
      expect(repo.fetchCalls, 1);
    });

    test('can be retried after a failure', () async {
      final repo = FakeServerConfigRepository()..fail = true;
      final container = ProviderContainer(
        overrides: [serverConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(serverConfigViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      await expectLater(
        container.read(serverConfigViewModelProvider.future),
        throwsA(isA<ServerConfigFailure>()),
      );
      expect(container.read(serverConfigViewModelProvider).hasError, isTrue);

      repo.fail = false;
      container.read(serverConfigViewModelProvider.notifier).reload();
      final config = await container.read(serverConfigViewModelProvider.future);

      expect(config.feeRates.storeOffer, 10);
      expect(repo.fetchCalls, 2);
    });
  });
}

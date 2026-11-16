import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/navigation/role_entry.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_brand_repository.dart';
import 'fake_campaign_repository.dart';

Future<String> _resolve({
  FakeBrandRepository? brand,
  FakeCampaignRepository? campaign,
}) {
  final container = ProviderContainer(
    overrides: [
      brandRepositoryProvider.overrideWithValue(brand ?? FakeBrandRepository()),
      campaignRepositoryProvider.overrideWithValue(
        campaign ?? FakeCampaignRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  final ref = container.read(Provider((ref) => ref));
  return defaultRoleEntryResolver(ref, UserRole.brand);
}

void main() {
  test('brand entry goes to profile, then campaign, then discovery', () async {
    expect(await _resolve(), AppRoutes.brandProfileSetup);

    expect(
      await _resolve(brand: FakeBrandRepository(profile: defaultBrandProfile)),
      AppRoutes.brandCampaignNew,
    );

    expect(
      await _resolve(
        brand: FakeBrandRepository(profile: defaultBrandProfile),
        campaign: FakeCampaignRepository(active: defaultCampaign),
      ),
      AppRoutes.brand,
    );
  });

  test(
    'brand entry throws when a lookup fails so the router can retry',
    () async {
      await expectLater(
        _resolve(brand: FakeBrandRepository()..failFetch = true),
        throwsA(isA<BrandFailure>()),
      );
    },
  );
}

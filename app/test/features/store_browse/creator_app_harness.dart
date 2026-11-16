import 'package:cora/core/time/clock.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/collaboration/presentation/mail_launcher.dart';
import 'package:cora/features/creator_profile/domain/creator_profile.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/core/config/app_config.dart';
import 'package:cora/features/instagram_connect/domain/instagram_repository.dart';
import 'package:cora/features/payout_account/domain/payout_account_repository.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/offers/domain/received_offers_repository.dart';
import 'package:cora/features/offers/presentation/viewmodels/received_offers_view_model.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/proposals/domain/counter_proposal_repository.dart';
import 'package:cora/features/store_browse/domain/store_browse_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../creator_profile/fake_creator_profile_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../offers/fake_received_offers_repository.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../payout_account/fake_payout_account_repository.dart';
import '../proposals/fake_counter_proposal_repository.dart';
import '../onboarding/fake_me_repository.dart';
import 'fake_store_browse_repository.dart';

/// 로그인한 크리에이터로 실제 [CoraApp]을 띄운다. 프로필이 있으니 첫 화면은 크리에이터 홈
/// (`/creator`)이고, 활동 지역은 서울이다.
Future<void> pumpCreatorApp(
  WidgetTester tester, {
  FakeStoreBrowseRepository? stores,

  /// 08이 읽는 오늘 목록. 주지 않으면 [stores]의 가게마다 가게 카드 하나다.
  FakeDiscoveryRepository? discovery,
  FakeReceivedOffersRepository? offers,
  FakeCollaborationRepository? collaborations,
  MailLauncher? mail,
  FakePayoutAccountRepository? payoutAccounts,
  FakeInstagramRepository? instagram,
  FakeCounterProposalRepository? counter,
  CoraEnv env = CoraEnv.dev,
  String mySido = '서울특별시',
  Duration undoWindow = const Duration(seconds: 30),
  bool profileFails = false,
  bool smallPhoneLargeText = false,
  FakeClock? clock,
  List<Override> overrides = const [],
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    usePhone(tester);
  }
  final browse = stores ?? FakeStoreBrowseRepository();
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.creator),
    env: env,
    overrides: [
      creatorProfileRepositoryProvider.overrideWithValue(
        FakeCreatorProfileRepository(
          profile: CreatorProfile(displayName: '서윤', regionSido: mySido),
        )..failFetch = profileFails,
      ),
      storeBrowseRepositoryProvider.overrideWithValue(browse),
      discoveryRepositoryProvider.overrideWithValue(
        discovery ??
            FakeDiscoveryRepository(
              campaignCards: [
                for (final s in browse.stores)
                  discoveryStore(
                    s.id,
                    summary: s,
                    name: s.name,
                    otherSido: s.regionSido != mySido ? s.regionSido : null,
                  ),
              ],
            ),
      ),
      receivedOffersRepositoryProvider.overrideWithValue(
        offers ?? FakeReceivedOffersRepository(),
      ),
      collaborationRepositoryProvider.overrideWithValue(
        collaborations ?? FakeCollaborationRepository(),
      ),
      if (mail != null) mailLauncherProvider.overrideWithValue(mail),
      instagramRepositoryProvider.overrideWithValue(
        instagram ?? FakeInstagramRepository(),
      ),
      counterProposalRepositoryProvider.overrideWithValue(
        counter ?? FakeCounterProposalRepository(),
      ),
      payoutAccountRepositoryProvider.overrideWithValue(
        payoutAccounts ?? FakePayoutAccountRepository(),
      ),
      undoDeclineWindowProvider.overrideWithValue(undoWindow),
      clockProvider.overrideWithValue(clock ?? FakeClock()),
      ...overrides,
    ],
  );
}

/// 쌓인 화면 가운데 맨 위 화면의 경로. `push`한 화면은 `currentPath`에 나오지 않는다.
String topPath(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.last.matchedLocation;

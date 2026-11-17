import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/presentation/viewmodels/contract_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat/chat_fixtures.dart' show FakeRealtimeConnection;
import '../collaboration/fake_collaboration_repository.dart';
import 'brand_collaboration_harness.dart';
import 'fake_negotiation_repository.dart';

ProviderContainer _container(FakeNegotiationRepository repo) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      negotiationRepositoryProvider.overrideWithValue(repo),
      realtimeConnectionProvider.overrideWithValue(FakeRealtimeConnection()),
      collaborationRepositoryProvider.overrideWithValue(
        FakeCollaborationRepository(
          active: [brandCollab(role: CollaborationRole.creator)],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('the voided notice counts as seen only after it was rendered', () async {
    final repo = FakeNegotiationRepository()
      ..contract = sampleContract(voidedNotice: true);
    final container = _container(repo);
    final provider = contractViewModelProvider(brandCollabId);

    // 화면이 띠를 그리기 전에 만들어졌다 버려져도(다시 시도, 사용자 변화 등) 본 것으로 치지 않는다.
    var subscription = container.listen(provider, (_, _) {});
    expect((await container.read(provider.future)).showVoidedNotice, isTrue);
    subscription.close();
    await Future<void>.delayed(Duration.zero);

    subscription = container.listen(provider, (_, _) {});
    expect((await container.read(provider.future)).showVoidedNotice, isTrue);

    // 그려진 뒤 알리면 본 것이 된다.
    container.read(provider.notifier).markVoidedNoticeSeen();
    subscription.close();
    await Future<void>.delayed(Duration.zero);

    subscription = container.listen(provider, (_, _) {});
    expect((await container.read(provider.future)).showVoidedNotice, isFalse);
    subscription.close();
  });
}

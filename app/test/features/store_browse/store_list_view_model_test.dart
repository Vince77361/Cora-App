import 'package:cora/features/creator_profile/domain/creator_profile.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/store_browse/domain/store_browse_repository.dart';
import 'package:cora/features/store_browse/presentation/viewmodels/store_list_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../creator_profile/fake_creator_profile_repository.dart';
import 'fake_store_browse_repository.dart';

ProviderContainer _container({
  required FakeStoreBrowseRepository stores,
  required FakeCreatorProfileRepository profile,
}) {
  final container = ProviderContainer(
    overrides: [
      storeBrowseRepositoryProvider.overrideWithValue(stores),
      creatorProfileRepositoryProvider.overrideWithValue(profile),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('marks only stores outside my province', () async {
    final busan = ramenStore(id: '2', regionSido: '부산광역시');
    final container = _container(
      stores: FakeStoreBrowseRepository(stores: [ramenStore(), busan]),
      profile: FakeCreatorProfileRepository(
        profile: const CreatorProfile(displayName: '서윤', regionSido: '서울특별시'),
      ),
    );

    final state = await container.read(storeListViewModelProvider.future);

    expect(state.inOtherProvince(state.stores[0]), isFalse);
    expect(state.inOtherProvince(state.stores[1]), isTrue);
  });

  test('does not mark anything when my province is unknown', () async {
    // 프로필을 못 읽어도 목록은 보이고 시·도 표지만 붙이지 않는다.
    final container = _container(
      stores: FakeStoreBrowseRepository(
        stores: [ramenStore(regionSido: '부산광역시')],
      ),
      profile: FakeCreatorProfileRepository()..failFetch = true,
    );

    final state = await container.read(storeListViewModelProvider.future);

    expect(state.mySido, isNull);
    expect(state.inOtherProvince(state.stores.single), isFalse);
  });

  test('keeps the visible list when a refresh fails', () async {
    final stores = FakeStoreBrowseRepository();
    final container = _container(
      stores: stores,
      profile: FakeCreatorProfileRepository(),
    );
    await container.read(storeListViewModelProvider.future);

    stores.failFetch = true;
    await container.read(storeListViewModelProvider.notifier).refresh();

    expect(
      container.read(storeListViewModelProvider).value?.stores,
      hasLength(1),
    );
  });
}

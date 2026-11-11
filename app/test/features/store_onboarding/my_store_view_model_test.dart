import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/domain/store_repository.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store_repository.dart';
import 'store_view_model_support.dart';

void main() {
  test('is null for a user who has no store yet', () async {
    final container = storeContainer();

    expect(await container.read(myStoreViewModelProvider.future), isNull);
  });

  test('loads the saved store', () async {
    final container = storeContainer(
      stores: FakeStoreRepository(store: sampleStore()),
    );

    final store = await container.read(myStoreViewModelProvider.future);

    expect(store?.name, '한그릇 라멘');
    expect(store?.industry, IndustryCategory.foodCafe);
  });

  test(
    'analyze replaces the state with the new store and returns the flag',
    () async {
      final stores = FakeStoreRepository();
      final container = storeContainer(stores: stores);
      await container.read(myStoreViewModelProvider.future);
      const link = SourceLink(
        kind: SourceLinkKind.naverMap,
        url: 'https://naver.me/abc',
      );

      final failed = await container
          .read(myStoreViewModelProvider.notifier)
          .analyze([link]);

      expect(failed, isFalse);
      expect(container.read(myStoreViewModelProvider).value?.name, '한그릇 라멘');
      expect(stores.analyzed.single.single, link);
    },
  );

  test(
    'analyze returns true and keeps an empty store when nothing was read',
    () async {
      final stores = FakeStoreRepository()..analysisFails = true;
      final container = storeContainer(stores: stores);
      await container.read(myStoreViewModelProvider.future);

      final failed = await container
          .read(myStoreViewModelProvider.notifier)
          .analyze([
            const SourceLink(
              kind: SourceLinkKind.naverMap,
              url: 'https://naver.me/fail',
            ),
          ]);

      expect(failed, isTrue);
      final store = container.read(myStoreViewModelProvider).value!;
      expect(store.hasName, isFalse);
      expect(store.wasAutoFilled, isFalse);
    },
  );

  test('a failed change throws and leaves the state alone', () async {
    final stores = FakeStoreRepository(store: sampleStore())..failUpdate = true;
    final container = storeContainer(stores: stores);
    await container.read(myStoreViewModelProvider.future);

    await expectLater(
      container
          .read(myStoreViewModelProvider.notifier)
          .saveEdit(const StoreEdit(name: '바뀐 이름')),
      throwsA(isA<StoreFailure>()),
    );

    expect(container.read(myStoreViewModelProvider).value?.name, '한그릇 라멘');
  });

  test('advance moves the saved step forward', () async {
    final stores = FakeStoreRepository(store: sampleStore());
    final container = storeContainer(stores: stores);
    await container.read(myStoreViewModelProvider.future);

    await container
        .read(myStoreViewModelProvider.notifier)
        .advance(StoreOnboardingStep.drafts);

    expect(
      container.read(myStoreViewModelProvider).value?.onboardingStep,
      StoreOnboardingStep.drafts,
    );
  });
}

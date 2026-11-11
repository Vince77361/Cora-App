import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/navigation/role_entry.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store_repository.dart';
import 'store_view_model_support.dart';

/// 진입 규칙이 라우터에서 받는 `Ref`를 흉내 낸다.
final _refProvider = Provider<Ref>((ref) => ref);

Future<String> _entry(ProviderContainer container) => container.read(
  roleEntryResolverProvider,
)(container.read(_refProvider), UserRole.store);

void main() {
  test('resumes at the links step when no store exists', () async {
    final container = storeContainer();

    expect(await _entry(container), AppRoutes.storeOnboardingLinks);
  });

  test('resumes at the page step for a draft store saved at PAGE', () async {
    final container = storeContainer(
      stores: FakeStoreRepository(store: sampleStore()),
    );

    expect(await _entry(container), AppRoutes.storeOnboardingPage);
  });

  test(
    'resumes at the drafts step for a draft store saved at DRAFTS',
    () async {
      final container = storeContainer(
        stores: FakeStoreRepository(
          store: sampleStore(step: StoreOnboardingStep.drafts),
        ),
      );

      expect(await _entry(container), AppRoutes.storeOnboardingDrafts);
    },
  );

  test('resumes at the terms step for a draft store saved at TERMS', () async {
    final container = storeContainer(
      stores: FakeStoreRepository(
        store: sampleStore(step: StoreOnboardingStep.terms),
      ),
    );

    expect(await _entry(container), AppRoutes.storeOnboardingTerms);
  });

  test('opens the owner home for a published store', () async {
    final container = storeContainer(
      stores: FakeStoreRepository(
        store: sampleStore(
          status: StoreStatus.published,
          step: StoreOnboardingStep.done,
        ),
      ),
    );

    expect(await _entry(container), AppRoutes.store);
  });

  test('follows the store as it moves forward in the same session', () async {
    final stores = FakeStoreRepository(store: sampleStore());
    final container = storeContainer(stores: stores);
    expect(await _entry(container), AppRoutes.storeOnboardingPage);

    await container
        .read(myStoreViewModelProvider.notifier)
        .advance(StoreOnboardingStep.drafts);

    expect(await _entry(container), AppRoutes.storeOnboardingDrafts);
  });

  test('a failed load is thrown, and the next entry tries again', () async {
    final stores = FakeStoreRepository(store: sampleStore())..failFetch = true;
    final container = storeContainer(stores: stores);

    await expectLater(_entry(container), throwsA(anything));

    stores.failFetch = false;
    expect(await _entry(container), AppRoutes.storeOnboardingPage);
  });
}

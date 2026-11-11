import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/store_edit_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import 'fake_store_repository.dart';
import 'store_view_model_support.dart';

Future<ProviderContainer> _open({
  FakeStoreRepository? stores,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
}) async {
  final container = storeContainer(
    stores: stores ?? FakeStoreRepository(store: sampleStore()),
    picker: picker,
    uploader: uploader,
  );
  await container.read(myStoreViewModelProvider.future);
  container.listen(storeEditViewModelProvider, (_, _) {});
  await container.read(storeEditViewModelProvider.future);
  return container;
}

StoreEditViewModel _vm(ProviderContainer c) =>
    c.read(storeEditViewModelProvider.notifier);
StoreEditState _state(ProviderContainer c) =>
    c.read(storeEditViewModelProvider).requireValue;

void main() {
  test('starts from the saved store', () async {
    final c = await _open();

    expect(_state(c).valueOf(StoreTextField.name), '한그릇 라멘');
    expect(_state(c).valueOf(StoreTextField.hours), '11:30 – 21:00');
    expect(_state(c).industry, IndustryCategory.foodCafe);
    expect(_state(c).regionSido, '서울특별시');
  });

  test('cannot save without a store name', () async {
    final c = await _open();

    _vm(c).setText(StoreTextField.name, '  ');
    expect(_state(c).canSave, isFalse);
    expect(await _vm(c).save(), isFalse);

    _vm(c).setText(StoreTextField.name, '새 이름');
    expect(_state(c).canSave, isTrue);
  });

  test('save sends trimmed values and updates the shared store', () async {
    final stores = FakeStoreRepository(store: sampleStore());
    final c = await _open(stores: stores);
    _vm(c).setText(StoreTextField.name, ' 두그릇 라멘 ');
    _vm(c).setText(StoreTextField.seats, '');
    _vm(c).setIndustry(IndustryCategory.beauty);
    _vm(c).setRegionSido('부산광역시');

    expect(await _vm(c).save(), isTrue);

    final edit = stores.edits.single;
    expect(edit.name, '두그릇 라멘');
    // 비운 항목은 빈 글자로 보내 서버가 지우게 한다.
    expect(edit.seats, '');
    expect(edit.industry, IndustryCategory.beauty);
    expect(edit.regionSido, '부산광역시');
    expect(c.read(myStoreViewModelProvider).value?.name, '두그릇 라멘');
  });

  test('a failed save keeps the values and flags the failure', () async {
    final c = await _open(
      stores: FakeStoreRepository(store: sampleStore())..failUpdate = true,
    );
    _vm(c).setText(StoreTextField.name, '두그릇 라멘');

    expect(await _vm(c).save(), isFalse);

    expect(_state(c).saveFailed, isTrue);
    expect(_state(c).saving, isFalse);
    expect(_state(c).valueOf(StoreTextField.name), '두그릇 라멘');
    expect(c.read(myStoreViewModelProvider).value?.name, '한그릇 라멘');

    _vm(c).setText(StoreTextField.name, '두그릇 라멘!');
    expect(_state(c).saveFailed, isFalse);
  });

  test('changePhoto uploads for the store cover and keeps the path', () async {
    final uploader = FakePhotoUploader()..path = 'stores/user-1/a.jpg';
    final c = await _open(
      picker: FakePhotoPicker(
        next: PickedPhoto(bytes: Uint8List(4), contentType: 'image/jpeg'),
      ),
      uploader: uploader,
    );

    await _vm(c).changePhoto();

    expect(_state(c).coverPhotoPath, 'stores/user-1/a.jpg');
    expect(_state(c).coverPreview, isNotNull);
    expect(_state(c).uploadingPhoto, isFalse);
  });

  test('changePhoto does nothing when the picker is closed', () async {
    final uploader = FakePhotoUploader();
    final c = await _open(uploader: uploader);

    await _vm(c).changePhoto();

    expect(uploader.uploadCalls, 0);
    expect(_state(c).coverPhotoPath, isNull);
  });

  test('changePhoto reports a photo over 5MB without uploading it', () async {
    final uploader = FakePhotoUploader();
    final c = await _open(
      picker: FakePhotoPicker(
        next: PickedPhoto(
          bytes: Uint8List(5 * 1024 * 1024 + 1),
          contentType: 'image/jpeg',
        ),
      ),
      uploader: uploader,
    );

    await _vm(c).changePhoto();

    expect(_state(c).photoProblem, StorePhotoProblem.tooLarge);
    expect(uploader.uploadCalls, 0);
  });
}

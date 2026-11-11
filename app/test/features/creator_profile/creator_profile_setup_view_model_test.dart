import 'dart:async';
import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/creator_profile/presentation/viewmodels/creator_profile_setup_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import 'fake_creator_profile_repository.dart';

ProviderContainer _container({
  FakeCreatorProfileRepository? repo,
  FakePhotoUploader? uploader,
  FakePhotoPicker? picker,
}) {
  final container = ProviderContainer(
    overrides: [
      creatorProfileRepositoryProvider.overrideWithValue(
        repo ?? FakeCreatorProfileRepository(),
      ),
      photoUploaderProvider.overrideWithValue(uploader ?? FakePhotoUploader()),
      photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

CreatorProfileSetupViewModel _vm(ProviderContainer c) =>
    c.read(creatorProfileSetupViewModelProvider.notifier);

CreatorProfileSetupState _state(ProviderContainer c) =>
    c.read(creatorProfileSetupViewModelProvider).requireValue;

Future<ProviderContainer> _ready(ProviderContainer c) async {
  c.listen(creatorProfileSetupViewModelProvider, (_, _) {});
  await c.read(creatorProfileSetupViewModelProvider.future);
  return c;
}

void main() {
  test('cannot submit until a name and a province are both given', () async {
    final c = await _ready(_container());
    expect(_state(c).canSubmit, isFalse);

    _vm(c).setDisplayName('  ');
    expect(_state(c).canSubmit, isFalse);

    _vm(c).setDisplayName('서윤');
    expect(_state(c).canSubmit, isFalse);

    _vm(c).setRegionSido('서울특별시');
    expect(_state(c).canSubmit, isTrue);
  });

  test('saves the trimmed values and leaves blank optional ones out', () async {
    final repo = FakeCreatorProfileRepository();
    final c = await _ready(_container(repo: repo));
    _vm(c)
      ..setDisplayName('  서윤  ')
      ..setRegionSido('경기도')
      ..setRegionSigungu('  ')
      ..setContentFocus(' 맛집 릴스 ')
      ..setInstagramHandle('');

    final ok = await _vm(c).submit();

    expect(ok, isTrue);
    expect(repo.savedDisplayName, '서윤');
    expect(repo.savedRegionSido, '경기도');
    expect(repo.savedRegionSigungu, isNull);
    expect(repo.savedContentFocus, '맛집 릴스');
    expect(repo.savedInstagramHandle, isNull);
    expect(repo.savedPhotoPath, isNull);
  });

  test('uploads the picked photo first and saves its path', () async {
    final repo = FakeCreatorProfileRepository();
    final uploader = FakePhotoUploader()..path = 'creators/u/p.png';
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(10), contentType: 'image/png'),
    );
    final c = await _ready(
      _container(repo: repo, uploader: uploader, picker: picker),
    );
    _vm(c)
      ..setDisplayName('서윤')
      ..setRegionSido('서울특별시');

    await _vm(c).pickPhoto();
    expect(_state(c).photo, isNotNull);
    final ok = await _vm(c).submit();

    expect(ok, isTrue);
    expect(uploader.lastPurpose, PhotoPurpose.creatorPhoto);
    expect(uploader.lastContentType, 'image/png');
    expect(repo.savedPhotoPath, 'creators/u/p.png');
  });

  test(
    'keeps the current photo when the picker is closed without a choice',
    () async {
      final picker = FakePhotoPicker(
        next: PickedPhoto(bytes: Uint8List(10), contentType: 'image/jpeg'),
      );
      final c = await _ready(_container(picker: picker));
      await _vm(c).pickPhoto();
      picker.next = null;
      await _vm(c).pickPhoto();
      expect(_state(c).photo, isNotNull);
    },
  );

  test(
    'refuses a photo over 5MB when it is picked and does not keep it',
    () async {
      final picker = FakePhotoPicker(
        next: PickedPhoto(
          bytes: Uint8List(maxPhotoBytes + 1),
          contentType: 'image/jpeg',
        ),
      );
      final c = await _ready(_container(picker: picker));

      await _vm(c).pickPhoto();

      expect(_state(c).photo, isNull);
      expect(_state(c).error, CreatorProfileSetupError.photoTooLarge);
    },
  );

  test('a failed save keeps every input and reports the error', () async {
    final repo = FakeCreatorProfileRepository()..failSave = true;
    final c = await _ready(_container(repo: repo));
    _vm(c)
      ..setDisplayName('서윤')
      ..setRegionSido('서울특별시')
      ..setContentFocus('맛집 릴스');

    final ok = await _vm(c).submit();

    expect(ok, isFalse);
    final s = _state(c);
    expect(s.error, CreatorProfileSetupError.saveFailed);
    expect(s.saving, isFalse);
    expect(s.displayName, '서윤');
    expect(s.regionSido, '서울특별시');
    expect(s.contentFocus, '맛집 릴스');
  });

  test('a failed photo upload does not save the profile', () async {
    final repo = FakeCreatorProfileRepository();
    final uploader = FakePhotoUploader()..fail = true;
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(10), contentType: 'image/jpeg'),
    );
    final c = await _ready(
      _container(repo: repo, uploader: uploader, picker: picker),
    );
    _vm(c)
      ..setDisplayName('서윤')
      ..setRegionSido('서울특별시');
    await _vm(c).pickPhoto();

    final ok = await _vm(c).submit();

    expect(ok, isFalse);
    expect(repo.saveCalls, 0);
    expect(_state(c).error, CreatorProfileSetupError.saveFailed);
  });

  test('editing an input clears a previous error', () async {
    final repo = FakeCreatorProfileRepository()..failSave = true;
    final c = await _ready(_container(repo: repo));
    _vm(c)
      ..setDisplayName('서윤')
      ..setRegionSido('서울특별시');
    await _vm(c).submit();

    _vm(c).setDisplayName('서윤이');

    expect(_state(c).error, isNull);
  });

  test('ignores a second submit while saving', () async {
    final repo = FakeCreatorProfileRepository();
    final c = await _ready(_container(repo: repo));
    _vm(c)
      ..setDisplayName('서윤')
      ..setRegionSido('서울특별시');
    final hold = repo.holdSave = Completer<void>();

    final first = _vm(c).submit();
    await Future<void>.delayed(Duration.zero);
    expect(_state(c).saving, isTrue);
    final second = await _vm(c).submit();
    hold.complete();
    await first;

    expect(second, isFalse);
    expect(repo.saveCalls, 1);
  });
}

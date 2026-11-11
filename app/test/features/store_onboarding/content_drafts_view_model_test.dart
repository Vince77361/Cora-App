import 'package:cora/features/store_onboarding/domain/content_draft.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/content_drafts_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_content_draft_repository.dart';
import 'store_view_model_support.dart';

Future<ProviderContainer> _open(FakeContentDraftRepository drafts) async {
  final container = storeContainer(drafts: drafts);
  container.listen(contentDraftsViewModelProvider, (_, _) {});
  await container.read(contentDraftsViewModelProvider.future);
  return container;
}

ContentDraftsViewModel _vm(ProviderContainer c) =>
    c.read(contentDraftsViewModelProvider.notifier);
ContentDraftsState _state(ProviderContainer c) =>
    c.read(contentDraftsViewModelProvider).requireValue;

void main() {
  test('orders the tabs card news, reels script, blog', () async {
    final c = await _open(
      FakeContentDraftRepository(drafts: sampleDrafts().reversed.toList()),
    );

    expect(_state(c).drafts.map((d) => d.kind), ContentDraftKind.values);
    expect(_state(c).current.kind, ContentDraftKind.cardNews);
  });

  test('regenerate only touches the selected draft', () async {
    final repo = FakeContentDraftRepository();
    final c = await _open(repo);
    _vm(c).select(2);

    await _vm(c).regenerate();

    expect(repo.regenerated, [ContentDraftKind.blog]);
    expect(_state(c).drafts[2].regenerationsLeftToday, 9);
    expect(_state(c).drafts[0].regenerationsLeftToday, 10);
    expect(_state(c).versionOf(ContentDraftKind.blog), 1);
    expect(_state(c).versionOf(ContentDraftKind.cardNews), 0);
  });

  test('regenerate does nothing when none are left', () async {
    final repo = FakeContentDraftRepository(drafts: sampleDrafts(left: 0));
    final c = await _open(repo);

    expect(_state(c).canRegenerate, isFalse);
    await _vm(c).regenerate();

    expect(repo.regenerated, isEmpty);
  });

  test('a limit answer zeroes the left count of that draft only', () async {
    final repo = FakeContentDraftRepository()..limitReached = true;
    final c = await _open(repo);

    await _vm(c).regenerate();

    expect(_state(c).limitReached, isTrue);
    expect(_state(c).drafts[1].regenerationsLeftToday, 10);
    expect(_state(c).regenerateFailed, isFalse);
  });

  test(
    'a failure keeps the draft and flags it until the next action',
    () async {
      final repo = FakeContentDraftRepository()..failRegenerate = true;
      final c = await _open(repo);

      await _vm(c).regenerate();

      expect(_state(c).regenerateFailed, isTrue);
      expect(_state(c).canRegenerate, isTrue);
      _vm(c).select(1);
      expect(_state(c).regenerateFailed, isFalse);
    },
  );

  test('cannot switch tabs while regenerating', () async {
    final c = await _open(FakeContentDraftRepository());
    final pending = _vm(c).regenerate();

    _vm(c).select(1);
    await pending;

    expect(_state(c).selected, 0);
  });
}

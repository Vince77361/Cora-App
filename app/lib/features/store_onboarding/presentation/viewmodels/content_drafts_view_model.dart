import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content_draft.dart';
import '../../domain/content_draft_repository.dart';
import '../../domain/content_draft_repository_provider.dart';

/// AI 초안 화면(A4)의 상태. 화면을 떠나면 고른 탭도 버린다.
final contentDraftsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      ContentDraftsViewModel,
      ContentDraftsState
    >(ContentDraftsViewModel.new, retry: (_, _) => null);

class ContentDraftsState {
  const ContentDraftsState({
    required this.drafts,
    this.selected = 0,
    this.versions = const {},
    this.regenerating = false,
    this.regenerateFailed = false,
  });

  /// 탭 순서(카드뉴스, 릴스 대본, 블로그 글)의 초안.
  final List<ContentDraft> drafts;
  final int selected;

  /// 종류마다 이 화면에서 다시 만든 횟수. 사진 없는 슬라이드의 색이 다시 만들 때마다 바뀐다(캔버스).
  final Map<ContentDraftKind, int> versions;
  final bool regenerating;
  final bool regenerateFailed;

  ContentDraft get current => drafts[selected];

  /// 보고 있는 탭을 오늘 더 다시 만들 수 있는지.
  bool get canRegenerate => !regenerating && current.regenerationsLeftToday > 0;

  /// 오늘 더 만들 수 없어 막힌 상태.
  bool get limitReached => current.regenerationsLeftToday <= 0;

  int versionOf(ContentDraftKind kind) => versions[kind] ?? 0;

  ContentDraftsState copyWith({
    List<ContentDraft>? drafts,
    int? selected,
    Map<ContentDraftKind, int>? versions,
    bool? regenerating,
    bool? regenerateFailed,
  }) => ContentDraftsState(
    drafts: drafts ?? this.drafts,
    selected: selected ?? this.selected,
    versions: versions ?? this.versions,
    regenerating: regenerating ?? this.regenerating,
    regenerateFailed: regenerateFailed ?? this.regenerateFailed,
  );
}

class ContentDraftsViewModel extends AsyncNotifier<ContentDraftsState> {
  @override
  Future<ContentDraftsState> build() async {
    final drafts = await ref.read(contentDraftRepositoryProvider).fetchMine();
    // 탭 순서를 고정한다. 서버가 다른 순서로 주어도 화면은 카드뉴스, 릴스 대본, 블로그 글이다.
    final ordered = [
      for (final kind in ContentDraftKind.values)
        ...drafts.where((d) => d.kind == kind),
    ];
    if (ordered.isEmpty) throw const ContentDraftFailure();
    return ContentDraftsState(drafts: ordered);
  }

  void select(int index) {
    final current = state.value;
    if (current == null || current.regenerating) return;
    if (index < 0 || index >= current.drafts.length) return;
    state = AsyncData(
      current.copyWith(selected: index, regenerateFailed: false),
    );
  }

  /// 지금 보고 있는 탭만 다시 만든다.
  Future<void> regenerate() async {
    final current = state.value;
    if (current == null || !current.canRegenerate) return;
    final kind = current.current.kind;
    state = AsyncData(
      current.copyWith(regenerating: true, regenerateFailed: false),
    );
    ContentDraft? fresh;
    var failed = false;
    var limit = false;
    try {
      fresh = await ref.read(contentDraftRepositoryProvider).regenerate(kind);
    } on DraftRegenerationLimit {
      limit = true;
    } on ContentDraftFailure {
      failed = true;
    }
    if (!ref.mounted) return;
    // 기다리는 동안 다른 변화는 없지만(탭 이동은 막혀 있다) 최신 상태에서 이어 간다.
    final latest = state.value ?? current;
    final drafts = [
      for (final d in latest.drafts)
        if (d.kind != kind)
          d
        else if (fresh != null)
          fresh
        else if (limit)
          d.withRegenerationsLeft(0)
        else
          d,
    ];
    state = AsyncData(
      latest.copyWith(
        drafts: drafts,
        regenerating: false,
        regenerateFailed: failed,
        versions: fresh == null
            ? null
            : {...latest.versions, kind: latest.versionOf(kind) + 1},
      ),
    );
  }
}

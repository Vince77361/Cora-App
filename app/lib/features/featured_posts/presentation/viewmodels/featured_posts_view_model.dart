import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../instagram_connect/domain/instagram_repository.dart';
import '../../domain/featured_post.dart';
import '../../domain/featured_posts_repository.dart';
import '../featured_posts_text.dart';

/// 대표 게시물 화면의 상태. [items]가 화면에 보이는 목록(저장 전의 바뀜 포함), [original]이 서버에 저장된 목록이다.
class FeaturedPostsState {
  const FeaturedPostsState({
    required this.items,
    required this.original,
    this.instagramHandle,
    this.saving = false,
    this.error,
  });

  final List<FeaturedPost> items;
  final List<FeaturedPost> original;

  /// 연동한 인스타그램 아이디(@ 없음). 연동하지 않았으면 null.
  final String? instagramHandle;
  final bool saving;

  /// 저장 실패 안내(서버 문구 또는 일반 문구).
  final String? error;

  bool get instagramConnected => instagramHandle != null;

  /// 저장하지 않은 바뀜이 있다(순서, 교체, 추가, 뺌). 저장된 행은 ID로, 초안은 늘 다른 것으로 본다.
  bool get dirty {
    if (items.length != original.length) return true;
    for (var i = 0; i < items.length; i++) {
      final id = items[i].id;
      if (id == null || id != original[i].id) return true;
    }
    return false;
  }

  /// 더 담을 수 있는 수(최대 4개).
  int get remaining => FeaturedPostLimits.maxPosts - items.length;

  /// 이미 대표 게시물인 인스타그램 게시물 ID. 저장된 것과 화면에 있는 초안 모두다(서버는 저장된 것을 다시 가져오지 못하게
  /// 막으므로, 화면에서 뺀 것도 저장하기 전에는 다시 고를 수 없다).
  Set<String> get importedInstagramIds => {
    for (final post in [...original, ...items]) ?post.instagramMediaId,
  };

  FeaturedPostsState copyWith({
    List<FeaturedPost>? items,
    List<FeaturedPost>? original,
    String? instagramHandle,
    bool clearInstagram = false,
    bool? saving,
    String? error,
    bool clearError = false,
  }) => FeaturedPostsState(
    items: items ?? this.items,
    original: original ?? this.original,
    instagramHandle: clearInstagram
        ? null
        : (instagramHandle ?? this.instagramHandle),
    saving: saving ?? this.saving,
    error: clearError ? null : (error ?? this.error),
  );
}

/// 크리에이터 프로필 설정 화면(`대표 게시물 n / 4` 줄)과 대표 게시물 화면이 함께 쓴다. 자동 재시도는 끈다.
final featuredPostsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      FeaturedPostsViewModel,
      FeaturedPostsState
    >(FeaturedPostsViewModel.new, retry: (_, _) => null);

class FeaturedPostsViewModel extends AsyncNotifier<FeaturedPostsState> {
  FeaturedPostsRepository get _repo =>
      ref.read(featuredPostsRepositoryProvider);

  @override
  Future<FeaturedPostsState> build() async {
    ref.watch(currentUserIdProvider);
    final posts = await _repo.fetchMine();
    return FeaturedPostsState(
      items: posts,
      original: posts,
      instagramHandle: await _instagramHandle(),
    );
  }

  /// 연동 여부를 읽지 못해도 대표 게시물은 보여야 하므로 실패는 "연동 안 됨"으로 본다.
  Future<String?> _instagramHandle() async {
    try {
      return (await ref.read(instagramRepositoryProvider).fetch())?.handle;
    } on InstagramFailure {
      return null;
    }
  }

  /// 연동 화면을 다녀온 뒤 연동 여부를 다시 읽는다.
  Future<void> refreshInstagram() async {
    final handle = await _instagramHandle();
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      handle == null
          ? current.copyWith(clearInstagram: true)
          : current.copyWith(instagramHandle: handle),
    );
  }

  // 저장 중에는 목록을 바꾸지 않는다. 바꾼 뒤에는 지난 오류 안내를 지운다.
  void _edit(FeaturedPostsState Function(FeaturedPostsState) f) {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(f(current).copyWith(clearError: true));
  }

  /// 뒤에 붙인다. 4개를 넘는 것은 담지 않는다(화면이 먼저 막는다).
  void addAll(List<FeaturedPost> posts) => _edit(
    (s) => s.copyWith(
      items: [...s.items, ...posts].take(FeaturedPostLimits.maxPosts).toList(),
    ),
  );

  /// [index] 자리의 게시물을 [post]로 바꾼다(인스타·사진첩에서 골라 교체).
  void replaceAt(int index, FeaturedPost post) => _edit((s) {
    if (index < 0 || index >= s.items.length) return s;
    return s.copyWith(items: [...s.items]..[index] = post);
  });

  void moveToFront(int index) => reorder(index, 0);

  void removeAt(int index) => _edit((s) {
    if (index < 0 || index >= s.items.length) return s;
    return s.copyWith(items: [...s.items]..removeAt(index));
  });

  /// [oldIndex]의 게시물을 [newIndex] 자리로 옮긴다(끌어 놓은 자리가 곧 새 번호이고 나머지는 한 칸씩 밀린다).
  void reorder(int oldIndex, int newIndex) => _edit((s) {
    final n = s.items.length;
    if (oldIndex < 0 || oldIndex >= n || newIndex < 0 || newIndex >= n) {
      return s;
    }
    if (oldIndex == newIndex) return s;
    final next = [...s.items];
    next.insert(newIndex, next.removeAt(oldIndex));
    return s.copyWith(items: next);
  });

  /// 저장하지 않은 바뀜을 버리고 서버에 있는 목록([FeaturedPostsState.original])으로 되돌린다. 프로필 설정 화면이 이
  /// autoDispose provider를 계속 보고 있어 화면을 나가도 상태가 남으므로, `저장 안 함`을 고른 쪽이 직접 부른다.
  /// 저장 중에는 되돌리지 않는다.
  void discard() {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(
      current.copyWith(items: current.original, clearError: true),
    );
  }

  /// 목록 전체를 한 번에 저장한다. 저장되면(또는 바뀐 것이 없으면) true. 실패하면 목록을 그대로 두고 false.
  Future<bool> save() async {
    final current = state.value;
    if (current == null || current.saving) return false;
    if (!current.dirty) return true;
    state = AsyncData(current.copyWith(saving: true, clearError: true));
    try {
      final saved = await _repo.replaceMine(current.items);
      if (!ref.mounted) return true;
      state = AsyncData(
        current.copyWith(items: saved, original: saved, saving: false),
      );
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final message = error is FeaturedPostsFailure ? error.message : null;
      state = AsyncData(
        current.copyWith(
          saving: false,
          error: (message == null || message.trim().isEmpty)
              ? FeaturedPostsText.saveFailed
              : message,
        ),
      );
      return false;
    }
  }
}

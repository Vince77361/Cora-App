import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../instagram_connect/domain/instagram_repository.dart';
import '../../domain/featured_post.dart';
import '../../domain/featured_posts_repository.dart';
import '../featured_posts_text.dart';
import 'featured_posts_view_model.dart';

/// 격자의 칸을 눌렀을 때의 결과. 한도를 넘으면 화면이 안내 문구를 띄운다.
enum InstagramPickToggle { picked, unpicked, limitReached, ignored }

/// 인스타에서 고르기 화면의 상태.
class InstagramPickState {
  const InstagramPickState({
    required this.posts,
    required this.handle,
    required this.imported,
    required this.limit,
    required this.single,
    this.picked = const [],
    this.busy = false,
    this.error,
  });

  final List<InstagramPost> posts;

  /// 연동한 인스타그램 아이디(@ 없음).
  final String handle;

  /// 이미 대표 게시물인 게시물 ID(격자에서 "가져옴"으로 보이고 다시 고를 수 없다).
  final Set<String> imported;

  /// 한 번에 고를 수 있는 수. 더하기는 (4 − 지금 개수), 교체는 1이다.
  final int limit;

  /// 교체(한 개만 고르고, 다른 칸을 누르면 고른 것을 바꾼다).
  final bool single;

  /// 고른 게시물 ID, 누른 차례대로.
  final List<String> picked;
  final bool busy;
  final String? error;

  InstagramPickState copyWith({
    List<String>? picked,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => InstagramPickState(
    posts: posts,
    handle: handle,
    imported: imported,
    limit: limit,
    single: single,
    picked: picked ?? this.picked,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );
}

/// [single]이 참이면 교체(`인스타에서 골라 교체`)다. 자동 재시도는 끈다.
final instagramPickViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<InstagramPickViewModel, InstagramPickState, bool>(
      InstagramPickViewModel.new,
      retry: (_, _) => null,
    );

class InstagramPickViewModel extends AsyncNotifier<InstagramPickState> {
  InstagramPickViewModel(this.single);

  final bool single;

  FeaturedPostsRepository get _repo =>
      ref.read(featuredPostsRepositoryProvider);

  @override
  Future<InstagramPickState> build() async {
    ref.watch(currentUserIdProvider);
    final featured = ref.read(featuredPostsViewModelProvider).value;
    final posts = await _repo.listInstagramPosts();
    final connection = await ref.read(instagramRepositoryProvider).fetch();
    return InstagramPickState(
      posts: posts,
      handle: connection?.handle ?? '',
      imported: featured?.importedInstagramIds ?? const {},
      limit: single ? 1 : (featured?.remaining ?? FeaturedPostLimits.maxPosts),
      single: single,
    );
  }

  InstagramPost? _post(InstagramPickState s, String id) {
    for (final post in s.posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  /// [id] 칸을 누른다. 가져왔거나 가져올 수 없는 칸은 무시하고, 한도를 넘는 새 칸은 [InstagramPickToggle.limitReached].
  InstagramPickToggle toggle(String id) {
    final s = state.value;
    if (s == null || s.busy) return InstagramPickToggle.ignored;
    final post = _post(s, id);
    if (post == null || s.imported.contains(id) || !post.importable) {
      return InstagramPickToggle.ignored;
    }
    if (s.picked.contains(id)) {
      state = AsyncData(
        s.copyWith(
          picked: [
            for (final p in s.picked)
              if (p != id) p,
          ],
          clearError: true,
        ),
      );
      return InstagramPickToggle.unpicked;
    }
    // 교체는 한 개만 고르므로 다른 칸을 누르면 고른 것을 바꾼다.
    if (s.single) {
      state = AsyncData(s.copyWith(picked: [id], clearError: true));
      return InstagramPickToggle.picked;
    }
    if (s.picked.length >= s.limit) return InstagramPickToggle.limitReached;
    state = AsyncData(s.copyWith(picked: [...s.picked, id], clearError: true));
    return InstagramPickToggle.picked;
  }

  /// 고른 게시물을 서버로 가져온다(저장은 대표 게시물 화면의 `저장하기`). 고른 차례대로 초안을 돌려주고, 실패하면
  /// 안내를 남기고 null이다.
  Future<List<FeaturedPost>?> importPicked() async {
    final s = state.value;
    if (s == null || s.busy || s.picked.isEmpty) return null;
    state = AsyncData(s.copyWith(busy: true, clearError: true));
    try {
      final drafts = await _repo.importInstagram(s.picked);
      if (!ref.mounted) return drafts;
      state = AsyncData(s.copyWith(busy: false));
      // 서버가 준 차례와 상관없이 고른 차례대로 놓는다.
      final byId = {for (final d in drafts) d.instagramMediaId: d};
      return [
        for (final id in s.picked)
          if (byId[id] != null) byId[id]!,
      ];
    } catch (error) {
      if (!ref.mounted) return null;
      final message = error is FeaturedPostsFailure ? error.message : null;
      state = AsyncData(
        s.copyWith(
          busy: false,
          error: (message == null || message.trim().isEmpty)
              ? FeaturedPostsText.importFailed
              : message,
        ),
      );
      return null;
    }
  }
}

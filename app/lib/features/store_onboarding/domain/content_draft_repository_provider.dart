import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_draft_repository.dart';

/// AI 초안 저장소. 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final contentDraftRepositoryProvider = Provider<ContentDraftRepository>(
  (ref) => throw UnimplementedError(
    'contentDraftRepositoryProvider must be overridden',
  ),
);

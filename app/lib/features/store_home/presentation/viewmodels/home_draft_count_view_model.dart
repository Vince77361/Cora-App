import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../store_onboarding/domain/content_draft_repository_provider.dart';

/// 홈의 `이번 주 가게 게시물` 칸이 말하는 저장된 AI 초안 수(`AI 초안 3개 준비`). 읽는 중이거나 읽지 못했으면
/// null이다. 칸 하나 때문에 홈이 오류나 로딩에 묶이지 않게 홈 본문과 따로 읽는다.
final homeDraftCountProvider = FutureProvider.autoDispose<int?>((ref) async {
  ref.watch(currentUserIdProvider);
  try {
    return (await ref.read(contentDraftRepositoryProvider).fetchMine()).length;
  } on Object {
    return null;
  }
});

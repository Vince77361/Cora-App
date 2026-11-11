import 'content_draft.dart';

/// 내 가게의 AI 초안을 서버와 주고받는 포트.
abstract class ContentDraftRepository {
  /// 세 종류 초안. 서버가 처음 부르면 만들어 저장한다.
  Future<List<ContentDraft>> fetchMine();

  /// [kind]만 다시 만든다. 오늘 한도를 넘으면 [DraftRegenerationLimit].
  Future<ContentDraft> regenerate(ContentDraftKind kind);
}

/// 오늘 이 초안을 더 만들 수 없다(429).
class DraftRegenerationLimit implements Exception {
  const DraftRegenerationLimit();

  @override
  String toString() => 'DraftRegenerationLimit';
}

/// 초안을 서버와 주고받지 못했다.
class ContentDraftFailure implements Exception {
  const ContentDraftFailure();

  @override
  String toString() => 'ContentDraftFailure';
}

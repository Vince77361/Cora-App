import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../domain/content_draft.dart';
import '../domain/content_draft_repository.dart';

/// 생성된 API 클라이언트로 AI 초안을 주고받는다.
class ApiContentDraftRepository implements ContentDraftRepository {
  ApiContentDraftRepository(api.ApiClient client)
    : _drafts = api.ContentDraftsApi(client);

  final api.ContentDraftsApi _drafts;

  @override
  Future<List<ContentDraft>> fetchMine() async {
    try {
      final models = await _drafts.listMyContentDrafts();
      if (models == null) throw const ContentDraftFailure();
      return models.map(_toDraft).toList();
    } on ContentDraftFailure {
      rethrow;
    } catch (_) {
      throw const ContentDraftFailure();
    }
  }

  @override
  Future<ContentDraft> regenerate(ContentDraftKind kind) async {
    try {
      final model = await _drafts.regenerateMyContentDraft(_kindToWire(kind));
      if (model == null) throw const ContentDraftFailure();
      return _toDraft(model);
    } on ContentDraftFailure {
      rethrow;
    } catch (error) {
      if (ApiError.from(error).isRateLimited) {
        throw const DraftRegenerationLimit();
      }
      throw const ContentDraftFailure();
    }
  }
}

ContentDraft _toDraft(api.ContentDraftModel m) => ContentDraft(
  kind: switch (m.kind) {
    api.ContentDraftKind.CARD_NEWS => ContentDraftKind.cardNews,
    api.ContentDraftKind.REELS_SCRIPT => ContentDraftKind.reelsScript,
    _ => ContentDraftKind.blog,
  },
  bodyLabel: m.bodyLabel,
  body: m.body,
  scenes: [
    for (final s in m.scenes)
      DraftScene(label: s.label, text: s.text, usesPhoto: s.usesPhoto),
  ],
  regenerationsLeftToday: m.regenerationsLeftToday,
);

api.ContentDraftKind _kindToWire(ContentDraftKind kind) => switch (kind) {
  ContentDraftKind.cardNews => api.ContentDraftKind.CARD_NEWS,
  ContentDraftKind.reelsScript => api.ContentDraftKind.REELS_SCRIPT,
  ContentDraftKind.blog => api.ContentDraftKind.BLOG,
};

import 'dart:async';

import 'package:cora/features/store_onboarding/domain/content_draft.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository.dart';

/// 캔버스 A4의 초안 세 종류.
List<ContentDraft> sampleDrafts({int left = 10}) => [
  ContentDraft(
    kind: ContentDraftKind.cardNews,
    bodyLabel: '본문',
    body: '성수동 골목 안, 12시간 끓인 국물 한 그릇.\n오후 3시 이후엔 줄 없이 들어올 수 있어요.\n#성수라멘 #돈코츠',
    scenes: const [
      DraftScene(label: '1', text: '12시간 끓인\n국물 한 그릇', usesPhoto: true),
      DraftScene(label: '2', text: '대표 메뉴\n돈코츠 라멘\n11,000원', usesPhoto: false),
      DraftScene(label: '3', text: '줄 없는 시간\n오후 3시 – 5시', usesPhoto: false),
    ],
    regenerationsLeftToday: left,
  ),
  ContentDraft(
    kind: ContentDraftKind.reelsScript,
    bodyLabel: '촬영 순서',
    body: '0–3초  김이 오르는 그릇 클로즈업\n3–8초  면을 들어 올리는 손\n8–15초  가게 간판과 위치 자막',
    scenes: const [
      DraftScene(label: '장면 1', text: '김이 오르는\n첫 숟가락', usesPhoto: true),
      DraftScene(label: '장면 2', text: '면을 들어\n올리는 손', usesPhoto: false),
      DraftScene(label: '장면 3', text: '골목 간판과\n위치 자막', usesPhoto: false),
    ],
    regenerationsLeftToday: left,
  ),
  ContentDraft(
    kind: ContentDraftKind.blog,
    bodyLabel: '도입부',
    body: '성수역에서 걸어서 5분, 골목 끝에 바 좌석 18석짜리 라멘집이 있어요. 국물은 매일 아침 12시간을 끓여요.',
    scenes: const [
      DraftScene(label: '제목', text: '성수 골목\n라멘집 한 곳', usesPhoto: true),
      DraftScene(label: '소제목 1', text: '12시간\n끓인 국물', usesPhoto: false),
      DraftScene(label: '소제목 2', text: '줄 없이\n먹는 시간', usesPhoto: false),
    ],
    regenerationsLeftToday: left,
  ),
];

/// 손으로 쓴 가짜 초안 저장소. 다시 만든 종류를 기록한다.
class FakeContentDraftRepository implements ContentDraftRepository {
  FakeContentDraftRepository({List<ContentDraft>? drafts})
    : drafts = drafts ?? sampleDrafts();

  List<ContentDraft> drafts;

  /// 다시 만든 종류, 부른 순서대로.
  final regenerated = <ContentDraftKind>[];
  bool failFetch = false;
  bool failRegenerate = false;

  /// true이면 다시 만들기가 오늘 한도를 넘었다고 답한다.
  bool limitReached = false;

  /// 설정하면 [fetchMine]이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdFetch;

  @override
  Future<List<ContentDraft>> fetchMine() async {
    final hold = holdFetch;
    if (hold != null) await hold.future;
    if (failFetch) throw const ContentDraftFailure();
    return drafts;
  }

  @override
  Future<ContentDraft> regenerate(ContentDraftKind kind) async {
    regenerated.add(kind);
    if (limitReached) throw const DraftRegenerationLimit();
    if (failRegenerate) throw const ContentDraftFailure();
    final old = drafts.firstWhere((d) => d.kind == kind);
    final fresh = ContentDraft(
      kind: kind,
      bodyLabel: old.bodyLabel,
      body: '${old.body} (다시 만듦 ${regenerated.length})',
      scenes: old.scenes,
      regenerationsLeftToday: old.regenerationsLeftToday - 1,
    );
    drafts = [for (final d in drafts) d.kind == kind ? fresh : d];
    return fresh;
  }
}

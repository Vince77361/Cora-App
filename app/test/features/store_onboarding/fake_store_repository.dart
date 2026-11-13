import 'dart:async';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/domain/store_repository.dart';

/// 캔버스 A3의 견본 가게(`한그릇 라멘`).
MyStore sampleStore({
  StoreStatus status = StoreStatus.draft,
  StoreOnboardingStep step = StoreOnboardingStep.page,
  String? name = '한그릇 라멘',
  String? regionSido = '서울특별시',
  String? regionSigungu = '성동구',
  String? intro = '진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.',
  String? coverPhotoUrl,
  List<SourceLink>? sourceLinks,
}) => MyStore(
  id: 'store-1',
  status: status,
  onboardingStep: step,
  industry: IndustryCategory.foodCafe,
  name: name,
  category: '라멘집',
  neighborhood: '성수동',
  regionSido: regionSido,
  regionSigungu: regionSigungu,
  coverPhotoUrl: coverPhotoUrl,
  signatureMenu: '돈코츠 라멘 11,000원',
  hours: '11:30 – 21:00',
  seats: '18석, 바 좌석',
  bestShootingTime: '오후 3시 – 5시',
  intro: intro,
  sourceLinks:
      sourceLinks ??
      const [
        SourceLink(
          kind: SourceLinkKind.naverMap,
          url: 'https://naver.me/abc',
          summary: '사진 12장, 메뉴 8개 찾음',
        ),
      ],
);

/// 링크를 읽지 못해 만들어진 빈 가게(링크만 있고 요약이 없다).
MyStore emptyStore({List<SourceLink> links = const []}) => MyStore(
  id: 'store-1',
  status: StoreStatus.draft,
  onboardingStep: StoreOnboardingStep.page,
  industry: IndustryCategory.foodCafe,
  sourceLinks: links,
);

/// 손으로 쓴 가짜 가게 저장소. 서버가 가진 가게를 흉내 내고 실패와 지연을 정한다.
class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository({this.store});

  /// 서버에 있는 가게. null이면 아직 만들지 않은 사람.
  MyStore? store;

  /// true이면 [analyze]가 링크를 읽지 못한 빈 가게를 돌려준다.
  bool analysisFails = false;

  /// true이면 해당 호출이 [StoreFailure]를 던진다.
  bool failFetch = false;

  /// 설정하면 [fetchMine]이 이 Completer가 끝날 때까지 기다린다(불러오는 중 화면을 본다).
  Completer<void>? holdFetch;
  bool failAnalyze = false;
  bool failUpdate = false;
  bool failAdvance = false;

  /// 설정하면 [analyze]가 이 Completer가 끝날 때까지 기다린다(분석 중 상태 확인용).
  Completer<void>? holdAnalyze;

  int fetchCalls = 0;
  final analyzed = <List<SourceLink>>[];
  final edits = <StoreEdit>[];
  final advanced = <StoreOnboardingStep>[];
  final terms = <OfferTerms>[];
  int publishCalls = 0;

  @override
  Future<MyStore?> fetchMine() async {
    fetchCalls++;
    await holdFetch?.future;
    if (failFetch) throw const StoreFailure();
    return store;
  }

  @override
  Future<({MyStore store, bool analysisFailed})> analyze(
    List<SourceLink> links,
  ) async {
    analyzed.add(links);
    final hold = holdAnalyze;
    if (hold != null) await hold.future;
    if (failAnalyze) throw const StoreFailure();
    final made = analysisFails
        ? emptyStore(links: links)
        : sampleStore(
            sourceLinks: [
              for (final link in links)
                SourceLink(
                  kind: link.kind,
                  url: link.url,
                  summary: '${link.kind.serviceName} 찾음',
                ),
            ],
          );
    store = made;
    return (store: made, analysisFailed: analysisFails);
  }

  @override
  Future<MyStore> update(StoreEdit edit) async {
    edits.add(edit);
    if (failUpdate) throw const StoreFailure();
    final s = store!;
    return store = MyStore(
      id: s.id,
      status: s.status,
      onboardingStep: s.onboardingStep,
      industry: edit.industry ?? s.industry,
      name: edit.name ?? s.name,
      category: edit.category ?? s.category,
      neighborhood: edit.neighborhood ?? s.neighborhood,
      regionSido: edit.regionSido ?? s.regionSido,
      regionSigungu: edit.regionSigungu ?? s.regionSigungu,
      coverPhotoUrl: s.coverPhotoUrl,
      signatureMenu: edit.signatureMenu ?? s.signatureMenu,
      hours: edit.hours ?? s.hours,
      seats: edit.seats ?? s.seats,
      bestShootingTime: edit.bestShootingTime ?? s.bestShootingTime,
      intro: edit.intro ?? s.intro,
      defaultTerms: s.defaultTerms,
      sourceLinks: s.sourceLinks,
    );
  }

  @override
  Future<MyStore> advance(StoreOnboardingStep step) async {
    advanced.add(step);
    if (failAdvance) throw const StoreFailure();
    final s = store!;
    return store = MyStore(
      id: s.id,
      status: s.status,
      onboardingStep: step.index > s.onboardingStep.index
          ? step
          : s.onboardingStep,
      industry: s.industry,
      name: s.name,
      category: s.category,
      neighborhood: s.neighborhood,
      regionSido: s.regionSido,
      regionSigungu: s.regionSigungu,
      coverPhotoUrl: s.coverPhotoUrl,
      signatureMenu: s.signatureMenu,
      hours: s.hours,
      seats: s.seats,
      bestShootingTime: s.bestShootingTime,
      intro: s.intro,
      defaultTerms: s.defaultTerms,
      sourceLinks: s.sourceLinks,
    );
  }

  @override
  Future<MyStore> setDefaultTerms(OfferTerms input) async {
    terms.add(input);
    return store!;
  }

  @override
  Future<MyStore> publish() async {
    publishCalls++;
    return store!;
  }
}

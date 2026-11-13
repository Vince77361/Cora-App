import 'dart:async';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/domain/store_repository.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';

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
  String? publicUrl = 'cora.page/l/hangeureut-ramen',
  List<String> tags = const ['진한국물', '바좌석', '조용한오후'],
  List<String> customerPhrases = const ['국물이 진해요', '혼밥하기 좋아요'],
  String? recruitLine,
  TrialInfo? trialInfo,
  TrialBannerKind? trialBanner,
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
  slug: publicUrl?.split('/').last,
  publicUrl: publicUrl,
  tags: tags,
  customerPhrases: customerPhrases,
  recruitLine: recruitLine,
  trialInfo: trialInfo,
  trialBanner: trialBanner,
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

/// 캔버스 F7의 지점 견본(`성수점`, `합정점`).
const sampleBranches = [
  StoreBranch(
    label: '성수점',
    address: '서울 성동구 성수이로 100',
    neighborhood: '성수동2가',
    regionSido: '서울특별시',
    regionSigungu: '성동구',
  ),
  StoreBranch(
    label: '합정점',
    address: '서울 마포구 양화로 45',
    neighborhood: '합정동',
    regionSido: '서울특별시',
    regionSigungu: '마포구',
  ),
];

/// 링크를 읽지 못해 만들어진 빈 가게(링크만 있고 요약이 없다).
MyStore emptyStore({List<SourceLink> links = const []}) => MyStore(
  id: 'store-1',
  status: StoreStatus.draft,
  onboardingStep: StoreOnboardingStep.page,
  industry: IndustryCategory.foodCafe,
  sourceLinks: links,
);

/// [s]에서 일부만 바꾼 사본(가짜 저장소가 서버의 갱신을 흉내 낼 때 쓴다).
MyStore _copy(
  MyStore s, {
  StoreOnboardingStep? step,
  IndustryCategory? industry,
  String? name,
  String? category,
  String? neighborhood,
  String? regionSido,
  String? regionSigungu,
  String? signatureMenu,
  String? hours,
  String? seats,
  String? bestShootingTime,
  String? intro,
  List<String>? tags,
  List<String>? customerPhrases,
  String? recruitLine,
  StoreStatus? status,
  bool replaceTrial = false,
  TrialInfo? trialInfo,
  TrialBannerKind? trialBanner,
}) => MyStore(
  id: s.id,
  status: status ?? s.status,
  onboardingStep: step ?? s.onboardingStep,
  industry: industry ?? s.industry,
  name: name ?? s.name,
  category: category ?? s.category,
  neighborhood: neighborhood ?? s.neighborhood,
  regionSido: regionSido ?? s.regionSido,
  regionSigungu: regionSigungu ?? s.regionSigungu,
  coverPhotoUrl: s.coverPhotoUrl,
  signatureMenu: signatureMenu ?? s.signatureMenu,
  hours: hours ?? s.hours,
  seats: seats ?? s.seats,
  bestShootingTime: bestShootingTime ?? s.bestShootingTime,
  intro: intro ?? s.intro,
  defaultTerms: s.defaultTerms,
  sourceLinks: s.sourceLinks,
  slug: s.slug,
  publicUrl: s.publicUrl,
  tags: tags ?? s.tags,
  customerPhrases: customerPhrases ?? s.customerPhrases,
  recruitLine: recruitLine ?? s.recruitLine,
  // 체험단 정보는 지울 수 있어야 해서 [replaceTrial]일 때만 바꾼다(null이 지운다는 뜻).
  trialInfo: replaceTrial ? trialInfo : s.trialInfo,
  trialBanner: replaceTrial ? trialBanner : s.trialBanner,
);

/// 서버가 체험단 줄과 계약 정보를 바꾼 것을 흉내 낸다.
MyStore withTrial(MyStore s, {TrialInfo? info, TrialBannerKind? banner}) =>
    _copy(s, replaceTrial: true, trialInfo: info, trialBanner: banner);

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
  final manuals = <ManualStore>[];

  /// 이름(앞뒤 공백 뺀 값)별로 [findBranches]가 돌려줄 지점. 캔버스 F7의 견본이 기본이다.
  final branchesByName = <String, List<StoreBranch>>{'한그릇 라멘': sampleBranches};
  final branchLookups = <String>[];
  bool failManual = false;
  bool failBranches = false;
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
  Future<MyStore> createManually(ManualStore input) async {
    manuals.add(input);
    if (failManual) throw const StoreFailure();
    final branch = input.branch;
    return store = MyStore(
      id: 'store-1',
      status: StoreStatus.draft,
      onboardingStep: StoreOnboardingStep.page,
      industry: IndustryCategory.foodCafe,
      name: input.name,
      neighborhood: branch?.neighborhood,
      regionSido: branch?.regionSido,
      regionSigungu: branch?.regionSigungu,
      signatureMenu: input.signatureMenu,
      slug: 'store-slug',
      publicUrl: 'cora.page/l/store-slug',
      sourceLinks: store?.sourceLinks ?? const [],
    );
  }

  @override
  Future<List<StoreBranch>> findBranches(String name) async {
    branchLookups.add(name);
    if (failBranches) throw const StoreFailure();
    return branchesByName[name] ?? const [];
  }

  @override
  Future<MyStore> update(StoreEdit edit) async {
    edits.add(edit);
    if (failUpdate) throw const StoreFailure();
    return store = _copy(
      store!,
      industry: edit.industry,
      name: edit.name,
      category: edit.category,
      neighborhood: edit.neighborhood,
      regionSido: edit.regionSido,
      regionSigungu: edit.regionSigungu,
      signatureMenu: edit.signatureMenu,
      hours: edit.hours,
      seats: edit.seats,
      bestShootingTime: edit.bestShootingTime,
      intro: edit.intro,
      tags: edit.tags,
      customerPhrases: edit.customerPhrases,
      recruitLine: edit.recruitLine,
    );
  }

  @override
  Future<MyStore> advance(StoreOnboardingStep step) async {
    advanced.add(step);
    if (failAdvance) throw const StoreFailure();
    final s = store!;
    return store = _copy(
      s,
      step: step.index > s.onboardingStep.index ? step : s.onboardingStep,
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

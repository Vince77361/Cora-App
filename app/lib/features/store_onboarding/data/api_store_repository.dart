import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../domain/my_store.dart';
import '../domain/source_link.dart';
import '../domain/store_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 가게를 주고받는다. 생성된 타입은 여기서 도메인 타입으로
/// 바꾸고, 이 파일 밖으로 내보내지 않는다.
class ApiStoreRepository implements StoreRepository {
  ApiStoreRepository(api.ApiClient client) : _stores = api.StoresApi(client);

  final api.StoresApi _stores;

  @override
  Future<MyStore?> fetchMine() async {
    try {
      final model = await _stores.getMyStore();
      return model == null ? null : _toStore(model);
    } catch (error) {
      // 가게를 아직 만들지 않은 사람은 404다. 오류가 아니라 "없음"이다.
      if (ApiError.from(error).isNotFound) return null;
      throw _failure(error);
    }
  }

  @override
  Future<({MyStore store, bool analysisFailed})> analyze(
    List<SourceLink> links,
  ) => _guard(() async {
    final result = await _stores.analyzeMyStoreLinks(
      api.AnalyzeLinksDto(
        links: [
          for (final link in links)
            api.SourceLinkInputDto(
              kind: _linkKindToWire(link.kind),
              url: link.url,
            ),
        ],
      ),
    );
    if (result == null) throw const StoreFailure();
    return (
      store: _toStore(result.store),
      analysisFailed: result.analysisFailed,
    );
  });

  @override
  Future<MyStore> update(StoreEdit edit) =>
      _guardStore(() => _stores.updateMyStore(_PartialUpdate(edit)));

  @override
  Future<MyStore> advance(StoreOnboardingStep step) => _guardStore(
    () => _stores.advanceMyStoreOnboarding(
      api.AdvanceOnboardingDto(
        step: switch (step) {
          StoreOnboardingStep.drafts => api.AdvanceOnboardingStep.DRAFTS,
          StoreOnboardingStep.terms => api.AdvanceOnboardingStep.TERMS,
          // 서버가 앱에서 받는 단계는 이 둘뿐이다(PAGE는 분석이, DONE은 공개가 정한다).
          _ => throw ArgumentError.value(step, 'step', '앱이 올릴 수 없는 단계'),
        },
      ),
    ),
  );

  @override
  Future<MyStore> setDefaultTerms(OfferTermsInput input) => _guardStore(
    () => _stores.setMyStoreDefaultTerms(
      api.SetDefaultTermsDto(
        format: _formatToWire(input.format),
        reward: rewardInputToWire(input),
      ),
    ),
  );

  @override
  Future<MyStore> publish() => _guardStore(_stores.publishMyStore);

  Future<MyStore> _guardStore(Future<api.MyStoreModel?> Function() call) =>
      _guard(() async {
        final model = await call();
        if (model == null) throw const StoreFailure();
        return _toStore(model);
      });

  /// 어떤 실패든 [StoreFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on StoreFailure {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  StoreFailure _failure(Object error) {
    final parsed = ApiError.from(error);
    return StoreFailure(
      isConflict: parsed.isConflict,
      isRateLimited: parsed.isRateLimited,
    );
  }
}

/// 서버의 `PATCH /stores/me`는 빠진 항목은 그대로 두지만, 생성된 [api.UpdateStoreDto]는 비운 항목을
/// 명시적 `null`로 보낸다. 서버는 `null`을 값으로 보고 검증에서 거절하므로(`name: null` 등), 값이
/// 있는 항목만 담아 보내도록 `toJson`을 바꾼 것이다.
class _PartialUpdate extends api.UpdateStoreDto {
  _PartialUpdate(this._edit);

  final StoreEdit _edit;

  @override
  Map<String, dynamic> toJson() {
    final e = _edit;
    return {
      'name': ?e.name,
      'category': ?e.category,
      'industry': ?(e.industry == null ? null : _industryToWire(e.industry!)),
      'neighborhood': ?e.neighborhood,
      'regionSido': ?e.regionSido,
      'regionSigungu': ?e.regionSigungu,
      'signatureMenu': ?e.signatureMenu,
      'hours': ?e.hours,
      'seats': ?e.seats,
      'bestShootingTime': ?e.bestShootingTime,
      'intro': ?e.intro,
      'coverPhotoPath': ?e.coverPhotoPath,
    };
  }
}

MyStore _toStore(api.MyStoreModel m) => MyStore(
  id: m.id,
  status: switch (m.status) {
    api.StoreStatus.PUBLISHED => StoreStatus.published,
    _ => StoreStatus.draft,
  },
  onboardingStep: switch (m.onboardingStep) {
    api.StoreOnboardingStep.DRAFTS => StoreOnboardingStep.drafts,
    api.StoreOnboardingStep.TERMS => StoreOnboardingStep.terms,
    api.StoreOnboardingStep.DONE => StoreOnboardingStep.done,
    _ => StoreOnboardingStep.page,
  },
  industry: _industryFromWire(m.industry),
  name: m.name,
  category: m.category,
  neighborhood: m.neighborhood,
  regionSido: m.regionSido,
  regionSigungu: m.regionSigungu,
  coverPhotoUrl: m.coverPhotoUrl,
  signatureMenu: m.signatureMenu,
  hours: m.hours,
  seats: m.seats,
  bestShootingTime: m.bestShootingTime,
  intro: m.intro,
  defaultTerms: m.defaultTerms == null
      ? null
      : offerTermsFromWire(m.defaultTerms!),
  sourceLinks: [
    for (final link in m.sourceLinks)
      SourceLink(
        kind: _linkKindFromWire(link.kind),
        url: link.url,
        summary: link.summary,
      ),
  ],
);

api.SourceLinkKind _linkKindToWire(SourceLinkKind kind) => switch (kind) {
  SourceLinkKind.naverMap => api.SourceLinkKind.NAVER_MAP,
  SourceLinkKind.catchtable => api.SourceLinkKind.CATCHTABLE,
  SourceLinkKind.instagram => api.SourceLinkKind.INSTAGRAM,
};

SourceLinkKind _linkKindFromWire(api.SourceLinkKind kind) => switch (kind) {
  api.SourceLinkKind.NAVER_MAP => SourceLinkKind.naverMap,
  api.SourceLinkKind.CATCHTABLE => SourceLinkKind.catchtable,
  _ => SourceLinkKind.instagram,
};

api.ContentFormat _formatToWire(ContentFormat f) => switch (f) {
  ContentFormat.shorts => api.ContentFormat.SHORTS,
  ContentFormat.reels => api.ContentFormat.REELS,
  ContentFormat.cardNews => api.ContentFormat.CARD_NEWS,
  ContentFormat.blog => api.ContentFormat.BLOG,
};

const _industries = <IndustryCategory, api.IndustryCategory>{
  IndustryCategory.foodCafe: api.IndustryCategory.FOOD_CAFE,
  IndustryCategory.beauty: api.IndustryCategory.BEAUTY,
  IndustryCategory.fashion: api.IndustryCategory.FASHION,
  IndustryCategory.accessory: api.IndustryCategory.ACCESSORY,
  IndustryCategory.living: api.IndustryCategory.LIVING,
  IndustryCategory.grocery: api.IndustryCategory.GROCERY,
  IndustryCategory.digital: api.IndustryCategory.DIGITAL,
  IndustryCategory.health: api.IndustryCategory.HEALTH,
  IndustryCategory.other: api.IndustryCategory.OTHER,
  IndustryCategory.alcohol: api.IndustryCategory.ALCOHOL,
  IndustryCategory.gambling: api.IndustryCategory.GAMBLING,
  IndustryCategory.loan: api.IndustryCategory.LOAN,
  IndustryCategory.dietSupplement: api.IndustryCategory.DIET_SUPPLEMENT,
};

api.IndustryCategory _industryToWire(IndustryCategory c) => _industries[c]!;

IndustryCategory _industryFromWire(api.IndustryCategory c) =>
    _industries.entries.firstWhere((e) => e.value == c).key;

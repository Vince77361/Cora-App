import '../../offer_terms/domain/offer_terms.dart';
import '../../trial_compare/domain/trial_info.dart';
import 'source_link.dart';

/// 가게가 공개됐는지. 등록 중이면 `draft`.
enum StoreStatus { draft, published }

/// 등록이 어디까지 왔는지. 앞으로만 간다.
enum StoreOnboardingStep { page, drafts, terms, done }

/// 업종 분류(공통 모델 3장). 마지막 네 가지는 크리에이터가 피할 수 있는 업종이다.
enum IndustryCategory {
  foodCafe('맛집·카페'),
  beauty('뷰티·미용'),
  fashion('패션'),
  accessory('액세서리·주얼리'),
  living('리빙·소품'),
  grocery('식품'),
  digital('전자·디지털'),
  health('건강·운동'),
  other('기타'),
  alcohol('주류'),
  gambling('도박·사행성'),
  loan('대출·금융'),
  dietSupplement('다이어트 보조제');

  const IndustryCategory(this.label);

  /// 화면에 보이는 이름.
  final String label;
}

/// 사장님 본인의 가게(주인에게만 보인다). 등록 중에도 읽힌다.
class MyStore {
  const MyStore({
    required this.id,
    required this.status,
    required this.onboardingStep,
    required this.industry,
    this.name,
    this.category,
    this.neighborhood,
    this.regionSido,
    this.regionSigungu,
    this.coverPhotoUrl,
    this.signatureMenu,
    this.hours,
    this.seats,
    this.bestShootingTime,
    this.intro,
    this.defaultTerms,
    this.sourceLinks = const [],
    this.slug,
    this.publicUrl,
    this.tags = const [],
    this.customerPhrases = const [],
    this.recruitLine,
    this.trialInfo,
    this.trialBanner,
  });

  final String id;
  final StoreStatus status;
  final StoreOnboardingStep onboardingStep;
  final String? name;

  /// 표시용 업종(예: `라멘집`). 분류는 [industry]다.
  final String? category;
  final IndustryCategory industry;
  final String? neighborhood;
  final String? regionSido;
  final String? regionSigungu;
  final String? coverPhotoUrl;
  final String? signatureMenu;
  final String? hours;
  final String? seats;
  final String? bestShootingTime;
  final String? intro;
  final OfferTerms? defaultTerms;
  final List<SourceLink> sourceLinks;

  /// 공개 주소 이름. 이름이 처음 생길 때 서버가 정하고 바뀌지 않는다. 이름이 없으면 null.
  final String? slug;

  /// 공개 주소(`cora.page/l/{slug}`, `https://` 없이). 이름이 없으면 null.
  final String? publicUrl;

  /// 꼬리표(`#` 없이)와 손님들이 자주 한 말, 모집 한 줄(A3).
  final List<String> tags;
  final List<String> customerPhrases;
  final String? recruitLine;

  /// 사장님이 넣은 체험단 계약 정보. 없으면 null.
  final TrialInfo? trialInfo;

  /// 사장님 홈에 보일 체험단 줄. 언제 보일지는 서버가 정한다. 없으면 null.
  final TrialBannerKind? trialBanner;

  bool get isPublished => status == StoreStatus.published;

  /// 링크를 읽어 채운 가게인지. 읽지 못한 분석은 링크 요약이 하나도 없다(서버는 읽었을 때만 요약을 저장한다).
  bool get wasAutoFilled => sourceLinks.any((link) => link.summary != null);

  /// 이름이 비어 있지 않은지. 가게 이름만 필수다.
  bool get hasName => (name ?? '').trim().isNotEmpty;

  /// 시·도를 골랐는지. 공개하려면 필요하다.
  bool get hasRegion => (regionSido ?? '').isNotEmpty;

  /// `성수동`, `라멘집, 성수동`처럼 사진 위에 보이는 한 줄. 둘 다 없으면 null.
  String? get categoryAndNeighborhood {
    final parts = [
      category,
      neighborhood,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// `서울특별시 성동구`. 시·도가 없으면 null.
  String? get regionText {
    if (!hasRegion) return null;
    final sigungu = (regionSigungu ?? '').trim();
    return sigungu.isEmpty ? regionSido : '$regionSido $sigungu';
  }
}

/// 가게 정보 고치기 요청. 화면이 모든 항목의 지금 값을 보낸다(비운 항목은 빈 글자, 지운다는 뜻).
/// 서버는 빠진 항목은 그대로 두므로 사진만 바꿀 때처럼 일부만 보낼 수도 있다.
class StoreEdit {
  const StoreEdit({
    this.name,
    this.category,
    this.industry,
    this.neighborhood,
    this.regionSido,
    this.regionSigungu,
    this.signatureMenu,
    this.hours,
    this.seats,
    this.bestShootingTime,
    this.intro,
    this.coverPhotoPath,
    this.tags,
    this.customerPhrases,
    this.recruitLine,
  });

  final String? name;
  final String? category;
  final IndustryCategory? industry;
  final String? neighborhood;
  final String? regionSido;
  final String? regionSigungu;
  final String? signatureMenu;
  final String? hours;
  final String? seats;
  final String? bestShootingTime;
  final String? intro;

  /// 사진 올리기가 돌려준 저장 위치. 이미 올린 사진을 가게에 연결할 때만 담는다.
  final String? coverPhotoPath;

  /// 꼬리표(`#` 없이), 손님들이 자주 한 말, 모집 한 줄. 빈 목록·빈 글자는 지운다는 뜻이고 null이면
  /// 서버가 그대로 둔다.
  final List<String>? tags;
  final List<String>? customerPhrases;
  final String? recruitLine;
}

/// 같은 이름의 가게 중 하나(F7 지점 고르기). 서버가 지점 이름과 동네·지역을 준다.
class StoreBranch {
  const StoreBranch({
    required this.label,
    required this.address,
    this.neighborhood,
    this.regionSido,
    this.regionSigungu,
  });

  /// 지점 이름(예: `성수점`).
  final String label;

  /// 전체 주소. 화면에는 [neighborhood]를 보이고, 동네가 없을 때만 이것을 보인다.
  final String address;
  final String? neighborhood;
  final String? regionSido;
  final String? regionSigungu;

  /// 지점 줄 오른쪽에 보이는 동네(캔버스: `성수동2가`).
  String get shownPlace =>
      (neighborhood ?? '').trim().isEmpty ? address : neighborhood!;

  @override
  bool operator ==(Object other) =>
      other is StoreBranch &&
      other.label == label &&
      other.address == address &&
      other.neighborhood == neighborhood &&
      other.regionSido == regionSido &&
      other.regionSigungu == regionSigungu;

  @override
  int get hashCode =>
      Object.hash(label, address, neighborhood, regionSido, regionSigungu);
}

/// 링크 없이 직접 입력해 만드는 가게(F7).
class ManualStore {
  const ManualStore({
    required this.name,
    this.branch,
    this.signatureMenu,
    this.coverPhotoPath,
  });

  final String name;
  final StoreBranch? branch;
  final String? signatureMenu;

  /// 사진 올리기가 돌려준 저장 위치.
  final String? coverPhotoPath;
}

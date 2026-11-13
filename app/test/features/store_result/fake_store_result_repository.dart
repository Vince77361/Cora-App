import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_result/domain/store_result.dart';
import 'package:cora/features/store_result/domain/store_result_repository.dart';

/// 캔버스 G1의 견본: 하루 한 컵의 릴스가 12,500회(평소 약 4,000회, 3.1배), 크리에이터 지급 25,000원,
/// 사장님께 환불 35,000원.
StoreResult sampleResult({
  int? views = 12500,
  int? usualViews = 4000,
  int? multiplierTenths = 31,
  int payout = 25000,
  int refund = 35000,
  int fixedCash = 0,
  bool fixedCashOnly = false,
  String postUrl = 'https://www.instagram.com/reel/abc',
  String? photoUrl,
}) => StoreResult(
  creator: StoreResultCreator(
    userId: 'creator-1',
    name: '하루 한 컵',
    photoUrl: photoUrl,
  ),
  format: ContentFormat.reels,
  // 한국 시간으로 11월 4일.
  postedAt: DateTime.utc(2026, 11, 4, 3),
  postUrl: postUrl,
  views: views,
  usualViews: usualViews,
  multiplierTenths: multiplierTenths,
  payout: payout,
  refund: refund,
  fixedCash: fixedCash,
  fixedCashOnly: fixedCashOnly,
);

/// 손으로 쓴 가짜 7일 결과 저장소.
class FakeStoreResultRepository implements StoreResultRepository {
  FakeStoreResultRepository({StoreResult? result})
    : result = result ?? sampleResult();

  StoreResult result;
  bool fail = false;
  bool notFound = false;
  final fetched = <String>[];

  @override
  Future<StoreResult> fetch(String collaborationId) async {
    fetched.add(collaborationId);
    if (notFound) throw const StoreResultFailure(notFound: true);
    if (fail) throw const StoreResultFailure();
    return result;
  }
}

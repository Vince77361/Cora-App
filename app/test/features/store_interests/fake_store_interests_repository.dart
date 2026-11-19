import 'package:cora/features/store_interests/domain/store_interest.dart';
import 'package:cora/features/store_interests/domain/store_interests_repository.dart';

StoreInterest storeInterest(
  String id, {
  String? name,
  String? shortName,
  String? contentFocus = '리빙 릴스',
  int? followers = 640,
  String? photoUrl,
  String? headline,
  String? representativePhotoUrl,
  bool mutual = false,
}) => StoreInterest(
  creatorId: id,
  name: name ?? '크리에이터 $id',
  shortName: shortName ?? name ?? '크리에이터 $id',
  contentFocus: contentFocus,
  followers: followers,
  photoUrl: photoUrl,
  headline: headline,
  representativePhotoUrl: representativePhotoUrl,
  mutual: mutual,
);

/// 손으로 쓴 가짜 사장님 저장함 저장소. 저장 탭과 보낸 관심 탭의 줄을 그대로 준다.
class FakeStoreInterestsRepository implements StoreInterestsRepository {
  FakeStoreInterestsRepository({
    List<StoreInterest>? saved,
    List<StoreInterest>? sent,
  }) : saved = saved ?? [],
       sent = sent ?? [];

  List<StoreInterest> saved;
  List<StoreInterest> sent;
  bool failFetch = false;
  int savedCalls = 0;
  int sentCalls = 0;

  @override
  Future<List<StoreInterest>> fetchSaved() async {
    savedCalls++;
    if (failFetch) throw const StoreInterestsFailure();
    return List.of(saved);
  }

  @override
  Future<List<StoreInterest>> fetchSent() async {
    sentCalls++;
    if (failFetch) throw const StoreInterestsFailure();
    return List.of(sent);
  }
}

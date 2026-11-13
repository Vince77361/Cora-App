import 'package:cora_api/api.dart' as api;

import '../domain/applicant_pick.dart';
import '../domain/applicant_picks_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 지원자 추천을 읽는다. 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiApplicantPicksRepository implements ApplicantPicksRepository {
  ApiApplicantPicksRepository(api.ApiClient client)
    : _applications = api.ApplicationsApi(client);

  final api.ApplicationsApi _applications;

  @override
  Future<ApplicantPicks> fetchPicks() => _guard(() async {
    final m = await _applications.listRecommendedApplicants();
    if (m == null) throw const ApplicantPicksFailure();
    return ApplicantPicks(
      totalNew: m.totalNew,
      items: [
        for (final item in m.items)
          ApplicantPick(
            applicationId: item.applicationId,
            pitch: item.pitch,
            reasons: List.of(item.reasons),
            creator: PickCreator(
              userId: item.creator.userId,
              displayName: item.creator.displayName,
              photoUrl: item.creator.photoUrl,
              contentFocus: item.creator.contentFocus,
              regionSido: item.creator.regionSido,
              regionSigungu: item.creator.regionSigungu,
              // 연동하지 않은 크리에이터의 팔로워는 보이지 않는다.
              followers: item.creator.instagramConnected
                  ? item.creator.followers
                  : null,
            ),
          ),
      ],
    );
  });

  @override
  Future<void> skip(String applicationId) =>
      _guard(() => _applications.skipRecommendedApplicant(applicationId));

  /// 어떤 실패든 [ApplicantPicksFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApplicantPicksFailure {
      rethrow;
    } catch (_) {
      throw const ApplicantPicksFailure();
    }
  }
}

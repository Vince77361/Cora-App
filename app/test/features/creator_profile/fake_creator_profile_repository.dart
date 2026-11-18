import 'dart:async';

import 'package:cora/features/creator_profile/domain/creator_profile.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';

/// 손으로 쓴 가짜 크리에이터 프로필 저장소. 서버가 가진 프로필을 흉내 낸다.
class FakeCreatorProfileRepository implements CreatorProfileRepository {
  /// [profile]이 서버에 저장된 프로필이다. null이면 아직 만들지 않은 사람.
  FakeCreatorProfileRepository({this.profile});

  CreatorProfile? profile;

  /// true이면 [fetchMine]이 [CreatorProfileFailure]를 던진다.
  bool failFetch = false;

  /// true이면 [save]가 [CreatorProfileFailure]를 던진다.
  bool failSave = false;

  /// 설정하면 [save]가 이 Completer가 끝날 때까지 기다린다(저장 중 상태 확인용).
  Completer<void>? holdSave;

  int fetchCalls = 0;
  int saveCalls = 0;

  /// 마지막 [save]에 넘어온 값들.
  String? savedDisplayName;
  String? savedRegionSido;
  String? savedRegionSigungu;
  String? savedContentFocus;
  String? savedInstagramHandle;
  String? savedPhotoPath;

  @override
  Future<CreatorProfile?> fetchMine() async {
    fetchCalls++;
    if (failFetch) throw const CreatorProfileFailure();
    return profile;
  }

  @override
  Future<CreatorProfile> save({
    required String displayName,
    required String regionSido,
    String? regionSigungu,
    String? contentFocus,
    String? instagramHandle,
    String? photoPath,
  }) async {
    saveCalls++;
    savedDisplayName = displayName;
    savedRegionSido = regionSido;
    savedRegionSigungu = regionSigungu;
    savedContentFocus = contentFocus;
    savedInstagramHandle = instagramHandle;
    savedPhotoPath = photoPath;
    final hold = holdSave;
    if (hold != null) await hold.future;
    if (failSave) throw const CreatorProfileFailure();
    final saved = CreatorProfile(
      displayName: displayName,
      regionSido: regionSido,
      regionSigungu: regionSigungu,
      contentFocus: contentFocus,
      instagramHandle: instagramHandle,
      photoUrl: photoPath == null ? null : 'https://photos.test/$photoPath',
    );
    profile = saved;
    return saved;
  }
}

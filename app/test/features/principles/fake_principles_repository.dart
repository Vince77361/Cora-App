import 'dart:async';

import 'package:cora/features/principles/domain/principles.dart';
import 'package:cora/features/principles/domain/principles_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart'
    show IndustryCategory;

/// 협업 원칙을 정한 크리에이터의 기본 원칙(08이 원칙 띠를 보이지 않는다).
const defaultPrinciples = Principles(
  fields: [IndustryCategory.foodCafe],
  blockedIndustries: [],
  faceOk: true,
  scriptOk: true,
  honestReview: true,
  feeBand: FeeBand.w300k,
  trialDays: ProductTrialDays.d7,
);

/// 손으로 쓴 가짜 협업 원칙 저장소. 서버가 가진 원칙을 흉내 낸다.
class FakePrinciplesRepository implements PrinciplesRepository {
  /// [principles]가 서버에 저장된 원칙이다. null이면 아직 정하지 않은 사람.
  FakePrinciplesRepository({this.principles});

  Principles? principles;

  /// true이면 [fetchMine]이 [PrinciplesFailure]를 던진다.
  bool failFetch = false;

  /// true이면 [save]가 [PrinciplesFailure]를 던진다.
  bool failSave = false;

  /// 설정하면 [save]가 이 Completer가 끝날 때까지 기다린다(저장 중 상태 확인용).
  Completer<void>? holdSave;

  int fetchCalls = 0;
  int saveCalls = 0;

  /// 마지막 [save]에 넘어온 값.
  Principles? saved;

  @override
  Future<Principles?> fetchMine() async {
    fetchCalls++;
    if (failFetch) throw const PrinciplesFailure();
    return principles;
  }

  @override
  Future<Principles> save(Principles value) async {
    saveCalls++;
    saved = value;
    final hold = holdSave;
    if (hold != null) await hold.future;
    if (failSave) throw const PrinciplesFailure();
    principles = value;
    return value;
  }
}

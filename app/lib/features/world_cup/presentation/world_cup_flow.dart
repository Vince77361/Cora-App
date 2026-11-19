import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../domain/world_cup_candidate.dart';
import 'widgets/world_cup_count_sheet.dart';

/// 결과 화면의 `제안하기`가 하는 일. 사장님은 받는 사람이 채워진 오퍼 작성(A5), 브랜드는 보상 제안(F1)을 연다. 서버에
/// 쓰는 일은 그 화면이 하고 월드컵 자신은 아무것도 쓰지 않는다. 뒤에 띄울 안내가 있으면 돌려준다.
typedef WorldCupPropose =
    Future<WorldCupNotice?> Function(
      BuildContext context,
      WorldCupCandidate winner,
    );

/// 대결 화면이 받는 것: 저장한 사람 전부([saved]), 몇 강으로 할지([size]), 우승자에게 제안하는 방법([onPropose]).
/// 판마다 새로 만들고 같은 값을 가졌어도 다른 판이다(그래서 `==`를 두지 않는다. 다시 하기가 새 대진을 뽑는다).
class WorldCupMatchArgs {
  WorldCupMatchArgs({
    required this.saved,
    required this.size,
    required this.onPropose,
  });

  final List<WorldCupCandidate> saved;
  final int size;
  final WorldCupPropose onPropose;
}

/// 결과 화면이 받는 것: 우승자, 우승자를 뺀 4강 진출자, 그리고 다시 하기에 쓸 판 정보.
class WorldCupResultArgs {
  WorldCupResultArgs({
    required this.champion,
    required this.semifinalists,
    required this.match,
  });

  final WorldCupCandidate champion;
  final List<WorldCupCandidate> semifinalists;

  /// 방금 한 판. `다시 하기`는 같은 사람들 가운데서 같은 몇 강으로 새로 뽑는다.
  final WorldCupMatchArgs match;

  WorldCupMatchArgs again() => WorldCupMatchArgs(
    saved: match.saved,
    size: match.size,
    onPropose: match.onPropose,
  );
}

/// 저장함의 `월드컵 하기`: 몇 강으로 할지 시트로 묻고, 고르면 대결 화면을 연다. 시트를 그냥 닫으면 아무 일도 없다.
Future<void> startWorldCup(
  BuildContext context, {
  required List<WorldCupCandidate> saved,
  required WorldCupPropose onPropose,
}) async {
  final size = await showWorldCupCountSheet(context, savedCount: saved.length);
  if (size == null || !context.mounted) return;
  await context.push(
    AppRoutes.worldCupMatch,
    extra: WorldCupMatchArgs(saved: saved, size: size, onPropose: onPropose),
  );
}

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/world_cup_bracket.dart';
import '../../domain/world_cup_candidate.dart';
import '../world_cup_flow.dart';

/// 대진을 뽑는 무작위. 시험은 고정 시드로 바꿔 끼운다.
final worldCupRandomProvider = Provider<Random>((ref) => Random());

/// 월드컵이 한창일 때의 상태. [step]은 고른 횟수라 같은 대진 객체가 바뀌어도 화면이 새로 그려진다.
class WorldCupState {
  const WorldCupState(
    this.bracket,
    this.step, {
    required this.shown,
    required this.stage,
  });

  final WorldCupBracket<WorldCupCandidate> bracket;
  final int step;

  /// 화면에 보이는 대결과 단계 글자. 끝난 대진은 대결을 읽을 수 없어서, 결승을 고른 뒤 결과 화면으로 바뀌는 동안
  /// 나가는 대결 화면이 빈 바탕이 되지 않게 마지막 대결을 여기 남긴다.
  final ({WorldCupCandidate a, WorldCupCandidate b}) shown;
  final String stage;

  bool get finished => bracket.finished;
}

/// 한 판의 월드컵. 판([WorldCupMatchArgs])마다 새로 뽑고, 화면을 떠나면 버린다. 서버를 읽지도 쓰지도 않는다 ---
/// 저장함이 이미 읽어 둔 목록으로 끝까지 한다(도중에 저장이 바뀌어도 뽑은 사람 그대로).
final worldCupViewModelProvider = NotifierProvider.autoDispose
    .family<WorldCupViewModel, WorldCupState, WorldCupMatchArgs>(
      WorldCupViewModel.new,
    );

class WorldCupViewModel extends Notifier<WorldCupState> {
  WorldCupViewModel(this.args);

  final WorldCupMatchArgs args;

  @override
  WorldCupState build() {
    final bracket = WorldCupBracket<WorldCupCandidate>.start(
      args.saved,
      size: args.size,
      random: ref.read(worldCupRandomProvider),
    );
    return WorldCupState(
      bracket,
      0,
      shown: bracket.match,
      stage: bracket.roundLabel,
    );
  }

  /// [winner]를 고른다. 같은 프레임에 두 번 눌렸거나 끝난 뒤에 늦게 들어온 선택, 지금 대결에 없는 사람은 버린다
  /// (대진은 그런 선택을 오류로 막지만 화면에서는 일어날 수 있는 일이라 오류가 되지 않게 한다).
  void pick(WorldCupCandidate winner) {
    final bracket = state.bracket;
    if (bracket.finished) return;
    final match = bracket.match;
    if (winner != match.a && winner != match.b) return;
    final before = state;
    bracket.pick(winner);
    state = WorldCupState(
      bracket,
      before.step + 1,
      shown: bracket.finished ? before.shown : bracket.match,
      stage: bracket.finished ? before.stage : bracket.roundLabel,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/discovery_card.dart';
import '../../domain/discovery_repository.dart';

/// 역할 없는 사용자의 둘러보기(9A). 화면을 떠나면 버리고 다시 열 때 카드를 새로 읽는다.
/// 읽기만 한다. 결정, 넘긴 이유, 되돌리기를 저장소에 보내지 않는다.
final previewDiscoveryViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      PreviewDiscoveryViewModel,
      PreviewDiscoveryState
    >(
      PreviewDiscoveryViewModel.new,
      // 실패는 자동으로 다시 읽지 않고 `다시 시도`를 누를 때만 읽는다.
      retry: (_, _) => null,
    );

class PreviewDiscoveryState {
  const PreviewDiscoveryState({required this.cards, this.passed = 0});

  /// 서버가 준 카드 전체(최대 10장). `{n}/{total}`의 total이다.
  final List<PreviewCard> cards;

  /// 왼쪽으로 밀어 넘긴 카드 수. 서버에는 저장하지 않는다.
  final int passed;

  int get total => cards.length;

  /// 아직 넘기지 않은 카드(덱에 넘기는 목록).
  List<PreviewCard> get remaining => cards.skip(passed).toList();

  /// [card]의 `{n}/{total}`에서 n.
  int positionOf(PreviewCard card) => cards.indexOf(card) + 1;
}

class PreviewDiscoveryViewModel extends AsyncNotifier<PreviewDiscoveryState> {
  @override
  Future<PreviewDiscoveryState> build() async {
    final cards = await ref
        .read(discoveryRepositoryProvider)
        .fetchPreviewCards();
    return PreviewDiscoveryState(cards: cards);
  }

  /// [card]를 넘기고 다음 카드로 간다. 저장하지 않는다(메모리에서만).
  void pass(PreviewCard card) {
    final current = state.value;
    if (current == null || current.remaining.firstOrNull != card) return;
    state = AsyncData(
      PreviewDiscoveryState(cards: current.cards, passed: current.passed + 1),
    );
  }

  /// 불러오기 실패 뒤 `다시 시도`.
  void reload() => ref.invalidateSelf();
}

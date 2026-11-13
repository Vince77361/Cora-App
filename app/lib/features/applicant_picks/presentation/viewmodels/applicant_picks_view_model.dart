import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/applicant_pick.dart';
import '../../domain/applicant_picks_repository.dart';

/// G2 지원자 추천의 상태. 화면을 떠나면 버린다(다시 열면 서버에서 새로 읽는다).
final applicantPicksViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      ApplicantPicksViewModel,
      ApplicantPicksState
    >(ApplicantPicksViewModel.new, retry: (_, _) => null);

class ApplicantPicksState {
  const ApplicantPicksState({
    required this.items,
    required this.totalNew,
    this.index = 0,
    this.busy = false,
    this.skipFailed = false,
  });

  /// 처음 읽은 추천(최대 3명). 넘겨도 줄지 않고 [index]만 앞으로 간다(`추천 2 / 3`).
  final List<ApplicantPick> items;
  final int totalNew;
  final int index;

  /// 넘기는 요청을 보내는 중이다.
  final bool busy;
  final bool skipFailed;

  int get total => items.length;

  /// 지금 보는 추천. 다 봤거나 추천이 없으면 null이다.
  ApplicantPick? get current => index < items.length ? items[index] : null;

  bool get allSeen => items.isNotEmpty && index >= items.length;

  ApplicantPicksState copyWith({int? index, bool? busy, bool? skipFailed}) =>
      ApplicantPicksState(
        items: items,
        totalNew: totalNew,
        index: index ?? this.index,
        busy: busy ?? this.busy,
        skipFailed: skipFailed ?? this.skipFailed,
      );
}

class ApplicantPicksViewModel extends AsyncNotifier<ApplicantPicksState> {
  @override
  Future<ApplicantPicksState> build() async {
    final picks = await ref.read(applicantPicksRepositoryProvider).fetchPicks();
    return ApplicantPicksState(items: picks.items, totalNew: picks.totalNew);
  }

  /// 지금 추천을 넘기고 다음 추천을 보인다. 서버가 넘겼다고 답한 뒤에 넘어가고, 실패하면 그 자리에 머문다.
  Future<void> skip() async {
    final current = state.value;
    final pick = current?.current;
    if (current == null || pick == null || current.busy) return;
    state = AsyncData(current.copyWith(busy: true, skipFailed: false));
    try {
      await ref.read(applicantPicksRepositoryProvider).skip(pick.applicationId);
    } on ApplicantPicksFailure {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(busy: false, skipFailed: true));
      }
      return;
    }
    if (ref.mounted) {
      state = AsyncData(
        current.copyWith(index: current.index + 1, busy: false),
      );
    }
  }
}

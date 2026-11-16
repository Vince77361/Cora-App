import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/principle_questions.dart';
import '../../domain/principles_repository.dart';

/// 화면을 떠나면 고른 것도 버린다(`나중에`는 저장하지 않는다).
final principlesViewModelProvider =
    AsyncNotifierProvider.autoDispose<PrinciplesViewModel, PrinciplesState>(
      PrinciplesViewModel.new,
    );

/// 협업 원칙 화면의 상태. [step]이 질문 수와 같으면 요약이다.
class PrinciplesState {
  const PrinciplesState({
    this.step = 0,
    this.answers = const PrincipleAnswers.empty(),
    this.saving = false,
    this.saveFailed = false,
  });

  /// 0부터 센 질문 번호. 마지막 질문 다음(`principleQuestions.length`)이 요약이다.
  final int step;
  final PrincipleAnswers answers;
  final bool saving;
  final bool saveFailed;

  static int get questionCount => principleQuestions.length;

  /// 질문을 보여 주는 중인지(아니면 요약).
  bool get asking => step < questionCount;

  /// 지금 보이는 질문. 요약일 때는 마지막 질문(캔버스도 같다).
  PrincipleQuestion get question =>
      principleQuestions[asking ? step : questionCount - 1];

  /// `다음`을 켤 수 있는지.
  bool get canContinue => answers.canContinue(question);

  PrinciplesState copyWith({
    int? step,
    PrincipleAnswers? answers,
    bool? saving,
    bool? saveFailed,
  }) => PrinciplesState(
    step: step ?? this.step,
    answers: answers ?? this.answers,
    saving: saving ?? this.saving,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

class PrinciplesViewModel extends AsyncNotifier<PrinciplesState> {
  /// 저장된 원칙이 있으면 그 값을 처음 선택으로 연다(고치는 경우). 조회에 실패하면 오류 상태다.
  @override
  Future<PrinciplesState> build() async {
    final saved = await ref.read(principlesRepositoryProvider).fetchMine();
    return PrinciplesState(
      answers: saved == null
          ? const PrincipleAnswers.empty()
          : PrincipleAnswers.from(saved),
    );
  }

  // 저장 중에는 입력을 받지 않는다. 고치면 지난 저장 실패 안내는 지운다.
  void _edit(PrinciplesState Function(PrinciplesState) f) {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(f(current).copyWith(saveFailed: false));
  }

  /// 지금 질문의 [index]번 선택지를 누른다.
  void pick(int index) => _edit((s) {
    if (!s.asking) return s;
    return s.copyWith(answers: s.answers.pick(s.question, index));
  });

  /// 다음 질문으로. 고르지 않아 `다음`이 꺼져 있으면 움직이지 않는다.
  void next() => _edit((s) {
    if (!s.asking || !s.canContinue) return s;
    return s.copyWith(step: s.step + 1);
  });

  /// 이전 질문으로. 첫 질문에서는 움직이지 않는다.
  void back() => _edit((s) => s.step == 0 ? s : s.copyWith(step: s.step - 1));

  /// 요약에서 `다시 고르기`. 고른 것은 그대로 두고 첫 질문으로 간다.
  void restart() => _edit((s) => s.copyWith(step: 0));

  /// 요약의 선택을 저장한다. 저장되면 true. 실패하면 요약을 그대로 두고 false.
  Future<bool> save() async {
    final current = state.value;
    if (current == null || current.saving || current.asking) return false;
    final principles = current.answers.toPrinciples();
    if (principles == null) return false;
    state = AsyncData(current.copyWith(saving: true, saveFailed: false));
    try {
      await ref.read(principlesRepositoryProvider).save(principles);
      if (!ref.mounted) return true;
      state = AsyncData(current.copyWith(saving: false));
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = AsyncData(current.copyWith(saving: false, saveFailed: true));
      return false;
    }
  }
}

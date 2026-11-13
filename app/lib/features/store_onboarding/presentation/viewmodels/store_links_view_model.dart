import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/source_link.dart';
import '../../domain/store_repository.dart';
import 'my_store_view_model.dart';

/// 링크 입력 화면(A2)의 상태. 화면을 떠나면 입력도 버린다. 다시 열면 저장된 링크에서 시작한다.
final storeLinksViewModelProvider =
    AsyncNotifierProvider.autoDispose<StoreLinksViewModel, StoreLinksState>(
      StoreLinksViewModel.new,
      retry: (_, _) => null,
    );

/// 분석을 눌러 끝난 결과.
enum StoreLinksOutcome {
  /// 가게 페이지(A3)로 간다.
  analyzed,

  /// 읽지 못했다. 화면이 직접 입력(F7)으로 보낸다(안내 문구와 함께).
  analysisFailed,

  /// 서버에 닿지 못했거나 서버가 거절했다. 입력은 그대로 남는다.
  failed,
}

class StoreLinksState {
  const StoreLinksState({
    required this.inputs,
    required this.analyzed,
    this.analyzing = false,
    this.errorMessage,
  });

  /// 입력란에 적힌 글자. 종류마다 하나.
  final Map<SourceLinkKind, String> inputs;

  /// 서버가 이미 분석한 링크(저장된 가게의 링크). 입력이 이것과 같으면 요약을 보여 준다.
  final List<SourceLink> analyzed;
  final bool analyzing;

  /// 서버에 닿지 못했을 때 보여 줄 문구.
  final String? errorMessage;

  String textOf(SourceLinkKind kind) => inputs[kind] ?? '';

  /// 적은 링크의 종류들.
  List<SourceLinkKind> get filled => [
    for (final kind in SourceLinkKind.values)
      if (textOf(kind).trim().isNotEmpty) kind,
  ];

  bool isInvalid(SourceLinkKind kind) {
    final text = textOf(kind);
    return text.trim().isNotEmpty && !kind.accepts(text);
  }

  /// 링크가 하나 이상 있고 모두 형식이 맞아야 만들 수 있다.
  bool get canSubmit =>
      !analyzing &&
      filled.isNotEmpty &&
      filled.every((kind) => !isInvalid(kind));

  /// 입력이 서버가 분석한 링크와 같을 때 그 요약(`사진 12장, 메뉴 8개 찾음`). 아니면 null.
  String? summaryOf(SourceLinkKind kind) {
    final text = textOf(kind);
    if (text.trim().isEmpty) return null;
    final normalized = SourceLinkKind.normalize(text);
    for (final link in analyzed) {
      if (link.kind == kind && link.url == normalized) return link.summary;
    }
    return null;
  }

  StoreLinksState copyWith({
    Map<SourceLinkKind, String>? inputs,
    List<SourceLink>? analyzed,
    bool? analyzing,
    String? Function()? errorMessage,
  }) => StoreLinksState(
    inputs: inputs ?? this.inputs,
    analyzed: analyzed ?? this.analyzed,
    analyzing: analyzing ?? this.analyzing,
    errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
  );
}

class StoreLinksViewModel extends AsyncNotifier<StoreLinksState> {
  /// 서버에 닿지 못했을 때의 문구(캔버스에 없는 상태).
  static const unreachable = '서버에 연결하지 못했어요.';

  /// 이미 공개한 가게는 다시 만들 수 없다(서버 문구와 같다).
  static const alreadyPublished = '이미 공개한 가게는 다시 만들 수 없어요.';

  @override
  Future<StoreLinksState> build() async {
    // 저장된 가게가 있으면(A3에서 뒤로 왔을 때) 그 링크로 시작한다.
    final store = await ref.read(myStoreViewModelProvider.future);
    final links = store?.sourceLinks ?? const <SourceLink>[];
    return StoreLinksState(
      inputs: {
        for (final link in links) link.kind: SourceLinkKind.display(link.url),
      },
      analyzed: links,
    );
  }

  void setInput(SourceLinkKind kind, String text) {
    final current = state.value;
    if (current == null || current.analyzing) return;
    state = AsyncData(
      current.copyWith(
        inputs: {...current.inputs, kind: text},
        // 입력을 고치면 지난 오류는 더 이상 맞지 않는다.
        errorMessage: () => null,
      ),
    );
  }

  /// 링크를 분석해 가게를 만든다.
  Future<StoreLinksOutcome> submit() async {
    final current = state.value;
    if (current == null || !current.canSubmit) return StoreLinksOutcome.failed;
    state = AsyncData(
      current.copyWith(analyzing: true, errorMessage: () => null),
    );
    try {
      final failed = await ref.read(myStoreViewModelProvider.notifier).analyze([
        for (final kind in current.filled)
          SourceLink(
            kind: kind,
            url: SourceLinkKind.normalize(current.textOf(kind)),
          ),
      ]);
      if (!ref.mounted) return StoreLinksOutcome.failed;
      state = AsyncData(
        current.copyWith(
          analyzing: false,
          // 방금 분석한 링크와 요약으로 바꿔, 뒤로 돌아왔을 때 ✓ 요약이 보이게 한다.
          analyzed:
              ref.read(myStoreViewModelProvider).value?.sourceLinks ??
              current.analyzed,
        ),
      );
      return failed
          ? StoreLinksOutcome.analysisFailed
          : StoreLinksOutcome.analyzed;
    } on StoreFailure catch (error) {
      if (!ref.mounted) return StoreLinksOutcome.failed;
      state = AsyncData(
        current.copyWith(
          analyzing: false,
          errorMessage: () => error.isConflict ? alreadyPublished : unreachable,
        ),
      );
      return StoreLinksOutcome.failed;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_view_model.dart';
import '../../domain/view_report.dart';
import '../../domain/view_report_repository.dart';
import '../view_report_text.dart';

class ViewReportState {
  const ViewReportState({required this.report, this.busy = false, this.notice});

  final ViewReport report;

  /// 확인·이의 제기를 서버에 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 화면에 보일 안내(서버 문구 또는 일반 실패 문구).
  final String? notice;

  ViewReportState copyWith({
    ViewReport? report,
    bool? busy,
    String? notice,
    bool clearNotice = false,
  }) => ViewReportState(
    report: report ?? this.report,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// F4 `성과 확인`의 상태. 협업마다 하나이고 화면을 떠나면 버린다. 캡처 올리기 화면이 [apply]로 새
/// 상태를 넘겨 주면 F4가 바로 바뀐다. 앱은 계산하지 않고 서버가 준 값을 그대로 보인다.
///
/// Riverpod의 자동 재시도는 끈다(읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final viewReportViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ViewReportViewModel, ViewReportState, String>(
      ViewReportViewModel.new,
      retry: (_, _) => null,
    );

class ViewReportViewModel extends AsyncNotifier<ViewReportState> {
  ViewReportViewModel(this.collaborationId);

  final String collaborationId;

  ViewReportRepository get _repo => ref.read(viewReportRepositoryProvider);

  @override
  Future<ViewReportState> build() async {
    ref.watch(currentUserIdProvider);
    final report = await _repo.fetch(collaborationId);
    // 집계가 끝나 계산이 나오는 것처럼 협업 화면이 열린 사이에 단계가 바뀌었을 수 있다. 뒤로 돌아갔을 때
    // 낡은 `집계 중`이 남지 않게 협업 쪽도 다시 읽게 한다(방금 연 화면이라 다른 데이터가 흔들리지 않는다).
    Future.microtask(() {
      if (ref.mounted) _refreshCollaboration();
    });
    return ViewReportState(report: report);
  }

  /// 다른 화면이 서버에서 받은 최신 조회 자료를 넘긴다.
  void apply(ViewReport next) {
    final current = state.value;
    state = AsyncData(
      current == null
          ? ViewReportState(report: next)
          : current.copyWith(report: next, clearNotice: true),
    );
    _refreshCollaboration();
  }

  /// `자료 확인했어요`. 성공하면 true. 정산이 이어지므로 협업 화면도 새로 읽게 한다.
  Future<bool> confirm() => _act(() => _repo.confirm(collaborationId));

  /// `이의 제기`. 성공하면 null, 실패하면 시트에 보일 문구.
  Future<String?> dispute(String reason) async {
    final current = state.value;
    if (current == null || current.busy) return reportActionFailedMessage;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      final next = await _repo.dispute(collaborationId, reason.trim());
      if (!ref.mounted) return null;
      state = AsyncData(
        (state.value ?? current).copyWith(report: next, busy: false),
      );
      _refreshCollaboration();
      return null;
    } catch (error) {
      final text = reportFailureText(error, reportActionFailedMessage);
      if (!ref.mounted) return text;
      state = AsyncData((state.value ?? current).copyWith(busy: false));
      if (error is ViewReportFailure && error.conflict) {
        await _refreshQuietly(text);
      }
      return text;
    }
  }

  Future<bool> _act(Future<ViewReport> Function() call) async {
    final current = state.value;
    if (current == null || current.busy) return false;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      final next = await call();
      if (!ref.mounted) return true;
      state = AsyncData(
        (state.value ?? current).copyWith(report: next, busy: false),
      );
      _refreshCollaboration();
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final text = reportFailureText(error, reportActionFailedMessage);
      state = AsyncData(
        (state.value ?? current).copyWith(busy: false, notice: text),
      );
      // 409(그사이 바뀜: 이미 자동 확인됐거나 이의가 걸림)는 서버 문구를 보이고, 최신 상태로 맞춰 버튼이
      // 낡지 않게 한다.
      if (error is ViewReportFailure && error.conflict) {
        await _refreshQuietly(text);
      }
      return false;
    }
  }

  Future<void> _refreshQuietly(String notice) async {
    try {
      final fresh = await _repo.fetch(collaborationId);
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(report: fresh, busy: false, notice: notice),
      );
      _refreshCollaboration();
    } catch (_) {
      // 못 읽어도 안내는 이미 떠 있다.
    }
  }

  /// 확인·이의·캡처로 협업의 단계와 금액이 바뀌었을 수 있다. 협업 화면과 목록이 다시 읽는다.
  void _refreshCollaboration() {
    ref.invalidate(collaborationViewModelProvider(collaborationId));
    ref.invalidate(collaborationListViewModelProvider);
  }
}

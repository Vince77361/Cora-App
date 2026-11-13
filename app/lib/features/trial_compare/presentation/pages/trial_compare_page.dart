import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../notifications/presentation/notification_routes.dart';
import '../../../store_home/presentation/viewmodels/store_home_view_model.dart';
import '../../domain/trial_compare_repository.dart';
import '../../domain/trial_comparison.dart';
import '../trial_compare_text.dart';
import '../viewmodels/trial_compare_view_model.dart';

/// G3 지난 3개월 비교(NSwitchReport / DarkNSwitchReport). 체험단과 Cora를 같은 석 달로 견준다. 체험단 쪽
/// 숫자는 사장님이 입력한 값이고, `가게 계정에 남은 것` 줄과 `가게 계정 게시물`은 AI 제작 계획이 넣는다.
class TrialComparePage extends ConsumerStatefulWidget {
  const TrialComparePage({super.key});

  static const title = '지난 3개월 비교';
  static const heading = '같은 3개월,\n무엇이 남았나요?';
  static const trialColumn = '체험단';
  static const coraColumn = 'Cora';
  static const spentRow = '들어간 돈';
  static const contentRow = '생긴 콘텐츠';
  static const reactionRow = '평소 대비 반응';
  static const whoRow = '누가 왔나';
  static const trialReaction = '확인 어려움';
  static const trialWho = '플랫폼이 선정';
  static const coraWho = '지원자 중 직접 좋아요';
  static const note = '체험단 금액은 사장님이 입력한 값이에요.';
  static const later = '나중에';
  static const sendNext = '다음 달은 Cora로 오퍼 보내기';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '비교를 불러오지 못했어요.';
  static const noInfoTitle = '체험단 계약 정보가 없어요.';
  static const noInfoDescription = '계약 정보를 넣으면 비교해 드려요.';
  static const noInfoAction = '계약 정보 넣기';
  static const failedNotice = '잠시 문제가 생겼어요. 다시 시도해 주세요.';

  @override
  ConsumerState<TrialComparePage> createState() => _TrialComparePageState();
}

class _TrialComparePageState extends ConsumerState<TrialComparePage> {
  bool _busy = false;
  bool _failed = false;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  /// `나중에`: 홈의 체험단 줄을 7일 숨기고 홈으로 돌아간다.
  Future<void> _later() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await ref.read(trialCompareViewModelProvider.notifier).snooze();
    } on TrialCompareFailure {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _leave();
  }

  /// `다음 달은 Cora로 오퍼 보내기`: 새 지원이 있으면 추천(G2)으로, 없으면 홈의 지원자 탭으로 간다. 받는 사람이
  /// 없으면 오퍼 보내기(A5)를 열 수 없다.
  Future<void> _sendNext() async {
    var hasApplicants = false;
    try {
      final home = await ref.read(storeHomeViewModelProvider.future);
      hasApplicants = home.summary.newApplications > 0;
    } on Object {
      hasApplicants = false;
    }
    if (!mounted) return;
    if (hasApplicants) {
      context.push(AppRoutes.storeApplicantPicks);
    } else {
      context.go(
        '${AppRoutes.store}?${NotificationRoutes.tabParam}=${NotificationRoutes.applicantsTab}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(trialCompareViewModelProvider);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: TrialComparePage.title,
              extent: 64,
              onBack: _leave,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Content(comparison: value),
                ),
                AsyncError(:final error) =>
                  error is TrialCompareFailure && error.notFound
                      ? CoraStateView.empty(
                          title: TrialComparePage.noInfoTitle,
                          description: TrialComparePage.noInfoDescription,
                          actionLabel: TrialComparePage.noInfoAction,
                          // 정보를 저장하고 돌아오면 비교를 다시 읽는다.
                          onAction: () async {
                            await context.push(AppRoutes.storeTrialInfo);
                            if (mounted) {
                              ref.invalidate(trialCompareViewModelProvider);
                            }
                          },
                        )
                      : CoraStateView.loadFailed(
                          title: TrialComparePage.loadFailed,
                          onRetry: () =>
                              ref.invalidate(trialCompareViewModelProvider),
                        ),
                _ => const CoraStateView.loading(),
              },
            ),
            if (async.hasValue)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    if (_failed)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          TrialComparePage.failedNotice,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(color: c.text),
                        ),
                      ),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          flex: 10,
                          child: CoraPillButton(
                            label: TrialComparePage.later,
                            onPressed: _busy ? null : _later,
                            background: c.subtleAction,
                            foreground: c.onSubtleAction,
                            textStyle: CoraTextStyles.buttonMedium,
                            height: 58,
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: CoraPillButton(
                            label: TrialComparePage.sendNext,
                            onPressed: _busy ? null : _sendNext,
                            background: c.accent,
                            foreground: c.onAccent,
                            textStyle: CoraTextStyles.button,
                            height: 58,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.comparison});

  final TrialComparison comparison;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trial = comparison.trial;
    final cora = comparison.cora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _Notice(text: trialEndNotice(trial.endsOn)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          child: Semantics(
            header: true,
            child: Text(
              TrialComparePage.heading,
              style: CoraTextStyles.display.copyWith(
                fontSize: 24,
                letterSpacing: -1.08,
                height: 1.3,
                color: c.text,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _CompareTable(
            rows: [
              _Row(
                TrialComparePage.spentRow,
                trialSpentLine(trial.monthlyFee),
                coraSpentLine(cora.offerCount, cora.spent),
              ),
              _Row(
                TrialComparePage.contentRow,
                trialPostsLine(trial.postCount),
                contentLine(cora.contentByFormat),
              ),
              _Row(
                TrialComparePage.reactionRow,
                TrialComparePage.trialReaction,
                reactionLine(cora.averageMultiplierTenths),
              ),
              const _Row(
                TrialComparePage.whoRow,
                TrialComparePage.trialWho,
                TrialComparePage.coraWho,
                coraBold: false,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Text(
            TrialComparePage.note,
            style: CoraTextStyles.legal.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// 맨 위 안내 상자: 안쪽 12/16, 모서리 18, `surface`, 종 18과 글자 사이 10.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 10,
          children: [
            ExcludeSemantics(
              child: CustomPaint(
                size: const Size.square(18),
                painter: _BellPainter(c.text),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: CoraTextStyles.meta.copyWith(height: 1.5, color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.trial, this.cora, {this.coraBold = true});

  final String label;
  final String trial;
  final String cora;

  /// Cora 칸의 글자 굵기. `누가 왔나`만 500이고 나머지는 700이다.
  final bool coraBold;
}

/// 비교 표. 첫 칸 34%, 나머지 둘이 같게 나눈다. 줄 사이에 1px 선(`line`)이 있다.
class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Table(
      columnWidths: const {
        0: FractionColumnWidth(0.34),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      border: TableBorder(horizontalInside: BorderSide(color: c.line)),
      children: [
        TableRow(
          // 선은 줄 사이에만 있다(캔버스는 본문 줄마다 위 선이 있고 머리 줄 위에는 없다).
          children: [
            const SizedBox.shrink(),
            _head(c, TrialComparePage.trialColumn, bold: false),
            _head(c, TrialComparePage.coraColumn, bold: true),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  row.label,
                  style: CoraTextStyles.label.copyWith(color: c.textSecondary),
                ),
              ),
              _cell(c, row.trial, FontWeight.w400),
              _cell(
                c,
                row.cora,
                row.coraBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ],
          ),
      ],
    );
  }

  Widget _head(CoraColors c, String label, {required bool bold}) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
    child: Text(
      label,
      style: CoraTextStyles.label.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: bold ? c.text : c.textSecondary,
      ),
    ),
  );

  Widget _cell(CoraColors c, String text, FontWeight weight) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
    child: Text(
      text,
      style: CoraTextStyles.bodySmall.copyWith(
        fontWeight: weight,
        color: c.text,
      ),
    ),
  );
}

/// 종: `M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z`와 `M10 20a2 2 0 0 0 4 0`(24 x 24 칸, 선 2).
class _BellPainter extends CustomPainter {
  const _BellPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final body = Path()
      ..moveTo(6, 16)
      ..lineTo(6, 11)
      ..arcToPoint(
        const Offset(18, 11),
        radius: const Radius.circular(6),
        clockwise: true,
      )
      ..lineTo(18, 16)
      ..lineTo(19.5, 18)
      ..lineTo(4.5, 18)
      ..close();
    final clapper = Path()
      ..moveTo(10, 20)
      ..arcToPoint(
        const Offset(14, 20),
        radius: const Radius.circular(2),
        clockwise: false,
      );
    canvas
      ..drawPath(body, paint)
      ..drawPath(clapper, paint);
  }

  @override
  bool shouldRepaint(_BellPainter old) => old.color != color;
}

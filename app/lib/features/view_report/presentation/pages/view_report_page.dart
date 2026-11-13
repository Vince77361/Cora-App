import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../collaboration/presentation/link_launcher.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/view_report.dart';
import '../../domain/view_report_repository.dart';
import '../view_report_text.dart';
import '../viewmodels/view_report_view_model.dart';
import '../widgets/dispute_sheet.dart';

/// 이 화면을 여는 쪽. 뒤로 갈 곳이 다르다.
enum ViewReportViewer { creator, owner }

/// F4 성과 확인(NMetrics / DarkNMetrics). 조회수 집계 결과와 보상 계산을 보이고, 맡기는 쪽은 `자료
/// 확인했어요`, 양쪽은 `이의 제기`를 누른다. 자료가 확인되기 전에는 돈이 그대로 보관된다. 머리의 "안"
/// 표시는 캔버스 검토용이라 앱에 없다(확정된 화면).
class ViewReportPage extends ConsumerStatefulWidget {
  const ViewReportPage({
    super.key,
    required this.collaborationId,
    required this.viewer,
  });

  final String collaborationId;
  final ViewReportViewer viewer;

  static const title = '성과 확인';
  static const dataTitle = '조회 자료';
  static const post = '게시물';
  static const period = '측정 기간';
  static const source = '자료 출처';
  static const calcTitle = '보상 계산';
  static const viewPay = '조회수 수당';
  static const cap = '1인 상한';
  static const fixedCash = '고정 현금';
  static const refund = '사장님께 환불';
  static const payout = '크리에이터 지급 예정';
  static const countingPlaceholder = '집계가 끝나면 계산해요.';
  static const guide =
      '자료가 확인되기 전에는 0원이나 지급 완료로 처리하지 않아요. 지급 방식(직접 지급 기록 또는 Cora 보관)은 아직 정하는 중이에요.';
  static const dispute = '이의 제기';
  static const confirm = '자료 확인했어요';
  static const noViews = '-';

  /// 제출된 캡처 그림의 접근성 이름(캔버스에 없다).
  static const evidenceImage = '제출한 인사이트 캡처';

  @override
  ConsumerState<ViewReportPage> createState() => _ViewReportPageState();
}

class _ViewReportPageState extends ConsumerState<ViewReportPage> {
  String? _linkNotice;

  ViewReportViewModel get _vm =>
      ref.read(viewReportViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(switch (widget.viewer) {
        ViewReportViewer.creator => AppRoutes.creatorCollaboration(
          widget.collaborationId,
        ),
        ViewReportViewer.owner => AppRoutes.storeCollaboration(
          widget.collaborationId,
        ),
      });
    }
  }

  /// 크리에이터가 낸 게시 링크는 `http`·`https`일 때만 바깥 브라우저로 연다.
  Future<void> _openPost(ViewReport report) async {
    final url = openableLink(report.postUrl);
    final opened =
        url != null && await ref.read(externalLinkLauncherProvider).open(url);
    if (!mounted || opened) return;
    setState(() => _linkNotice = reportLinkFailedMessage);
  }

  Future<void> _openDispute() =>
      showDisputeSheet(context, onSubmit: _vm.dispute);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      viewReportViewModelProvider(widget.collaborationId),
    );
    final value = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: ViewReportPage.title,
              extent: 64,
              onBack: _leave,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Content(
                    report: value.report,
                    onOpenPost: () => _openPost(value.report),
                  ),
                ),
                AsyncError(:final error) =>
                  error is ViewReportFailure && error.notFound
                      ? const CoraStateView.empty(
                          title: reportNotAvailableMessage,
                        )
                      : CoraStateView.loadFailed(
                          title: reportLoadFailedMessage,
                          onRetry: () => ref.invalidate(
                            viewReportViewModelProvider(widget.collaborationId),
                          ),
                        ),
                _ => const CoraStateView.loading(),
              },
            ),
            if (value != null)
              _BottomBar(
                state: value,
                notice: _linkNotice ?? value.notice,
                bottom: bottom,
                onDispute: _openDispute,
                onConfirm: _vm.confirm,
              ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.report, required this.onOpenPost});

  final ViewReport report;
  final VoidCallback onOpenPost;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final calc = report.calc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _DataBox(report: report, onOpenPost: onOpenPost),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: calc == null
              ? const _CountingBox()
              : _CalcBox(calc: calc, views: report.views),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Text(
            ViewReportPage.guide,
            // 캔버스는 줄 높이 1.6이다.
            style: CoraTextStyles.legal.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// 위 상자(캔버스 첫 `section`): 모서리 26, 안쪽 18, `surface`.
class _DataBox extends StatelessWidget {
  const _DataBox({required this.report, required this.onOpenPost});

  final ViewReport report;
  final VoidCallback onOpenPost;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final views = report.views;
    final evidence = report.evidence;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              children: [
                Flexible(
                  child: Text(
                    ViewReportPage.dataTitle,
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ),
                _StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: ViewReportPage.dataTitle,
              value: views == null ? ViewReportPage.noViews : viewsLabel(views),
              child: ExcludeSemantics(
                child: Text(
                  views == null ? ViewReportPage.noViews : viewsLabel(views),
                  // 캔버스는 줄 높이를 주지 않아(`normal`) 글자 크기의 1.448배다.
                  style: CoraTextStyles.display.copyWith(
                    height: 1.448,
                    color: c.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _KeyValueRow(
              term: ViewReportPage.post,
              value: postLinkLabel(report.postUrl),
              first: true,
              onTapValue: onOpenPost,
            ),
            _KeyValueRow(
              term: ViewReportPage.period,
              value: periodLabel(report.periodStart, report.periodEnd),
            ),
            _KeyValueRow(
              term: ViewReportPage.source,
              value: sourceLabel(report.source),
            ),
            // 서명 주소를 못 만들었으면(null) 사진 자리를 비운다.
            if (evidence?.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Semantics(
                  image: true,
                  label: ViewReportPage.evidenceImage,
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(CoraRadius.sm),
                      child: SizedBox(
                        height: 200,
                        child: CoraNetworkPhoto(
                          url: evidence!.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          background: c.line,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 표지(알약): 안쪽 5/10, 글자 12/500. `미확인`·`집계 중`은 `reportBadge` 바탕에 보조 글자, `확인 완료`는
/// 라임, `이의 제기됨`은 `reportBadge` 바탕에 본문 글자(NMetrics `st`).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ViewReportStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (status) {
      ViewReportStatus.confirmed => (c.accent, c.onAccent),
      ViewReportStatus.disputed => (c.reportBadge, c.text),
      ViewReportStatus.counting ||
      ViewReportStatus.unconfirmed => (c.reportBadge, c.textSecondary),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          statusLabel(status),
          style: CoraTextStyles.caption.copyWith(color: fg),
        ),
      ),
    );
  }
}

/// 보상 계산 상자(캔버스 둘째 `section`): 모서리 26, 안쪽 14/18/6, `surface`.
class _CalcBox extends StatelessWidget {
  const _CalcBox({required this.calc, required this.views});

  final ViewReportCalc calc;
  final int? views;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Semantics(
                header: true,
                child: Text(
                  ViewReportPage.calcTitle,
                  style: CoraTextStyles.label.copyWith(color: c.textSecondary),
                ),
              ),
            ),
            _KeyValueRow(
              term: ViewReportPage.viewPay,
              value: viewPayFormula(calc, views),
              first: true,
            ),
            _KeyValueRow(term: ViewReportPage.cap, value: capLine(calc)),
            if (calc.fixedCash > 0)
              _KeyValueRow(
                term: ViewReportPage.fixedCash,
                value: wonExact(calc.fixedCash),
              ),
            _KeyValueRow(
              term: ViewReportPage.refund,
              value: wonExact(calc.refund),
            ),
            _KeyValueRow(
              term: ViewReportPage.payout,
              value: wonExact(calc.payout),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// 측정 중에 계산 상자 자리에 보이는 안내(캔버스에 없다): 같은 상자 모양에 문구만.
class _CountingBox extends StatelessWidget {
  const _CountingBox();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Semantics(
          liveRegion: true,
          child: Text(
            ViewReportPage.countingPlaceholder,
            style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// 항목 한 줄(캔버스 `dl > div`): 위아래 10, 첫 줄 말고는 위에 선, 왼쪽 항목(13, 보조색)과 오른쪽 값(15/500,
/// 오른쪽 정렬) 사이 12. 첫 줄은 [first]다. 캔버스는 CSS flex라 두 글자가 한 줄에 안 들어가면 각자의
/// 본래 너비에 비례해 줄어든다(항목이 두 줄이 되기도 한다). 같은 모양이 되도록 본래 너비를 재서 그
/// 비율로 칸을 나눈다.
class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.term,
    required this.value,
    this.first = false,
    this.bold = false,
    this.onTapValue,
  });

  final String term;
  final String value;
  final bool first;
  final bool bold;

  /// 값을 누르면 하는 일(게시 링크를 연다). 없으면 글자일 뿐이다.
  final VoidCallback? onTapValue;

  static const double _gap = 12;

  double _width(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final termStyle = CoraTextStyles.meta.copyWith(color: c.textSecondary);
    final valueStyle =
        (bold ? CoraTextStyles.amountSmall : CoraTextStyles.buttonMedium)
            .copyWith(color: c.text);
    final termFlex = math.max(
      1,
      (_width(context, term, termStyle) * 100).round(),
    );
    final valueFlex = math.max(
      1,
      (_width(context, value, valueStyle) * 100).round(),
    );
    Widget valueText = Text(
      value,
      textAlign: TextAlign.right,
      style: valueStyle,
    );
    if (onTapValue != null) {
      valueText = Semantics(
        link: true,
        onTap: onTapValue,
        child: ExcludeSemantics(
          child: CoraPressable(onTap: onTapValue, child: valueText),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                flex: termFlex,
                child: Text(term, style: termStyle),
              ),
              const SizedBox(width: _gap),
              Flexible(flex: valueFlex, child: valueText),
            ],
          ),
        ),
      ),
    );
  }
}

/// 아래 버튼(캔버스 하단): 높이 58, 사이 8, 왼쪽이 1, 오른쪽이 1.6. 서버가 준 `canDispute`·`canConfirm`·
/// `canUploadEvidence`가 참인 것만 보이고, 하나뿐이면 가로를 다 채운다. 확인 완료나 이의 제기 뒤에는
/// 서버가 모두 거짓으로 줘서 버튼이 없다.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.notice,
    required this.bottom,
    required this.onDispute,
    required this.onConfirm,
  });

  final ViewReportState state;
  final String? notice;
  final double bottom;
  final VoidCallback onDispute;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = state.report;
    final busy = state.busy;
    final primary = r.canConfirm
        ? (label: ViewReportPage.confirm, onTap: onConfirm)
        : null;
    if (!r.canDispute && primary == null && notice == null) {
      return SizedBox(height: bottom);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  notice!,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.meta.copyWith(color: c.text),
                ),
              ),
            ),
          Row(
            spacing: 8,
            children: [
              if (r.canDispute)
                Expanded(
                  flex: primary == null ? 16 : 10,
                  child: CoraPillButton(
                    label: ViewReportPage.dispute,
                    onPressed: busy ? null : onDispute,
                    background: c.subtleAction,
                    foreground: c.onSubtleAction,
                    textStyle: CoraTextStyles.buttonMedium,
                    height: 58,
                  ),
                ),
              if (primary != null)
                Expanded(
                  flex: 16,
                  child: CoraPillButton(
                    label: primary.label,
                    onPressed: busy ? null : primary.onTap,
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
    );
  }
}

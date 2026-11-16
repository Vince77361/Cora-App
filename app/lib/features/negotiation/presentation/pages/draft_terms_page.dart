import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_motion.dart';
import '../../../../core/theme/cora_negotiation_tokens.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart' show won;
import '../../../store_browse/presentation/widgets/photo_overlays.dart';
import '../../domain/terms_version.dart';
import '../terms_text.dart';
import '../widgets/canvas_text.dart';
import '../viewmodels/terms_view_model.dart';

/// 06 조건 협의(Terms / DarkTerms): 협업의 최신 조건 판본을 보고 수락한다. 사진 위에 상대 이름과 콘텐츠 제목,
/// 아래 흰 면에 판본 머리와 표지, 칸 세 개(현금 고정비·혜택·성과 추가), 접히는 묶음 넷이 있다.
///
/// [fromProgress]이면 07에서 열린 것이라, 수락한 뒤 07을 새로 쌓지 않고 07로 돌아간다.
class DraftTermsPage extends ConsumerStatefulWidget {
  const DraftTermsPage({
    super.key,
    required this.collaborationId,
    this.fromProgress = false,
  });

  final String collaborationId;
  final bool fromProgress;

  @override
  ConsumerState<DraftTermsPage> createState() => _DraftTermsPageState();
}

class _DraftTermsPageState extends ConsumerState<DraftTermsPage> {
  /// 펼친 묶음. 캔버스는 `추천된 이유`가 처음에 펼쳐져 있다.
  _Group? _open = _Group.why;

  TermsViewModel get _vm =>
      ref.read(termsViewModelProvider(widget.collaborationId).notifier);

  void _leave(TermsState? state) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        state == null || state.isBrand
            ? AppRoutes.brandCollaborations
            : AppRoutes.creatorOffers,
      );
    }
  }

  Future<void> _accept() async {
    final done = await _vm.confirm();
    if (!mounted || !done) return;
    if (widget.fromProgress && context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement(
        AppRoutes.collaborationProgress(widget.collaborationId),
      );
    }
  }

  Future<void> _connectInstagram() async {
    await context.push(AppRoutes.creatorInstagram);
    // 연동하고 돌아오면 서버가 `needsInstagram`을 바꿨으므로 버튼이 `이 판본 수락`이 된다.
    if (mounted) await _vm.reload();
  }

  void _modify(TermsState state) {
    context.push(
      state.isBrand
          ? AppRoutes.brandComingSoon(TermsTexts.modify)
          : AppRoutes.creatorComingSoon(TermsTexts.modify),
      extra: AppRoutes.stacked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = termsViewModelProvider(widget.collaborationId);
    final async = ref.watch(provider);
    final value = async.value;
    if (value != null && value.staleVersion != null) {
      return _Shell(
        onBack: () => _leave(value),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CoraStateView.staleVersion(
            version: value.staleVersion!,
            onOpen: _vm.reload,
          ),
        ),
      );
    }
    if (value == null) {
      return _Shell(
        onBack: () => _leave(null),
        child: async.hasError
            ? CoraStateView.loadFailed(
                title: TermsTexts.loadFailed,
                onRetry: () => ref.invalidate(provider),
              )
            : const CoraStateView.loading(),
      );
    }
    final c = context.colors;
    final bottom = math.max(24.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  _Photo(state: value, onBack: () => _leave(value)),
                  // 사진(높이 248) 위로 흰 면이 24 겹쳐 올라온다.
                  Padding(
                    padding: const EdgeInsets.only(top: _Photo.height - 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: _Body(
                          latest: value.latest,
                          open: _open,
                          onToggle: (g) =>
                              setState(() => _open = _open == g ? null : g),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ActionBar(
            state: value,
            bottom: bottom,
            onModify: () => _modify(value),
            onAccept: _accept,
            onConnect: _connectInstagram,
          ),
        ],
      ),
    );
  }
}

enum _Group { why, edit, use, pay }

/// 불러오는 중, 불러오기 실패, 옛 판본에서 쓰는 틀: 위에 뒤로 가기만 있다.
class _Shell extends StatelessWidget {
  const _Shell({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(onBack: onBack, extent: 64),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 사진(높이 248): 왼쪽 위 뒤로 가기, 아래에 상대 이름과 콘텐츠 제목을 어두운 덮개 위에 얹는다.
class _Photo extends StatelessWidget {
  const _Photo({required this.state, required this.onBack});

  final TermsState state;
  final VoidCallback onBack;

  static const height = 248.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final collaboration = state.collaboration;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: '${collaboration.counterpartName} 대표 사진',
            child: ExcludeSemantics(
              child: CoraNetworkPhoto(
                url: collaboration.counterpartPhotoUrl,
                // 캔버스 object-position 50% 42%
                alignment: const Alignment(0, -0.16),
                background: c.photoPlaceholder,
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: top + 10,
            child: PhotoBackButton(onPressed: onBack),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: CoraNegotiationTokens.termsPhotoScrim,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collaboration.counterpartName,
                      style: canvasText(
                        13,
                        FontWeight.w500,
                        c.onPhotoSecondary,
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        state.latest.terms.title,
                        style: canvasText(
                          24,
                          FontWeight.w900,
                          c.onPhoto,
                          spacingEm: -0.04,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.latest,
    required this.open,
    required this.onToggle,
  });

  final TermsLatest latest;
  final _Group? open;
  final ValueChanged<_Group> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = latest.terms;
    final header = termsHeader(
      version: t.version,
      myTurn: latest.myTurn,
      mine: latest.mine,
      agreed: t.agreed,
    );
    final notice = latest.notice;
    final groups = _groups(latest);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        header.title,
                        style: canvasText(15, FontWeight.w700, c.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(header: header),
                ],
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 6,
                  children: [
                    Expanded(
                      child: _Cell(
                        label: TermsTexts.cellFee,
                        value: won(t.fee),
                        valueStyle: canvasText(
                          18,
                          FontWeight.w900,
                          c.text,
                          spacingEm: -0.03,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Cell(
                        label: TermsTexts.cellBenefit,
                        value: compareBenefitLabel(t.productProvided),
                        valueStyle: canvasText(15, FontWeight.w700, c.text),
                      ),
                    ),
                    Expanded(
                      child: _Cell(
                        label: TermsTexts.cellPerf,
                        value: perfLabel(t.performance),
                        valueStyle: canvasText(15, FontWeight.w700, c.text),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                termsAcceptNote(
                  t.maxCash,
                  hasPerformance: t.performance != null,
                ),
                style: canvasText(12, FontWeight.w400, c.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                children: [
                  Text(
                    deliverableLabel(t.format, t.pieces),
                    style: canvasText(16, FontWeight.w700, c.text),
                  ),
                  Text(
                    startFromLabel(t.startDate),
                    style: canvasText(16, FontWeight.w500, c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (notice != null && notice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(CoraRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  notice,
                  style: canvasText(14, FontWeight.w400, c.text, height: 1.55),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            children: [
              for (final g in groups)
                _GroupTile(
                  data: g,
                  open: open == g.id,
                  onToggle: () => onToggle(g.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 접히는 묶음 넷. 추천된 이유는 보일 내용이 없으면(이유도 팔로워도 없으면) 줄이지 않고 뺀다.
  List<_GroupData> _groups(TermsLatest latest) {
    final t = latest.terms;
    final reasons = latest.reasons;
    final fields = latest.fields;
    final followers = latest.followers;
    return [
      if (reasons.isNotEmpty || fields.isNotEmpty || followers != null)
        _GroupData(
          id: _Group.why,
          title: TermsTexts.groupWhy,
          // 요약은 첫 이유(브리프). 이유가 없으면 분야, 그것도 없으면 팔로워다.
          summary: reasons.isNotEmpty
              ? reasonLabel(reasons.first)
              : (fields.isNotEmpty
                    ? fields.join(', ')
                    : followersLabel(followers!)),
          rows: [
            if (reasons.isNotEmpty)
              (TermsTexts.rowFit, reasons.map(reasonLabel).join(', ')),
            if (fields.isNotEmpty) (TermsTexts.rowFields, fields.join(', ')),
            if (followers != null)
              (TermsTexts.rowFollowers, followersLabel(followers)),
          ],
        ),
      _GroupData(
        id: _Group.edit,
        title: TermsTexts.groupEdit,
        summary: revisionLabel(t.revisionScope),
        rows: [
          (TermsTexts.rowRevision, revisionLabel(t.revisionScope)),
          (TermsTexts.rowExtraShoot, TermsTexts.negotiable),
        ],
      ),
      _GroupData(
        id: _Group.use,
        title: TermsTexts.groupUse,
        summary: usageLabel(t.usageRights),
        rows: [
          (TermsTexts.rowRepost, repostValueLabel(t.usageRights)),
          (TermsTexts.rowAds, adsValueLabel(t.usageRights)),
        ],
      ),
      _GroupData(
        id: _Group.pay,
        title: TermsTexts.groupPay,
        summary: payoutLabel(t.payoutDays),
        rows: [
          (TermsTexts.rowPayout, payoutLabel(t.payoutDays)),
          (TermsTexts.rowAdMark, TermsTexts.adMark),
        ],
      ),
    ];
  }
}

class _GroupData {
  const _GroupData({
    required this.id,
    required this.title,
    required this.summary,
    required this.rows,
  });

  final _Group id;
  final String title;
  final String summary;
  final List<(String, String)> rows;
}

/// 머리 오른쪽 표지. 내가 응답할 차례면 라임 알약이고, 그 밖의 표지(캔버스 밖)는 `surface` 알약이다.
class _Badge extends StatelessWidget {
  const _Badge({required this.header});

  final TermsHeader header;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: header.highlighted ? c.accent : c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          header.badge,
          style: canvasText(
            12,
            FontWeight.w500,
            header.highlighted ? c.onAccent : c.text,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: canvasText(11, FontWeight.w400, c.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.data,
    required this.open,
    required this.onToggle,
  });

  final _GroupData data;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          expanded: open,
          label: '${data.title}, ${data.summary}',
          onTap: onToggle,
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 2,
                        children: [
                          Text(
                            data.title,
                            style: canvasText(16, FontWeight.w700, c.text),
                          ),
                          Text(
                            data.summary,
                            style: canvasText(
                              13,
                              FontWeight.w400,
                              c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: CoraMotion.resolve(
                        context,
                        CoraMotion.stateDuration,
                      ),
                      child: CustomPaint(
                        size: const Size.square(18),
                        painter: _ChevronPainter(c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(CoraRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    for (final (key, value) in data.rows)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 12,
                        children: [
                          Text(
                            key,
                            style: canvasText(
                              14,
                              FontWeight.w400,
                              c.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              style: canvasText(14, FontWeight.w500, c.text),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// SVG `M6 9l6 6 6-6`(viewBox 24, stroke 2.4, round)를 18로 줄여 그린다.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// 아래 버튼 줄(높이 90 = 위 12 + 버튼 54 + 아래 24). 배경은 화면 바탕이고 위로 그림자가 드리운다.
/// 수락 자리는 내 차례면 `이 판본 수락`, 인스타그램 연동이 필요하면 `연동하기`(위에 안내), 내가 이미 확인했으면
/// 꺼진 `상대의 응답을 기다리고 있어요`, 양쪽이 확인했으면 없다.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.bottom,
    required this.onModify,
    required this.onAccept,
    required this.onConnect,
  });

  final TermsState state;
  final double bottom;
  final VoidCallback onModify;
  final VoidCallback onAccept;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final latest = state.latest;
    final agreed = latest.terms.agreed;
    final needsInstagram = latest.myTurn && latest.needsInstagram;
    final busy = state.busy;
    final notice = state.notice;
    final Widget? primary;
    if (agreed) {
      primary = null;
    } else if (!latest.myTurn) {
      primary = Opacity(
        opacity: 0.5,
        child: CoraPillButton(
          label: TermsTexts.waiting,
          onPressed: null,
          background: c.accent,
          foreground: c.onAccent,
          textStyle: canvasText(15, FontWeight.w700, c.onAccent),
          height: 54,
        ),
      );
    } else if (needsInstagram) {
      primary = CoraPillButton(
        label: TermsTexts.connectInstagram,
        onPressed: busy ? null : onConnect,
        background: c.accent,
        foreground: c.onAccent,
        textStyle: canvasText(15, FontWeight.w700, c.onAccent),
        height: 54,
      );
    } else {
      primary = CoraPillButton(
        label: TermsTexts.accept,
        onPressed: busy ? null : onAccept,
        background: c.accent,
        foreground: c.onAccent,
        textStyle: canvasText(15, FontWeight.w700, c.onAccent),
        height: 54,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        boxShadow: [
          BoxShadow(
            color: c.termsBarShadow,
            offset: const Offset(0, -8),
            blurRadius: CoraShadows.blurRadiusFor(24),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (needsInstagram)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    TermsTexts.needsInstagram,
                    textAlign: TextAlign.center,
                    style: canvasText(12, FontWeight.w400, c.textSecondary),
                  ),
                ),
              ),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    notice,
                    textAlign: TextAlign.center,
                    style: canvasText(12, FontWeight.w400, c.text),
                  ),
                ),
              ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 10,
                  child: CoraPillButton(
                    label: TermsTexts.modify,
                    onPressed: busy ? null : onModify,
                    background: c.surface,
                    foreground: c.text,
                    textStyle: canvasText(15, FontWeight.w700, c.text),
                    height: 54,
                  ),
                ),
                if (primary != null) Expanded(flex: 14, child: primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

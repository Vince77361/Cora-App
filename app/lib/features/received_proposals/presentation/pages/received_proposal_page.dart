import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_received_proposal_tokens.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/text/utf16_length_limiting_formatter.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../chat/presentation/widgets/chat_glyphs.dart';
import '../../../discovery/presentation/creator_discovery_text.dart';
import '../../../interests/presentation/widgets/interest_icons.dart';
import '../../domain/received_proposal.dart';
import '../received_proposals_text.dart';
import '../viewmodels/received_proposal_view_model.dart';
import '../viewmodels/received_proposals_view_model.dart';
import 'inquiry_sheet.dart';

/// 10 콘텐츠 기반 제안(Proposal / DarkProposal). 브랜드가 내 콘텐츠에 관심을 보내며 건넨 제안을 사진 카드로 본다.
/// `관심 보내기`는 입력한 한 줄을 붙여 관심을 보내고(서로 관심이 되면 05가 열린다), `조건부터 질문하기`는 서로
/// 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다.
///
/// 질문을 보내거나 관심만 보내고 닫히면 03이 보여 줄 안내 문구를 `pop`의 값으로 돌려준다.
class ReceivedProposalPage extends ConsumerStatefulWidget {
  const ReceivedProposalPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<ReceivedProposalPage> createState() =>
      _ReceivedProposalPageState();
}

class _ReceivedProposalPageState extends ConsumerState<ReceivedProposalPage> {
  final _idea = TextEditingController();
  String? _notice;

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
  }

  ReceivedProposalViewModel get _vm => ref.read(
    receivedProposalViewModelProvider(widget.campaignId).notifier,
  );

  Future<void> _sendInterest() async {
    setState(() => _notice = null);
    final outcome = await _vm.sendInterest(_idea.text);
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case InterestMatched(:final collaborationId):
        // 서로 관심이 닿았다. 이 제안은 더 볼 일이 없으니 05(03이 시트로 연다)로 바꿔 연다.
        context.pushReplacement(AppRoutes.creatorMatch(collaborationId));
      case InterestSent():
        context.pop(CreatorDiscoveryTexts.likeToast);
      case InterestFailed():
        setState(() => _notice = ReceivedProposalsTexts.interestFailed);
    }
  }

  Future<void> _ask() async {
    setState(() => _notice = null);
    final sent = await showInquirySheet(
      context,
      onSubmit: (message) => _vm.inquire(message, _idea.text),
    );
    if (sent == true && mounted) {
      context.pop(ReceivedProposalsTexts.inquirySent);
    }
  }

  void _retry() {
    ref.invalidate(receivedProposalsViewModelProvider);
    ref.invalidate(receivedProposalViewModelProvider(widget.campaignId));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(
      receivedProposalViewModelProvider(widget.campaignId),
    );
    final Widget body = switch (async) {
      AsyncData(:final value) => _Card(
        proposal: value.proposal,
        idea: _idea,
        busy: value.busy,
        notice: _notice,
        onSendInterest: _sendInterest,
        onAsk: _ask,
      ),
      AsyncError(:final error) when error is ReceivedProposalGone =>
        const CoraStateView.empty(
          title: ReceivedProposalsTexts.goneTitle,
          description: ReceivedProposalsTexts.goneBody,
        ),
      AsyncError() => CoraStateView.loadFailed(
        title: ReceivedProposalsTexts.loadFailedTitle,
        onRetry: _retry,
      ),
      _ => const CoraStateView.loading(),
    };
    return Scaffold(
      backgroundColor: c.background,
      // 키보드는 카드를 줄이지 않고 아래 입력줄만 밀어 올린다(카드 위의 글이 머리와 겹치지 않게).
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: body is _Card
                    ? body
                    : SingleChildScrollView(child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 위 막대: 높이 56, 안쪽 좌우 8. 왼쪽 닫기(44 x 44 칸에 X 20, 두께 2.4), 가운데 `받은 제안`(16/500).
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  container: true,
                  button: true,
                  label: ReceivedProposalsTexts.close,
                  onTap: () => context.pop(),
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: () => context.pop(),
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: InterestIcon(ClosePainter(c.text), size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  ReceivedProposalsTexts.title,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

/// 사진 카드(모서리 28, 바탕 `#0F1012`). 사진 위에 진행 막대, 브랜드 줄, 좋아한 점 말풍선, 제작비 줄이 있고 아래에
/// 버튼 둘과 한 줄 입력줄이 있다.
class _Card extends StatelessWidget {
  const _Card({
    required this.proposal,
    required this.idea,
    required this.busy,
    required this.notice,
    required this.onSendInterest,
    required this.onAsk,
  });

  final ReceivedProposal proposal;
  final TextEditingController idea;
  final bool busy;
  final String? notice;
  final VoidCallback onSendInterest;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 키보드가 올라오면 아래 입력줄과 그 위 글을 키보드 위로 올린다(카드 아래 여백 24는 키보드 밑이다).
    final lift = (MediaQuery.viewInsetsOf(context).bottom - 24).clamp(
      0.0,
      double.infinity,
    );
    final note = proposal.note;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: CoraReceivedProposalTokens.cardBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: true,
              label: '브랜드가 고른 내 콘텐츠',
              child: ExcludeSemantics(
                child: CoraNetworkPhoto(
                  url: proposal.contentPhotoUrl,
                  alignment: const Alignment(0, -0.3),
                  background: CoraReceivedProposalTokens.cardBackground,
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: CoraReceivedProposalTokens.topScrimHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: CoraReceivedProposalTokens.topScrim,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: CoraReceivedProposalTokens.bottomScrimHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: CoraReceivedProposalTokens.bottomScrim,
                    stops: CoraReceivedProposalTokens.bottomScrimStops,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 12,
              child: ExcludeSemantics(
                child: Row(
                  spacing: 4,
                  children: [
                    Expanded(
                      child: _ProgressSegment(color: c.swipeProgressOn),
                    ),
                    const Expanded(
                      child: _ProgressSegment(
                        color: CoraSwipeTokens.progressIdle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 24,
              child: _BrandLine(proposal: proposal),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 168 + lift,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  if (note != null && note.trim().isNotEmpty)
                    _NoteBubble(note: note),
                  _PriceLine(proposal: proposal),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: lift,
              child: _Controls(
                idea: idea,
                busy: busy,
                notice: notice,
                onSendInterest: onSendInterest,
                onAsk: onAsk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
    child: const SizedBox(height: 3),
  );
}

/// 위 왼쪽 브랜드 줄: 브랜드 사진 원(36)과 이름(14/500), 아래 `내 콘텐츠 「…」에 제안했어요`(12).
class _BrandLine extends StatelessWidget {
  const _BrandLine({required this.proposal});

  final ReceivedProposal proposal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        spacing: 10,
        children: [
          ExcludeSemantics(
            child: ClipOval(
              child: SizedBox.square(
                dimension: 36,
                child: CoraNetworkPhoto(
                  url: proposal.brandPhotoUrl,
                  alignment: const Alignment(0.24, -0.2),
                  background: CoraReceivedProposalTokens.avatarPlaceholder,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proposal.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.onPhoto,
                  ),
                ),
                Text(
                  ReceivedProposalsTexts.proposedOn(proposal),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    color: CoraReceivedProposalTokens.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `브랜드가 좋아한 점` 말풍선: 최대 폭 300, 안쪽 16 18, 모서리 20/20/20/6, 반투명 흰 바탕, -1.5도 기울임.
class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Transform.rotate(
        angle: CoraReceivedProposalTokens.noteTilt,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: CoraReceivedProposalTokens.noteBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 캔버스는 이 한 줄만 모드의 글자색(다크 #F2F3F5)을 쓰고 나머지는 어두운 글자라, 다크에서는
                // 흰 바탕 위에 밝은 글자로 거의 보이지 않는다. 캔버스 그대로다.
                Text(
                  ReceivedProposalsTexts.likedLabel,
                  style: CoraTextStyles.caption.copyWith(color: c.text),
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  style: CoraTextStyles.bodyLarge.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: CoraReceivedProposalTokens.noteInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 제작비 줄: `30만 원 + 제품`(28/900, 자간 -0.04em, 라임)과 `릴스 1편`(14), 글자 아래선을 맞춘다.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.proposal});

  final ReceivedProposal proposal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final price = ReceivedProposalsTexts.priceLine(proposal);
    final format = ReceivedProposalsTexts.formatLine(proposal);
    return Semantics(
      container: true,
      label: '$price, $format',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 10,
          children: [
            Flexible(
              child: Text(
                price,
                style: CoraTextStyles.display.copyWith(
                  fontSize: 28,
                  letterSpacing: -1.12,
                  height: 1.448,
                  color: c.accent,
                ),
              ),
            ),
            Text(
              format,
              style: CoraTextStyles.bodySmall.copyWith(
                color: CoraReceivedProposalTokens.formatLine,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아래 묶음: 버튼 둘(높이 48, 사이 8), 한 줄 입력줄(높이 52). 안쪽 좌우 14, 아래 16, 사이 10.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.idea,
    required this.busy,
    required this.notice,
    required this.onSendInterest,
    required this.onAsk,
  });

  final TextEditingController idea;
  final bool busy;
  final String? notice;
  final VoidCallback onSendInterest;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (notice != null)
            Semantics(
              liveRegion: true,
              child: Text(
                notice!,
                textAlign: TextAlign.center,
                style: CoraTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.onPhoto,
                ),
              ),
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: CoraPillButton(
                  label: ReceivedProposalsTexts.sendInterest,
                  onPressed: busy ? null : onSendInterest,
                  background: c.accent,
                  foreground: c.onAccent,
                  textStyle: CoraTextStyles.button.copyWith(fontSize: 15),
                  height: 48,
                ),
              ),
              Expanded(
                child: _GlassPill(
                  label: ReceivedProposalsTexts.askConditions,
                  onPressed: busy ? null : onAsk,
                ),
              ),
            ],
          ),
          _IdeaField(controller: idea, busy: busy, onSend: onSendInterest),
        ],
      ),
    );
  }
}

/// `조건부터 질문하기`: 높이 48, 반투명 흰 바탕을 뒤 사진 위에서 8만큼 흐린다, 흰 글자 15/500.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: CoraReceivedProposalTokens.glassBlur,
                sigmaY: CoraReceivedProposalTokens.glassBlur,
              ),
              child: ColoredBox(
                color: CoraReceivedProposalTokens.glassPill,
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: CoraTextStyles.buttonMedium.copyWith(
                          color: c.onPhoto,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 한 줄 입력줄: 높이 52, 안쪽 왼쪽 18·오른쪽 6, 반투명 바탕. 오른쪽에 라임 원(40)과 화살표(18, 두께 2.4).
class _IdeaField extends StatelessWidget {
  const _IdeaField({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: CoraReceivedProposalTokens.glassBlur,
          sigmaY: CoraReceivedProposalTokens.glassBlur,
        ),
        child: ColoredBox(
          color: CoraReceivedProposalTokens.glassField,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 6),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Semantics(
                      textField: true,
                      label: ReceivedProposalsTexts.ideaLabel,
                      child: TextField(
                        controller: controller,
                        enabled: !busy,
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        inputFormatters: const [
                          Utf16LengthLimitingFormatter(
                            ReceivedProposalsTexts.ideaMax,
                          ),
                        ],
                        cursorColor: c.onPhoto,
                        style: CoraTextStyles.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: c.onPhoto,
                        ),
                        decoration: InputDecoration(
                          hintText: ReceivedProposalsTexts.ideaHint,
                          hintStyle: CoraTextStyles.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: CoraReceivedProposalTokens.fieldHint,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    container: true,
                    button: true,
                    enabled: !busy,
                    label: ReceivedProposalsTexts.ideaSendLabel,
                    onTap: busy ? null : onSend,
                    child: ExcludeSemantics(
                      child: CoraPressable(
                        onTap: busy ? null : onSend,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: 40,
                            child: Center(
                              child: ChatGlyphIcon(
                                ChatGlyph.arrowSend,
                                size: 18,
                                color: c.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_chat_tokens.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../domain/conversation.dart';
import '../chat_text.dart';
import '../viewmodels/message_request_view_model.dart';
import '../widgets/decline_request_sheet.dart';

/// 11 메시지 요청(Chat / DarkChat). 크리에이터가 "조건부터 질문하기"로 보낸 요청을 브랜드가 읽고
/// `대화 열기`로 수락하거나 `요청 거절`로 거절한다. 위 숫자는 협의 중인 제안이고 조건을 수락한 것이 아니다.
class MessageRequestPage extends ConsumerWidget {
  const MessageRequestPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(messageRequestViewModelProvider(conversationId));
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: switch (async) {
        AsyncData(:final value) => _Loaded(
          conversationId: conversationId,
          state: value,
        ),
        AsyncError() => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlainBack(onBack: () => context.pop()),
              CoraStateView.loadFailed(
                title: ChatTexts.requestLoadFailed,
                onRetry: () => ref.invalidate(
                  messageRequestViewModelProvider(conversationId),
                ),
              ),
            ],
          ),
        ),
        _ => const SafeArea(child: CoraStateView.loading()),
      },
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.conversationId, required this.state});

  final String conversationId;
  final MessageRequestState state;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  @override
  void initState() {
    super.initState();
    // 이미 답한 요청(상대가 먼저 거절했거나 다른 기기에서 열었다)이나 내가 보낸 요청은 11이 할 일이 없다.
    // 그 방의 화면으로 바꿔 연다.
    if (!widget.state.detail.isRequestForMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement(AppRoutes.chat(widget.conversationId));
        }
      });
    }
  }

  Future<void> _open() async {
    final vm = ref.read(
      messageRequestViewModelProvider(widget.conversationId).notifier,
    );
    final outcome = await vm.accept();
    if (!mounted || outcome != RequestOutcome.done) return;
    // 11을 대화방으로 바꿔 연다. 뒤로 가면 목록이다.
    context.pushReplacement(AppRoutes.chat(widget.conversationId));
  }

  Future<void> _decline() async {
    final confirmed = await showDeclineRequestSheet(context);
    if (confirmed != true || !mounted) return;
    final vm = ref.read(
      messageRequestViewModelProvider(widget.conversationId).notifier,
    );
    final outcome = await vm.decline();
    if (!mounted || outcome != RequestOutcome.done) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = widget.state;
    final detail = state.detail;
    final first = state.firstMessage;
    final terms = detail.campaignTerms;
    final now = ref.watch(clockProvider).now();
    final bottomBar = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: _buttonsHeight + 24 + bottomBar),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(detail: detail, onBack: () => context.pop()),
              Transform.translate(
                offset: const Offset(0, -24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(CoraRadius.xl),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (first != null) ...[
                          Text(
                            '“${first.text ?? ''}”',
                            style: CoraTextStyles.bodyLarge.copyWith(
                              fontSize: 22,
                              letterSpacing: -0.66,
                              height: 1.5,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            requestTime(first.at, now),
                            style: CoraTextStyles.meta.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                        if (terms != null) ...[
                          const SizedBox(height: 28),
                          _Summary(terms: terms),
                        ],
                        const SizedBox(height: 24),
                        const _Notice(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.notice != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        state.notice!,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.bodySmall.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: CoraPillButton(
                        label: ChatTexts.decline,
                        onPressed: state.busy ? null : _decline,
                        background: c.surface,
                        foreground: c.text,
                        textStyle: CoraTextStyles.bodyLarge,
                        height: 60,
                      ),
                    ),
                    Expanded(
                      child: CoraPillButton(
                        label: ChatTexts.open,
                        onPressed: state.busy ? null : _open,
                        background: c.accent,
                        foreground: c.onAccent,
                        textStyle: CoraTextStyles.button,
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 아래 버튼 줄의 높이(버튼 60 + 위 여백 12 + 아래 여백 28)에서 스크롤 여백만 뺀 값.
  static const double _buttonsHeight = 60 + 12 + 28;
}

/// 사진(높이 330, 상태 표시줄 아래까지 이어진다): 아래 200에 어두운 덮개, 왼쪽 위 뒤로 가기, 아래에 `메시지 요청`·보낸 사람 이름·캠페인 한 줄.
class _Hero extends StatelessWidget {
  const _Hero({required this.detail, required this.onBack});

  final ConversationDetail detail;
  final VoidCallback onBack;

  static const double height = 330;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: '${detail.counterpartName} 사진',
            child: ExcludeSemantics(
              child: CoraNetworkPhoto(
                url: detail.counterpartPhotoUrl,
                alignment: const Alignment(0.24, 0),
                background: CoraChatTokens.heroPlaceholder,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: CoraChatTokens.heroScrim,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: top + 12,
            child: _HeroBack(onPressed: onBack),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ChatTexts.requestTitle,
                  style: CoraTextStyles.meta.copyWith(
                    color: CoraChatTokens.heroLabel,
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  header: true,
                  child: Text(
                    detail.counterpartName,
                    style: CoraTextStyles.display.copyWith(
                      fontSize: 28,
                      letterSpacing: -1.12,
                      height: 1.448,
                      color: context.colors.onPhoto,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.contextLabel,
                  style: CoraTextStyles.bodySmall.copyWith(
                    color: CoraChatTokens.heroLabel,
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

/// 사진 위의 뒤로 가기: 44 x 44 칸 안에 흰색 `<`(24, 두께 2.4). 원 바탕이 없다.
class _HeroBack extends StatelessWidget {
  const _HeroBack({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: '뒤로',
    onTap: onPressed,
    child: ExcludeSemantics(
      child: CoraPressable(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: CustomPaint(
              size: const Size.square(24),
              painter: _ChevronPainter(context.colors.onPhoto),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 사진이 없는 상태(불러오기 실패)의 뒤로 가기.
class _PlainBack extends StatelessWidget {
  const _PlainBack({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        container: true,
        button: true,
        label: '뒤로',
        onTap: onBack,
        child: ExcludeSemantics(
          child: CoraPressable(
            onTap: onBack,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: CustomPaint(
                  size: const Size.square(24),
                  painter: _ChevronPainter(context.colors.text),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// SVG `M15 5l-7 7 7 7`(viewBox 24, stroke 2.4, round).
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * size.width / 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = size.width / 24;
    final path = Path()
      ..moveTo(15 * s, 5 * s)
      ..lineTo(8 * s, 12 * s)
      ..lineTo(15 * s, 19 * s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// 요약 세 칸(`제작물`·`제작비`·`촬영`): 칸 사이 8, 안쪽 12, 모서리 14, 바탕 `surface`.
class _Summary extends StatelessWidget {
  const _Summary({required this.terms});

  final CampaignTerms terms;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Expanded(
            child: _Cell(
              label: ChatTexts.summaryDeliverable,
              value: requestDeliverable(terms),
            ),
          ),
          Expanded(
            child: _Cell(label: ChatTexts.summaryFee, value: requestFee(terms)),
          ),
          Expanded(
            child: _Cell(
              label: ChatTexts.summaryShooting,
              value: requestShooting(terms),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: '$label $value',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CoraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 안내: 자물쇠 아이콘(18)과 14px 글, 줄 간격 1.6, 색 `textSecondary`.
class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: ExcludeSemantics(
            child: CustomPaint(
              size: const Size.square(18),
              painter: _LockPainter(c.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: Text(
            ChatTexts.requestNotice,
            style: CoraTextStyles.bodySmall.copyWith(
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// SVG `<rect x=5 y=11 width=14 height=10 rx=2>` + `<path M8 11V8a4 4 0 0 1 8 0v3>`(viewBox 24, stroke 2).
class _LockPainter extends CustomPainter {
  const _LockPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5 * s, 11 * s, 14 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      paint,
    );
    final shackle = Path()
      ..moveTo(8 * s, 11 * s)
      ..lineTo(8 * s, 8 * s)
      ..arcToPoint(
        Offset(16 * s, 8 * s),
        radius: Radius.circular(4 * s),
        clockwise: true,
      )
      ..lineTo(16 * s, 11 * s);
    canvas.drawPath(shackle, paint);
  }

  @override
  bool shouldRepaint(_LockPainter old) => old.color != color;
}

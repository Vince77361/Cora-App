import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/id/uuid_v4.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/text/utf16_length_limiting_formatter.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_motion.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../chat/domain/chat_repository.dart';
import '../../../chat/domain/message.dart';
import '../../../chat/presentation/chat_text.dart';
import '../../../chat/presentation/widgets/chat_glyphs.dart';
import '../../domain/match_info.dart';
import '../interests_text.dart';
import '../reward_proposal_entry.dart';
import '../widgets/interest_icons.dart';

/// 시트가 어떻게 닫혔는가. [moved]는 버튼으로 다른 화면(06, 07)에 갔다는 뜻이고, 그 밖에는 내리거나 바깥을
/// 눌러 닫은 것이다.
enum MatchSheetResult { dismissed, moved }

/// 05 서로 관심 확인. 아래에서 올라오는 시트이고 두 프로필 사진이 양쪽에서 들어와 겹친다. 아래로 내리거나
/// 바깥을 눌러 닫는다.
Future<MatchSheetResult> showMatchSheet(
  BuildContext context,
  MatchInfo info,
) async {
  final result = await showModalBottomSheet<MatchSheetResult>(
    context: context,
    isScrollControlled: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    // 캔버스 Pass의 뒤 덮개 rgba(15,16,18,0.45). 두 모드가 같다.
    barrierColor: CoraSwipeTokens.sheetBarrier,
    elevation: 0,
    showDragHandle: false,
    builder: (_) => MatchSheet(info: info),
  );
  return result ?? MatchSheetResult.dismissed;
}

/// 05의 내용(캔버스 Match `section`): 안쪽 위 30·아래 32·좌우 24, 위쪽 모서리 28. 본문 아래에 첫 인사 입력란
/// (`콘텐츠에 대한 첫 인사 남기기`)과 보내기 원이 있다. 원을 누르면 그 방(D3)으로 가고, 글을 쓴 채 `받은 제안
/// 보기`나 `내가 먼저 제안하기`를 눌러도 그 방에 보낸다(이동은 막지 않는다).
class MatchSheet extends ConsumerStatefulWidget {
  const MatchSheet({super.key, required this.info});

  final MatchInfo info;

  @override
  ConsumerState<MatchSheet> createState() => _MatchSheetState();
}

class _MatchSheetState extends ConsumerState<MatchSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this);
  final _greeting = TextEditingController();

  /// 첫 인사를 보낼 때 쓰는 중복 방지 값. 보내기가 실패해 다시 보내도 서버가 새 메시지를 만들지 않는다. 보내고
  /// 나면 다음 글을 위해 새로 만든다.
  String _greetingClientId = uuidV4();
  bool _greetingBusy = false;
  String? _greetingError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.isDismissed) {
      _enter.duration = CoraMotion.resolve(context, CoraMotion.sheetDuration);
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _greeting.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(MatchSheetResult.dismissed);

  /// 입력한 첫 인사를 그 방에 보낸다. 보냈거나 보낼 글(또는 방)이 없으면 true, 보내지 못했으면 false.
  Future<bool> _sendGreeting() async {
    final conversationId = widget.info.conversationId;
    final text = _greeting.text.trim();
    if (conversationId == null || text.isEmpty) return true;
    try {
      await ref
          .read(chatRepositoryProvider)
          .send(
            conversationId,
            clientId: _greetingClientId,
            kind: MessageKind.text,
            text: text,
          );
    } catch (_) {
      return false;
    }
    _greetingClientId = uuidV4();
    if (mounted) _greeting.clear();
    return true;
  }

  /// 보내기 원: 첫 인사를 보내고 그 방(D3)으로 간다. 보내지 못하면 시트에 남아 안내를 보인다.
  Future<void> _greet() async {
    if (_greetingBusy || _greeting.text.trim().isEmpty) return;
    final conversationId = widget.info.conversationId;
    if (conversationId == null) return;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _greetingBusy = true;
      _greetingError = null;
    });
    final ok = await _sendGreeting();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _greetingBusy = false;
        _greetingError = InterestsTexts.greetingFailed;
      });
      return;
    }
    navigator.pop(MatchSheetResult.moved);
    router.push(AppRoutes.chat(conversationId));
  }

  /// 이동 버튼을 연달아 눌러 첫 인사와 화면이 두 번 가지 않게 한다.
  bool _moving = false;

  Future<void> _viewProposals() async {
    if (_moving) return;
    _moving = true;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    // 첫 인사를 보내지 못해도 이동은 막지 않는다(그 방에서 다시 보낼 수 있다).
    await _sendGreeting();
    if (!mounted) return;
    navigator.pop(MatchSheetResult.moved);
    router.push(AppRoutes.collaborationTerms(widget.info.collaborationId));
  }

  /// 제안 흐름이 열려 있는 동안 다시 눌러 자리 화면이 두 번 쌓이지 않게 한다.
  bool _proposing = false;

  Future<void> _proposeFirst() async {
    if (_proposing || _moving) return;
    _proposing = true;
    try {
      await _sendGreeting();
      if (!mounted) return;
      await _proposeFirstOnce();
    } finally {
      _proposing = false;
    }
  }

  Future<void> _proposeFirstOnce() async {
    final info = widget.info;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final sent = await openRewardProposal(
      context,
      AfterMatch(info.collaborationId, info.baseVersion),
    );
    if (sent is! ProposalSent || !mounted) return;
    // 보낸 제안은 그 협업의 07(진행 단계)에서 이어서 본다. 브랜드와 크리에이터가 같은 경로를 쓰고, 목록이나
    // 받은 오퍼 탭이 아니라 이 협업으로 곧바로 간다.
    navigator.pop(MatchSheetResult.moved);
    router.go(AppRoutes.collaborationProgress(info.collaborationId));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final info = widget.info;
    final tagline = info.brandTagline;
    final badge = InterestsTexts.matchBadge(
      tagline == null || tagline.isEmpty ? info.brandName : tagline,
    );
    final bottom =
        math.max(32.0, MediaQuery.viewPaddingOf(context).bottom) +
        MediaQuery.viewInsetsOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 30, 24, bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: _Photos(info: info, animation: _enter),
                ),
                const SizedBox(height: 18),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        badge,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.caption.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  header: true,
                  child: Text(
                    InterestsTexts.matchTitle,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.headline.copyWith(
                      letterSpacing: -1.26,
                      height: 1.448,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      InterestsTexts.matchBody(
                        info.brandName,
                        info.creatorName,
                      ),
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.body.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (info.conversationId != null) ...[
                  _GreetingField(
                    controller: _greeting,
                    busy: _greetingBusy,
                    onChanged: () {
                      if (_greetingError != null) {
                        setState(() => _greetingError = null);
                      }
                    },
                    onSend: _greet,
                  ),
                  if (_greetingError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _greetingError!,
                          style: CoraTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                _PrimaryAction(
                  label: InterestsTexts.viewProposals(info.pendingProposals),
                  onTap: _viewProposals,
                ),
                const SizedBox(height: 4),
                _TextAction(
                  label: InterestsTexts.proposeFirst,
                  onTap: _proposeFirst,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Semantics(
              container: true,
              button: true,
              label: InterestsTexts.close,
              onTap: _close,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: InterestIcon(ClosePainter(c.text), size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 사진 둘(지름 96, 4 고리)이 양쪽에서 들어와 겹치고 가운데 아래에 하트(지름 40)가 뜬다. 왼쪽이 크리에이터,
/// 오른쪽이 브랜드다.
class _Photos extends StatelessWidget {
  const _Photos({required this.info, required this.animation});

  final MatchInfo info;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slide = CurvedAnimation(
      parent: animation,
      curve: CoraMotion.standardCurve,
    );
    final heart = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1, curve: Curves.easeOutBack),
    );
    Widget ring({required Widget child}) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.matchRing, spreadRadius: 4)],
      ),
      child: ClipOval(child: child),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: 168,
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: slide,
                builder: (context, child) => Opacity(
                  opacity: slide.value.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(-(1 - slide.value) * 72, 0),
                    child: child,
                  ),
                ),
                child: ring(
                  child: SizedBox.square(
                    dimension: 96,
                    child: CoraNetworkPhoto(
                      url: info.creatorPhotoUrl,
                      background: c.photoPlaceholder,
                      alignment: const Alignment(0.1, -0.2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: slide,
                builder: (context, child) => Opacity(
                  opacity: slide.value.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset((1 - slide.value) * 72, 0),
                    child: child,
                  ),
                ),
                child: ring(
                  child: SizedBox.square(
                    dimension: 96,
                    child: CoraNetworkPhoto(
                      url: info.brandPhotoUrl,
                      background: c.avatarPlaceholder,
                      alignment: const Alignment(0.24, -0.2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 64,
              bottom: -8,
              child: AnimatedBuilder(
                animation: heart,
                builder: (context, child) => Transform.scale(
                  scale: heart.value.clamp(0, 1.2),
                  child: child,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent,
                    boxShadow: [BoxShadow(color: c.matchRing, spreadRadius: 4)],
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: InterestIcon(
                        HeartFillPainter(c.onAccent),
                        size: 20,
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

/// 첫 인사 입력줄(캔버스 Match): 높이 52, 안쪽 왼쪽 18·오른쪽 6, `surface` 바탕 알약. 입력 14, 오른쪽 라임 원(40)과
/// 화살표(18, 두께 2.4).
class _GreetingField extends StatelessWidget {
  const _GreetingField({
    required this.controller,
    required this.busy,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
      ),
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
                  label: InterestsTexts.greetingLabel,
                  child: TextField(
                    controller: controller,
                    enabled: !busy,
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onSend(),
                    inputFormatters: const [
                      Utf16LengthLimitingFormatter(ChatTexts.messageMax),
                    ],
                    cursorColor: c.text,
                    style: CoraTextStyles.bodySmall.copyWith(color: c.text),
                    decoration: InputDecoration(
                      hintText: InterestsTexts.greetingHint,
                      hintStyle: CoraTextStyles.bodySmall.copyWith(
                        color: c.textSecondary,
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
                label: InterestsTexts.greetingSendLabel,
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
    );
  }
}

/// 높이 56의 라임 알약(16/700).
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  label,
                  style: CoraTextStyles.button.copyWith(color: c.onAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 높이 44의 글자 버튼(14/500, 보조색).
class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: CoraTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

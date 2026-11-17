import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../domain/conversation.dart';
import '../../domain/message.dart';
import '../chat_text.dart';
import '../chat_thread_rows.dart';
import '../viewmodels/chat_thread_view_model.dart';
import '../widgets/attach_sheet.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_glyphs.dart';
import '../widgets/chat_header.dart';
import '../widgets/content_card_bubble.dart';
import '../widgets/message_bubble.dart';
import '../widgets/system_line.dart';
import '../widgets/thread_menu_sheet.dart';

/// D3 대화방(NChatThread / DarkNChatThread). 위에서부터 머리, 조건 요약 상자, 메시지(아래에서부터 쌓이고 위로 끝까지
/// 올리면 이전 50개), 입력 줄이다. 소켓이 새 메시지를 밀어 주고, 끊겼다 붙으면 빠진 번호를 서버에서 받아 메운다.
class ChatThreadPage extends ConsumerStatefulWidget {
  const ChatThreadPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  bool _attachOpen = false;

  ChatThreadViewModel get _vm =>
      ref.read(chatThreadViewModelProvider(widget.conversationId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    // 화면이 앞에 있는 동안만 읽음으로 알린다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.setVisible(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _vm.setVisible(state == AppLifecycleState.resumed);
  }

  /// 위로 끝에 가까워지면 이전 메시지를 더 읽는다(목록이 뒤집혀 있어 맨 위가 `maxScrollExtent`다).
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      _vm.loadOlder();
    }
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openMenu(ChatThreadState state) async {
    setState(() => _attachOpen = false);
    final action = await showThreadMenuSheet(
      context,
      muted: state.detail.muted,
    );
    if (!mounted) return;
    if (action == ThreadMenuAction.toggleMute) {
      await _vm.toggleMute();
    }
  }

  Future<void> _sendContentCard() async {
    setState(() => _attachOpen = false);
    final sent = await _vm.sendContentCard();
    if (sent && mounted) _toBottom();
  }

  void _proposeTerms(ConversationDetail detail) {
    setState(() => _attachOpen = false);
    context.push(AppRoutes.collaborationTermsPropose(detail.collaborationId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatThreadViewModelProvider(widget.conversationId));
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: switch (async) {
        AsyncData(:final value) when value.detail.isRequestForMe =>
          _RedirectToRequest(conversationId: widget.conversationId),
        AsyncData(:final value) => _body(context, value),
        AsyncError() => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlainBack(onBack: () => context.pop()),
              CoraStateView.loadFailed(
                title: ChatTexts.threadLoadFailed,
                onRetry: () => ref.invalidate(
                  chatThreadViewModelProvider(widget.conversationId),
                ),
              ),
            ],
          ),
        ),
        _ => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlainBack(onBack: () => context.pop()),
              const CoraStateView.loading(),
            ],
          ),
        ),
      },
    );
  }

  Widget _body(BuildContext context, ChatThreadState state) {
    final detail = state.detail;
    final closedText = _closedText(detail);
    final canAttach =
        closedText == null &&
        (detail.canSendContentCard || detail.canProposeTerms);
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChatHeader(
                detail: detail,
                onBack: () => context.pop(),
                onMenu: () => _openMenu(state),
              ),
              _terms(context, state),
              const SizedBox(height: 12),
              Expanded(child: _messages(state)),
              // 캔버스는 목록이 입력 줄 위 10에서 끝난다.
              const SizedBox(height: 10),
              ChatComposer(
                closedText: closedText,
                attachOpen: _attachOpen,
                onAttach: canAttach
                    ? () => setState(() => _attachOpen = !_attachOpen)
                    : null,
                notice: state.notice,
                onChanged: _vm.clearNotice,
                onSend: (text) {
                  _vm.send(text);
                  _toBottom();
                },
              ),
            ],
          ),
        ),
        if (_attachOpen) ...[
          // 메뉴 밖을 누르면 닫힌다. 누른 곳의 버튼(머리의 `대화 관리` 등)은 그대로 눌리도록 누름을 막지 않고 듣기만
          // 한다. 더하기 버튼이 있는 입력 줄(아래 92)은 덮지 않아서 그 버튼이 열고 닫는다.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 92,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => setState(() => _attachOpen = false),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 92,
            child: AttachMenu(
              onContentCard: detail.canSendContentCard
                  ? _sendContentCard
                  : null,
              onProposeTerms: detail.canProposeTerms
                  ? () => _proposeTerms(detail)
                  : null,
            ),
          ),
        ],
      ],
    );
  }

  /// 머리 아래 조건 요약 상자. 조건이 없는 방(아직 판본이 없는 협업)은 상자가 없다.
  Widget _terms(BuildContext context, ChatThreadState state) {
    final d = state.detail;
    final inquiry = d.stage == ConversationStage.inquiry;
    final String? summary;
    if (inquiry && d.campaignTerms != null) {
      summary = campaignSummary(d.campaignTerms!);
    } else if (d.terms != null) {
      summary = termsSummary(d.terms!);
    } else if (d.storeTerms != null) {
      summary = storeHeaderLine(d.storeTerms!);
    } else {
      summary = null;
    }
    if (summary == null) return const SizedBox.shrink();
    return ChatTermsBar(
      summary: summary,
      status: statusLine(d),
      // 조건 합의(12)는 조건 판본이 있는 브랜드 계약만 연다. 가게 오퍼의 판본 주고받기는 대화방이 열리기 전에 끝난다.
      onTap: !inquiry && d.terms != null
          ? () => context.push(
              AppRoutes.collaborationAgreement(d.collaborationId),
            )
          : null,
      onLike: d.canLikeCampaign ? _vm.likeCampaign : null,
      likeEnabled: !state.liking && !state.likeSent,
      likeLabel: state.likeSent ? ChatTexts.likeSent : ChatTexts.likeCampaign,
    );
  }

  Widget _messages(ChatThreadState state) {
    if (state.isEmpty) {
      return Center(
        child: Text(
          ChatTexts.emptyRoom,
          style: CoraTextStyles.bodySmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      );
    }
    // 목록을 뒤집어 맨 아래(최신)에 붙여 둔다. 그래서 가장 새 줄이 0번이다.
    final items = threadRows(state.messages, state.pending).reversed.toList();
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final row = items[index];
        // 줄 사이 간격 10. 가장 오래된 줄(맨 위) 위에는 두지 않는다.
        final top = index == items.length - 1 ? 0.0 : 10.0;
        return Padding(
          key: ValueKey(switch (row) {
            DayRow(:final at) => 'day-${at.millisecondsSinceEpoch}',
            MessageRow(:final message) => message.clientId,
          }),
          padding: EdgeInsets.only(top: top),
          child: switch (row) {
            DayRow(:final at) => DayDivider(text: dayDivider(at)),
            MessageRow(:final message) => _message(message),
          },
        );
      },
    );
  }

  Widget _message(ChatMessage m) => switch (m.kind) {
    MessageKind.system => SystemLine(text: m.text ?? ''),
    MessageKind.contentCard => ContentCardBubble(message: m),
    MessageKind.text => MessageBubble(
      message: m,
      onRetry: () => _vm.retry(m.clientId),
    ),
  };

  /// 입력란 자리에 대신 놓일 안내. 글을 보낼 수 있으면 null이다.
  String? _closedText(ConversationDetail d) {
    if (d.blockedByMe) return ChatTexts.composerBlocked;
    return switch (d.status) {
      ConversationStatus.open => null,
      ConversationStatus.requested =>
        d.requestedByMe ? ChatTexts.composerWaiting : null,
      ConversationStatus.declined => ChatTexts.notOpened,
      ConversationStatus.closed => ChatTexts.closed,
    };
  }
}

/// 내가 답해야 하는 메시지 요청 방은 11이 연다(알림이 방 번호로 열어도 요청이면 11로 바꾼다).
class _RedirectToRequest extends StatefulWidget {
  const _RedirectToRequest({required this.conversationId});

  final String conversationId;

  @override
  State<_RedirectToRequest> createState() => _RedirectToRequestState();
}

class _RedirectToRequestState extends State<_RedirectToRequest> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pushReplacement(AppRoutes.chatRequest(widget.conversationId));
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      const SafeArea(child: CoraStateView.loading());
}

/// 대화방을 읽는 동안과 읽지 못했을 때의 뒤로 가기(머리가 없어서 글자색 `text`의 `<`만 있다).
class _PlainBack extends StatelessWidget {
  const _PlainBack({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ChatIconButton(
        label: ChatTexts.back,
        onTap: onBack,
        child: ChatGlyphIcon(
          ChatGlyph.chevronBack,
          size: 24,
          color: context.colors.text,
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/message.dart';
import '../chat_text.dart';

/// 글 말풍선. 내 것은 오른쪽 `myBubble`, 상대 것은 왼쪽 `surface`다. 말풍선은 글 폭이 270에 닿으면 줄을 바꾼다
/// (캔버스 `max-width: 270px`에 안쪽 여백 14가 더해진 폭). 보내는 중이면 흐리게, 실패하면 아래에
/// `보내지 못했어요` / `다시 보내기`를 보인다.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.onRetry});

  final ChatMessage message;

  /// 실패한 말풍선의 `다시 보내기`.
  final VoidCallback? onRetry;

  static const double textMaxWidth = 270;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.mine;
    final sending = message.state == SendState.sending;
    final failed = message.state == SendState.failed;
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: textMaxWidth + 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: mine ? c.myBubble : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            message.text ?? '',
            style: CoraTextStyles.bodyLarge.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: mine ? c.onMyBubble : c.text,
            ),
          ),
        ),
      ),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label: mine ? '내 메시지 ${message.text}' : '${message.text}',
            child: ExcludeSemantics(
              child: Opacity(opacity: sending ? 0.6 : 1, child: bubble),
            ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _FailedNote(onRetry: onRetry),
            ),
        ],
      ),
    );
  }
}

/// 실패한 말풍선 아래 줄(캔버스에 없는 모양): 12px 글자 `보내지 못했어요`와 누를 수 있는 `다시 보내기`.
class _FailedNote extends StatelessWidget {
  const _FailedNote({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ChatTexts.sendFailed,
          style: CoraTextStyles.caption.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          container: true,
          button: true,
          label: ChatTexts.resend,
          onTap: onRetry,
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: onRetry,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    ChatTexts.resend,
                    style: CoraTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: c.text,
                      color: c.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

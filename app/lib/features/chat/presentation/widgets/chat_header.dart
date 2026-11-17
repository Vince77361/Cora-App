import 'package:flutter/material.dart';

import '../../../../core/theme/cora_chat_tokens.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/conversation.dart';
import '../chat_text.dart';
import 'chat_glyphs.dart';

/// 대화방 머리 한 줄(캔버스 D3): 뒤로 가기, 상대 사진(원 40), 이름과 캠페인 한 줄, 오른쪽 `대화 관리`(점 셋).
/// 높이 64, 좌우 8, 칸 사이 8.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.detail,
    required this.onBack,
    required this.onMenu,
  });

  final ConversationDetail detail;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          spacing: 8,
          children: [
            ChatIconButton(
              label: ChatTexts.back,
              onTap: onBack,
              child: ChatGlyphIcon(
                ChatGlyph.chevronBack,
                size: 24,
                color: c.text,
              ),
            ),
            ExcludeSemantics(
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 40,
                  child: CoraNetworkPhoto(
                    url: detail.counterpartPhotoUrl,
                    alignment: const Alignment(0.24, -0.2),
                    background: CoraChatTokens.heroPlaceholder,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                container: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detail.counterpartName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    Text(
                      detail.contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CoraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ChatIconButton(
              label: ChatTexts.manage,
              onTap: onMenu,
              child: ChatGlyphIcon(
                ChatGlyph.dots,
                size: 22,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44 x 44 칸 안에 그림 하나가 있는 아이콘 버튼.
class ChatIconButton extends StatelessWidget {
  const ChatIconButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: CoraPressable(
        onTap: onTap,
        child: SizedBox.square(dimension: 44, child: Center(child: child)),
      ),
    ),
  );
}

/// 머리 아래의 조건 요약 상자(캔버스 D3): 좌우 16, 안쪽 12·16, 모서리 18, `surface`. 그림 하나, 두 줄(조건 요약과
/// 상태), 오른쪽 `>`. [onTap]이 있으면 눌러 조건 합의(12)를 연다. 서로 관심 전에 크리에이터가 [onLike]를 주면
/// `>` 자리에 `관심 보내기` 알약이 선다.
class ChatTermsBar extends StatelessWidget {
  const ChatTermsBar({
    super.key,
    required this.summary,
    this.status,
    this.onTap,
    this.onLike,
    this.likeEnabled = true,
    this.likeLabel = ChatTexts.likeCampaign,
  });

  final String summary;
  final String? status;
  final VoidCallback? onTap;

  /// 서로 관심 전, 크리에이터에게만. null이면 알약이 없다.
  final VoidCallback? onLike;

  /// false이면 알약이 흐려져 누를 수 없다(보내는 중이거나 이미 보냈다).
  final bool likeEnabled;
  final String likeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lines = status == null ? summary : '$summary\n$status';
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 10,
          children: [
            ChatGlyphIcon(ChatGlyph.pin, size: 16, color: c.onAccent),
            Expanded(
              child: Text(
                lines,
                style: CoraTextStyles.label.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: c.text,
                ),
              ),
            ),
            if (onLike != null)
              _LikePill(label: likeLabel, onTap: likeEnabled ? onLike : null)
            else if (onTap != null)
              ChatGlyphIcon(
                ChatGlyph.chevronForward,
                size: 16,
                color: c.onAccent,
              ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // 알약이 있으면 안쪽 버튼이 자기 의미를 가지므로 상자 전체를 하나로 묶지 않는다.
      child: onLike != null
          ? body
          : onTap == null
          ? Semantics(
              container: true,
              label: lines.replaceAll('\n', ', '),
              child: ExcludeSemantics(child: body),
            )
          : Semantics(
              container: true,
              button: true,
              label: lines.replaceAll('\n', ', '),
              onTap: onTap,
              child: ExcludeSemantics(
                child: CoraPressable(onTap: onTap, child: body),
              ),
            ),
    );
  }
}

/// `관심 보내기` 알약(캔버스에 없는 모양): 라임 바탕, 13px 700. 보낸 뒤에는 `onTap`이 null이라 흐려진다.
class _LikePill extends StatelessWidget {
  const _LikePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  style: CoraTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.onAccent,
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

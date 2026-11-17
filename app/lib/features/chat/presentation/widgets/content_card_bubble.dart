import 'package:flutter/material.dart';

import '../../../../core/theme/cora_chat_tokens.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../domain/message.dart';
import '../chat_text.dart';

/// 콘텐츠 카드 메시지(캔버스 D3): 폭 220, 모서리 20, `surface` 바탕, 위에 높이 120의 사진, 아래에 `콘텐츠 카드`
/// 라벨과 제목. 내 것은 오른쪽, 상대 것은 왼쪽에 놓는다.
class ContentCardBubble extends StatelessWidget {
  const ContentCardBubble({super.key, required this.message});

  final ChatMessage message;

  static const double width = 220;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = message.card;
    final title = card?.title ?? '';
    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        container: true,
        label: '${ChatTexts.contentCard} $title',
        child: ExcludeSemantics(
          child: SizedBox(
            width: width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 120,
                      child: CoraNetworkPhoto(
                        url: card?.photoUrl,
                        alignment: const Alignment(-0.2, -0.2),
                        background: CoraChatTokens.cardPhotoPlaceholder,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ChatTexts.contentCard,
                            style: CoraTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: CoraTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

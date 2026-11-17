import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_received_proposal_tokens.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/received_proposal.dart';
import '../received_proposals_text.dart';

/// 03 맨 위 `받은 제안 {n}` 묶음(크리에이터, 받은 제안이 있을 때). 캔버스에 없는 모양이라 기존 토큰으로 최소로
/// 만들었다: 머리 글 한 줄과, 옆으로 넘기는 카드(브랜드 사진, 이름, `내 콘텐츠 「…」에 제안했어요`).
class ReceivedProposalsGroup extends StatelessWidget {
  const ReceivedProposalsGroup({
    super.key,
    required this.proposals,
    required this.onOpen,
  });

  final List<ReceivedProposal> proposals;
  final ValueChanged<ReceivedProposal> onOpen;

  /// 카드 한 장의 높이와 폭.
  static const double cardHeight = 72;
  static const double cardWidth = 280;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Semantics(
            header: true,
            child: Text(
              ReceivedProposalsTexts.group(proposals.length),
              style: CoraTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: proposals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _ProposalCard(
              proposal: proposals[i],
              onTap: () => onOpen(proposals[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal, required this.onTap});

  final ReceivedProposal proposal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final proposedOn = ReceivedProposalsTexts.proposedOn(proposal);
    final lines = ReceivedProposalsTexts.proposedOnLines(proposal);
    return Semantics(
      container: true,
      button: true,
      label: '${proposal.brandName}, $proposedOn',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox(
            width: ReceivedProposalsGroup.cardWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(CoraRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  spacing: 12,
                  children: [
                    ClipOval(
                      child: SizedBox.square(
                        dimension: 44,
                        child: CoraNetworkPhoto(
                          url: proposal.brandPhotoUrl,
                          alignment: const Alignment(0.24, -0.2),
                          background:
                              CoraReceivedProposalTokens.avatarPlaceholder,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proposal.brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CoraTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          for (final line in [lines.head, ?lines.tail])
                            Text(
                              line,
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

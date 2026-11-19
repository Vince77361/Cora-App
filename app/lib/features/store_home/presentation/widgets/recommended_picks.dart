import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_store_home_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../applicant_picks/domain/applicant_pick.dart';
import '../store_home_text.dart';

/// 홈의 `추천 3명`(캔버스 M19G4 `<section>`): 제목 15/700, 안내 12, 세 칸 격자(칸 사이 8). 칸은 높이 176의
/// 사진(없으면 이름 첫 글자), 이름, 설명 두 줄, `제안하기`다. 지원자 중에서 뽑았을 때([applied])만 사진 위에
/// `지원` 표지가 붙는다.
class RecommendedPicks extends StatelessWidget {
  const RecommendedPicks({
    super.key,
    required this.picks,
    required this.intro,
    required this.applied,
    required this.now,
    required this.onOffer,
  });

  final List<ApplicantPick> picks;

  /// 제목 아래 안내 문장.
  final String intro;
  final bool applied;
  final DateTime now;
  final ValueChanged<ApplicantPick> onOffer;

  static const title = '추천 3명';
  static const appliedChip = '지원';
  static const offer = '제안하기';

  static const double photoHeight = 176;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: CoraTextStyles.stateTitle.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          intro,
          style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        // 설명이 한 줄인 칸과 두 줄인 칸의 `제안하기`가 같은 높이에 놓이도록 가장 큰 칸에 맞춘다.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: i < picks.length
                      ? _PickCell(
                          pick: picks[i],
                          index: i,
                          applied: applied,
                          now: now,
                          onOffer: () => onOffer(picks[i]),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickCell extends StatelessWidget {
  const _PickCell({
    required this.pick,
    required this.index,
    required this.applied,
    required this.now,
    required this.onOffer,
  });

  final ApplicantPick pick;
  final int index;
  final bool applied;
  final DateTime now;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final creator = pick.creator;
    final description = pickDescription(
      contentFocus: creator.contentFocus,
      appliedAt: pick.appliedAt,
      followers: creator.followers,
      now: now,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: RecommendedPicks.photoHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CoraRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Cover(
                  photoUrl: creator.photoUrl,
                  name: creator.displayName,
                  index: index,
                ),
                if (applied)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.photoChip,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          RecommendedPicks.appliedChip,
                          style: CoraTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: c.onPhotoChip,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          creator.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CoraTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: c.text,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: description.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.fieldLabel.copyWith(
                      fontSize: 11,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          button: true,
          label: '${creator.displayName} ${RecommendedPicks.offer}',
          onTap: onOffer,
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: onOffer,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.highlightAction,
                  borderRadius: BorderRadius.circular(CoraRadius.pill),
                ),
                child: SizedBox(
                  height: 34,
                  child: Center(
                    child: Text(
                      RecommendedPicks.offer,
                      maxLines: 1,
                      style: CoraTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.onHighlightAction,
                      ),
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

/// 사진이 있으면 사진(`object-position: 50% 30%`), 없으면 두 톤을 번갈아 쓰는 그라데이션과 이름 첫 글자.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.photoUrl,
    required this.name,
    required this.index,
  });

  final String? photoUrl;
  final String name;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    if (hasPhoto) {
      return CoraNetworkPhoto(
        url: photoUrl,
        alignment: const Alignment(0, -0.4),
        background: c.creatorPhotoPlaceholder,
      );
    }
    final tones = CoraStoreHomeTokens.avatarTones;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tones[index.isOdd ? 0 : 1]),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: ExcludeSemantics(
            child: Text(
              name.isEmpty ? '' : String.fromCharCodes(name.runes.take(1)),
              style: CoraTextStyles.listLabel.copyWith(
                fontSize: 44,
                fontWeight: FontWeight.w500,
                color: CoraStoreHomeTokens.avatarInitial,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

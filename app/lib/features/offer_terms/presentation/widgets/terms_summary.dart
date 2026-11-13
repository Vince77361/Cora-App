import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 받는 사람 카드(캔버스 NReviewSend 첫 상자): 모서리 22, `surface` 바탕, 안쪽 14, 사진 52 원 + 라벨 12 /
/// 이름 16/700. 캔버스 오른쪽의 고른 작품 사진은 쓸 자료가 없어 그리지 않는다. F2와 제안 상세가 함께 쓴다.
class TermsRecipientCard extends StatelessWidget {
  const TermsRecipientCard({
    super.key,
    required this.label,
    required this.name,
    required this.photoUrl,
  });

  final String label;
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.panel),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: 12,
            children: [
              ExcludeSemantics(
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: 52,
                    child: CoraNetworkPhoto(
                      url: photoUrl,
                      alignment: const Alignment(0, -0.5),
                      background: c.creatorPhotoPlaceholder,
                    ),
                  ),
                ),
              ),
              Expanded(
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
                    Text(
                      name,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
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
    );
  }
}

/// 조건 상자의 줄 하나. [changed]이면 이름 옆에 `바뀜` 표지가 붙는다(제안 상세가 앞 판본과 다른 줄에 쓴다).
class TermsRow {
  const TermsRow({
    required this.label,
    required this.value,
    this.onTap,
    this.bold = false,
    this.changed = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool bold;
  final bool changed;

  static const changedLabel = '바뀜';
}

/// 조건 상자(캔버스 NReviewSend `<dl>`): 모서리 22, `surface` 바탕, 좌우 16, 위 4·아래 6. 줄 사이에 1px `line`.
class TermsRowsCard extends StatelessWidget {
  const TermsRowsCard({super.key, required this.rows});

  final List<TermsRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              _TermsRowView(row: rows[i], first: i == 0),
          ],
        ),
      ),
    );
  }
}

/// 줄 하나: 위아래 10, 첫 줄 말고는 위에 1px `line`. 왼쪽 13 보조색, 오른쪽 15/500(마지막 줄 700).
class _TermsRowView extends StatelessWidget {
  const _TermsRowView({required this.row, required this.first});

  final TermsRow row;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 6,
              children: [
                Text(
                  row.label,
                  style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                ),
                if (row.changed) const _ChangedMark(),
              ],
            ),
            Flexible(
              child: Text(
                row.value,
                textAlign: TextAlign.right,
                style: CoraTextStyles.body.copyWith(
                  height: 1.448,
                  fontWeight: row.bold ? FontWeight.w700 : FontWeight.w500,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final onTap = row.onTap;
    return Semantics(
      container: true,
      button: onTap != null,
      label: row.changed
          ? '${row.label}, ${row.value}, ${TermsRow.changedLabel}'
          : '${row.label}, ${row.value}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: onTap == null
            ? content
            : CoraPressable(onTap: onTap, child: content),
      ),
    );
  }
}

/// `바뀜` 표지(캔버스 밖): 라임 알약, 11/500.
class _ChangedMark extends StatelessWidget {
  const _ChangedMark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          TermsRow.changedLabel,
          style: CoraTextStyles.caption.copyWith(
            fontSize: 11,
            color: c.onAccent,
          ),
        ),
      ),
    );
  }
}

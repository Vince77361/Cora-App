import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/conversation.dart';
import '../chat_text.dart';

/// 대화 목록의 한 줄(캔버스에 없는 화면이라 기존 목록 줄 `CoraListRow`의 크기와 토큰을 따른다): 지름 46 사진,
/// 이름과 `{캠페인 한 줄 또는 가게 이름}` 꼬리, 마지막 메시지, 오른쪽에 시각과 안 읽은 수. 알림을 끈 방은 이름
/// 옆에 종 꺼짐 아이콘이 붙는다.
class ConversationRow extends StatelessWidget {
  const ConversationRow({
    super.key,
    required this.row,
    required this.now,
    required this.onTap,
  });

  final ConversationSummary row;
  final DateTime now;
  final VoidCallback onTap;

  static const double photoSize = 46;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = row.lastMessage;
    final message = rowMessage(row);
    final unread = row.unreadCount;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      label: [
        row.counterpartName,
        row.contextLabel,
        message,
        if (row.muted) ChatTexts.mutedLabel,
        if (unread > 0) '안 읽은 메시지 $unread개',
      ].join(', '),
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _Avatar(row: row),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: row.counterpartName,
                                    style: CoraTextStyles.buttonMedium.copyWith(
                                      color: c.text,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ${row.contextLabel}',
                                    style: CoraTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (row.muted) ...[
                            const SizedBox(width: 6),
                            CustomPaint(
                              key: ValueKey('muted-${row.id}'),
                              size: const Size.square(14),
                              painter: _BellOffPainter(c.textSecondary),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CoraTextStyles.bodySmall.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    if (last != null)
                      Text(
                        listTime(last.at, now),
                        style: CoraTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    if (unread > 0) _UnreadBadge(count: unread),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.row});

  final ConversationSummary row;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = row.counterpartPhotoUrl;
    final name = row.counterpartName;
    return SizedBox.square(
      dimension: ConversationRow.photoSize,
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CoraNetworkPhoto(url: url)
            : ColoredBox(
                color: c.surface,
                child: Center(
                  child: Text(
                    name.isEmpty
                        ? ''
                        : String.fromCharCodes(name.runes.take(1)),
                    style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                  ),
                ),
              ),
      ),
    );
  }
}

/// 안 읽은 수. 0이면 부르는 쪽이 그리지 않는다.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            widthFactor: 1,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: CoraTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: c.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 종 꺼짐 아이콘(24 칸에 그린 선 그림을 14로 줄인다): 종 모양과 왼쪽 위에서 오른쪽 아래로 가는 사선.
class _BellOffPainter extends CustomPainter {
  const _BellOffPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bell = Path()
      ..moveTo(6, 16)
      ..lineTo(6, 11)
      ..arcToPoint(const Offset(18, 11), radius: const Radius.circular(6))
      ..lineTo(18, 16)
      ..lineTo(20, 18)
      ..lineTo(4, 18)
      ..close();
    canvas.drawPath(bell, paint);
    canvas.drawLine(const Offset(4, 4), const Offset(20, 20), paint);
  }

  @override
  bool shouldRepaint(_BellOffPainter old) => old.color != color;
}

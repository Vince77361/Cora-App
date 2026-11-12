import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 불러오는 중, 모두 봄, 불러오기 실패, 빈 목록, 이전 판본의 다섯 상태(캔버스 F8
/// `빈 상태·오류 패턴`). 화면마다 따로 그리던 빈 화면과 오류 문구를 이 카드 하나로 모은다.
enum CoraStateKind { loading, allSeen, loadFailed, empty, staleVersion }

/// F8 상태 카드. 좌우 16 여백을 가지고 위쪽에 붙어 자란다(캔버스가 카드를 머리 바로 아래
/// 16 여백으로 쌓는다). 세로로는 줄 안에서 가운데로 모으지 않는다.
///
/// 불러오는 중은 회색 막대 두 줄과 `불러오는 중`이고, 나머지는 왼쪽 원 안의 그림, 제목,
/// 설명, 작은 단추다. 오류와 불러오는 중은 화면이 바뀌지 않아도 스크린 리더가 바로 읽게
/// `liveRegion`으로 둔다. 이전 판본도 수락이 막힌 결과라 같은 이유로 `liveRegion`이다.
class CoraStateView extends StatelessWidget {
  const CoraStateView({
    super.key,
    required this.kind,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together',
       );

  /// F8 `불러오는 중`.
  const CoraStateView.loading({super.key, this.title = '불러오는 중'})
    : kind = CoraStateKind.loading,
      description = null,
      actionLabel = null,
      onAction = null;

  /// F8 `영상을 불러오지 못했어요`. 화면마다 [title]을 그 화면의 말로 바꿔 쓴다.
  const CoraStateView.loadFailed({
    super.key,
    this.title = '영상을 불러오지 못했어요',
    this.description = '연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.',
    required VoidCallback onRetry,
  }) : kind = CoraStateKind.loadFailed,
       actionLabel = retryLabel,
       onAction = onRetry;

  /// 빈 목록. 단추는 [actionLabel]과 [onAction]을 함께 줄 때만 나온다.
  const CoraStateView.empty({
    super.key,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  }) : kind = CoraStateKind.empty,
       assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together',
       );

  /// F8 `오늘 추천을 모두 봤어요`(4번 계획이 쓴다).
  const CoraStateView.allSeen({super.key, required VoidCallback onOpenSaved})
    : kind = CoraStateKind.allSeen,
      title = '오늘 추천을 모두 봤어요',
      description = '관심과 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.',
      actionLabel = '저장한 후보 보기',
      onAction = onOpenSaved;

  /// F8 `이전 판본이라 수락할 수 없어요`. [version]은 상대가 보낸 최신 판본 번호다.
  const CoraStateView.staleVersion({
    super.key,
    required int version,
    required VoidCallback onOpen,
  }) : kind = CoraStateKind.staleVersion,
       title = '이전 판본이라 수락할 수 없어요',
       description = '상대가 판본 $version을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.',
       actionLabel = '판본 $version 보기',
       onAction = onOpen;

  final CoraStateKind kind;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const retryLabel = '다시 시도';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: kind == CoraStateKind.loading
            ? _LoadingCard(label: title)
            : _MessageCard(
                kind: kind,
                title: title,
                description: description,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
      ),
    );
  }
}

/// 불러오는 중 카드. 안쪽 16, 둥근 24, 사진 자리 56(둥근 16)과 막대 두 줄(70%·45%).
class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 12,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(CoraRadius.md),
                  ),
                  child: const SizedBox(width: 56, height: 56),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      _Bar(factor: 0.7, height: 12, color: c.line),
                      _Bar(factor: 0.45, height: 10, color: c.line),
                    ],
                  ),
                ),
                Text(
                  label,
                  style: CoraTextStyles.stateLoading.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.factor, required this.height, required this.color});

  final double factor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: factor,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

/// 그림 원 + 제목 + 설명 + 작은 단추 카드. 안쪽 위아래 14·좌우 16, 둥근 22.
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.kind,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final CoraStateKind kind;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final live =
        kind == CoraStateKind.loadFailed || kind == CoraStateKind.staleVersion;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CoraTextStyles.stateTitle.copyWith(color: c.text)),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              description!,
              style: CoraTextStyles.stateDescription.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            ExcludeSemantics(child: _IconCircle(kind: kind)),
            Expanded(
              child: Column(
                // 세로로 늘어나지 않고 글자 높이만큼만 차지한다(Row가 위쪽 높이를 느슨하게 준다).
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 오류는 화면이 바뀌지 않아도 스크린 리더가 바로 읽게 한다.
                  live
                      ? Semantics(
                          container: true,
                          liveRegion: true,
                          child: text,
                        )
                      : text,
                  if (actionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _ActionChip(label: actionLabel!, onTap: onAction!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 40 크기 원. 라이트는 흰색, 다크는 `background`(#0F1012)라 `background` 토큰이다.
class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.kind});

  final CoraStateKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.background, shape: BoxShape.circle),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: CustomPaint(
            size: const Size(20, 20),
            painter: _IconPainter(kind: kind, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// 캔버스의 SVG(24 칸, 선 2, 둥근 끝)를 20 크기로 줄여 그린다.
class _IconPainter extends CustomPainter {
  const _IconPainter({required this.kind, required this.color});

  final CoraStateKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const r4 = Radius.circular(4);
    const r2 = Radius.circular(2);
    switch (kind) {
      case CoraStateKind.allSeen:
        // 하트
        final path = Path()
          ..moveTo(12, 21)
          ..cubicTo(12, 21, 5, 16.6, 5, 11)
          ..arcToPoint(const Offset(12, 8.4), radius: r4)
          ..arcToPoint(const Offset(19, 10), radius: r4)
          ..cubicTo(19, 15.6, 12, 20, 12, 20)
          ..close();
        canvas.drawPath(path, paint);
      case CoraStateKind.loadFailed:
        // 사진 틀
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 5, 18, 14),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3, 15)
            ..lineTo(8, 10)
            ..lineTo(12, 14)
            ..lineTo(15, 11)
            ..lineTo(21, 17),
          paint,
        );
      case CoraStateKind.empty:
        // 말풍선
        canvas.drawPath(
          Path()
            ..moveTo(4, 5)
            ..lineTo(20, 5)
            ..lineTo(20, 16)
            ..lineTo(10, 16)
            ..lineTo(4, 20)
            ..close(),
          paint,
        );
      case CoraStateKind.staleVersion:
        // 느낌표 든 삼각형
        canvas.drawPath(
          Path()
            ..moveTo(12, 8)
            ..lineTo(12, 13)
            ..moveTo(12, 16.5)
            ..lineTo(12, 17),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10.3, 3.9)
            ..lineTo(2.6, 17.5)
            ..arcToPoint(const Offset(4.3, 20.5), radius: r2, clockwise: false)
            ..lineTo(19.7, 20.5)
            ..arcToPoint(const Offset(21.4, 17.5), radius: r2, clockwise: false)
            ..lineTo(13.7, 3.9)
            ..arcToPoint(const Offset(10.3, 3.9), radius: r2, clockwise: false)
            ..close(),
          paint,
        );
      case CoraStateKind.loading:
        break;
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.kind != kind || old.color != color;
}

/// 카드 안의 작은 알약 단추. 높이 36, 좌우 14, 13px 500. 흰 바탕에 #17181C 글자(라이트·다크 같음).
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 캔버스의 `width: max-content`처럼 글자 너비만큼만 차지해 왼쪽에 붙는다.
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        container: true,
        button: true,
        enabled: true,
        onTap: onTap,
        child: CoraPressable(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.chipAction,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            // `alignment`를 주면 Container가 가로로 늘어난다. 글자 너비만큼만 두고 세로로만 가운데에 둔다.
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: CoraTextStyles.label.copyWith(color: c.onChipAction),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

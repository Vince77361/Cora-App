import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shadows.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 하단 메뉴의 한 항목. 캔버스의 아이콘은 SVG 선 그림이라 Material 아이콘과 모양이 다르다.
/// 캔버스와 같은 모양이 필요하면 [iconPainter]로 그린다(`CoraNavItems.store`가 그렇게 쓴다).
@immutable
class CoraNavItem {
  const CoraNavItem({
    required this.icon,
    required this.label,
    this.iconPainter,
  });

  final IconData icon;
  final String label;

  /// 주면 [icon] 대신 이 색으로 22 x 22에 그린다.
  final CustomPainter Function(Color color)? iconPainter;
}

/// 캔버스 NStoreHome의 하단 메뉴 항목 다섯 개(홈, 찾기, 대화, 오퍼, AI 글).
abstract final class CoraNavItems {
  static const store = [
    CoraNavItem(
      icon: Icons.home_outlined,
      label: '홈',
      iconPainter: _HomePainter.new,
    ),
    CoraNavItem(
      icon: Icons.movie_outlined,
      label: '찾기',
      iconPainter: _FindPainter.new,
    ),
    CoraNavItem(
      icon: Icons.chat_bubble_outline,
      label: '대화',
      iconPainter: _ChatPainter.new,
    ),
    CoraNavItem(icon: Icons.add, label: '오퍼', iconPainter: _OfferPainter.new),
    CoraNavItem(
      icon: Icons.auto_awesome_outlined,
      label: 'AI 글',
      iconPainter: _SparklePainter.new,
    ),
  ];
}

/// 화면 아래에 떠 있는 알약 모양 메뉴(캔버스 NStoreHome `<nav>`). 높이 64, 모서리 32,
/// 좌우 16·아래 20 띄움. 위젯 자체가 그 여백을 갖고 있으니 화면 맨 아래에 그대로 둔다
/// (캔버스의 20은 화면 맨 아래에서 잰 값이라 안전 영역을 더하지 않는다).
class CoraBottomNav extends StatelessWidget {
  const CoraBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<CoraNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double height = 64;
  static const double radius = 32;
  static const EdgeInsets margin = EdgeInsets.fromLTRB(16, 0, 16, 20);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: margin,
      child: Semantics(
        container: true,
        label: '주요 메뉴',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.navSurface,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: CoraShadows.bottomNav(c.navShadow),
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 좁은 화면(글자 크게 보기 + 작은 휴대폰)에서는 항목이 58보다 좁아진다.
                  for (final (i, item) in items.indexed)
                    Flexible(
                      child: _NavButton(
                        item: item,
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CoraNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.navActive : c.navInactive;
    final painter = item.iconPainter;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (painter != null)
                  CustomPaint(
                    size: const Size.square(22),
                    painter: painter(color),
                  )
                else
                  Icon(item.icon, size: 22, color: color),
                const SizedBox(height: 3),
                // 글자가 커져도 칸(58 x 52)을 넘지 않게 한 줄로 줄인다.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: CoraTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: color,
                    ),
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

/// SVG 아이콘 공통: viewBox 24를 22로 줄여 stroke 2로 그린다.
abstract class _NavIconPainter extends CustomPainter {
  const _NavIconPainter(this.color);

  final Color color;

  StrokeCap get cap => StrokeCap.butt;

  void draw(Canvas canvas, Paint paint);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round;
    draw(canvas, paint);
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter old) => old.color != color;
}

/// `M4 10l8-6 8 6v10H4z`
class _HomePainter extends _NavIconPainter {
  const _HomePainter(super.color);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(4, 10)
        ..lineTo(12, 4)
        ..lineTo(20, 10)
        ..lineTo(20, 20)
        ..lineTo(4, 20)
        ..close(),
      paint,
    );
  }
}

/// `<rect x=6 y=3 width=12 height=17 rx=3>` + `M3 7v10M21 7v10`
class _FindPainter extends _NavIconPainter {
  const _FindPainter(super.color);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromLTRBR(6, 3, 18, 20, const Radius.circular(3)),
      paint,
    );
    canvas.drawLine(const Offset(3, 7), const Offset(3, 17), paint);
    canvas.drawLine(const Offset(21, 7), const Offset(21, 17), paint);
  }
}

/// `M4 5h16v11H10l-6 4z`
class _ChatPainter extends _NavIconPainter {
  const _ChatPainter(super.color);

  @override
  void draw(Canvas canvas, Paint paint) {
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
  }
}

/// `M12 5v14M5 12h14`(끝이 둥글다)
class _OfferPainter extends _NavIconPainter {
  const _OfferPainter(super.color);

  @override
  StrokeCap get cap => StrokeCap.round;

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(12, 5), const Offset(12, 19), paint);
    canvas.drawLine(const Offset(5, 12), const Offset(19, 12), paint);
  }
}

/// `M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z`
class _SparklePainter extends _NavIconPainter {
  const _SparklePainter(super.color);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(12, 3)
        ..lineTo(14, 8)
        ..lineTo(19, 10)
        ..lineTo(14, 12)
        ..lineTo(12, 17)
        ..lineTo(10, 12)
        ..lineTo(5, 10)
        ..lineTo(10, 8)
        ..close(),
      paint,
    );
  }
}

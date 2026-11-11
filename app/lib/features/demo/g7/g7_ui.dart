import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g7(알림·설정·정산·고객센터) 화면이 함께 쓰는 색과 머리글. 라이트/다크 값은 artifact 그대로다.
class G7Colors {
  const G7Colors._(this.dark);

  factory G7Colors.of(BuildContext context) =>
      G7Colors._(Theme.of(context).brightness == Brightness.dark);

  final bool dark;

  Color get bg => dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
  Color get text => dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);
  Color get sub => dark ? const Color(0xFFA0A4AD) : const Color(0xFF5C6068);
  Color get surface => dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);
  Color get button => dark ? const Color(0xFF2A2D33) : const Color(0xFFF2F3F5);
  Color get line => dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB);
  Color get chevron => const Color(0xFFA0A4AD);
  static const lime = Color(0xFFC6FF3D);
  static const onLime = Color(0xFF1F2A00);
}

const g7BackSvg =
    '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 5l-7 7 7 7"></path></svg>';

const g7ChevronSvg =
    '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#A0A4AD" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7"></path></svg>';

/// artifact의 `header`: 60px | 1fr | 60px, 높이 64, 좌우 8.
class G7Header extends StatelessWidget {
  const G7Header({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => demoBack(context),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DemoSvg(g7BackSvg, color: c.text, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: c.text,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Align(alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ),
      ),
    );
  }
}

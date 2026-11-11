import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 05 서로 관심 확인 (`Match.dc.html`).
class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  static const String _close =
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"></path></svg>';
  static const String _heart =
      '<svg viewBox="0 0 24 24" fill="#1F2A00"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';
  static const String _arrow =
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>';

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    final pageBg = p.dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);
    return DemoFrame(
      background: pageBg,
      children: [
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          height: 560,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFE8DDCB)),
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 2,
                    sigmaY: 2,
                    tileMode: TileMode.clamp,
                  ),
                  child: DemoPhoto(
                    DemoImages.forBlob(
                      '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
                    ),
                    x: 50,
                    y: 30,
                  ),
                ),
                const ColoredBox(color: Color(0x730F1012)),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              reverse: true,
              child: _sheet(context, p),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheet(BuildContext context, G1Palette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.dark ? const Color(0xFF0F1012) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E0F1012),
            offset: Offset(0, -12),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _avatars(),
                const SizedBox(height: 26),
                Text(
                  '서로를 골랐어요.',
                  textAlign: TextAlign.center,
                  style: g1Text(28, 900, p.text, ls: -0.045),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      '모아 스튜디오와 서윤의 작은 취향이 서로의 콘텐츠에 관심을 표시했어요. 아직 계약이나 지급 의무는 생기지 않아요.',
                      textAlign: TextAlign.center,
                      style: g1Text(15, 400, p.sub, height: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 52,
                  padding: const EdgeInsets.fromLTRB(18, 0, 6, 0),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: g1Text(14, 400, p.text),
                          cursorColor: p.text,
                          decoration: InputDecoration(
                            hintText: '콘텐츠에 대한 첫 인사 남기기',
                            hintStyle: g1Text(14, 400, const Color(0xFF757575)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      G1Tap(
                        onTap: () => demoGo(context, 'Chat.dc.html'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.dark ? const Color(0xFF0F1012) : g1Lime,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: DemoSvg(
                            _arrow,
                            color: p.dark ? Colors.white : g1OnLime,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                G1Tap(
                  onTap: () => demoGo(context, 'Terms.dc.html'),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: g1Lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text('협업 조건 확인하기', style: g1Text(16, 700, g1OnLime)),
                  ),
                ),
                const SizedBox(height: 4),
                G1Tap(
                  onTap: () => demoGo(context, 'Main.dc.html'),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Text('계속 둘러보기', style: g1Text(14, 500, p.sub)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: G1Tap(
              onTap: () => demoBack(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: DemoSvg(_close, color: p.text, size: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 두 사람 얼굴이 겹친 모양과 가운데 하트.
  Widget _avatars() {
    Widget circle(Color bg, String blob, double x) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.white, spreadRadius: 4)],
        ),
        child: ClipOval(
          child: DemoPhoto(DemoImages.forBlob(blob), x: x, y: 40),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: 168,
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: circle(
                const Color(0xFFE8DDCB),
                '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
                55,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: circle(
                const Color(0xFF2E5B43),
                '/_blob/b17a81a543b08af172aa89b26b5db39c',
                62,
              ),
            ),
            Positioned(
              left: 64,
              bottom: -8,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: g1Lime,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 4)],
                ),
                alignment: Alignment.center,
                child: const DemoSvg(_heart, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

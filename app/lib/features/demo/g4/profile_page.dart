import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// B2 크리에이터 포트폴리오 (`NProfile.dc.html`).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _gear =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="3"></circle><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"></path></svg>';
  static const _check =
      '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';
  static const _principles =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"></path><circle cx="16" cy="6" r="2"></circle><circle cx="10" cy="12" r="2"></circle><circle cx="18" cy="18" r="2"></circle></svg>';
  static const _plusBig =
      '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"></path></svg>';
  static const _insta =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="4" y="4" width="16" height="16" rx="5"></rect><circle cx="12" cy="12" r="3.5"></circle></svg>';
  static const _plusCell =
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"></path></svg>';

  // [x, y, 좋아요]
  static const _photos = [
    [50.0, 30.0, '512'],
    [50.0, 62.0, '301'],
    [80.0, 20.0, '188'],
    [30.0, 45.0, '129'],
  ];

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(child: _Avatar(c: c)),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    '민의 옷장 기록',
                    style: g4Style(
                      24,
                      weight: FontWeight.w900,
                      color: c.text,
                      em: -0.04,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '인스타그램 연동됨, @min.closet',
                    style: g4Style(13, color: c.sub),
                  ),
                ),
                // 가운데 큰 버튼은 artifact에서 margin-top -8이라 줄 높이가 8 줄어든다. 아래 간격에서 같은 만큼 뺐다.
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Action(
                      label: '협업 원칙',
                      labelColor: c.sub,
                      circle: 52,
                      circleColor: c.fill,
                      icon: _principles,
                      iconColor: c.text,
                      iconSize: 22,
                      onTap: () => demoGo(context, 'Principles.dc.html'),
                    ),
                    const SizedBox(width: 28),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: _Action(
                        label: '콘텐츠 올리기',
                        labelColor: c.text,
                        circle: 68,
                        circleColor: G4Colors.lime,
                        icon: _plusBig,
                        iconColor: G4Colors.onLime,
                        iconSize: 28,
                        onTap: () => demoGo(context, 'NUpload.dc.html'),
                      ),
                    ),
                    const SizedBox(width: 28),
                    _Action(
                      label: '인스타 가져오기',
                      labelColor: c.sub,
                      circle: 52,
                      circleColor: c.fill,
                      icon: _insta,
                      iconColor: c.text,
                      iconSize: 22,
                      onTap: () => demoGo(context, 'NInstagram.dc.html'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Count(c: c, label: '콘텐츠', value: '7'),
                      ),
                      Expanded(
                        child: _Count(c: c, label: '받은 좋아요', value: '1,240'),
                      ),
                      Expanded(
                        child: _Count(c: c, label: '완료한 협업', value: '3'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '내 콘텐츠',
                        style: g4Style(
                          15,
                          weight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      Text('좋아요 많은 순', style: g4Style(12, color: c.sub)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: _PhotoCell(index: i, photo: _photos[i]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _PhotoCell(index: 3, photo: _photos[3]),
                          ),
                          const SizedBox(width: 4),
                          Expanded(child: _AddCell(c: c, index: 4)),
                          const SizedBox(width: 4),
                          Expanded(child: _AddCell(c: c, index: 5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => demoGo(context, 'NSettings.dc.html'),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: DemoSvg(_gear, color: c.text, size: 22)),
            ),
          ),
        ),
        DemoBottomNav(
          activeColor: c.navActive,
          items: const [
            DemoNavItem(
              label: '발견',
              svg: G4Icons.discover,
              canvasFile: 'NReels.dc.html',
            ),
            DemoNavItem(
              label: '관심',
              svg: G4Icons.heart,
              canvasFile: 'Likes.dc.html',
            ),
            DemoNavItem(
              label: '오퍼',
              svg: G4Icons.chat,
              canvasFile: 'NOfferInbox.dc.html',
            ),
            DemoNavItem(
              label: '협업',
              svg: G4Icons.work,
              canvasFile: 'NEscrow.dc.html',
            ),
            DemoNavItem(
              label: '프로필',
              svg: G4Icons.person,
              canvasFile: 'NProfile.dc.html',
              current: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.c});

  final G4Colors c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: G4Colors.photoBg,
              shape: BoxShape.circle,
            ),
            child: const DemoPhoto(DemoImages.minCloset, x: 50, y: 28),
          ),
          Positioned(
            right: 2,
            bottom: 6,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              // 고리는 라이트·다크 모두 #FFFFFF다(artifact 그대로).
              decoration: const BoxDecoration(
                color: G4Colors.lime,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 3),
                ],
              ),
              child: const DemoSvg(
                ProfilePage._check,
                color: G4Colors.onLime,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.labelColor,
    required this.circle,
    required this.circleColor,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.onTap,
  });

  final String label;
  final Color labelColor;
  final double circle;
  final Color circleColor;
  final String icon;
  final Color iconColor;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circle,
            height: circle,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: DemoSvg(icon, color: iconColor, size: iconSize),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: g4Style(12, weight: FontWeight.w500, color: labelColor),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.c, required this.label, required this.value});

  final G4Colors c;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: g4Style(12, color: c.sub)),
        const SizedBox(height: 2),
        Text(
          value,
          style: g4Style(18, weight: FontWeight.w700, color: c.text),
        ),
      ],
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({required this.index, required this.photo});

  final int index;
  final List<Object> photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: G4Colors.photoBg,
        borderRadius: G4CornerRadii.forIndex(index, 6),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DemoPhoto(
              DemoImages.minCloset,
              x: photo[0] as double,
              y: photo[1] as double,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 6,
            child: Text(
              '♥ ${photo[2]}',
              style: g4Style(
                12,
                weight: FontWeight.w500,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCell extends StatelessWidget {
  const _AddCell({required this.c, required this.index});

  final G4Colors c;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, 'NUpload.dc.html'),
      child: Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: G4CornerRadii.forIndex(index, 6),
        ),
        child: DemoSvg(ProfilePage._plusCell, color: c.sub, size: 24),
      ),
    );
  }
}

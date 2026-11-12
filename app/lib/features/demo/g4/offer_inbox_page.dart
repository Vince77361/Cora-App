import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g4_style.dart';

/// A6 받은 오퍼 · 크리에이터 (`NOfferInbox.dc.html`). 거절하면 안내 카드로 바뀌고 되돌릴 수 있다.
class OfferInboxPage extends StatefulWidget {
  const OfferInboxPage({super.key});

  @override
  State<OfferInboxPage> createState() => _OfferInboxPageState();
}

class _OfferInboxPageState extends State<OfferInboxPage> {
  bool _declined = false;

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned(left: 0, right: 0, top: 0, height: 64, child: _Header(c: c)),
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          bottom: 100,
          child: _declined
              ? _DeclinedCard(
                  c: c,
                  onUndo: () => setState(() => _declined = false),
                )
              : _OfferCard(onDecline: () => setState(() => _declined = true)),
        ),
        DemoBottomNav(
          activeColor: c.navActive,
          items: const [
            DemoNavItem(
              label: '발견',
              svg: G4Icons.discover,
              canvasFile: 'Main.dc.html',
            ),
            DemoNavItem(
              label: '관심',
              svg: G4Icons.heart,
              canvasFile: 'Likes.dc.html',
            ),
            DemoNavItem(
              label: '대화',
              svg: G4Icons.chat,
              canvasFile: 'Chat.dc.html',
            ),
            DemoNavItem(
              label: '협업',
              svg: G4Icons.work,
              canvasFile: 'Progress.dc.html',
              current: true,
            ),
            DemoNavItem(
              label: '프로필',
              svg: G4Icons.person,
              canvasFile: 'Principles.dc.html',
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c});

  final G4Colors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '받은 오퍼',
            style: g4Style(
              22,
              weight: FontWeight.w900,
              color: c.text,
              em: -0.04,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.onDecline});

  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    const soft = Color(0xFFE4E6EA);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF6E3C8),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 24, 28, 0.14),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DemoPhoto(DemoImages.ramen, x: 50, y: 45),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 480,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(23, 24, 28, 0),
                      Color.fromRGBO(23, 24, 28, 0.6),
                      Color.fromRGBO(23, 24, 28, 0.9),
                    ],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '소상공인 · 오늘 도착',
                style: g4Style(
                  12,
                  weight: FontWeight.w500,
                  color: G4Colors.ink,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '한그릇 라멘, 성수동',
                  style: g4Style(14, weight: FontWeight.w500, color: soft),
                ),
                const SizedBox(height: 10),
                Text(
                  '릴스 1편을\n부탁했어요',
                  style: g4Style(
                    30,
                    weight: FontWeight.w900,
                    color: Colors.white,
                    em: -0.05,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '2인 식사권 + 조회수당',
                  style: g4Style(
                    20,
                    weight: FontWeight.w900,
                    color: G4Colors.lime,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '조회 1회당 10원, 최대 10만 원. 김이 오르는 첫 숟가락 장면을 원해요.',
                  style: g4Style(14, color: soft, height: 1.55),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      '#팔로워무관',
                      style: g4Style(14, weight: FontWeight.w500, color: soft),
                    ),
                    Text(
                      '#오후3시촬영',
                      style: g4Style(14, weight: FontWeight.w500, color: soft),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDecline,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '거절',
                        style: g4Style(
                          16,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => demoGo(context, 'NEscrow.dc.html'),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: G4Colors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '수락하기',
                        style: g4Style(
                          16,
                          weight: FontWeight.w700,
                          color: G4Colors.onLime,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclinedCard extends StatelessWidget {
  const _DeclinedCard({required this.c, required this.onUndo});

  final G4Colors c;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '거절했어요.',
            style: g4Style(
              24,
              weight: FontWeight.w900,
              color: c.text,
              em: -0.04,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '가게에는 정중한 거절 알림만 가요. 다음 오퍼를 보여드릴게요.',
            style: g4Style(15, color: c.sub, height: 1.6),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onUndo,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '되돌리기',
                  style: g4Style(
                    14,
                    weight: FontWeight.w500,
                    color: c.text,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

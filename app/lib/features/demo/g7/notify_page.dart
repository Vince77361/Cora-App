import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E3 알림 (`NNotify.dc.html`)
class NotifyPage extends StatefulWidget {
  const NotifyPage({super.key});

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _Item {
  const _Item(
    this.k,
    this.text,
    this.time,
    this.href,
    this.blob,
    this.avBg,
    this.unread, {
    this.initial = '',
  });
  final int k;
  final String text;
  final String time;
  final String href;
  final String? blob;
  final Color avBg;
  final bool unread;
  final String initial;
}

class _NotifyPageState extends State<NotifyPage> {
  static const _labels = ['전체', '매칭', '협업', '정산'];
  static const _items = [
    _Item(
      1,
      '서윤의 작은 취향과 서로 관심이 닿았어요.',
      '방금',
      'Match.dc.html',
      'd607dd0c30dba30c6efc831cbd7a6f4f',
      Color(0xFFE8DDCB),
      true,
    ),
    _Item(
      2,
      '모아 스튜디오가 조건 버전 2를 확인했어요.',
      '12분 전',
      'Agreement.dc.html',
      'b17a81a543b08af172aa89b26b5db39c',
      Color(0xFF2E5B43),
      true,
    ),
    _Item(
      1,
      '한그릇 라멘이 릴스 1편 오퍼를 보냈어요.',
      '1시간 전',
      'NOfferInbox.dc.html',
      '05c6e2f12662029787761493c831ec3a',
      Color(0xFFF6E3C8),
      false,
    ),
    _Item(
      3,
      '정산 43,200원이 다음 주 수요일에 들어와요.',
      '어제',
      'NWallet.dc.html',
      null,
      Color(0xFFF8F9FA),
      false,
      initial: '₩',
    ),
    _Item(
      2,
      '초안 0:12 구간에 댓글이 달렸어요.',
      '11월 9일',
      'Review.dc.html',
      null,
      Color(0xFFF8F9FA),
      false,
      initial: '✎',
    ),
  ];
  static const _settingsSvg =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M4 7h10M18 7h2M4 17h4M12 17h8"></path><circle cx="16" cy="7" r="2"></circle><circle cx="10" cy="17" r="2"></circle></svg>';

  /// 조건 합의 알림은 브랜드 협업(모아 스튜디오) 것이다. 사장님에게는 같은 12번 화면으로 가는 크리에이터의 역제안 알림이다.
  static const _storeAgreement = _Item(
    2,
    '하루 한 컵이 판본 2를 보냈어요.',
    '12분 전',
    'Agreement.dc.html',
    '2c6508f8caadc5c0466b315d99cbda6b',
    Color(0xFFF3E3D3),
    true,
  );

  /// 브랜드(모아 스튜디오)에게는 자기 이름의 알림 대신, 판본 2를 보낸 크리에이터의 알림이다(12 브랜드 시점과 같다).
  static const _brandAgreement = _Item(
    2,
    '서윤의 작은 취향이 조건 버전 2를 보냈어요.',
    '12분 전',
    'Agreement.dc.html',
    'd607dd0c30dba30c6efc831cbd7a6f4f',
    Color(0xFFE8DDCB),
    true,
  );

  static _Item _forRole(_Item x) {
    if (x.href != 'Agreement.dc.html') return x;
    return switch (demoRole.value) {
      DemoRole.store => _storeAgreement,
      DemoRole.brand => _brandAgreement,
      _ => x,
    };
  }

  int _tab = 0;
  bool _read = false;

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    // 알림은 내 역할이 열 수 있는 화면으로 가는 것만 보인다(캔버스의 알림 목록은 역할이 섞여 있다).
    final rows = _items
        .map(_forRole)
        .where((x) => demoCanOpen(x.href) && (_tab == 0 || x.k == _tab))
        .toList();
    final selChip = c.dark ? const Color(0xFF33363D) : const Color(0xFFE3E5E9);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G7Header(
                  title: '알림',
                  fallback: 'Main.dc.html',
                  trailing: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => demoGo(context, 'NNotifySettings.dc.html'),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: DemoSvg(_settingsSvg, color: c.text, size: 22),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _labels.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == _tab ? selChip : c.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _labels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: c.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                  child: Column(
                    children: [for (final r in rows) _row(context, c, r)],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: GestureDetector(
              onTap: () => setState(() => _read = true),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.button,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '모두 읽음으로 표시',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, G7Colors c, _Item r) {
    final unread = r.unread && !_read;
    final avBg = r.blob == null && c.dark ? const Color(0xFF1C1E22) : r.avBg;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoGo(context, r.href),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: avBg, shape: BoxShape.circle),
              child: r.blob != null
                  ? DemoPhoto(DemoImages.forBlob(r.blob!), x: 50, y: 30)
                  : Text(
                      r.initial,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.text,
                    style: TextStyle(fontSize: 14, height: 1.5, color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(r.time, style: TextStyle(fontSize: 12, color: c.sub)),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                // artifact 다크 판도 #0F1012 그대로.
                decoration: BoxDecoration(
                  color: c.dark
                      ? const Color(0xFF0F1012)
                      : const Color(0xFF17181C),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

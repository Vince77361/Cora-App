import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../g4/g4_style.dart';
import 'demo_ui.dart';

/// 역할별 하단 메뉴(공통 모델 14장). 화면은 자기 역할과 켜진 칸의 위치만 넘긴다.
/// - 사장님: 홈, 찾기, 대화, 오퍼, AI 글
/// - 브랜드: 발견, 관심, 대화, 협업, 프로필
/// - 크리에이터: 발견, 관심, 대화, 협업, 프로필
///
/// 크리에이터의 "관심"은 캔버스에서 브랜드의 관심·보류(03)로 가지만 그 화면은 브랜드 것이라
/// 크리에이터의 보관함(D5)으로 보낸다. 브랜드의 "프로필"은 캔버스에서 크리에이터의 협업 원칙(09)으로 가지만
/// 브랜드에게는 프로필 화면이 없어(공통 모델 14장 "프로필 탭 → 설정") 설정(E4)으로 보낸다.
/// 도착 화면에 하단 메뉴가 없는 칸(대화, 보관함, 설정)은 쌓아서 열어 뒤로 가기로 돌아올 수 있게 한다.
List<DemoNavItem> demoRoleNavItems(DemoRole role, int current) {
  DemoNavItem item(
    int i,
    String label,
    String svg,
    String file, {
    bool stack = false,
  }) => DemoNavItem(
    label: label,
    svg: svg,
    canvasFile: file,
    current: i == current,
    stack: stack,
  );
  return switch (role) {
    DemoRole.store => [
      item(0, '홈', G4Icons.home, 'NStoreHome.dc.html'),
      item(1, '찾기', G4Icons.discover, 'NReels.dc.html'),
      item(2, '대화', G4Icons.chat, 'NChatThread.dc.html', stack: true),
      item(3, '오퍼', G4Icons.plus, 'NOffer.dc.html'),
      item(4, 'AI 글', G4Icons.sparkle, 'NStoreAI.dc.html'),
    ],
    DemoRole.brand => [
      item(0, '발견', G4Icons.discover, 'Main.dc.html'),
      item(1, '관심', G4Icons.heart, 'Likes.dc.html'),
      // 11 메시지 요청은 크리에이터가 받는 화면이다. 브랜드는 진행 중인 크리에이터와의 대화(D3)를 연다.
      item(2, '대화', G4Icons.chat, 'NChatThread.dc.html', stack: true),
      item(3, '협업', G4Icons.work, 'Progress.dc.html'),
      item(4, '프로필', G4Icons.person, 'NSettings.dc.html', stack: true),
    ],
    DemoRole.creator => [
      item(0, '발견', G4Icons.discover, 'CreatorDiscover.dc.html'),
      item(1, '관심', G4Icons.heart, 'NKeepList.dc.html', stack: true),
      item(2, '대화', G4Icons.chat, 'Chat.dc.html', stack: true),
      item(3, '협업', G4Icons.work, 'NOfferInbox.dc.html'),
      item(4, '프로필', G4Icons.person, 'NProfile.dc.html'),
    ],
  };
}

/// 지금 역할의 하단 메뉴. 역할이 비어 있으면(경로로 바로 연 화면) [fallback] 역할의 메뉴를 보여 준다.
Widget demoRoleNav({
  required int current,
  required DemoRole fallback,
  Color? activeColor,
}) {
  return DemoBottomNav(
    activeColor: activeColor,
    items: demoRoleNavItems(demoRole.value ?? fallback, current),
  );
}

import 'package:cora/features/demo/demo_app.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_role.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:cora/features/demo/shared/demo_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 역할 셋(가게 사장님, 브랜드, 크리에이터)을 E1부터 따라가며 어느 화면에서도 다른 역할 전용 화면이 나오지 않는지 확인한다.
Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);

  // 시연 앱의 역할은 전역 값이라 테스트마다 비운다.
  setUp(() {
    demoRole.value = null;
    demoRedirectFallbacks.clear();
  });
  tearDown(() => demoRole.value = null);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> start(WidgetTester tester, [String? path]) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
    demoRouter.go(path ?? DemoPaths.login);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(DemoBottomNav),
        matching: find.text(label),
      ),
    );
    await settle(tester);
  }

  List<String> stack() => [
    for (final m in demoRouter.routerDelegate.currentConfiguration.matches)
      m.matchedLocation,
  ];
  String path() => stack().last;

  /// 쌓인 화면이 모두 지금 역할의 화면인가.
  void expectInRole(DemoRole role) {
    final allowed = demoAllowedPaths(role);
    for (final p in stack()) {
      expect(allowed, contains(p), reason: '$role 역할에 다른 역할의 화면 $p가 나왔다');
    }
  }

  Future<void> back(WidgetTester tester) async {
    demoRouter.pop();
    await settle(tester);
  }

  /// E1 → E2 → A1에서 역할 카드를 골라 그 역할의 첫 화면까지.
  Future<void> signIn(
    WidgetTester tester,
    String card,
    String cta,
    String firstPath,
  ) async {
    await start(tester);
    expect(path(), DemoPaths.login);
    await tapText(tester, '휴대폰 번호로 시작하기');
    expect(path(), DemoPaths.verify);
    await tapText(tester, '5');
    await tapText(tester, '6');
    await tapText(tester, '확인');
    expect(path(), DemoPaths.role);
    expect(demoRole.value, isNull);
    await tapText(tester, card);
    await tapText(tester, cta);
    expect(path(), firstPath);
    expect(stack().length, 1);
  }

  testWidgets('store owner stays inside store screens from E1 to logout', (
    tester,
  ) async {
    await signIn(tester, '가게를 알리고 싶어요', '가게 링크로 시작하기', DemoPaths.storeLink);
    expect(demoRole.value, DemoRole.store);
    await tapText(tester, '가게 페이지 만들기');
    expect(path(), DemoPaths.storePage);
    await tapText(tester, 'AI로 직접 제작');
    expect(path(), DemoPaths.storeAI);
    await tapText(tester, '오퍼 만들기');
    expect(path(), DemoPaths.offer);
    await tapText(tester, '다음');
    await tapText(tester, '다음');
    // 2026-11-12 캔버스: A5 → F2 보내기 전 검토 → F3 제안함(함께 쓰는 화면).
    await tapText(tester, '검토하고 보내기');
    expect(path(), DemoPaths.reviewSend);
    await tapText(tester, '이 조건으로 보내기');
    expect(path(), DemoPaths.proposals);
    expectInRole(DemoRole.store);
    // 제안함에는 하단 메뉴가 없어 홈에서 메뉴를 확인한다.
    demoRouter.go(DemoPaths.storeHome);
    await settle(tester);

    // 하단 메뉴: 홈, 찾기, 대화, 오퍼, AI 글.
    for (final (label, target) in [
      ('찾기', DemoPaths.reels),
      ('오퍼', DemoPaths.offer),
      ('AI 글', DemoPaths.storeAI),
      ('홈', DemoPaths.storeHome),
    ]) {
      await tapNav(tester, label);
      expect(path(), target);
      expectInRole(DemoRole.store);
      // 오퍼 화면에는 하단 메뉴가 없어, 다음 칸은 홈에서 다시 시작한다.
      demoRouter.go(DemoPaths.storeHome);
      await settle(tester);
    }
    await tapNav(tester, '대화');
    expect(path(), DemoPaths.chatThread);
    expectInRole(DemoRole.store);
    await back(tester);
    expect(path(), DemoPaths.storeHome);

    // 설정: 크리에이터 줄이 없고 로그아웃하면 E1로, 역할도 비운다.
    demoRouter.push(DemoPaths.settings);
    await settle(tester);
    expect(find.text('가게 사장님'), findsWidgets);
    expect(find.text('연결된 계정'), findsNothing);
    expect(find.text('정산 계좌와 내역'), findsNothing);
    expect(find.text('다시 만나고 싶은 브랜드'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await settle(tester);
    await tapText(tester, '로그아웃');
    expect(path(), DemoPaths.login);
    expect(demoRole.value, isNull);
    expect(demoRedirectFallbacks, isEmpty);
  });

  testWidgets('brand stays inside brand screens from E1 to logout', (
    tester,
  ) async {
    await signIn(
      tester,
      '브랜드 제품을 알리고 싶어요',
      '크리에이터 둘러보기',
      DemoPaths.brandDiscover,
    );
    expect(demoRole.value, DemoRole.brand);
    expectInRole(DemoRole.brand);

    await tapNav(tester, '관심');
    expect(path(), DemoPaths.likes);
    await tapText(tester, '선택한 2명 비교하기');
    expect(path(), DemoPaths.compare);
    expectInRole(DemoRole.brand);
    await tapText(tester, '서윤의 제안 보기');
    expect(path(), DemoPaths.terms);
    expectInRole(DemoRole.brand);
    await back(tester);
    await back(tester);

    await tapNav(tester, '협업');
    expect(path(), DemoPaths.progress);
    expectInRole(DemoRole.brand);
    await tapNav(tester, '발견');
    expect(path(), DemoPaths.brandDiscover);
    await tapNav(tester, '대화');
    expect(path(), DemoPaths.chat);
    expectInRole(DemoRole.brand);
    await back(tester);
    // 브랜드의 "프로필"은 설정이다. 크리에이터의 협업 원칙이 아니다.
    await tapNav(tester, '프로필');
    expect(path(), DemoPaths.settings);
    expectInRole(DemoRole.brand);
    expect(find.text('브랜드'), findsWidgets);
    expect(find.text('연결된 계정'), findsNothing);
    expect(find.text('정산 계좌와 내역'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await settle(tester);
    await tapText(tester, '로그아웃');
    expect(path(), DemoPaths.login);
    expect(demoRole.value, isNull);
    expect(demoRedirectFallbacks, isEmpty);
  });

  testWidgets('creator stays inside creator screens from E1 to logout', (
    tester,
  ) async {
    await signIn(tester, '콘텐츠를 만들고 싶어요', '내 협업 원칙 정하기', DemoPaths.principles);
    expect(demoRole.value, DemoRole.creator);
    await tapText(tester, '나중에');
    expect(path(), DemoPaths.creatorDiscover);
    expectInRole(DemoRole.creator);

    // 하단 메뉴: 발견, 관심(보관함), 대화, 협업(받은 오퍼), 프로필.
    await tapNav(tester, '관심');
    expect(path(), DemoPaths.keepList);
    expectInRole(DemoRole.creator);
    await back(tester);
    await tapNav(tester, '대화');
    expect(path(), DemoPaths.chat);
    expectInRole(DemoRole.creator);
    await back(tester);
    await tapNav(tester, '협업');
    expect(path(), DemoPaths.offerInbox);
    expectInRole(DemoRole.creator);
    // A6 수락하기는 크리에이터의 에스크로(A7)로 간다. 가게 결제(A8)가 아니다.
    await tapText(tester, '수락하기');
    expect(path(), DemoPaths.escrow);
    expectInRole(DemoRole.creator);
    await tapText(tester, '콘텐츠 링크 제출');
    expect(path(), DemoPaths.review);
    await back(tester);
    await back(tester);
    await tapNav(tester, '프로필');
    expect(path(), DemoPaths.profile);
    expectInRole(DemoRole.creator);

    demoRouter.push(DemoPaths.settings);
    await settle(tester);
    expect(find.text('연결된 계정'), findsOneWidget);
    expect(find.text('정산 계좌와 내역'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await settle(tester);
    await tapText(tester, '로그아웃');
    expect(path(), DemoPaths.login);
    expect(demoRole.value, isNull);
    expect(demoRedirectFallbacks, isEmpty);
  });

  testWidgets('switching role from settings changes the menu and the screens', (
    tester,
  ) async {
    await start(tester, DemoPaths.role);
    await tapText(tester, '콘텐츠를 만들고 싶어요');
    await tapText(tester, '내 협업 원칙 정하기');
    demoRouter.push(DemoPaths.settings);
    await settle(tester);
    await tapText(tester, '역할 전환');
    expect(path(), DemoPaths.role);
    await tapText(tester, '가게를 알리고 싶어요');
    await tapText(tester, '가게 링크로 시작하기');
    expect(path(), DemoPaths.storeLink);
    expect(demoRole.value, DemoRole.store);
    expect(stack().length, 1);
  });

  testWidgets('without a role the canvas links are followed unchanged', (
    tester,
  ) async {
    // 경로로 바로 연 화면 확인이 깨지지 않게, 역할이 없으면 화면을 가리지 않는다.
    await start(tester, DemoPaths.offer);
    await tapText(tester, '다음');
    await tapText(tester, '다음');
    await tapText(tester, '검토하고 보내기');
    expect(path(), DemoPaths.reviewSend);
  });

  // D4 계약은 세 가지를 모두 확인해야 다음으로 간다. 크리에이터와 브랜드는 진행 단계로, 사장님은 진행 단계가 없어 합의한 오퍼의 결제(A8)로 간다.
  for (final (role, target, check) in [
    (DemoRole.creator, DemoPaths.progress, '콘텐츠는 브랜드 계정 재게시에만 쓰여요'),
    (DemoRole.brand, DemoPaths.progress, '콘텐츠는 브랜드 계정 재게시에만 쓰여요'),
    (DemoRole.store, DemoPaths.pay, '콘텐츠는 가게 계정 재게시에만 쓰여요'),
  ]) {
    testWidgets('contract confirm as ${role.name} goes to $target', (
      tester,
    ) async {
      demoRole.value = role;
      await start(tester, DemoPaths.contract);
      await tapText(tester, check);
      await tapText(tester, '동의하고 계약하기');
      expect(path(), target);
      expectInRole(role);
      expect(demoRedirectFallbacks, isEmpty);
    });
  }

  // 화면마다 눌 수 있는 곳을 하나씩 눌러, 어디로 가든 역할 안의 화면인지 확인한다.
  // 새 링크가 역할 홈으로 떨어지는 대비책에 걸리면 [demoRedirectFallbacks]에 남으므로 그것도 실패다.
  for (final role in DemoRole.values) {
    // A1은 역할을 새로 고르는 화면이라 누르면 역할이 바뀐다. 위의 흐름 시험이 다룬다.
    for (final screen in demoAllowedPaths(role).difference({DemoPaths.role})) {
      testWidgets('every tap on $screen as ${role.name} stays in the role', (
        tester,
      ) async {
        demoRole.value = role;
        await start(tester, screen);
        // 같은 화면을 다시 열 때마다 처음 상태에서 시작한다.
        Future<void> reopen() async {
          // 로그아웃 줄을 누르면 역할이 비므로 매번 다시 정한다.
          demoRole.value = role;
          demoRouter.go(DemoPaths.help);
          await settle(tester);
          demoRouter.go(screen);
          await settle(tester);
        }

        final taps = tester
            .widgetList<GestureDetector>(find.byType(GestureDetector))
            .where((g) => g.onTap != null)
            .length;
        final cards = find.byType(DemoCardGestures).evaluate().length;
        for (var i = 0; i < taps + cards; i++) {
          await reopen();
          if (i < taps) {
            final all = tester
                .widgetList<GestureDetector>(find.byType(GestureDetector))
                .where((g) => g.onTap != null)
                .toList();
            if (i >= all.length) continue;
            all[i].onTap!();
          } else {
            await tester.pump(const Duration(milliseconds: 800));
            await tester.tap(find.byType(DemoCardGestures).at(i - taps));
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1000));
          expectInRole(role);
          // 카드를 넘기면 뜨는 토스트의 링크(이유 남기기, 관심 목록, 보류 보기, 확인하기)도 눌러 본다.
          for (final link in ['이유 남기기', '관심 목록', '보류 보기', '확인하기']) {
            if (find.text(link).evaluate().isEmpty) continue;
            await tester.tap(find.text(link).last);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 1000));
            expectInRole(role);
          }
        }
        // 토스트 같은 시간 장치가 남지 않게 흘려 보낸다.
        await tester.pump(const Duration(seconds: 10));
        expect(demoRedirectFallbacks, isEmpty, reason: '표에 없는 링크가 역할 홈으로 떨어졌다');
      });
    }
  }
}

import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_role.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 여러 역할이 함께 쓰는 화면(11 대화, D3, 12 조건 합의, D4, 14, F2, F3)은 역할에 맞는 상대와 값을 보여 줘야 한다.
/// 사장님에게는 브랜드의 협업이, 크리에이터가 가게에 제안할 때는 브랜드의 이름이 나오면 안 된다.
Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    demoRole.value = null;
    demoRedirectFallbacks.clear();
  });
  tearDown(() => demoRole.value = null);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> open(
    WidgetTester tester,
    DemoRole role,
    String path, {
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    demoRole.value = role;
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: coraLightTheme,
        darkTheme: coraDarkTheme,
        themeMode: mode,
        routerConfig: demoRouter,
      ),
    );
    demoRouter.go(path);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  String path() => demoRouter
      .routerDelegate
      .currentConfiguration
      .matches
      .last
      .matchedLocation;

  /// 브랜드 협업의 이름·돈·말이 남아 있지 않은지.
  void expectNoBrand() {
    for (final word in ['브랜드', '모아 스튜디오', '주얼리', '350,000', '300,000']) {
      expect(find.textContaining(word), findsNothing, reason: '"$word"가 남아 있다');
    }
  }

  testWidgets('store F3 respond opens the store version of 12, not brand', (
    tester,
  ) async {
    await open(tester, DemoRole.store, DemoPaths.proposals);
    expect(find.text('응답하기'), findsOneWidget);
    await tapText(tester, '응답하기');
    expect(path(), DemoPaths.agreement);
    expectNoBrand();
    // 가게 협업의 판본 2: 하루 한 컵의 역제안에 내가 응답한다.
    expect(find.text('내가 응답할 차례'), findsOneWidget);
    expect(find.text('나 · 대기'), findsOneWidget);
    expect(find.text('상대 · 확인함'), findsOneWidget);
    expect(find.text('60,000원 → 30,000원'), findsOneWidget);
    expect(find.text('카드뉴스 1편'), findsOneWidget);
    expect(find.text('식사권 40,000원 · 2인'), findsOneWidget);
    expect(find.text('가게 계정 재게시 3개월'), findsOneWidget);
    expect(find.text('고쳐서 다시 보내기'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsOneWidget);
    expect(find.text('계약서 미리 보기'), findsNothing);
  });

  testWidgets('store 12 accept goes to payment and edit goes to F1', (
    tester,
  ) async {
    await open(tester, DemoRole.store, DemoPaths.agreement);
    await tapText(tester, '이 판본 수락');
    expect(path(), DemoPaths.pay);
    expect(demoRedirectFallbacks, isEmpty);

    await open(tester, DemoRole.store, DemoPaths.agreement);
    await tapText(tester, '고쳐서 다시 보내기');
    expect(path(), DemoPaths.budget);
  });

  testWidgets('brand screens show brand terms, not store ones', (tester) async {
    for (final screen in [
      DemoPaths.budget,
      DemoPaths.reviewSend,
      DemoPaths.proposals,
      DemoPaths.metrics,
    ]) {
      await open(tester, DemoRole.brand, screen);
      expect(find.textContaining('식사권'), findsNothing, reason: screen);
      expect(find.textContaining('하루 한 컵 ·'), findsNothing, reason: screen);
      expect(find.textContaining('사장님'), findsNothing, reason: screen);
    }
    await open(tester, DemoRole.brand, DemoPaths.notify);
    expect(find.textContaining('모아 스튜디오가'), findsNothing);
    await open(tester, DemoRole.brand, DemoPaths.contract);
    expect(find.text('광고 표시 의무를 지킬게요'), findsNothing);
  });

  testWidgets('creator screens speak as 민의 옷장 기록, not the brand', (
    tester,
  ) async {
    await open(tester, DemoRole.creator, DemoPaths.progress);
    expect(find.text('남은 캠페인 예산'), findsNothing);
    expect(find.text('민의 옷장 기록과 모아 스튜디오'), findsOneWidget);
    await open(tester, DemoRole.creator, DemoPaths.review);
    expect(find.text('이 판본(v2) 게시 승인'), findsNothing);
    await open(tester, DemoRole.creator, DemoPaths.contract);
    expect(find.text('민의 옷장 기록'), findsOneWidget);
  });

  testWidgets('brand D3 talks with the creator from the brand side', (
    tester,
  ) async {
    await open(tester, DemoRole.brand, DemoPaths.chatThread);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('모아 스튜디오'), findsNothing);
    expect(find.text('메시지 요청'), findsNothing);
  });

  testWidgets('brand 12 shows the brand side of version 2', (tester) async {
    await open(tester, DemoRole.brand, DemoPaths.agreement);
    expect(find.text('내가 응답할 차례'), findsOneWidget);
    expect(find.text('크리에이터 · 확인함'), findsOneWidget);
    expect(find.text('브랜드 확인 대기 중'), findsNothing);
    expect(find.text('계약서 미리 보기'), findsOneWidget);
    expect(find.text('300,000원 → 350,000원'), findsOneWidget);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final screen in [
      DemoPaths.chat,
      DemoPaths.chatThread,
      DemoPaths.agreement,
      DemoPaths.contract,
      DemoPaths.reviewSend,
      DemoPaths.proposals,
      DemoPaths.notify,
    ]) {
      testWidgets('store ${mode.name} $screen has no brand content', (
        tester,
      ) async {
        await open(tester, DemoRole.store, screen, mode: mode);
        expectNoBrand();
      });
    }
  }

  testWidgets(
    'store F3 closed tab has no brand content and D4 link is payment',
    (tester) async {
      await open(tester, DemoRole.store, DemoPaths.proposals);
      await tapText(tester, '종료 2');
      expectNoBrand();
      // "합의 완료 · 계약으로 이동"은 사장님을 결제로 보낸다.
      await tapText(tester, '합의 완료 · 계약으로 이동');
      expect(path(), DemoPaths.pay);
      expect(demoRedirectFallbacks, isEmpty);
    },
  );

  testWidgets('store cannot open draft review and its link goes to home', (
    tester,
  ) async {
    expect(demoAllowedPaths(DemoRole.store), isNot(contains(DemoPaths.review)));
    expect(demoAllowedPaths(DemoRole.brand), contains(DemoPaths.review));
    expect(demoAllowedPaths(DemoRole.creator), contains(DemoPaths.review));
    demoRole.value = DemoRole.store;
    expect(
      demoResolvePath(DemoPaths.notify, DemoPaths.review),
      DemoPaths.storeHome,
    );
    expect(demoRedirectFallbacks, isEmpty);
    // 알림에서도 초안 댓글 줄은 사장님에게 보이지 않는다.
    await open(tester, DemoRole.store, DemoPaths.notify);
    expect(find.text('초안 0:12 구간에 댓글이 달렸어요.'), findsNothing);
  });

  testWidgets('store D4 confirm goes to payment', (tester) async {
    await open(tester, DemoRole.store, DemoPaths.contract);
    await tapText(tester, '콘텐츠는 가게 계정 재게시에만 쓰여요');
    await tapText(tester, '동의하고 계약하기');
    expect(path(), DemoPaths.pay);
  });

  testWidgets('store D3 shows the creator as the other side', (tester) async {
    await open(tester, DemoRole.store, DemoPaths.chatThread);
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('리빙 릴스 · 팔로워 640명'), findsOneWidget);
    expect(find.textContaining('조건 버전 2 · 내가 응답할 차례'), findsOneWidget);
  });

  testWidgets('store notification for the agreement is the creator counter', (
    tester,
  ) async {
    await open(tester, DemoRole.store, DemoPaths.notify);
    expect(find.text('하루 한 컵이 판본 2를 보냈어요.'), findsOneWidget);
    expect(find.textContaining('모아 스튜디오'), findsNothing);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'creator F2 to F3 has the store on the other side (${mode.name})',
      (tester) async {
        await open(tester, DemoRole.creator, DemoPaths.reviewSend, mode: mode);
        expect(find.text('한그릇 라멘'), findsOneWidget);
        expect(find.text('하루 한 컵'), findsNothing);
        expect(find.textContaining('판본 2로 고정되고'), findsOneWidget);
        // F2 하단의 [수수료]는 캔버스 원문 자리표시다.
        expect(find.textContaining('[수수료]'), findsOneWidget);
        expectNoBrand();
        await tapText(tester, '이 조건으로 보내기');
        expect(path(), DemoPaths.proposals);
        expect(find.text('한그릇 라멘'), findsOneWidget);
        expect(find.text('상대 대기'), findsOneWidget);
        expect(find.text('판본 2 · 릴스 1편 · 2일 안에 답이 와요'), findsOneWidget);
        // 가게 화면에서 온 이름(다른 크리에이터)은 크리에이터의 제안함에 없다.
        expect(find.text('민의 옷장 기록'), findsNothing);
        expect(find.text('서윤의 작은 취향'), findsNothing);
        expectNoBrand();
        expect(demoRedirectFallbacks, isEmpty);
      },
    );
  }

  testWidgets('creator F3 closed row opens the creator escrow', (tester) async {
    await open(tester, DemoRole.creator, DemoPaths.proposals);
    await tapText(tester, '종료 1');
    await tapText(tester, '합의 완료 · 계약으로 이동');
    expect(path(), DemoPaths.escrow);
    expect(demoRedirectFallbacks, isEmpty);
  });
}

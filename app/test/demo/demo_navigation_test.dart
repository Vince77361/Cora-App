import 'package:cora/features/demo/demo_app.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_role.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:cora/features/demo/g7/g7_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 앱처럼 로그인에서 시작해 역할 홈으로 들어가는 흐름, 탭 이동, 뒤로 가기.
Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  // 역할은 전역 값이라 앞 시험에서 고른 역할이 남지 않게 매번 비운다.
  setUp(() => demoRole.value = null);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> start(
    WidgetTester tester, [
    String path = DemoPaths.login,
  ]) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
    demoRouter.go(path);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  // 쌓은(push) 화면은 uri가 아니라 맨 위 match가 가리킨다.
  String path() => demoRouter
      .routerDelegate
      .currentConfiguration
      .matches
      .last
      .matchedLocation;
  int stackSize() =>
      demoRouter.routerDelegate.currentConfiguration.matches.length;

  testWidgets('app starts on the login screen', (tester) async {
    await start(tester);
    expect(find.text('휴대폰 번호로 시작하기'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
  });

  testWidgets('phone login goes through verify and role to the store flow', (
    tester,
  ) async {
    await start(tester);
    await tapText(tester, '휴대폰 번호로 시작하기');
    expect(path(), DemoPaths.verify);
    await tapText(tester, '5');
    await tapText(tester, '6');
    await tapText(tester, '확인');
    expect(path(), DemoPaths.role);
    expect(find.text('가게를 알리고 싶어요'), findsOneWidget);
    await tapText(tester, '가게 링크로 시작하기');
    expect(path(), DemoPaths.storeLink);
    // 역할 첫 화면에서는 로그인 쪽 화면이 비어 뒤로 갈 곳이 없다.
    expect(demoRouter.canPop(), isFalse);
    expect(stackSize(), 1);
  });

  testWidgets('kakao login goes to role and the brand home', (tester) async {
    await start(tester);
    await tapText(tester, '카카오로 계속하기');
    expect(path(), DemoPaths.role);
    await tapText(tester, '브랜드 제품을 알리고 싶어요');
    await tapText(tester, '크리에이터 둘러보기');
    expect(path(), DemoPaths.brandDiscover);
    expect(demoRouter.canPop(), isFalse);
  });

  testWidgets('naver login goes to role and the creator home', (tester) async {
    await start(tester);
    await tapText(tester, '네이버로 계속하기');
    expect(path(), DemoPaths.role);
    await tapText(tester, '콘텐츠를 만들고 싶어요');
    await tapText(tester, '내 협업 원칙 정하기');
    expect(path(), DemoPaths.principles);
    expect(demoRouter.canPop(), isFalse);
  });

  testWidgets('terms link on login opens the help screen', (tester) async {
    await start(tester);
    // 약관 글자는 문장 가운데의 일부라, 그 조각의 누르기 처리기를 직접 부른다.
    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('이용약관'),
      ),
    );
    TapGestureRecognizer? tap;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == '이용약관') {
        tap = span.recognizer as TapGestureRecognizer?;
      }
      return true;
    });
    tap!.onTap!();
    await settle(tester);
    expect(path(), DemoPaths.help);
    expect(demoRouter.canPop(), isTrue);
  });

  testWidgets('bottom menu moves replace the screen instead of stacking', (
    tester,
  ) async {
    await start(tester, DemoPaths.brandDiscover);
    expect(stackSize(), 1);
    await tapText(tester, '관심');
    expect(path(), DemoPaths.likes);
    expect(stackSize(), 1);
    expect(demoRouter.canPop(), isFalse);
    await tapText(tester, '협업');
    expect(path(), DemoPaths.progress);
    expect(demoRouter.canPop(), isFalse);
  });

  testWidgets('other moves still stack and back pops', (tester) async {
    await start(tester, DemoPaths.likes);
    await tester.tap(find.textContaining('비교하기').last);
    await settle(tester);
    expect(path(), DemoPaths.compare);
    expect(stackSize(), 2);
    demoRouter.pop();
    await settle(tester);
    expect(path(), DemoPaths.likes);
  });

  testWidgets('going to a screen already below closes back to it', (
    tester,
  ) async {
    await start(tester, DemoPaths.settings);
    await tapText(tester, '프로필 수정');
    expect(path(), DemoPaths.editProfile);
    expect(stackSize(), 2);
    await tapText(tester, '저장하기');
    expect(path(), DemoPaths.settings);
    expect(stackSize(), 1);
  });

  testWidgets('going back to a screen several levels below closes them all', (
    tester,
  ) async {
    await start(tester, DemoPaths.brandDiscover);
    demoRouter.push(DemoPaths.likes);
    await settle(tester);
    demoRouter.push(DemoPaths.pass);
    await settle(tester);
    expect(stackSize(), 3);
    await tapText(tester, '이유 없이 다음 보기');
    expect(path(), DemoPaths.brandDiscover);
    expect(stackSize(), 1);
  });

  testWidgets('logout clears the stack and returns to login', (tester) async {
    await start(tester, DemoPaths.brandDiscover);
    demoRouter.push(DemoPaths.settings);
    await settle(tester);
    expect(demoRouter.canPop(), isTrue);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await settle(tester);
    await tapText(tester, '로그아웃');
    expect(path(), DemoPaths.login);
    expect(demoRouter.canPop(), isFalse);
  });

  testWidgets('back follows the canvas link when nothing is stacked', (
    tester,
  ) async {
    await start(tester, DemoPaths.settings);
    expect(demoRouter.canPop(), isFalse);
    await tester.tap(
      find
          .descendant(
            of: find.byType(G7Header),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await settle(tester);
    // 쌓인 화면이 없으면 캔버스의 뒤로 링크(설정 → 프로필)가 가리키는 화면으로 간다.
    expect(path(), DemoPaths.profile);
  });

  for (final target in [
    DemoPaths.brandDiscover,
    DemoPaths.compare,
    DemoPaths.settings,
  ]) {
    testWidgets(
      'edge swipe from $target pops back',
      (tester) async {
        await start(tester);
        demoRouter.push(target);
        await settle(tester);
        await tester.timedDragFrom(
          const Offset(5, 400),
          const Offset(300, 0),
          const Duration(milliseconds: 300),
        );
        await settle(tester);
        expect(path(), DemoPaths.login);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}

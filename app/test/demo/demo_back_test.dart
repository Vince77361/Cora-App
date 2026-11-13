import 'package:cora/features/demo/demo_app.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_role.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:cora/features/demo/shared/demo_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 뒤로·닫기 버튼이 있는 모든 화면을 세 역할로 연다.
/// 1) `go`로 바로 열면(쌓인 화면 없음, 홈 진입·탭 이동 뒤와 같다) 캔버스의 뒤로 링크가 가리키는 화면으로 간다.
/// 2) 다른 화면 위에 `push`로 열면 이전 화면으로 돌아간다.

/// 캔버스 화면(`NSettings`)과 그 화면의 뒤로·닫기 링크(`href`)가 가리키는 화면. 캔버스 `<a aria-label="뒤로|닫기" href>`에서 뽑았다.
/// 라이트(`X.dc.html`)와 다크(`DarkX.dc.html`)의 링크는 같은 화면을 가리킨다.
const Map<String, String> _canvasBack = {
  'Agreement': 'Chat',
  'Chat': 'Proposal',
  'Compare': 'Likes',
  'Guide': 'Agreement',
  'Match': 'Main',
  'NAIOrder': 'NStoreAI',
  'NApplicants': 'NStoreHome',
  'NBidResult': 'NBidding',
  'NBidding': 'Main',
  'NBudget': 'NStorePage',
  'NCampaign': 'CreatorDiscover',
  'NChatThread': 'Chat',
  'NContract': 'Agreement',
  'NCounter': 'NStoreView',
  'NCreatorView': 'NReels',
  'NEditProfile': 'NSettings',
  'NEscrow': 'NOfferInbox',
  'NHelp': 'NSettings',
  'NInstagram': 'NProfile',
  'NKeepList': 'Retro',
  'NMetrics': 'NEscrow',
  'NNotify': 'Main',
  'NNotifySettings': 'NSettings',
  'NOutreach': 'NDirectory',
  'NPay': 'NStoreHome',
  'NProposals': 'NStoreHome',
  'NResult': 'NStoreHome',
  'NReviewSend': 'NBudget',
  'NSettings': 'NProfile',
  'NStoreAI': 'NStorePage',
  'NStoreLink': 'NRole',
  'NStoreManual': 'NStoreLink',
  'NStorePage': 'NStoreLink',
  'NStoreView': 'CreatorDiscover',
  'NSwitchReport': 'NStoreHome',
  'NUpload': 'NProfile',
  'NVerify': 'NLogin',
  'NWallet': 'NSettings',
  'Proposal': 'CreatorDiscover',
  'Retro': 'Review',
  'Review': 'Guide',
  'Terms': 'Main',
};

Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
}

/// 머리 왼쪽의 화살표(`<`)나 X 그림. 모든 묶음이 같은 path를 쓴다.
final Finder _backIcon = find.byWidgetPredicate(
  (w) =>
      w is DemoSvg &&
      (w.svg.contains('M15 5l-7 7 7 7') ||
          w.svg.contains('M6 6l12 12M18 6L6 18')),
);

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

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
  }

  String path() => demoRouter
      .routerDelegate
      .currentConfiguration
      .matches
      .last
      .matchedLocation;
  int stackSize() =>
      demoRouter.routerDelegate.currentConfiguration.matches.length;

  /// 실제 손가락처럼 그림 한가운데를 눌러, 가리는 위젯이 있으면 눌리지 않게 한다.
  Future<void> tapBack(WidgetTester tester) async {
    expect(_backIcon, findsWidgets, reason: '${path()}에 뒤로·닫기 그림이 없다');
    await tester.tapAt(tester.getCenter(_backIcon.first));
    await settle(tester);
  }

  test('every back link in the table points at a known screen', () {
    for (final entry in _canvasBack.entries) {
      // 모르는 이름은 forCanvas가 로그인으로 돌려주므로, 로그인이 나오면 이름이 틀린 것이다.
      expect(DemoPaths.forCanvas(entry.key), isNot(DemoPaths.login));
      expect(
        DemoPaths.forCanvas(entry.value),
        entry.value == 'NLogin' ? DemoPaths.login : isNot(DemoPaths.login),
      );
    }
  });

  for (final role in DemoRole.values) {
    final allowed = demoAllowedPaths(role);
    final screens = [
      for (final e in _canvasBack.entries)
        if (allowed.contains(DemoPaths.forCanvas(e.key))) e,
    ];
    final home = demoHomePath(role);

    for (final e in screens) {
      final screen = DemoPaths.forCanvas(e.key);
      final wanted = DemoPaths.forCanvas(e.value);

      testWidgets('${role.name} ${e.key} back goes to another screen when '
          'opened with go', (tester) async {
        await start(tester);
        demoRole.value = role;
        demoRouter.go(screen);
        await settle(tester);
        expect(path(), screen);
        expect(stackSize(), 1);

        await tapBack(tester);

        expect(path(), isNot(screen), reason: '쌓인 화면이 없을 때 뒤로가 먹지 않는다');
        // 캔버스가 가리키는 화면이 역할 밖이면 table이 정한 같은 역할 화면. 어느 쪽이든 그 화면이 열려 있어야 한다.
        expect(demoAllowedPaths(role), contains(path()));
        if (allowed.contains(wanted) && wanted != screen) {
          expect(path(), wanted);
        }
        // 역할 홈으로 보낸 링크가 없어야 한다(대비책은 table에 적는다).
        expect(demoRedirectFallbacks, isEmpty);
      });

      testWidgets('${role.name} ${e.key} back returns to the previous screen '
          'when opened with push', (tester) async {
        await start(tester);
        demoRole.value = role;
        demoRouter.go(home);
        await settle(tester);
        demoRouter.push(screen);
        await settle(tester);
        expect(path(), screen);
        expect(stackSize(), 2);

        await tapBack(tester);

        expect(path(), home);
        expect(stackSize(), 1);
      });
    }
  }
}

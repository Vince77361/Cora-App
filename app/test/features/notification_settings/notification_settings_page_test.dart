import 'dart:async';

import 'package:cora/features/notification_settings/domain/notification_settings.dart';
import 'package:cora/features/notification_settings/presentation/pages/notification_settings_page.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart' show topPath;
import 'fake_notification_settings_repository.dart';
import 'notification_settings_harness.dart';

const _lime = Color(0xFFC6FF3D);
const _lightOff = Color(0xFFE6E8EB);
const _darkOff = Color(0xFF2A2D33);

Color? _track(WidgetTester tester, NotificationSwitch s) =>
    (tester
                .widget<DecoratedBox>(
                  find.byKey(ValueKey('notification-switch-track-${s.name}')),
                )
                .decoration
            as BoxDecoration)
        .color;

Color? _quiet(WidgetTester tester, QuietHours q) =>
    (tester
                .widget<Container>(
                  find.byKey(ValueKey('notification-quiet-${q.name}')),
                )
                .decoration
            as BoxDecoration)
        .color;

Offset _knobOffset(WidgetTester tester, NotificationSwitch s) =>
    tester.getTopLeft(
      find.byKey(ValueKey('notification-switch-knob-${s.name}')),
    ) -
    tester.getTopLeft(
      find.byKey(ValueKey('notification-switch-track-${s.name}')),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows five switches with four on and night quiet hours by '
      'default', (tester) async {
    final repo = FakeNotificationSettingsRepository();
    await pumpNotificationSettings(tester, repo: repo);

    expect(topPath(tester), NotificationRoutes.settings);
    expect(find.byType(NotificationSettingsPage), findsOneWidget);
    expect(find.text('알림'), findsOneWidget);
    expect(find.text('꼭 필요한 알림만\n받을 수 있어요.'), findsOneWidget);
    for (final text in [
      '서로 관심',
      '상대도 관심을 표시하면 알려줘요',
      '새 오퍼와 제안',
      '가게나 브랜드가 오퍼를 보냈을 때',
      '대화 메시지',
      '진행 중인 협업의 새 메시지',
      '정산',
      '지급 예정, 지급 완료',
      '추천 소식',
      '새로 올라온 캠페인과 크리에이터',
      '방해 금지 시간',
      '끄기',
      '밤 10시 – 아침 8시',
      '주말',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    for (final s in NotificationSwitch.values) {
      final on = s != NotificationSwitch.recommendations;
      // 라이트: 켜짐 #C6FF3D, 꺼짐 #E6E8EB. 손잡이는 켜짐 왼쪽 23, 꺼짐 3(위 3).
      expect(_track(tester, s), on ? _lime : _lightOff, reason: s.name);
      expect(_knobOffset(tester, s), Offset(on ? 23 : 3, 3), reason: s.name);
      expect(
        tester.getSize(
          find.byKey(ValueKey('notification-switch-track-${s.name}')),
        ),
        const Size(48, 28),
      );
      expect(
        tester.getSize(
          find.byKey(ValueKey('notification-switch-knob-${s.name}')),
        ),
        const Size(22, 22),
      );
    }
    // 방해 금지: 밤이 #FFFFFF, 나머지는 투명.
    expect(_quiet(tester, QuietHours.night), const Color(0xFFFFFFFF));
    expect(_quiet(tester, QuietHours.off), Colors.transparent);
    expect(_quiet(tester, QuietHours.weekend), Colors.transparent);
    // 줄 최소 높이 64.
    expect(
      tester
          .getSize(find.byKey(const ValueKey('notification-switch-offers')))
          .height,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('uses #2A2D33 for the off switch and quiet choice in dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpNotificationSettings(
      tester,
      repo: FakeNotificationSettingsRepository(),
    );

    // 켜짐은 두 모드 모두 #C6FF3D, 꺼짐은 다크에서 #2A2D33.
    expect(_track(tester, NotificationSwitch.offers), _lime);
    expect(_track(tester, NotificationSwitch.recommendations), _darkOff);
    expect(_quiet(tester, QuietHours.night), _darkOff);
    expect(_quiet(tester, QuietHours.off), Colors.transparent);
    // 손잡이는 두 모드 모두 흰색에 그림자 0 1 3 rgba(0,0,0,0.2).
    final knob =
        tester
                .widget<DecoratedBox>(
                  find.byKey(
                    const ValueKey('notification-switch-knob-recommendations'),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(knob.color, const Color(0xFFFFFFFF));
    expect(knob.boxShadow!.single.offset, const Offset(0, 1));
    expect(knob.boxShadow!.single.color, const Color.fromRGBO(0, 0, 0, 0.2));
  });

  testWidgets('saves a switch immediately and reverts on failure', (
    tester,
  ) async {
    final repo = FakeNotificationSettingsRepository();
    await pumpNotificationSettings(tester, repo: repo);

    // 누르면 바로 켜지고 저장 요청이 간다.
    await tester.tap(find.text('추천 소식'));
    await tester.pump();
    expect(_track(tester, NotificationSwitch.recommendations), _lime);
    await tester.pumpAndSettle();
    expect(repo.saved.single.recommendations, isTrue);
    expect(repo.saved.single.quietHours, QuietHours.night);
    expect(find.text('설정을 저장하지 못했어요.'), findsNothing);

    // 서버가 거절하면 그 스위치만 되돌리고 안내를 3초 보인다.
    final gate = Completer<void>();
    repo
      ..failSave = true
      ..saveGate = gate;
    await tester.tap(find.text('대화 메시지'));
    await tester.pump();
    expect(_track(tester, NotificationSwitch.messages), _lightOff);
    gate.complete();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_track(tester, NotificationSwitch.messages), _lime);
    // 위에서 켠 스위치는 그대로다.
    expect(_track(tester, NotificationSwitch.recommendations), _lime);
    expect(find.text('설정을 저장하지 못했어요.'), findsOneWidget);
    expect(repo.saved, hasLength(1));

    await tester.pump(const Duration(milliseconds: 2800));
    expect(find.text('설정을 저장하지 못했어요.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('설정을 저장하지 못했어요.'), findsNothing);
  });

  testWidgets('picks one quiet-hours option at a time', (tester) async {
    final repo = FakeNotificationSettingsRepository();
    await pumpNotificationSettings(tester, repo: repo);

    await tester.tap(find.text('주말'));
    await tester.pumpAndSettle();
    expect(_quiet(tester, QuietHours.weekend), const Color(0xFFFFFFFF));
    expect(_quiet(tester, QuietHours.night), Colors.transparent);
    expect(_quiet(tester, QuietHours.off), Colors.transparent);
    expect(repo.saved.single.quietHours, QuietHours.weekend);

    await tester.tap(find.text('끄기'));
    await tester.pumpAndSettle();
    expect(_quiet(tester, QuietHours.off), const Color(0xFFFFFFFF));
    expect(_quiet(tester, QuietHours.weekend), Colors.transparent);
    expect(repo.saved.last.quietHours, QuietHours.off);

    // 이미 고른 것을 다시 눌러도 저장하지 않는다.
    await tester.tap(find.text('끄기'));
    await tester.pumpAndSettle();
    expect(repo.saved, hasLength(2));
  });

  testWidgets('reverts the quiet-hours choice when saving fails', (
    tester,
  ) async {
    final repo = FakeNotificationSettingsRepository()..failSave = true;
    await pumpNotificationSettings(tester, repo: repo);

    await tester.tap(find.text('주말'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(_quiet(tester, QuietHours.night), const Color(0xFFFFFFFF));
    expect(_quiet(tester, QuietHours.weekend), Colors.transparent);
    expect(find.text('설정을 저장하지 못했어요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('sends saves one after another so a slow save cannot be '
      'overwritten', (tester) async {
    final gate = Completer<void>();
    final repo = FakeNotificationSettingsRepository()..saveGate = gate;
    await pumpNotificationSettings(tester, repo: repo);

    await tester.tap(find.text('추천 소식'));
    await tester.pump();
    await tester.tap(find.text('주말'));
    await tester.pump();
    // 첫 저장이 끝나기 전에 둘 다 화면에 보인다.
    expect(_track(tester, NotificationSwitch.recommendations), _lime);
    expect(_quiet(tester, QuietHours.weekend), const Color(0xFFFFFFFF));
    expect(repo.saved, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(2));
    // 두 번째 요청은 첫 변경을 이어받아 둘 다 담는다.
    expect(repo.saved.last.recommendations, isTrue);
    expect(repo.saved.last.quietHours, QuietHours.weekend);
    expect(repo.settings, repo.saved.last);
  });

  testWidgets('keeps saving a queued change after the page is closed', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakeNotificationSettingsRepository()..saveGate = gate;
    await pumpNotificationSettings(tester, repo: repo);

    await tester.tap(find.text('추천 소식'));
    await tester.pump();
    await tester.tap(find.text('주말'));
    await tester.pump();

    // 첫 저장이 끝나기 전에 화면을 닫는다. 줄에 남은 두 번째 저장도 서버에 가야 한다.
    routerOf(tester).pop();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsPage), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(2));
    expect(repo.saved.last.recommendations, isTrue);
    expect(repo.saved.last.quietHours, QuietHours.weekend);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes switches to assistive technology', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpNotificationSettings(
      tester,
      repo: FakeNotificationSettingsRepository(),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('서로 관심')),
      isSemantics(
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
        hint: '상대도 관심을 표시하면 알려줘요',
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('추천 소식')),
      isSemantics(hasToggledState: true, isToggled: false),
    );
    semantics.dispose();
  });

  testWidgets('shows an error with retry when settings cannot be loaded', (
    tester,
  ) async {
    final repo = FakeNotificationSettingsRepository()..failFetch = true;
    await pumpNotificationSettings(tester, repo: repo);

    expect(find.text('알림 설정을 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('서로 관심'), findsOneWidget);
    expect(repo.fetchCalls, 2);
  });

  testWidgets('goes back to where it was opened from', (tester) async {
    await pumpNotificationSettings(
      tester,
      repo: FakeNotificationSettingsRepository(),
    );

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationSettingsPage), findsNothing);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpNotificationSettings(
      tester,
      repo: FakeNotificationSettingsRepository(),
      smallPhoneLargeText: true,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('주말'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

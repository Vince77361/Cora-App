import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../negotiation/fake_negotiation_repository.dart'
    show FakeNegotiationRepository;
import 'chat_fixtures.dart';
import 'chat_harness.dart';

const _room = 'room-1';

FakeChatRepository _chat({ConversationDetail? detail}) => FakeChatRepository(
  details: {_room: detail ?? roomDetail(id: _room, terms: termsVersion())},
  messages: {
    _room: [message(seq: 1)],
  },
);

Future<void> _open(
  WidgetTester tester,
  FakeChatRepository chat, {
  FakeNegotiationRepository? negotiation,
  FakeRealtimeConnection? realtime,
  bool largeText = false,
}) async {
  await pumpChatApp(
    tester,
    chat: chat,
    realtime: realtime,
    smallPhoneLargeText: largeText,
    overrides: [
      if (negotiation != null)
        negotiationRepositoryProvider.overrideWithValue(negotiation),
    ],
  );
  await pushRoute(tester, AppRoutes.chat(_room));
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('대화 관리'));
  await tester.pumpAndSettle();
}

/// 메뉴에서 [item]을 눌러 시트를 연다.
Future<void> _pick(WidgetTester tester, String item) async {
  await _openMenu(tester);
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  group('menu', () {
    testWidgets('lists block, report and drop when I can drop', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _chat());
      await _openMenu(tester);

      expect(find.text('알림 끄기'), findsOneWidget);
      expect(find.text('차단하기'), findsOneWidget);
      expect(find.text('신고하기'), findsOneWidget);
      expect(find.text('협의 그만두기'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('hides drop when the negotiation cannot be dropped', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _chat(detail: roomDetail(id: _room, canDrop: false)));
      await _openMenu(tester);

      expect(find.text('신고하기'), findsOneWidget);
      expect(find.text('협의 그만두기'), findsNothing);
      handle.dispose();
    });

    testWidgets('hides block once I blocked the other side', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        _chat(detail: roomDetail(id: _room, blockedByMe: true)),
      );
      await _openMenu(tester);

      expect(find.text('차단하기'), findsNothing);
      expect(find.text('신고하기'), findsOneWidget);
      handle.dispose();
    });
  });

  group('block', () {
    testWidgets('asks first and closes the room for me after confirming', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);

      await _pick(tester, '차단하기');
      expect(find.text('모아 스튜디오님을 차단할까요?'), findsOneWidget);
      expect(
        find.text('이 대화방에서 서로 메시지를 보낼 수 없고, 추천에도 나오지 않아요.'),
        findsOneWidget,
      );
      expect(chat.blocked, isEmpty);

      await tester.tap(find.text('차단하기').last);
      await tester.pumpAndSettle();

      expect(chat.blocked, [_room]);
      expect(find.text('모아 스튜디오님을 차단할까요?'), findsNothing);
      expect(find.text('차단한 대화예요.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      handle.dispose();
    });

    testWidgets('does nothing when I cancel', (tester) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);

      await _pick(tester, '차단하기');
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(chat.blocked, isEmpty);
      expect(find.text('모아 스튜디오님을 차단할까요?'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      handle.dispose();
    });

    testWidgets('blocking shows the held-money message on conflict', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final chat = _chat()..blockFailure = const ChatFailure.conflict();
      await _open(tester, chat);

      await _pick(tester, '차단하기');
      await tester.tap(find.text('차단하기').last);
      await tester.pumpAndSettle();

      // 시트가 열린 채 문구가 보이고, 방은 그대로다.
      expect(find.text('진행 중인 협업이 있어요. 문의하기로 알려 주세요.'), findsOneWidget);
      expect(find.text('모아 스튜디오님을 차단할까요?'), findsOneWidget);
      expect(chat.blocked, isEmpty);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('차단한 대화예요.'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      handle.dispose();
    });

    testWidgets('shows a plain failure line when the network fails', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final chat = _chat()..blockFailure = const ChatFailure.failed();
      await _open(tester, chat);

      await _pick(tester, '차단하기');
      await tester.tap(find.text('차단하기').last);
      await tester.pumpAndSettle();

      expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ignores a second tap while the block is in flight', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);
      await _pick(tester, '차단하기');
      final hold = chat.holdBlock = Completer<void>();

      await tester.tap(find.text('차단하기').last);
      await tester.pump();
      await tester.tap(find.text('차단하기').last, warnIfMissed: false);
      await tester.pump();
      hold.complete();
      await tester.pumpAndSettle();

      expect(chat.blocked, [_room]);
      handle.dispose();
    });

    testWidgets('shows the other side only that the conversation ended', (
      tester,
    ) async {
      final chat = _chat();
      final realtime = FakeRealtimeConnection();
      await _open(tester, chat, realtime: realtime);
      expect(find.byType(TextField), findsOneWidget);

      // 서버가 방을 닫았다. 상대에게는 차단했다는 표시가 없다.
      chat.details[_room] = roomDetail(
        id: _room,
        status: ConversationStatus.closed,
      );
      realtime.emit(
        const ConversationUpdated(
          conversationId: _room,
          reason: ConversationUpdateReason.status,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('대화가 종료됐어요.'), findsOneWidget);
      expect(find.text('차단한 대화예요.'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('report', () {
    testWidgets('needs a reason before it can be sent', (tester) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);

      await _pick(tester, '신고하기');
      expect(find.text('광고·스팸'), findsOneWidget);
      expect(find.text('부적절한 말'), findsOneWidget);
      expect(find.text('사기 의심'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
      expect(find.text('자세한 내용 (선택)'), findsOneWidget);

      await tester.tap(find.text('신고하기').last);
      await tester.pumpAndSettle();
      expect(chat.reports, isEmpty);
      handle.dispose();
    });

    testWidgets('sends the reason and detail and confirms it', (tester) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);

      await _pick(tester, '신고하기');
      await tester.tap(find.text('사기 의심'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '  선입금을 요구해요  ');
      await tester.pump();
      await tester.tap(find.text('신고하기').last);
      await tester.pumpAndSettle();

      final report = chat.reports.single;
      expect(report.target.kind, ReportTargetKind.conversation);
      expect(report.target.id, _room);
      expect(report.reason, ReportReason.fraud);
      expect(report.detail, '선입금을 요구해요');
      expect(find.text('신고를 접수했어요.'), findsOneWidget);
      expect(find.text('자세한 내용 (선택)'), findsNothing);
      handle.dispose();
    });

    testWidgets('leaves the detail out when it is blank', (tester) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);

      await _pick(tester, '신고하기');
      await tester.tap(find.text('광고·스팸'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('신고하기').last);
      await tester.pumpAndSettle();

      expect(chat.reports.single.detail, isNull);
      expect(chat.reports.single.reason, ReportReason.spam);
      handle.dispose();
    });

    testWidgets('tells me when I already reported', (tester) async {
      final handle = tester.ensureSemantics();
      final chat = _chat()..reportFailure = const ChatFailure.conflict();
      await _open(tester, chat);

      await _pick(tester, '신고하기');
      await tester.tap(find.text('부적절한 말'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('신고하기').last);
      await tester.pumpAndSettle();

      expect(find.text('이미 신고했어요.'), findsOneWidget);
      expect(find.text('신고를 접수했어요.'), findsNothing);
      expect(find.text('자세한 내용 (선택)'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('keeps the detail within 500 characters', (tester) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      await _open(tester, chat);

      await _pick(tester, '신고하기');
      await tester.enterText(find.byType(TextField).last, '가' * 520);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller!.text.length, 500);
      handle.dispose();
    });
  });

  group('drop', () {
    testWidgets('dropping asks for a reason and shows the drop line', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final chat = _chat();
      final negotiation = FakeNegotiationRepository();
      final realtime = FakeRealtimeConnection();
      negotiation.onDropped = (_) {
        chat.details[_room] = roomDetail(
          id: _room,
          terms: termsVersion(),
          stage: ConversationStage.dropped,
          canDrop: false,
          canProposeTerms: false,
        );
      };
      await _open(tester, chat, negotiation: negotiation, realtime: realtime);

      await _pick(tester, '협의 그만두기');
      expect(find.text('협의를 그만둘까요?'), findsOneWidget);
      expect(find.text('상대에게는 이유를 알리지 않아요.'), findsOneWidget);
      expect(find.text('일정이 맞지 않아요'), findsOneWidget);
      expect(find.text('예산이 맞지 않아요'), findsOneWidget);
      expect(find.text('방향이 달라요'), findsOneWidget);
      expect(find.text('계속 협의하기'), findsOneWidget);

      // 이유를 고르기 전에는 그만둘 수 없다.
      await tester.tap(find.text('그만두기'));
      await tester.pumpAndSettle();
      expect(negotiation.dropped, isEmpty);

      await tester.tap(find.text('예산이 맞지 않아요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('그만두기'));
      await tester.pumpAndSettle();

      expect(negotiation.dropped.single.id, 'collab-$_room');
      expect(negotiation.dropped.single.reason, DropReason.budget);
      expect(find.text('협의를 그만둘까요?'), findsNothing);

      // 서버가 안내 줄을 소켓으로 밀어 준다.
      realtime.emit(
        MessageCreated(
          conversationId: _room,
          message: systemLine(seq: 2, text: '협의를 그만뒀어요.'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('협의를 그만뒀어요.'), findsOneWidget);
      expect(find.textContaining('협의가 끝났어요'), findsOneWidget);

      // 더는 그만둘 수 없다.
      await _openMenu(tester);
      expect(find.text('협의 그만두기'), findsNothing);
      handle.dispose();
    });

    testWidgets('keeps negotiating when I choose to continue', (tester) async {
      final handle = tester.ensureSemantics();
      final negotiation = FakeNegotiationRepository();
      await _open(tester, _chat(), negotiation: negotiation);

      await _pick(tester, '협의 그만두기');
      await tester.tap(find.text('일정이 맞지 않아요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('계속 협의하기'));
      await tester.pumpAndSettle();

      expect(negotiation.dropped, isEmpty);
      expect(find.text('협의를 그만둘까요?'), findsNothing);
      handle.dispose();
    });

    testWidgets('shows the server message when the drop is refused', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final negotiation = FakeNegotiationRepository()
        ..dropFailure = const NegotiationRejected(
          '브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.',
        );
      await _open(tester, _chat(), negotiation: negotiation);

      await _pick(tester, '협의 그만두기');
      await tester.tap(find.text('방향이 달라요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('그만두기'));
      await tester.pumpAndSettle();

      expect(find.text('브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('협의를 그만둘까요?'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('shows a plain failure line when the network fails', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final negotiation = FakeNegotiationRepository()
        ..dropFailure = const NegotiationFailure();
      await _open(tester, _chat(), negotiation: negotiation);

      await _pick(tester, '협의 그만두기');
      await tester.tap(find.text('기타').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('그만두기'));
      await tester.pumpAndSettle();

      expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('the report sheet does not overflow at 1.3x text scale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _chat(), largeText: true);

      await _pick(tester, '신고하기');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('광고·스팸'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('the sheets render in the dark theme', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _open(tester, _chat());

      await _pick(tester, '협의 그만두기');
      expect(find.text('협의를 그만둘까요?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}

import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/presentation/pages/message_request_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../store_home/store_home_harness.dart' show topPath;
import 'chat_fixtures.dart';
import 'chat_harness.dart';

FakeChatRepository _chatWithRequest() => FakeChatRepository(
  list: [
    requestSummary('r1'),
    summary('c1', name: '한그릇 라멘', preview: '내일 뵐게요'),
  ],
  details: {'r1': requestDetail('r1')},
  messages: {
    'r1': [message()],
  },
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'shows the canvas notice with the decline and open buttons on a request',
    (tester) async {
      await pumpChatApp(tester, chat: _chatWithRequest());
      await openChatTab(tester);
      await tester.tap(find.textContaining('모아 스튜디오').first);
      await tester.pumpAndSettle();

      expect(find.byType(MessageRequestPage), findsOneWidget);
      expect(find.text('메시지 요청'), findsOneWidget);
      expect(find.text('모아 스튜디오'), findsOneWidget);
      expect(find.text('느린 결, 일상의 주얼리 캠페인'), findsOneWidget);
      expect(
        find.text('“안녕하세요! 주얼리를 먼저 7일 정도 사용해보신 뒤, 11월 16일 이후 촬영이 가능하실까요?”'),
        findsOneWidget,
      );
      expect(find.text('오늘 오후 2:14'), findsOneWidget);
      expect(find.text('제작물'), findsOneWidget);
      expect(find.text('릴스 1편'), findsOneWidget);
      expect(find.text('제작비'), findsOneWidget);
      expect(find.text('30만 원'), findsOneWidget);
      expect(find.text('촬영'), findsOneWidget);
      expect(find.text('11/16 이후'), findsOneWidget);
      expect(
        find.text(
          '대화를 열어도 조건을 수락한 게 아니에요. 위 숫자는 협의 중인 제안이에요. 대화를 열기 전에는 내 연락처가 공개되지 않아요. 수락 후에도 대화 관리에서 차단하거나 신고할 수 있어요.',
        ),
        findsOneWidget,
      );
      expect(find.text('요청 거절'), findsOneWidget);
      expect(find.text('대화 열기'), findsOneWidget);
    },
  );

  testWidgets('opening a request opens the conversation', (tester) async {
    final chat = _chatWithRequest();
    await pumpChatApp(tester, chat: chat);
    await openRequest(tester, 'r1');

    await tester.tap(find.text('대화 열기'));
    await tester.pumpAndSettle();

    expect(chat.accepted, ['r1']);
    // 11이 대화방으로 바뀌어 열린다. 뒤로 가면 목록이다.
    expect(topPath(tester), AppRoutes.chat('r1'));
    expect(find.byType(MessageRequestPage), findsNothing);
  });

  testWidgets('does not send twice while opening', (tester) async {
    final chat = _chatWithRequest()..holdAccept = Completer<void>();
    await pumpChatApp(tester, chat: chat);
    await openRequest(tester, 'r1');

    await tester.tap(find.text('대화 열기'));
    await tester.pump();
    await tester.tap(find.text('대화 열기'));
    await tester.pump();
    chat.holdAccept!.complete();
    await tester.pumpAndSettle();

    expect(chat.accepted, ['r1']);
  });

  testWidgets('declining asks for confirmation and removes the request', (
    tester,
  ) async {
    final chat = _chatWithRequest();
    await pumpChatApp(tester, chat: chat);
    await openChatTab(tester);
    expect(find.text('메시지 요청 1'), findsOneWidget);
    await tester.tap(find.textContaining('모아 스튜디오').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('요청 거절'));
    await tester.pumpAndSettle();
    expect(find.text('요청을 거절할까요?'), findsOneWidget);
    expect(find.text('상대에게는 대화가 열리지 않았다고만 보여요.'), findsOneWidget);

    // 취소하면 아무것도 보내지 않는다.
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(chat.declined, isEmpty);
    expect(find.byType(MessageRequestPage), findsOneWidget);

    await tester.tap(find.text('요청 거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거절하기'));
    await tester.pumpAndSettle();

    expect(chat.declined, ['r1']);
    // 목록으로 돌아와 요청 묶음이 사라졌다.
    expect(topPath(tester), AppRoutes.chats);
    expect(find.text('메시지 요청 1'), findsNothing);
    expect(find.textContaining('한그릇 라멘'), findsOneWidget);
  });

  testWidgets(
    'shows a notice and stays when the request was already answered',
    (tester) async {
      final chat = _chatWithRequest()
        ..answerFailure = const ChatFailure.conflict();
      await pumpChatApp(tester, chat: chat);
      await openRequest(tester, 'r1');

      await tester.tap(find.text('대화 열기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 답한 메시지 요청이에요.'), findsOneWidget);
      expect(topPath(tester), AppRoutes.chatRequest('r1'));
    },
  );

  testWidgets('shows a notice and stays when answering fails', (tester) async {
    final chat = _chatWithRequest()..answerFailure = const ChatFailure.failed();
    await pumpChatApp(tester, chat: chat);
    await openRequest(tester, 'r1');

    await tester.tap(find.text('요청 거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거절하기'));
    await tester.pumpAndSettle();

    expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(topPath(tester), AppRoutes.chatRequest('r1'));
  });

  testWidgets('shows the shared error state with a retry when loading fails', (
    tester,
  ) async {
    final chat = _chatWithRequest()..failDetail = true;
    await pumpChatApp(tester, chat: chat);
    await openRequest(tester, 'r1');

    expect(find.text('메시지 요청을 불러오지 못했어요'), findsOneWidget);

    chat.failDetail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('대화 열기'), findsOneWidget);
  });

  testWidgets(
    'replaces itself with the room when the request is not mine to answer',
    (tester) async {
      final chat = FakeChatRepository(
        details: {'r2': requestDetail('r2', status: ConversationStatus.open)},
      );
      await pumpChatApp(tester, chat: chat);
      await openRequest(tester, 'r2');

      expect(topPath(tester), AppRoutes.chat('r2'));
      expect(find.text('대화 열기'), findsNothing);
    },
  );

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final chat = FakeChatRepository(
      details: {'r1': requestDetail('r1', name: '아주 긴 이름의 스튜디오 이름이 계속 이어집니다')},
      messages: {
        'r1': [message(text: '아주 긴 첫 메시지 ' * 12)],
      },
    );
    await pumpChatApp(tester, chat: chat, smallPhoneLargeText: true);
    await openRequest(tester, 'r1');

    expect(tester.takeException(), isNull);
    expect(find.text('요청 거절'), findsOneWidget);
    expect(find.text('대화 열기'), findsOneWidget);
  });

  testWidgets('renders in the dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpChatApp(tester, chat: _chatWithRequest());
    await openRequest(tester, 'r1');

    expect(tester.takeException(), isNull);
    expect(find.text('대화 열기'), findsOneWidget);
  });
}

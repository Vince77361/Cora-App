import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/chat/presentation/pages/conversation_list_page.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_home/store_home_harness.dart' show topPath;
import 'chat_fixtures.dart';
import 'chat_harness.dart';

Finder _nav(String label) =>
    find.descendant(of: find.byType(CoraBottomNav), matching: find.text(label));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('groups message requests above the conversations', (
    tester,
  ) async {
    final chat = FakeChatRepository(
      list: [
        requestSummary('r1', name: '모아 스튜디오'),
        summary('c1', name: '한그릇 라멘', preview: '내일 뵐게요'),
      ],
    );
    await pumpChatApp(tester, chat: chat);
    await openChatTab(tester);

    expect(topPath(tester), AppRoutes.chats);
    expect(find.byType(ConversationListPage), findsOneWidget);
    expect(find.text('대화'), findsWidgets);
    expect(find.text('메시지 요청 1'), findsOneWidget);
    final request = tester.getTopLeft(find.textContaining('모아 스튜디오').first).dy;
    final conversation = tester
        .getTopLeft(find.textContaining('한그릇 라멘').first)
        .dy;
    expect(request, lessThan(conversation));
    expect(find.text('내일 뵐게요'), findsOneWidget);
  });

  testWidgets('shows the time, the context tail and the unread count', (
    tester,
  ) async {
    final chat = FakeChatRepository(
      list: [
        summary(
          'c1',
          name: '한그릇 라멘',
          contextLabel: '한그릇 라멘 · 성수점',
          unread: 3,
          at: DateTime.utc(2026, 11, 11, 6, 20),
        ),
        summary('c2', name: '조용한 사진관', unread: 0, muted: true),
      ],
    );
    await pumpChatApp(tester, chat: chat);
    await openChatTab(tester);

    expect(find.text('오후 3:20'), findsWidgets);
    expect(find.textContaining('한그릇 라멘 · 성수점'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // 읽지 않은 것이 없으면 숫자를 숨기고, 알림을 끈 방에는 종 꺼짐 표시가 붙는다.
    expect(find.text('0'), findsNothing);
    expect(find.byKey(const ValueKey('muted-c2')), findsOneWidget);
    expect(find.byKey(const ValueKey('muted-c1')), findsNothing);
  });

  testWidgets('tells the requester that the request waits or was declined', (
    tester,
  ) async {
    final chat = FakeChatRepository(
      list: [
        summary('c1', status: ConversationStatus.requested),
        summary('c2', name: '다른 가게', status: ConversationStatus.declined),
        summary('c3', name: '닫힌 방', status: ConversationStatus.closed),
      ],
    );
    await pumpChatApp(tester, chat: chat);
    await openChatTab(tester);

    // 내가 보낸 요청은 묶음이 아니라 일반 줄이다.
    expect(find.textContaining('메시지 요청'), findsNothing);
    expect(find.text('수락을 기다리고 있어요'), findsOneWidget);
    expect(find.text('대화가 열리지 않았어요.'), findsOneWidget);
    expect(find.text('대화가 종료됐어요.'), findsOneWidget);
  });

  testWidgets('shows the shared empty and error states on the list', (
    tester,
  ) async {
    final chat = FakeChatRepository()..failList = true;
    await pumpChatApp(tester, chat: chat);
    await openChatTab(tester);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('대화를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.'), findsOneWidget);

    chat.failList = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('아직 대화가 없어요.'), findsOneWidget);
    expect(find.text('서로 관심이 닿거나 오퍼가 수락되면 대화가 열려요.'), findsOneWidget);
  });

  testWidgets('refreshes the list when a message arrives over the socket', (
    tester,
  ) async {
    final chat = FakeChatRepository(list: [summary('c1', preview: '첫 메시지')]);
    final realtime = FakeRealtimeConnection();
    await pumpChatApp(tester, chat: chat, realtime: realtime);
    await openChatTab(tester);
    expect(find.text('첫 메시지'), findsOneWidget);

    chat.list = [summary('c1', preview: '새 메시지', unread: 1)];
    realtime.emit(
      MessageCreated(conversationId: 'c1', message: message(seq: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.text('새 메시지'), findsOneWidget);
    expect(find.text('첫 메시지'), findsNothing);
  });

  testWidgets('refreshes the list when a room changes or the socket is back', (
    tester,
  ) async {
    final chat = FakeChatRepository(list: [summary('c1', preview: 'A')]);
    final realtime = FakeRealtimeConnection();
    await pumpChatApp(tester, chat: chat, realtime: realtime);
    await openChatTab(tester);
    final before = chat.listCalls;

    realtime.emit(
      const ConversationUpdated(
        conversationId: 'c1',
        reason: ConversationUpdateReason.status,
      ),
    );
    await tester.pumpAndSettle();
    expect(chat.listCalls, before + 1);

    realtime.emitReconnected();
    await tester.pumpAndSettle();
    expect(chat.listCalls, before + 2);
  });

  testWidgets('keeps what it shows when a refresh fails', (tester) async {
    final chat = FakeChatRepository(list: [summary('c1', preview: '그대로')]);
    final realtime = FakeRealtimeConnection();
    await pumpChatApp(tester, chat: chat, realtime: realtime);
    await openChatTab(tester);

    chat.failList = true;
    realtime.emitReconnected();
    await tester.pumpAndSettle();

    expect(find.text('그대로'), findsOneWidget);
    expect(find.text('대화를 불러오지 못했어요'), findsNothing);
  });

  testWidgets('a conversation row opens the room and a request opens 11', (
    tester,
  ) async {
    final chat = FakeChatRepository(
      list: [
        requestSummary('r1'),
        summary('c1', name: '한그릇 라멘'),
      ],
      details: {'r1': requestDetail('r1')},
    );
    await pumpChatApp(tester, chat: chat);
    await openChatTab(tester);

    await tester.tap(find.textContaining('한그릇 라멘'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.chat('c1'));

    routerOf(tester).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('모아 스튜디오').first);
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.chatRequest('r1'));
  });

  testWidgets('the chat tab is live for store, brand and creator', (
    tester,
  ) async {
    for (final role in UserRole.values) {
      // 역할마다 새 앱이다(같은 자리의 ProviderScope는 override 개수를 바꿀 수 없다).
      await tester.pumpWidget(const SizedBox());
      await pumpChatApp(
        tester,
        role: role,
        chat: FakeChatRepository(list: [summary('c1')]),
      );
      await openChatTab(tester);

      expect(topPath(tester), AppRoutes.chats, reason: '$role');
      expect(find.byType(ConversationListPage), findsOneWidget);
      expect(find.text('준비 중이에요.'), findsNothing, reason: '$role');
      expect(find.byType(CoraBottomNav), findsOneWidget, reason: '$role');
      // 다른 메뉴는 그대로다: 다시 `대화`를 눌러도 그 자리다.
      await tester.tap(_nav('대화'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.chats, reason: '$role');
    }
  });

  testWidgets('the chat tab leads back to the role home', (tester) async {
    await pumpChatApp(tester, role: UserRole.creator);
    await openChatTab(tester);

    await tester.tap(_nav('발견'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creator);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final chat = FakeChatRepository(
      list: [
        requestSummary(
          'r1',
          name: '아주 긴 이름의 스튜디오 이름이 계속 이어집니다',
          preview: '아주 긴 첫 메시지가 한 줄에 다 들어가지 않을 만큼 길게 이어집니다. 정말로 길어요.',
        ),
        summary(
          'c1',
          name: '한그릇 라멘',
          contextLabel: '아주 긴 캠페인 한 줄이 이름 옆에 붙어서 넘칠 수 있어요',
          unread: 120,
          muted: true,
        ),
      ],
    );
    await pumpChatApp(tester, chat: chat, smallPhoneLargeText: true);
    await openChatTab(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets(
    'starts the realtime connection while signed in and stops after',
    (tester) async {
      final realtime = FakeRealtimeConnection();
      final auth = FakeAuthRepository(
        session: FakeAuthRepository.signedInSession,
      );
      usePhone(tester);
      await pumpCoraApp(
        tester,
        auth: auth,
        me: FakeMeRepository(role: UserRole.brand),
        overrides: [realtimeConnectionProvider.overrideWithValue(realtime)],
      );
      expect(realtime.starts, 1);
      expect(realtime.stops, 0);

      await auth.signOut();
      await tester.pumpAndSettle();

      expect(realtime.stops, greaterThanOrEqualTo(1));
    },
  );
}

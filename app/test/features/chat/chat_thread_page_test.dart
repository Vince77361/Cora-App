import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/domain/message.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/chat/presentation/pages/chat_thread_page.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, OfferTerms, Reward, Voucher;
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import '../store_home/store_home_harness.dart' show topPath;
import 'chat_fixtures.dart';
import 'chat_harness.dart';

const _room = 'room-1';

const _storeTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(voucher: Voucher(name: '2인 식사권', value: 40000)),
);

FakeChatRepository _chat({
  ConversationDetail? detail,
  List<ChatMessage>? messages,
}) => FakeChatRepository(
  details: {_room: detail ?? roomDetail(id: _room, terms: termsVersion())},
  messages: {
    _room:
        messages ??
        [
          message(seq: 1),
          message(
            seq: 2,
            mine: true,
            text: '네, 가능해요. 대신 23일부터 시작하면 더 여유 있게 쓸 수 있어요.',
          ),
        ],
  },
);

Future<void> _open(
  WidgetTester tester,
  FakeChatRepository chat, {
  UserRole role = UserRole.creator,
  FakeRealtimeConnection? realtime,
  FakeDiscoveryRepository? discovery,
  FakeCollaborationRepository? collaborations,
  bool largeText = false,
}) async {
  await pumpChatApp(
    tester,
    role: role,
    chat: chat,
    realtime: realtime,
    discovery: discovery,
    collaborations: collaborations,
    smallPhoneLargeText: largeText,
  );
  await pushRoute(tester, AppRoutes.chat(_room));
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('보내기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the terms summary and status line in the header', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _chat());

    expect(find.byType(ChatThreadPage), findsOneWidget);
    expect(find.text('모아 스튜디오'), findsOneWidget);
    expect(find.text('느린 결, 일상의 주얼리 캠페인'), findsOneWidget);
    expect(
      find.text('릴스 1편, 35만 원 + 제품, 11월 23일 시작\n조건 버전 2 · 브랜드 확인 대기'),
      findsOneWidget,
    );
    // 날짜 구분선, 상대와 내 말풍선, 입력란 안내.
    expect(find.text('11월 11일'), findsOneWidget);
    expect(find.textContaining('주얼리를 먼저 7일'), findsOneWidget);
    expect(find.textContaining('네, 가능해요'), findsOneWidget);
    expect(find.text('메시지를 입력하세요'), findsOneWidget);
    expect(find.bySemanticsLabel('대화 관리'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('opens the agreement when the terms summary is tapped', (
    tester,
  ) async {
    await _open(tester, _chat());

    await tester.tap(find.textContaining('릴스 1편, 35만 원'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.collaborationAgreement('collab-$_room'));
  });

  testWidgets('shows the store offer reward line without a status line', (
    tester,
  ) async {
    final chat = _chat(
      detail: roomDetail(
        id: _room,
        kind: CollaborationKind.storeOffer,
        stage: ConversationStage.contracted,
        canProposeTerms: false,
        storeTerms: _storeTerms,
      ),
    );
    await _open(tester, chat);

    expect(find.textContaining('2인 식사권'), findsOneWidget);
    expect(find.textContaining('조건 버전'), findsNothing);
    // 가게 오퍼의 조건 주고받기는 대화방이 열리기 전에 끝난다.
    await tester.tap(find.textContaining('2인 식사권'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.chat(_room));
  });

  testWidgets('shows a retry action on a failed bubble', (tester) async {
    final chat = _chat();
    await _open(tester, chat);
    chat.sendFailure = const ChatFailure.failed();

    await _type(tester, '안녕하세요');
    await _tapSend(tester);

    expect(find.text('안녕하세요'), findsOneWidget);
    expect(find.text('보내지 못했어요'), findsOneWidget);
    expect(find.text('다시 보내기'), findsOneWidget);

    // 네트워크가 돌아오고 다시 보낸다. 서버에는 한 번만 저장된다.
    chat.sendFailure = null;
    await tester.tap(find.text('다시 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('보내지 못했어요'), findsNothing);
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(chat.sends.map((s) => s.clientId).toSet(), hasLength(1));
    expect(chat.messages[_room]!.where((m) => m.text == '안녕하세요'), hasLength(1));
  });

  testWidgets('clears the input and shows my message right away', (
    tester,
  ) async {
    final chat = _chat();
    await _open(tester, chat);

    await _type(tester, '곧 보낼게요');
    await _tapSend(tester);

    expect(find.text('곧 보낼게요'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(chat.sends, hasLength(1));
  });

  testWidgets('shows a message the other side sends through the socket', (
    tester,
  ) async {
    final chat = _chat();
    final realtime = FakeRealtimeConnection();
    await _open(tester, chat, realtime: realtime);

    realtime.emit(
      MessageCreated(
        conversationId: _room,
        message: message(seq: 3, text: '방금 보냈어요'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('방금 보냈어요'), findsOneWidget);
  });

  testWidgets('renders a content card and a system line', (tester) async {
    final chat = _chat(
      messages: [message(seq: 1), systemLine(seq: 2), cardMessage(seq: 3)],
    );
    await _open(tester, chat);

    expect(find.text('조건 버전 2를 크리에이터가 확인했어요.'), findsOneWidget);
    expect(find.text('콘텐츠 카드'), findsOneWidget);
    expect(find.text('이런 분위기로 찍을게요'), findsOneWidget);
  });

  testWidgets('puts a day divider where the Korean date changes', (
    tester,
  ) async {
    final chat = _chat(
      messages: [
        message(seq: 1, at: DateTime.utc(2026, 11, 10, 3)),
        message(seq: 2, at: DateTime.utc(2026, 11, 10, 14, 30)),
        message(seq: 3, at: DateTime.utc(2026, 11, 11, 3)),
      ],
    );
    await _open(tester, chat);

    // 10일 14:30 UTC는 한국 시간으로 11일 새벽이다.
    expect(find.text('11월 10일'), findsOneWidget);
    expect(find.text('11월 11일'), findsOneWidget);
  });

  testWidgets('shows the empty room line', (tester) async {
    await _open(tester, _chat(messages: []));

    expect(find.text('첫 메시지를 보내 보세요.'), findsOneWidget);
  });

  testWidgets('the attach menu lists my content card for a creator', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final chat = _chat();
    await _open(tester, chat);

    await tester.tap(find.bySemanticsLabel('콘텐츠 카드 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('내 콘텐츠 카드'), findsOneWidget);
    expect(find.text('조건 수정 제안'), findsOneWidget);

    await tester.tap(find.text('내 콘텐츠 카드'));
    await tester.pumpAndSettle();

    expect(chat.sends.single.kind, MessageKind.contentCard);
    expect(find.text('내 콘텐츠 카드'), findsNothing);
    expect(find.text('이런 분위기로 찍을게요'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the attach menu hides the content card for a brand', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final chat = _chat(
      detail: roomDetail(
        id: _room,
        terms: termsVersion(),
        myRole: ChatRole.commissioner,
        canSendContentCard: false,
      ),
    );
    await _open(tester, chat, role: UserRole.brand);

    await tester.tap(find.bySemanticsLabel('콘텐츠 카드 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('내 콘텐츠 카드'), findsNothing);
    expect(find.text('조건 수정 제안'), findsOneWidget);

    await tester.tap(find.text('조건 수정 제안'));
    await tester.pumpAndSettle();
    expect(
      topPath(tester),
      AppRoutes.collaborationTermsPropose('collab-$_room'),
    );
    handle.dispose();
  });

  testWidgets(
    'tapping elsewhere closes the attach menu and still presses the button',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _chat());

      await tester.tap(find.bySemanticsLabel('콘텐츠 카드 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('내 콘텐츠 카드'), findsOneWidget);

      // 한 번 눌러 메뉴를 닫으면서 `대화 관리`도 연다.
      await tester.tap(find.bySemanticsLabel('대화 관리'));
      await tester.pumpAndSettle();
      expect(find.text('내 콘텐츠 카드'), findsNothing);
      expect(find.text('알림 끄기'), findsOneWidget);

      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      // 더하기를 다시 누르면 열리고, 한 번 더 누르면 닫힌다.
      await tester.tap(find.bySemanticsLabel('콘텐츠 카드 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('내 콘텐츠 카드'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('콘텐츠 카드 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('내 콘텐츠 카드'), findsNothing);
      handle.dispose();
    },
  );

  testWidgets('has no attach button when there is nothing to attach', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final chat = _chat(
      detail: roomDetail(
        id: _room,
        terms: termsVersion(),
        stage: ConversationStage.contracted,
        canSendContentCard: false,
        canProposeTerms: false,
      ),
    );
    await _open(tester, chat);

    expect(find.bySemanticsLabel('콘텐츠 카드 보내기'), findsNothing);
    handle.dispose();
  });

  testWidgets('an inquiry shows like campaign to the creator only', (
    tester,
  ) async {
    final inquiry = ConversationStage.inquiry;
    final campaign = CampaignTerms(
      fee: 300000,
      format: ContentFormat.reels,
      productProvided: true,
      startFrom: DateTime(2026, 11, 16),
    );
    final creatorChat = _chat(
      detail: roomDetail(
        id: _room,
        stage: inquiry,
        campaignTerms: campaign,
        canLikeCampaign: true,
        canProposeTerms: false,
      ),
    );
    final discovery = FakeDiscoveryRepository();
    final collaborations = FakeCollaborationRepository(
      active: [
        collaboration(
          id: 'collab-$_room',
          kind: CollaborationKind.brandContract,
          campaign: const CollaborationCampaign(
            id: 'camp-9',
            brandName: '모아 스튜디오',
            headline: '느린 결, 일상의 주얼리 캠페인',
          ),
        ),
      ],
    );
    await _open(
      tester,
      creatorChat,
      discovery: discovery,
      collaborations: collaborations,
    );

    expect(
      find.text('릴스 1편, 30만 원 + 제품, 11월 16일 시작\n서로 관심 전 · 조건 문의 중'),
      findsOneWidget,
    );
    expect(find.text('관심 보내기'), findsOneWidget);
    // 조건 합의는 아직 없다.
    await tester.tap(find.textContaining('서로 관심 전'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.chat(_room));

    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();

    expect(
      discovery.decisions.single.target,
      const DiscoveryTarget.campaign('camp-9'),
    );
    expect(discovery.decisions.single.outcome, SwipeOutcome.like);
    expect(find.text('관심 보냄'), findsOneWidget);
  });

  testWidgets('an inquiry shows no like button to the brand', (tester) async {
    final chat = _chat(
      detail: roomDetail(
        id: _room,
        stage: ConversationStage.inquiry,
        myRole: ChatRole.commissioner,
        campaignTerms: CampaignTerms(
          fee: 300000,
          format: ContentFormat.reels,
          productProvided: false,
          startFrom: DateTime(2026, 11, 16),
        ),
        canLikeCampaign: false,
        canProposeTerms: false,
        canSendContentCard: false,
      ),
    );
    await _open(tester, chat, role: UserRole.brand);

    expect(find.textContaining('서로 관심 전 · 조건 문의 중'), findsOneWidget);
    expect(find.text('관심 보내기'), findsNothing);
  });

  testWidgets('shows the count limit and turns the send button off', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final chat = _chat();
    await _open(tester, chat);

    await _type(tester, '가' * 1001);
    expect(find.text('1,000자까지 보낼 수 있어요.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('보내기'));
    await tester.pump();
    expect(chat.sends, isEmpty);

    await _type(tester, '가' * 1000);
    expect(find.text('1,000자까지 보낼 수 있어요.'), findsNothing);
    handle.dispose();
  });

  testWidgets('replaces the input while the request waits for the other side', (
    tester,
  ) async {
    final chat = _chat(
      detail: roomDetail(
        id: _room,
        status: ConversationStatus.requested,
        requestedByMe: true,
        canProposeTerms: false,
        canSendContentCard: false,
      ),
    );
    await _open(tester, chat);

    expect(find.text('상대가 수락하면 대화를 이어갈 수 있어요.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('replaces the input in a blocked room', (tester) async {
    final chat = _chat(
      detail: roomDetail(id: _room, blockedByMe: true, canProposeTerms: false),
    );
    await _open(tester, chat);

    expect(find.text('차단한 대화예요.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the menu turns the room notifications off and on', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final chat = _chat();
    await _open(tester, chat);

    await tester.tap(find.bySemanticsLabel('대화 관리'));
    await tester.pumpAndSettle();
    expect(find.text('알림 끄기'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    await tester.tap(find.text('알림 끄기'));
    await tester.pumpAndSettle();
    expect(chat.mutes.single.muted, isTrue);

    await tester.tap(find.bySemanticsLabel('대화 관리'));
    await tester.pumpAndSettle();
    expect(find.text('알림 켜기'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('알림 켜기'), findsNothing);
    expect(chat.mutes, hasLength(1));
    handle.dispose();
  });

  testWidgets('opens the request screen for a request waiting for me', (
    tester,
  ) async {
    final chat = FakeChatRepository(
      details: {_room: requestDetail(_room)},
      messages: {
        _room: [message()],
      },
    );
    await _open(tester, chat);

    expect(topPath(tester), AppRoutes.chatRequest(_room));
  });

  testWidgets('shows a retry state when the room cannot be read', (
    tester,
  ) async {
    final chat = _chat()..failDetail = true;
    await _open(tester, chat);

    expect(find.text('대화방을 불러오지 못했어요'), findsOneWidget);
    chat.failDetail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('주얼리를 먼저 7일'), findsOneWidget);
  });

  testWidgets('renders in the dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _open(tester, _chat());

    expect(find.textContaining('주얼리를 먼저 7일'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final chat = _chat(
      messages: [
        message(seq: 1),
        message(seq: 2, mine: true, text: '아주 긴 말풍선 ' * 12),
        systemLine(seq: 3),
        cardMessage(seq: 4),
      ],
    );
    await _open(tester, chat, largeText: true);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('이런 분위기로 찍을게요'), findsOneWidget);
  });
}

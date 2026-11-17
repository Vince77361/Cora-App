import 'dart:async';

import 'package:cora/core/time/clock.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/domain/message.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/chat/presentation/viewmodels/chat_thread_view_model.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import 'chat_fixtures.dart';

const _room = 'room-1';

class _Harness {
  _Harness({FakeChatRepository? chat, List<ChatMessage>? initial})
    : chat =
          chat ??
          (FakeChatRepository(
            details: {_room: roomDetail(id: _room)},
            messages: {
              _room:
                  initial ??
                  [message(seq: 1), message(seq: 2), message(seq: 3)],
            },
          )) {
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(this.chat),
        realtimeConnectionProvider.overrideWithValue(realtime),
        currentUserIdProvider.overrideWithValue('me'),
        clockProvider.overrideWithValue(FakeClock()),
        collaborationRepositoryProvider.overrideWithValue(collaborations),
        discoveryRepositoryProvider.overrideWithValue(discovery),
      ],
    );
  }

  final FakeChatRepository chat;
  final realtime = FakeRealtimeConnection();
  final collaborations = FakeCollaborationRepository();
  final discovery = FakeDiscoveryRepository();
  late final ProviderContainer container;

  Future<ChatThreadViewModel> open() async {
    // autoDispose라서 듣는 쪽이 있어야 버려지지 않는다.
    container.listen(chatThreadViewModelProvider(_room), (_, _) {});
    await container.read(chatThreadViewModelProvider(_room).future);
    return container.read(chatThreadViewModelProvider(_room).notifier);
  }

  ChatThreadState get state =>
      container.read(chatThreadViewModelProvider(_room)).requireValue;

  List<int?> get seqs => [for (final m in state.messages) m.seq];

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void deliver(ChatMessage m) =>
      realtime.emit(MessageCreated(conversationId: _room, message: m));

  void dispose() => container.dispose();
}

void main() {
  test('merges by sequence number in order without duplicates', () {
    final merged = mergeMessages(
      [message(seq: 1), message(seq: 3)],
      [message(seq: 4), message(seq: 2), message(seq: 3)],
    );
    expect([for (final m in merged) m.seq], [1, 2, 3, 4]);
  });

  test('finds the last sequence number that is contiguous from the start', () {
    expect(contiguousLastSeq([]), 0);
    expect(contiguousLastSeq([message(seq: 5), message(seq: 6)]), 6);
    expect(
      contiguousLastSeq([message(seq: 1), message(seq: 2), message(seq: 6)]),
      2,
    );
  });

  test(
    'keeps messages in sequence order when they arrive out of order',
    () async {
      final h = _Harness(initial: [message(seq: 1)]);
      addTearDown(h.dispose);
      await h.open();
      // 서버에는 2, 3이 있다. 3이 먼저 오고 받는 사이(서버 읽기가 늦다)에 2가 온다.
      final two = h.chat.serverAdds(_room);
      final three = h.chat.serverAdds(_room);
      h.chat.holdFetch = Completer<void>();

      h.deliver(three);
      await h.settle();
      h.deliver(two);
      await h.settle();
      expect(h.seqs, [1, 2, 3]);

      h.chat.holdFetch!.complete();
      await h.settle();
      expect(h.seqs, [1, 2, 3]);
    },
  );

  test('fills a gap by fetching after the last sequence number', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.open();
    h.chat.serverAdds(_room);
    h.chat.serverAdds(_room);
    final six = h.chat.serverAdds(_room);
    h.chat.fetches.clear();

    // 3 다음에 6이 왔다. 4와 5는 서버에서 받는다.
    h.deliver(six);
    await h.settle();

    expect(h.chat.fetches.first.afterSeq, 3);
    expect(h.seqs, [1, 2, 3, 4, 5, 6]);
  });

  test(
    'stops after a bounded number of fetches when a gap is never filled',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.open();
      // 서버에는 4가 영영 없다(번호 5만 있다).
      h.chat.messages[_room]!.add(message(seq: 5));
      h.chat.fetches.clear();

      h.deliver(message(seq: 5));
      await h.settle();
      await h.settle();
      final first = h.chat.fetches.length;

      // 이어진 번호(3)가 늘지 않으면 거기서 멈춘다. 두드리기를 계속하지 않는다.
      expect(first, inInclusiveRange(1, 2));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(h.chat.fetches.length, first);
      expect(h.seqs, [1, 2, 3, 5]);

      // 다음 재연결은 다시 시도한다.
      h.realtime.emitReconnected();
      await h.settle();
      await h.settle();
      expect(h.chat.fetches.length, greaterThan(first));
      expect(h.chat.fetches.length, lessThanOrEqualTo(first + 2));
    },
  );

  test('does not mark messages beyond a gap as read', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final vm = await h.open();
    h.chat.messages[_room]!.add(message(seq: 6));
    vm.setVisible(true);

    h.deliver(message(seq: 6));
    await h.settle();

    expect(h.chat.reads, isEmpty);
  });

  test('fetches missed messages after a reconnect', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.open();
    h.chat.serverAdds(_room);
    h.chat.fetches.clear();

    h.realtime.emitReconnected();
    await h.settle();

    expect(h.chat.fetches.first.afterSeq, 3);
    expect(h.seqs, [1, 2, 3, 4]);
  });

  test('retries a failed message with the same client id', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final vm = await h.open();
    h.chat.sendFailure = const ChatFailure.failed();

    await vm.send('  안녕하세요  ');
    expect(h.state.pending.single.state, SendState.failed);
    expect(h.state.pending.single.text, '안녕하세요');
    final clientId = h.state.pending.single.clientId;

    h.chat.sendFailure = null;
    await vm.retry(clientId);

    expect(h.chat.sends.map((s) => s.clientId), [clientId, clientId]);
    expect(h.state.pending, isEmpty);
    expect(h.state.messages.last.text, '안녕하세요');
    expect(h.state.messages.last.mine, isTrue);
  });

  test(
    'does not duplicate a message the server already saved before the response was lost',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final vm = await h.open();
      h.chat.lostResponse = const ChatFailure.failed();

      await vm.send('한 번만 가야 해요');
      expect(h.state.pending.single.state, SendState.failed);
      expect(h.chat.messages[_room]!.length, 4);

      h.chat.lostResponse = null;
      await vm.retry(h.state.pending.single.clientId);

      // 서버는 같은 clientId의 처음 행을 돌려줬고, 앱도 하나만 가진다.
      expect(h.chat.messages[_room]!.length, 4);
      expect(
        h.state.messages.where((m) => m.text == '한 번만 가야 해요'),
        hasLength(1),
      );
      expect(h.state.pending, isEmpty);
    },
  );

  test(
    'replaces the sending bubble when the socket delivers the same client id first',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final vm = await h.open();
      h.chat.holdSend = Completer<void>();

      unawaited(vm.send('안녕'));
      await h.settle();
      final pending = h.state.pending.single;
      expect(pending.state, SendState.sending);

      h.deliver(
        ChatMessage(
          id: 'm4',
          seq: 4,
          clientId: pending.clientId,
          kind: MessageKind.text,
          mine: true,
          text: '안녕',
          at: DateTime.utc(2026, 11, 11, 8),
        ),
      );
      await h.settle();
      expect(h.state.pending, isEmpty);
      expect(h.seqs, [1, 2, 3, 4]);

      h.chat.holdSend!.complete();
      await h.settle();
      expect(h.seqs, [1, 2, 3, 4]);
      expect(h.state.pending, isEmpty);
    },
  );

  test('ignores empty and over-long text', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final vm = await h.open();

    await vm.send('   ');
    await vm.send('가' * 1001);

    expect(h.chat.sends, isEmpty);
    expect(h.state.pending, isEmpty);
    await vm.send('가' * 1000);
    expect(h.chat.sends, hasLength(1));
  });

  test('sends the same card client id again after a failed card', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final vm = await h.open();
    h.chat.sendFailure = const ChatFailure.failed();

    expect(await vm.sendContentCard(), isFalse);
    expect(h.state.notice, isNotNull);

    h.chat.sendFailure = null;
    expect(await vm.sendContentCard(), isTrue);

    expect(h.chat.sends[0].clientId, h.chat.sends[1].clientId);
    expect(h.state.messages.last.kind, MessageKind.contentCard);
    expect(h.state.notice, isNull);
  });

  test('marks the last number read only while the screen is visible', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final vm = await h.open();
    await h.settle();
    // 이미 마지막 번호(3)까지 읽었다.
    vm.setVisible(true);
    expect(h.chat.reads, isEmpty);

    h.deliver(h.chat.serverAdds(_room));
    await h.settle();
    expect(h.chat.reads.map((r) => r.seq), [4]);

    vm.setVisible(false);
    h.deliver(h.chat.serverAdds(_room));
    await h.settle();
    expect(h.chat.reads.map((r) => r.seq), [4]);

    vm.setVisible(true);
    await h.settle();
    expect(h.chat.reads.map((r) => r.seq), [4, 5]);
  });

  test('reads 50 older messages when the user reaches the top', () async {
    final h = _Harness(
      initial: [for (var i = 1; i <= 120; i++) message(seq: i)],
    );
    addTearDown(h.dispose);
    final vm = await h.open();
    expect(h.seqs.first, 71);
    expect(h.state.hasOlder, isTrue);

    await vm.loadOlder();
    expect(h.chat.fetches.last.beforeSeq, 71);
    expect(h.seqs.first, 21);
    expect(h.state.hasOlder, isTrue);

    await vm.loadOlder();
    expect(h.seqs.first, 1);
    expect(h.seqs.length, 120);
    expect(h.state.hasOlder, isFalse);
  });

  test('refreshes the header when the conversation is updated', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.open();
    expect(h.state.detail.stage, ConversationStage.negotiating);
    h.chat.details[_room] = roomDetail(
      id: _room,
      stage: ConversationStage.agreed,
    );

    h.realtime.emit(
      const ConversationUpdated(
        conversationId: _room,
        reason: ConversationUpdateReason.terms,
      ),
    );
    await h.settle();

    expect(h.state.detail.stage, ConversationStage.agreed);
  });

  test('ignores events of other conversations', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.open();

    h.realtime.emit(
      MessageCreated(conversationId: 'other', message: message(seq: 4)),
    );
    await h.settle();

    expect(h.seqs, [1, 2, 3]);
  });

  test('toggles mute and keeps the old value when it fails', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final vm = await h.open();

    await vm.toggleMute();
    expect(h.chat.mutes.single.muted, isTrue);
    expect(h.state.detail.muted, isTrue);

    h.chat.muteFailure = const ChatFailure.failed();
    await vm.toggleMute();
    expect(h.state.detail.muted, isTrue);
    expect(h.state.notice, isNotNull);
  });

  test('sends a like to the campaign of the collaboration', () async {
    final chat = FakeChatRepository(
      details: {
        _room: roomDetail(
          id: _room,
          stage: ConversationStage.inquiry,
          canLikeCampaign: true,
        ),
      },
      messages: {
        _room: [message(seq: 1)],
      },
    );
    final h = _Harness(chat: chat);
    addTearDown(h.dispose);
    h.collaborations.active = [
      collaboration(
        id: 'collab-$_room',
        kind: CollaborationKind.brandContract,
        campaign: const CollaborationCampaign(
          id: 'camp-9',
          brandName: '모아 스튜디오',
          headline: '느린 결, 일상의 주얼리 캠페인',
        ),
      ),
    ];
    h.discovery.matchOn.add('camp-9');
    final vm = await h.open();
    // 서로 관심이 되면 서버가 머리를 바꾼다.
    chat.details[_room] = roomDetail(
      id: _room,
      stage: ConversationStage.matched,
    );

    await vm.likeCampaign();

    expect(
      h.discovery.decisions.single.target,
      const DiscoveryTarget.campaign('camp-9'),
    );
    expect(h.state.detail.stage, ConversationStage.matched);
    expect(h.state.likeSent, isTrue);
  });
}

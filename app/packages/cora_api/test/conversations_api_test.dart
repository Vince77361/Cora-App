//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:cora_api/api.dart';
import 'package:test/test.dart';

/// tests for ConversationsApi
void main() {
  // final instance = ConversationsApi();

  group('tests for ConversationsApi', () {
    // 메시지 요청을 수락해 대화를 연다. 받은 사람만. 협업은 INQUIRY에 남고, 요청을 보낸 사람에게 알린다.
    //
    //Future<ConversationDetailModel> acceptMessageRequest(String id) async
    test('test acceptMessageRequest', () async {
      // TODO
    });

    // 메시지 요청을 거절한다. 받은 사람만. 협업은 끝나 같은 캠페인으로 다시 요청할 수 없고, 상대에게 알리지 않는다.
    //
    //Future declineMessageRequest(String id) async
    test('test declineMessageRequest', () async {
      // TODO
    });

    // 방 머리: 상대, 협업 단계, 조건, 내가 할 수 있는 일.
    //
    //Future<ConversationDetailModel> getConversation(String id) async
    test('test getConversation', () async {
      // TODO
    });

    // 내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순. 내가 거절한 요청은 빠진다.
    //
    //Future<List<ConversationSummaryModel>> listConversations() async
    test('test listConversations', () async {
      // TODO
    });

    // 메시지를 번호 오름차순으로. afterSeq(빠진 번호 받기)나 beforeSeq(위로 넘기기)를 주고, 둘 다 없으면 마지막 50개.
    //
    //Future<List<MessageModel>> listMessages(String id, { int afterSeq, int beforeSeq, int limit }) async
    test('test listMessages', () async {
      // TODO
    });

    // 여기까지 읽었다고 알린다. 읽은 번호는 줄어들지 않는다.
    //
    //Future markConversationRead(String id, MarkReadDto markReadDto) async
    test('test markConversationRead', () async {
      // TODO
    });

    // 글이나 콘텐츠 카드를 보낸다. 같은 clientId로 다시 보내면 첫 메시지를 돌려준다. 열린 방에만 보낼 수 있다.
    //
    //Future<MessageModel> sendMessage(String id, SendMessageDto sendMessageDto) async
    test('test sendMessage', () async {
      // TODO
    });

    // 이 방의 알림을 끄거나 켠다.
    //
    //Future<MutedModel> setConversationMuted(String id, SetMutedDto setMutedDto) async
    test('test setConversationMuted', () async {
      // TODO
    });
  });
}

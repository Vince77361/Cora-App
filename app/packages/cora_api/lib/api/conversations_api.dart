//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ConversationsApi {
  ConversationsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 방 머리: 상대, 협업 단계, 조건, 내가 할 수 있는 일.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getConversationWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/conversations/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 방 머리: 상대, 협업 단계, 조건, 내가 할 수 있는 일.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<ConversationDetailModel?> getConversation(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getConversationWithHttpInfo(
      id,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'ConversationDetailModel',
      ) as ConversationDetailModel;
    }
    return null;
  }

  /// 내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순. 내가 거절한 요청은 빠진다.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listConversationsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/conversations';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순. 내가 거절한 요청은 빠진다.
  Future<List<ConversationSummaryModel>?> listConversations({
    Future<void>? abortTrigger,
  }) async {
    final response = await listConversationsWithHttpInfo(
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(
              responseBody, 'List<ConversationSummaryModel>') as List)
          .cast<ConversationSummaryModel>()
          .toList(growable: false);
    }
    return null;
  }

  /// 메시지를 번호 오름차순으로. afterSeq(빠진 번호 받기)나 beforeSeq(위로 넘기기)를 주고, 둘 다 없으면 마지막 50개.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [int] afterSeq:
  ///   이 번호보다 큰 메시지(빠진 번호를 받을 때).
  ///
  /// * [int] beforeSeq:
  ///   이 번호보다 작은 메시지(위로 넘겨 볼 때).
  ///
  /// * [int] limit:
  Future<Response> listMessagesWithHttpInfo(
    String id, {
    int? afterSeq,
    int? beforeSeq,
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/conversations/{id}/messages'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (afterSeq != null) {
      queryParams.addAll(_queryParams('', 'afterSeq', afterSeq));
    }
    if (beforeSeq != null) {
      queryParams.addAll(_queryParams('', 'beforeSeq', beforeSeq));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 메시지를 번호 오름차순으로. afterSeq(빠진 번호 받기)나 beforeSeq(위로 넘기기)를 주고, 둘 다 없으면 마지막 50개.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [int] afterSeq:
  ///   이 번호보다 큰 메시지(빠진 번호를 받을 때).
  ///
  /// * [int] beforeSeq:
  ///   이 번호보다 작은 메시지(위로 넘겨 볼 때).
  ///
  /// * [int] limit:
  Future<List<MessageModel>?> listMessages(
    String id, {
    int? afterSeq,
    int? beforeSeq,
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    final response = await listMessagesWithHttpInfo(
      id,
      afterSeq: afterSeq,
      beforeSeq: beforeSeq,
      limit: limit,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(
              responseBody, 'List<MessageModel>') as List)
          .cast<MessageModel>()
          .toList(growable: false);
    }
    return null;
  }

  /// 여기까지 읽었다고 알린다. 읽은 번호는 줄어들지 않는다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MarkReadDto] markReadDto (required):
  Future<Response> markConversationReadWithHttpInfo(
    String id,
    MarkReadDto markReadDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/conversations/{id}/read'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = markReadDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 여기까지 읽었다고 알린다. 읽은 번호는 줄어들지 않는다.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MarkReadDto] markReadDto (required):
  Future<void> markConversationRead(
    String id,
    MarkReadDto markReadDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await markConversationReadWithHttpInfo(
      id,
      markReadDto,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 글이나 콘텐츠 카드를 보낸다. 같은 clientId로 다시 보내면 첫 메시지를 돌려준다. 열린 방에만 보낼 수 있다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [SendMessageDto] sendMessageDto (required):
  Future<Response> sendMessageWithHttpInfo(
    String id,
    SendMessageDto sendMessageDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/conversations/{id}/messages'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = sendMessageDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 글이나 콘텐츠 카드를 보낸다. 같은 clientId로 다시 보내면 첫 메시지를 돌려준다. 열린 방에만 보낼 수 있다.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [SendMessageDto] sendMessageDto (required):
  Future<MessageModel?> sendMessage(
    String id,
    SendMessageDto sendMessageDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await sendMessageWithHttpInfo(
      id,
      sendMessageDto,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MessageModel',
      ) as MessageModel;
    }
    return null;
  }

  /// 이 방의 알림을 끄거나 켠다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [SetMutedDto] setMutedDto (required):
  Future<Response> setConversationMutedWithHttpInfo(
    String id,
    SetMutedDto setMutedDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/conversations/{id}/mute'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = setMutedDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 이 방의 알림을 끄거나 켠다.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [SetMutedDto] setMutedDto (required):
  Future<MutedModel?> setConversationMuted(
    String id,
    SetMutedDto setMutedDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await setConversationMutedWithHttpInfo(
      id,
      setMutedDto,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MutedModel',
      ) as MutedModel;
    }
    return null;
  }
}

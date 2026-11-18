//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class DiscoveryApi {
  DiscoveryApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 후보 비교(브랜드). 이 캠페인에서 내가 저장한 두 크리에이터를 같은 결과물 기준으로 견주고 다른 줄을 알려 준다. 팔로워 수는 없다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] a (required):
  ///   비교할 크리에이터 한 명.
  ///
  /// * [String] b (required):
  ///   비교할 다른 크리에이터.
  Future<Response> compareCandidatesWithHttpInfo(
    String a,
    String b, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/compare';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'a', a));
    queryParams.addAll(_queryParams('', 'b', b));

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

  /// 후보 비교(브랜드). 이 캠페인에서 내가 저장한 두 크리에이터를 같은 결과물 기준으로 견주고 다른 줄을 알려 준다. 팔로워 수는 없다.
  ///
  /// Parameters:
  ///
  /// * [String] a (required):
  ///   비교할 크리에이터 한 명.
  ///
  /// * [String] b (required):
  ///   비교할 다른 크리에이터.
  Future<CompareModel?> compareCandidates(
    String a,
    String b, {
    Future<void>? abortTrigger,
  }) async {
    final response = await compareCandidatesWithHttpInfo(
      a,
      b,
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
        'CompareModel',
      ) as CompareModel;
    }
    return null;
  }

  /// \"조건부터 질문하기\": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다. 협업(INQUIRY)과 메시지 요청 방과 첫 메시지가 한 번에 만들어진다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] campaignId (required):
  ///
  /// * [InquiryDto] inquiryDto (required):
  Future<Response> createInquiryWithHttpInfo(
    String campaignId,
    InquiryDto inquiryDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/received-proposals/{campaignId}/inquiry'
        .replaceAll('{campaignId}', campaignId);

    // ignore: prefer_final_locals
    Object? postBody = inquiryDto;

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

  /// \"조건부터 질문하기\": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다. 협업(INQUIRY)과 메시지 요청 방과 첫 메시지가 한 번에 만들어진다.
  ///
  /// Parameters:
  ///
  /// * [String] campaignId (required):
  ///
  /// * [InquiryDto] inquiryDto (required):
  Future<InquiryResultModel?> createInquiry(
    String campaignId,
    InquiryDto inquiryDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createInquiryWithHttpInfo(
      campaignId,
      inquiryDto,
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
        'InquiryResultModel',
      ) as InquiryResultModel;
    }
    return null;
  }

  /// 하트·저장 목록. 내가 하트를 보냈거나 저장한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InterestTab] tab:
  ///   saved(기본) = 내 하트 + 저장, mutual = 서로 관심, sent = 보낸 관심(응답 대기), held = 저장.
  Future<Response> listInterestsWithHttpInfo({
    InterestTab? tab,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/interests';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (tab != null) {
      queryParams.addAll(_queryParams('', 'tab', tab));
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

  /// 하트·저장 목록. 내가 하트를 보냈거나 저장한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).
  ///
  /// Parameters:
  ///
  /// * [InterestTab] tab:
  ///   saved(기본) = 내 하트 + 저장, mutual = 서로 관심, sent = 보낸 관심(응답 대기), held = 저장.
  Future<List<InterestCardModel>?> listInterests({
    InterestTab? tab,
    Future<void>? abortTrigger,
  }) async {
    final response = await listInterestsWithHttpInfo(
      tab: tab,
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
              responseBody, 'List<InterestCardModel>') as List)
          .cast<InterestCardModel>()
          .toList(growable: false);
    }
    return null;
  }

  /// 크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 하트 가운데 아직 결정하지 않은 것.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listReceivedProposalsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/received-proposals';

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

  /// 크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 하트 가운데 아직 결정하지 않은 것.
  Future<List<ProposalModel>?> listReceivedProposals({
    Future<void>? abortTrigger,
  }) async {
    final response = await listReceivedProposalsWithHttpInfo(
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
              responseBody, 'List<ProposalModel>') as List)
          .cast<ProposalModel>()
          .toList(growable: false);
    }
    return null;
  }

  /// 사장님 저장함: tab=saved는 내가 저장한 크리에이터, tab=sent는 내가 하트를 보낸 크리에이터(서로 관심 표지 포함). 가게 계정만 쓴다. 보낸 제안은 GET /offers/proposals를 쓴다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StoreInterestTab] tab:
  ///   saved(기본) = 내가 저장한 크리에이터, sent = 내가 하트를 보낸 크리에이터.
  Future<Response> listStoreInterestsWithHttpInfo({
    StoreInterestTab? tab,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/store-interests';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (tab != null) {
      queryParams.addAll(_queryParams('', 'tab', tab));
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

  /// 사장님 저장함: tab=saved는 내가 저장한 크리에이터, tab=sent는 내가 하트를 보낸 크리에이터(서로 관심 표지 포함). 가게 계정만 쓴다. 보낸 제안은 GET /offers/proposals를 쓴다.
  ///
  /// Parameters:
  ///
  /// * [StoreInterestTab] tab:
  ///   saved(기본) = 내가 저장한 크리에이터, sent = 내가 하트를 보낸 크리에이터.
  Future<List<StoreInterestCardModel>?> listStoreInterests({
    StoreInterestTab? tab,
    Future<void>? abortTrigger,
  }) async {
    final response = await listStoreInterestsWithHttpInfo(
      tab: tab,
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
              responseBody, 'List<StoreInterestCardModel>') as List)
          .cast<StoreInterestCardModel>()
          .toList(growable: false);
    }
    return null;
  }

  /// 하트(LIKE)·넘김(PASS)·저장(HOLD)을 저장한다. 브랜드·크리에이터는 반대쪽도 하트면 서로 관심(협업과 조건 버전 1)이 만들어진다. 사장님은 크리에이터에게만(campaign 없음) 결정하며 협업을 만들지 않는다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PutDecisionDto] putDecisionDto (required):
  Future<Response> putDecisionWithHttpInfo(
    PutDecisionDto putDecisionDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/decisions';

    // ignore: prefer_final_locals
    Object? postBody = putDecisionDto;

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

  /// 하트(LIKE)·넘김(PASS)·저장(HOLD)을 저장한다. 브랜드·크리에이터는 반대쪽도 하트면 서로 관심(협업과 조건 버전 1)이 만들어진다. 사장님은 크리에이터에게만(campaign 없음) 결정하며 협업을 만들지 않는다.
  ///
  /// Parameters:
  ///
  /// * [PutDecisionDto] putDecisionDto (required):
  Future<DecisionResultModel?> putDecision(
    PutDecisionDto putDecisionDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await putDecisionWithHttpInfo(
      putDecisionDto,
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
        'DecisionResultModel',
      ) as DecisionResultModel;
    }
    return null;
  }

  /// 넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PassReasonDto] passReasonDto (required):
  Future<Response> putPassReasonWithHttpInfo(
    PassReasonDto passReasonDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/decisions/pass-reason';

    // ignore: prefer_final_locals
    Object? postBody = passReasonDto;

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

  /// 넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
  ///
  /// Parameters:
  ///
  /// * [PassReasonDto] passReasonDto (required):
  Future<void> putPassReason(
    PassReasonDto passReasonDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await putPassReasonWithHttpInfo(
      passReasonDto,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 가게 카드를 넘긴다(가게 카드의 하트는 지원 API로 보낸다).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] storeId (required):
  Future<Response> putStorePassWithHttpInfo(
    String storeId, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/discovery/store-passes/{storeId}'.replaceAll('{storeId}', storeId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

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

  /// 가게 카드를 넘긴다(가게 카드의 하트는 지원 API로 보낸다).
  ///
  /// Parameters:
  ///
  /// * [String] storeId (required):
  Future<void> putStorePass(
    String storeId, {
    Future<void>? abortTrigger,
  }) async {
    final response = await putStorePassWithHttpInfo(
      storeId,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다. 서로 관심이 된 결정(사장님은 하트를 보낸 크리에이터가 그 가게에 지원해 있을 때)은 409다.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> undoLastDecisionWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/discovery/decisions/last';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다. 서로 관심이 된 결정(사장님은 하트를 보낸 크리에이터가 그 가게에 지원해 있을 때)은 409다.
  Future<UndoneDecisionModel?> undoLastDecision({
    Future<void>? abortTrigger,
  }) async {
    final response = await undoLastDecisionWithHttpInfo(
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
        'UndoneDecisionModel',
      ) as UndoneDecisionModel;
    }
    return null;
  }
}

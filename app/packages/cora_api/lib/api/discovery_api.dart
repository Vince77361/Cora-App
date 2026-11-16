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

  /// 관심·넘김·보류를 저장한다. 반대쪽도 관심이면 서로 관심(협업과 조건 버전 1)이 만들어진다.
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

  /// 관심·넘김·보류를 저장한다. 반대쪽도 관심이면 서로 관심(협업과 조건 버전 1)이 만들어진다.
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

  /// 가게 카드를 넘긴다(가게 카드의 관심은 지원 API로 보낸다).
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

  /// 가게 카드를 넘긴다(가게 카드의 관심은 지원 API로 보낸다).
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

  /// 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다.
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

  /// 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다.
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

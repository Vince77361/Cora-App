//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TermsApi {
  TermsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 이 판본 수락. 최신이 아니면 409 STALE_VERSION(본문에 latestVersion), 성과 추가가 있는데 인스타그램 연동이 없으면 크리에이터는 409.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [num] version (required):
  Future<Response> confirmTermsWithHttpInfo(
    String id,
    num version, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/terms/{version}/confirm'
        .replaceAll('{id}', id)
        .replaceAll('{version}', version.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

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

  /// 이 판본 수락. 최신이 아니면 409 STALE_VERSION(본문에 latestVersion), 성과 추가가 있는데 인스타그램 연동이 없으면 크리에이터는 409.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [num] version (required):
  Future<TermsVersionModel?> confirmTerms(
    String id,
    num version, {
    Future<void>? abortTrigger,
  }) async {
    final response = await confirmTermsWithHttpInfo(
      id,
      version,
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
        'TermsVersionModel',
      ) as TermsVersionModel;
    }
    return null;
  }

  /// 브랜드 계약의 가장 최근 조건 판본(당사자만).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getLatestTermsWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/terms/latest'.replaceAll('{id}', id);

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

  /// 브랜드 계약의 가장 최근 조건 판본(당사자만).
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<TermsLatestModel?> getLatestTerms(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getLatestTermsWithHttpInfo(
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
        'TermsLatestModel',
      ) as TermsLatestModel;
    }
    return null;
  }

  /// 조건 판본 이력(당사자만). 최신이 먼저이고 판본마다 바뀐 항목을 담는다. agreement는 최신 판본의 확인 상태, editable은 지금 수정 제안을 낼 수 있는가.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> listTermsVersionsWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/terms'.replaceAll('{id}', id);

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

  /// 조건 판본 이력(당사자만). 최신이 먼저이고 판본마다 바뀐 항목을 담는다. agreement는 최신 판본의 확인 상태, editable은 지금 수정 제안을 낼 수 있는가.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<TermsHistoryModel?> listTermsVersions(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await listTermsVersionsWithHttpInfo(
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
        'TermsHistoryModel',
      ) as TermsHistoryModel;
    }
    return null;
  }

  /// 새 판본을 낸다(조건 수정 제안). 빠진 항목은 직전 판본에서 옮기고 성과 추가는 null이면 끈다. 낸 쪽은 확인함이고 단계는 협의가 되며 크리에이터의 계약 동의는 취소된다. 최신 판본이 아니면 409 STALE_VERSION, 브랜드 결제가 진행 중이면 409, 바뀐 것이 없으면 400.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [ProposeRewardDto] proposeRewardDto (required):
  Future<Response> proposeRewardWithHttpInfo(
    String id,
    ProposeRewardDto proposeRewardDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/terms'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = proposeRewardDto;

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

  /// 새 판본을 낸다(조건 수정 제안). 빠진 항목은 직전 판본에서 옮기고 성과 추가는 null이면 끈다. 낸 쪽은 확인함이고 단계는 협의가 되며 크리에이터의 계약 동의는 취소된다. 최신 판본이 아니면 409 STALE_VERSION, 브랜드 결제가 진행 중이면 409, 바뀐 것이 없으면 400.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [ProposeRewardDto] proposeRewardDto (required):
  Future<TermsVersionModel?> proposeReward(
    String id,
    ProposeRewardDto proposeRewardDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await proposeRewardWithHttpInfo(
      id,
      proposeRewardDto,
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
        'TermsVersionModel',
      ) as TermsVersionModel;
    }
    return null;
  }
}

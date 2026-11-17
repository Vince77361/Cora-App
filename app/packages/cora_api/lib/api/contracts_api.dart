//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ContractsApi {
  ContractsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 크리에이터가 계약에 동의한다(브랜드보다 먼저). 협업이 합의(AGREED) 상태이고 termsVersion이 최신일 때만: 최신이 아니면 409 STALE_VERSION(latestVersion), 그 밖의 상태는 409 CONFLICT, 확인한 문구가 서버의 문구와 다르면 400. 같은 판본에 다시 동의하면 바뀌는 것 없이 같은 계약을 돌려준다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatorConsentDto] creatorConsentDto (required):
  Future<Response> consentContractAsCreatorWithHttpInfo(
    String id,
    CreatorConsentDto creatorConsentDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/collaborations/{id}/contract/creator-consent'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = creatorConsentDto;

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

  /// 크리에이터가 계약에 동의한다(브랜드보다 먼저). 협업이 합의(AGREED) 상태이고 termsVersion이 최신일 때만: 최신이 아니면 409 STALE_VERSION(latestVersion), 그 밖의 상태는 409 CONFLICT, 확인한 문구가 서버의 문구와 다르면 400. 같은 판본에 다시 동의하면 바뀌는 것 없이 같은 계약을 돌려준다.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatorConsentDto] creatorConsentDto (required):
  Future<ContractModel?> consentContractAsCreator(
    String id,
    CreatorConsentDto creatorConsentDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await consentContractAsCreatorWithHttpInfo(
      id,
      creatorConsentDto,
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
        'ContractModel',
      ) as ContractModel;
    }
    return null;
  }

  /// 계약 화면(당사자만). 양쪽이 같은 판본을 확인하기 전(NOT_READY)에는 최신 판본과 문구를 미리 보기로 준다. 브랜드에게는 동의하면 결제할 금액(quote)이 함께 간다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getContractWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/contract'.replaceAll('{id}', id);

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

  /// 계약 화면(당사자만). 양쪽이 같은 판본을 확인하기 전(NOT_READY)에는 최신 판본과 문구를 미리 보기로 준다. 브랜드에게는 동의하면 결제할 금액(quote)이 함께 간다.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<ContractModel?> getContract(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getContractWithHttpInfo(
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
        'ContractModel',
      ) as ContractModel;
    }
    return null;
  }
}

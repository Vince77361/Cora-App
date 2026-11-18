//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RecommendationsApi {
  RecommendationsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 크리에이터의 오늘 캠페인·가게 추천
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listCampaignRecommendationsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/recommendations/campaigns';

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

  /// 크리에이터의 오늘 캠페인·가게 추천
  Future<CampaignRecommendationsModel?> listCampaignRecommendations({
    Future<void>? abortTrigger,
  }) async {
    final response = await listCampaignRecommendationsWithHttpInfo(
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
        'CampaignRecommendationsModel',
      ) as CampaignRecommendationsModel;
    }
    return null;
  }

  /// 브랜드의 오늘 크리에이터 추천(진행 중인 캠페인 필요)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listCreatorRecommendationsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/recommendations/creators';

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

  /// 브랜드의 오늘 크리에이터 추천(진행 중인 캠페인 필요)
  Future<CreatorRecommendationsModel?> listCreatorRecommendations({
    Future<void>? abortTrigger,
  }) async {
    final response = await listCreatorRecommendationsWithHttpInfo(
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
        'CreatorRecommendationsModel',
      ) as CreatorRecommendationsModel;
    }
    return null;
  }

  /// 역할이 없는 사용자의 둘러보기 카드(읽기 전용)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPreviewCardsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/recommendations/preview';

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

  /// 역할이 없는 사용자의 둘러보기 카드(읽기 전용)
  Future<PreviewCardsModel?> listPreviewCards({
    Future<void>? abortTrigger,
  }) async {
    final response = await listPreviewCardsWithHttpInfo(
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
        'PreviewCardsModel',
      ) as PreviewCardsModel;
    }
    return null;
  }

  /// 사장님의 오늘 전체 둘러보기 크리에이터 카드(하루 최대 10장, 한국 시간 자정에 새로 채움)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listStoreCreatorRecommendationsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/recommendations/store-creators';

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

  /// 사장님의 오늘 전체 둘러보기 크리에이터 카드(하루 최대 10장, 한국 시간 자정에 새로 채움)
  Future<StoreCreatorRecommendationsModel?> listStoreCreatorRecommendations({
    Future<void>? abortTrigger,
  }) async {
    final response = await listStoreCreatorRecommendationsWithHttpInfo(
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
        'StoreCreatorRecommendationsModel',
      ) as StoreCreatorRecommendationsModel;
    }
    return null;
  }
}

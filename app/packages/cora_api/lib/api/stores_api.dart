//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoresApi {
  StoresApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AdvanceOnboardingDto] advanceOnboardingDto (required):
  Future<Response> advanceMyStoreOnboardingWithHttpInfo(
    AdvanceOnboardingDto advanceOnboardingDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me/onboarding-step';

    // ignore: prefer_final_locals
    Object? postBody = advanceOnboardingDto;

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

  ///
  ///
  /// Parameters:
  ///
  /// * [AdvanceOnboardingDto] advanceOnboardingDto (required):
  Future<MyStoreModel?> advanceMyStoreOnboarding(
    AdvanceOnboardingDto advanceOnboardingDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await advanceMyStoreOnboardingWithHttpInfo(
      advanceOnboardingDto,
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
        'MyStoreModel',
      ) as MyStoreModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AnalyzeLinksDto] analyzeLinksDto (required):
  Future<Response> analyzeMyStoreLinksWithHttpInfo(
    AnalyzeLinksDto analyzeLinksDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me/analyze';

    // ignore: prefer_final_locals
    Object? postBody = analyzeLinksDto;

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

  ///
  ///
  /// Parameters:
  ///
  /// * [AnalyzeLinksDto] analyzeLinksDto (required):
  Future<AnalyzeStoreLinksResultModel?> analyzeMyStoreLinks(
    AnalyzeLinksDto analyzeLinksDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await analyzeMyStoreLinksWithHttpInfo(
      analyzeLinksDto,
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
        'AnalyzeStoreLinksResultModel',
      ) as AnalyzeStoreLinksResultModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ManualStoreDto] manualStoreDto (required):
  Future<Response> createMyStoreManuallyWithHttpInfo(
    ManualStoreDto manualStoreDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me/manual';

    // ignore: prefer_final_locals
    Object? postBody = manualStoreDto;

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

  ///
  ///
  /// Parameters:
  ///
  /// * [ManualStoreDto] manualStoreDto (required):
  Future<MyStoreModel?> createMyStoreManually(
    ManualStoreDto manualStoreDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createMyStoreManuallyWithHttpInfo(
      manualStoreDto,
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
        'MyStoreModel',
      ) as MyStoreModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   가게 이름.
  Future<Response> findMyStoreBranchesWithHttpInfo(
    String name, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me/branches';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'name', name));

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

  ///
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   가게 이름.
  Future<List<StoreBranchModel>?> findMyStoreBranches(
    String name, {
    Future<void>? abortTrigger,
  }) async {
    final response = await findMyStoreBranchesWithHttpInfo(
      name,
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
              responseBody, 'List<StoreBranchModel>') as List)
          .cast<StoreBranchModel>()
          .toList(growable: false);
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMyStoreWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me';

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

  ///
  Future<MyStoreModel?> getMyStore({
    Future<void>? abortTrigger,
  }) async {
    final response = await getMyStoreWithHttpInfo(
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
        'MyStoreModel',
      ) as MyStoreModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getPublishedStoreWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/{id}'.replaceAll('{id}', id);

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

  ///
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<StoreDetailModel?> getPublishedStore(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getPublishedStoreWithHttpInfo(
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
        'StoreDetailModel',
      ) as StoreDetailModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPublishedStoresWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores';

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

  ///
  Future<List<StoreSummaryModel>?> listPublishedStores({
    Future<void>? abortTrigger,
  }) async {
    final response = await listPublishedStoresWithHttpInfo(
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
              responseBody, 'List<StoreSummaryModel>') as List)
          .cast<StoreSummaryModel>()
          .toList(growable: false);
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> publishMyStoreWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me/publish';

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

  ///
  Future<MyStoreModel?> publishMyStore({
    Future<void>? abortTrigger,
  }) async {
    final response = await publishMyStoreWithHttpInfo(
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
        'MyStoreModel',
      ) as MyStoreModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SetDefaultTermsDto] setDefaultTermsDto (required):
  Future<Response> setMyStoreDefaultTermsWithHttpInfo(
    SetDefaultTermsDto setDefaultTermsDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me/default-terms';

    // ignore: prefer_final_locals
    Object? postBody = setDefaultTermsDto;

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

  ///
  ///
  /// Parameters:
  ///
  /// * [SetDefaultTermsDto] setDefaultTermsDto (required):
  Future<MyStoreModel?> setMyStoreDefaultTerms(
    SetDefaultTermsDto setDefaultTermsDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await setMyStoreDefaultTermsWithHttpInfo(
      setDefaultTermsDto,
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
        'MyStoreModel',
      ) as MyStoreModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UpdateStoreDto] updateStoreDto (required):
  Future<Response> updateMyStoreWithHttpInfo(
    UpdateStoreDto updateStoreDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/stores/me';

    // ignore: prefer_final_locals
    Object? postBody = updateStoreDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  ///
  ///
  /// Parameters:
  ///
  /// * [UpdateStoreDto] updateStoreDto (required):
  Future<MyStoreModel?> updateMyStore(
    UpdateStoreDto updateStoreDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateMyStoreWithHttpInfo(
      updateStoreDto,
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
        'MyStoreModel',
      ) as MyStoreModel;
    }
    return null;
  }
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CollaborationsApi {
  CollaborationsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 크리에이터가 사장님의 취소 요청에 동의한다(직접 그만두는 것과 같은 처리).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] requestId (required):
  Future<Response> acceptCollaborationCancelWithHttpInfo(
    String id,
    String requestId, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/cancel-requests/{requestId}/accept'
        .replaceAll('{id}', id)
        .replaceAll('{requestId}', requestId);

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

  /// 크리에이터가 사장님의 취소 요청에 동의한다(직접 그만두는 것과 같은 처리).
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] requestId (required):
  Future<CollaborationModel?> acceptCollaborationCancel(
    String id,
    String requestId, {
    Future<void>? abortTrigger,
  }) async {
    final response = await acceptCollaborationCancelWithHttpInfo(
      id,
      requestId,
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
        'CollaborationModel',
      ) as CollaborationModel;
    }
    return null;
  }

  /// 크리에이터가 링크를 제출하기 전에 협업을 그만둔다(수수료까지 전액 환급).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> cancelCollaborationWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/cancel'.replaceAll('{id}', id);

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

  /// 크리에이터가 링크를 제출하기 전에 협업을 그만둔다(수수료까지 전액 환급).
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<CollaborationModel?> cancelCollaboration(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await cancelCollaborationWithHttpInfo(
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
        'CollaborationModel',
      ) as CollaborationModel;
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
  Future<Response> getCollaborationWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}'.replaceAll('{id}', id);

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
  Future<CollaborationModel?> getCollaboration(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getCollaborationWithHttpInfo(
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
        'CollaborationModel',
      ) as CollaborationModel;
    }
    return null;
  }

  ///
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CollaborationScope] scope (required):
  ///   active: 진행 중(결제 대기·보관 중·집계 중·멈춤 등). done: 끝난 협업(정산 완료·환급·취소·중단). 최근 것부터.
  Future<Response> listCollaborationsWithHttpInfo(
    CollaborationScope scope, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'scope', scope));

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
  /// * [CollaborationScope] scope (required):
  ///   active: 진행 중(결제 대기·보관 중·집계 중·멈춤 등). done: 끝난 협업(정산 완료·환급·취소·중단). 최근 것부터.
  Future<List<CollaborationModel>?> listCollaborations(
    CollaborationScope scope, {
    Future<void>? abortTrigger,
  }) async {
    final response = await listCollaborationsWithHttpInfo(
      scope,
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
              responseBody, 'List<CollaborationModel>') as List)
          .cast<CollaborationModel>()
          .toList(growable: false);
    }
    return null;
  }

  /// 사장님이 취소를 요청한다. 3일 안에 답이 없으면 사라진다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> requestCollaborationCancelWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/cancel-requests'.replaceAll('{id}', id);

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

  /// 사장님이 취소를 요청한다. 3일 안에 답이 없으면 사라진다.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<CollaborationModel?> requestCollaborationCancel(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await requestCollaborationCancelWithHttpInfo(
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
        'CollaborationModel',
      ) as CollaborationModel;
    }
    return null;
  }
}

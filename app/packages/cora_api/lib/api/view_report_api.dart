//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ViewReportApi {
  ViewReportApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 맡긴 쪽이 \"자료 확인했어요\"를 누른다. 확인되면 정산이 이어진다. 확인할 수 없는 상태면 409, 크리에이터는 403.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> confirmViewReportWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/collaborations/{id}/view-report/confirm'.replaceAll('{id}', id);

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

  /// 맡긴 쪽이 \"자료 확인했어요\"를 누른다. 확인되면 정산이 이어진다. 확인할 수 없는 상태면 409, 크리에이터는 403.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<ViewReportModel?> confirmViewReport(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await confirmViewReportWithHttpInfo(
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
        'ViewReportModel',
      ) as ViewReportModel;
    }
    return null;
  }

  /// 조회 자료에 이의를 제기한다(당사자 누구나, 확인 전인 계산에 한 사람이 한 번). 돈은 그대로 보관되고 운영팀이 처리한다. 낼 수 없는 상태면 409.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DisputeViewReportDto] disputeViewReportDto (required):
  Future<Response> disputeViewReportWithHttpInfo(
    String id,
    DisputeViewReportDto disputeViewReportDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path =
        r'/collaborations/{id}/view-report/dispute'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = disputeViewReportDto;

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

  /// 조회 자료에 이의를 제기한다(당사자 누구나, 확인 전인 계산에 한 사람이 한 번). 돈은 그대로 보관되고 운영팀이 처리한다. 낼 수 없는 상태면 409.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DisputeViewReportDto] disputeViewReportDto (required):
  Future<ViewReportModel?> disputeViewReport(
    String id,
    DisputeViewReportDto disputeViewReportDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await disputeViewReportWithHttpInfo(
      id,
      disputeViewReportDto,
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
        'ViewReportModel',
      ) as ViewReportModel;
    }
    return null;
  }

  /// 조회 자료 확인(F4). 당사자만 읽는다. 조회수 수당이 없거나 링크 제출 전이면 404.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getViewReportWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/view-report'.replaceAll('{id}', id);

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

  /// 조회 자료 확인(F4). 당사자만 읽는다. 조회수 수당이 없거나 링크 제출 전이면 404.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<ViewReportModel?> getViewReport(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getViewReportWithHttpInfo(
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
        'ViewReportModel',
      ) as ViewReportModel;
    }
    return null;
  }

  /// 조회수를 읽지 못했을 때 크리에이터가 인사이트 캡처와 조회수를 낸다. 크리에이터만, 캡처가 요청된 때 한 번. 받을 수 없는 상태면 409, 내 파일이 아니면 403.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [SubmitViewEvidenceDto] submitViewEvidenceDto (required):
  Future<Response> submitViewEvidenceWithHttpInfo(
    String id,
    SubmitViewEvidenceDto submitViewEvidenceDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/collaborations/{id}/view-evidence'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = submitViewEvidenceDto;

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

  /// 조회수를 읽지 못했을 때 크리에이터가 인사이트 캡처와 조회수를 낸다. 크리에이터만, 캡처가 요청된 때 한 번. 받을 수 없는 상태면 409, 내 파일이 아니면 403.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [SubmitViewEvidenceDto] submitViewEvidenceDto (required):
  Future<ViewReportModel?> submitViewEvidence(
    String id,
    SubmitViewEvidenceDto submitViewEvidenceDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await submitViewEvidenceWithHttpInfo(
      id,
      submitViewEvidenceDto,
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
        'ViewReportModel',
      ) as ViewReportModel;
    }
    return null;
  }
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ReportsApi {
  ReportsApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 내가 참가한 방이나 그 상대를 신고한다. 운영자에게 메일이 간다. 돈이 보관 중인 협업이면 그 협업이 멈춘다.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateReportDto] createReportDto (required):
  Future<Response> createReportWithHttpInfo(
    CreateReportDto createReportDto, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/reports';

    // ignore: prefer_final_locals
    Object? postBody = createReportDto;

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

  /// 내가 참가한 방이나 그 상대를 신고한다. 운영자에게 메일이 간다. 돈이 보관 중인 협업이면 그 협업이 멈춘다.
  ///
  /// Parameters:
  ///
  /// * [CreateReportDto] createReportDto (required):
  Future<ReportCreatedModel?> createReport(
    CreateReportDto createReportDto, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createReportWithHttpInfo(
      createReportDto,
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
        'ReportCreatedModel',
      ) as ReportCreatedModel;
    }
    return null;
  }
}

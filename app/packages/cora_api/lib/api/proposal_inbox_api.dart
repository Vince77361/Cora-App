//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposalInboxApi {
  ProposalInboxApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 제안함의 브랜드 계약 줄(브랜드와 크리에이터 모두). 내가 당사자인 협업만, 내가 응답할 차례 → 상대 대기 → 끝남 순이고 같은 묶음에서는 최근 순이다. 계약 이후와 요청 거절·차단으로 끝난 협업은 없다.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listTermsProposalInboxWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/terms/proposal-inbox';

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

  /// 제안함의 브랜드 계약 줄(브랜드와 크리에이터 모두). 내가 당사자인 협업만, 내가 응답할 차례 → 상대 대기 → 끝남 순이고 같은 묶음에서는 최근 순이다. 계약 이후와 요청 거절·차단으로 끝난 협업은 없다.
  Future<List<ProposalInboxRowModel>?> listTermsProposalInbox({
    Future<void>? abortTrigger,
  }) async {
    final response = await listTermsProposalInboxWithHttpInfo(
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
              responseBody, 'List<ProposalInboxRowModel>') as List)
          .cast<ProposalInboxRowModel>()
          .toList(growable: false);
    }
    return null;
  }
}

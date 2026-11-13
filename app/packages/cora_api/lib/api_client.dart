//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ApiClient {
  ApiClient({
    this.basePath = 'http://localhost',
    this.authentication,
  });

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType, {
    Future<void>? abortTrigger,
  }) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (body is MultipartFile &&
          (contentType == null ||
              !contentType.toLowerCase().startsWith('multipart/form-data'))) {
        final request =
            AbortableStreamedRequest(method, uri, abortTrigger: abortTrigger);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
              request.sink.add,
              onDone: request.sink.close,
              // ignore: avoid_types_on_closure_parameters
              onError: (Object error, StackTrace trace) => request.sink.close(),
              cancelOnError: true,
            );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request =
            AbortableMultipartRequest(method, uri, abortTrigger: abortTrigger);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
          ? formParams
          : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      final request = AbortableRequest(method, uri, abortTrigger: abortTrigger);
      if (nullableHeaderParams != null) {
        request.headers.addAll(nullableHeaderParams);
      }
      if (msgBody is String && msgBody.isNotEmpty) {
        request.body = msgBody;
      } else if (msgBody is List<int> && msgBody.isNotEmpty) {
        request.bodyBytes = msgBody;
      } else if (msgBody is Map<String, String>) {
        request.bodyFields = msgBody;
      }
      final response = await _client.send(request);
      return Response.fromStream(response);
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }
  }

  Future<dynamic> deserializeAsync(
    String value,
    String targetType, {
    bool growable = false,
  }) async =>
      // ignore: deprecated_member_use_from_same_package
      deserialize(value, targetType, growable: growable);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(
    String value,
    String targetType, {
    bool growable = false,
  }) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType =
        targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
        ? value
        : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(
    dynamic value,
    String targetType, {
    bool growable = false,
  }) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'AcceptOfferDto':
          return AcceptOfferDto.fromJson(value);
        case 'AdvanceOnboardingDto':
          return AdvanceOnboardingDto.fromJson(value);
        case 'AdvanceOnboardingStep':
          return AdvanceOnboardingStepTypeTransformer().decode(value);
        case 'AnalyzeLinksDto':
          return AnalyzeLinksDto.fromJson(value);
        case 'AnalyzeStoreLinksResultModel':
          return AnalyzeStoreLinksResultModel.fromJson(value);
        case 'AppConfigModel':
          return AppConfigModel.fromJson(value);
        case 'ApplicantModel':
          return ApplicantModel.fromJson(value);
        case 'ApplicationModel':
          return ApplicationModel.fromJson(value);
        case 'ApplicationStatus':
          return ApplicationStatusTypeTransformer().decode(value);
        case 'ApplyDto':
          return ApplyDto.fromJson(value);
        case 'BankModel':
          return BankModel.fromJson(value);
        case 'CancelRequestModel':
          return CancelRequestModel.fromJson(value);
        case 'CollaborationCounterpartModel':
          return CollaborationCounterpartModel.fromJson(value);
        case 'CollaborationKind':
          return CollaborationKindTypeTransformer().decode(value);
        case 'CollaborationModel':
          return CollaborationModel.fromJson(value);
        case 'CollaborationRole':
          return CollaborationRoleTypeTransformer().decode(value);
        case 'CollaborationScope':
          return CollaborationScopeTypeTransformer().decode(value);
        case 'CollaborationSettlementModel':
          return CollaborationSettlementModel.fromJson(value);
        case 'CollaborationStage':
          return CollaborationStageTypeTransformer().decode(value);
        case 'CollaborationStepKey':
          return CollaborationStepKeyTypeTransformer().decode(value);
        case 'CollaborationStepModel':
          return CollaborationStepModel.fromJson(value);
        case 'CollaborationStepState':
          return CollaborationStepStateTypeTransformer().decode(value);
        case 'CompleteInstagramConnectDto':
          return CompleteInstagramConnectDto.fromJson(value);
        case 'ContentDraftKind':
          return ContentDraftKindTypeTransformer().decode(value);
        case 'ContentDraftModel':
          return ContentDraftModel.fromJson(value);
        case 'ContentFormat':
          return ContentFormatTypeTransformer().decode(value);
        case 'CreateCreatorSeriesDto':
          return CreateCreatorSeriesDto.fromJson(value);
        case 'CreatePaymentDto':
          return CreatePaymentDto.fromJson(value);
        case 'CreatePhotoUploadDto':
          return CreatePhotoUploadDto.fromJson(value);
        case 'CreatorProfileModel':
          return CreatorProfileModel.fromJson(value);
        case 'CreatorSeriesModel':
          return CreatorSeriesModel.fromJson(value);
        case 'CreatorSummaryModel':
          return CreatorSummaryModel.fromJson(value);
        case 'DraftSceneModel':
          return DraftSceneModel.fromJson(value);
        case 'EndOfferDto':
          return EndOfferDto.fromJson(value);
        case 'EndedOfferModel':
          return EndedOfferModel.fromJson(value);
        case 'FeeRatesModel':
          return FeeRatesModel.fromJson(value);
        case 'FixedCashMaxModel':
          return FixedCashMaxModel.fromJson(value);
        case 'FixedCashRangeModel':
          return FixedCashRangeModel.fromJson(value);
        case 'HealthModel':
          return HealthModel.fromJson(value);
        case 'IndustryCategory':
          return IndustryCategoryTypeTransformer().decode(value);
        case 'InstagramConnectUrlModel':
          return InstagramConnectUrlModel.fromJson(value);
        case 'InstagramConnectionModel':
          return InstagramConnectionModel.fromJson(value);
        case 'ManualBranchDto':
          return ManualBranchDto.fromJson(value);
        case 'ManualStoreDto':
          return ManualStoreDto.fromJson(value);
        case 'MeModel':
          return MeModel.fromJson(value);
        case 'MyApplicationStatus':
          return MyApplicationStatusTypeTransformer().decode(value);
        case 'MyOpenOfferModel':
          return MyOpenOfferModel.fromJson(value);
        case 'MyStoreModel':
          return MyStoreModel.fromJson(value);
        case 'NotificationActorModel':
          return NotificationActorModel.fromJson(value);
        case 'NotificationGlyph':
          return NotificationGlyphTypeTransformer().decode(value);
        case 'NotificationModel':
          return NotificationModel.fromJson(value);
        case 'NotificationPageModel':
          return NotificationPageModel.fromJson(value);
        case 'NotificationSettingsModel':
          return NotificationSettingsModel.fromJson(value);
        case 'NotificationTab':
          return NotificationTabTypeTransformer().decode(value);
        case 'NotificationTabFilter':
          return NotificationTabFilterTypeTransformer().decode(value);
        case 'NotificationTargetModel':
          return NotificationTargetModel.fromJson(value);
        case 'OfferEndReason':
          return OfferEndReasonTypeTransformer().decode(value);
        case 'OfferEndStatus':
          return OfferEndStatusTypeTransformer().decode(value);
        case 'OfferParty':
          return OfferPartyTypeTransformer().decode(value);
        case 'OfferTermsModel':
          return OfferTermsModel.fromJson(value);
        case 'OfferVersionModel':
          return OfferVersionModel.fromJson(value);
        case 'OfferVersionSeriesModel':
          return OfferVersionSeriesModel.fromJson(value);
        case 'OfferView':
          return OfferViewTypeTransformer().decode(value);
        case 'PaymentCreatedModel':
          return PaymentCreatedModel.fromJson(value);
        case 'PaymentMethod':
          return PaymentMethodTypeTransformer().decode(value);
        case 'PaymentQuoteModel':
          return PaymentQuoteModel.fromJson(value);
        case 'PaymentStatus':
          return PaymentStatusTypeTransformer().decode(value);
        case 'PaymentStatusModel':
          return PaymentStatusModel.fromJson(value);
        case 'PayoutAccountModel':
          return PayoutAccountModel.fromJson(value);
        case 'PayoutStatus':
          return PayoutStatusTypeTransformer().decode(value);
        case 'PerViewInputDto':
          return PerViewInputDto.fromJson(value);
        case 'PhotoUploadModel':
          return PhotoUploadModel.fromJson(value);
        case 'ProposalCounterpartModel':
          return ProposalCounterpartModel.fromJson(value);
        case 'ProposalDetailModel':
          return ProposalDetailModel.fromJson(value);
        case 'ProposalEndKind':
          return ProposalEndKindTypeTransformer().decode(value);
        case 'ProposalGroup':
          return ProposalGroupTypeTransformer().decode(value);
        case 'ProposalPersonModel':
          return ProposalPersonModel.fromJson(value);
        case 'ProposalRowModel':
          return ProposalRowModel.fromJson(value);
        case 'ProposalStoreModel':
          return ProposalStoreModel.fromJson(value);
        case 'ProposalTab':
          return ProposalTabTypeTransformer().decode(value);
        case 'ProposeVersionDto':
          return ProposeVersionDto.fromJson(value);
        case 'QuietHours':
          return QuietHoursTypeTransformer().decode(value);
        case 'ReceivedOfferModel':
          return ReceivedOfferModel.fromJson(value);
        case 'ReceivedOfferTab':
          return ReceivedOfferTabTypeTransformer().decode(value);
        case 'RewardConfigModel':
          return RewardConfigModel.fromJson(value);
        case 'RewardInputDto':
          return RewardInputDto.fromJson(value);
        case 'RewardRangeModel':
          return RewardRangeModel.fromJson(value);
        case 'SendOfferDto':
          return SendOfferDto.fromJson(value);
        case 'SentOfferModel':
          return SentOfferModel.fromJson(value);
        case 'SetDefaultTermsDto':
          return SetDefaultTermsDto.fromJson(value);
        case 'SettlementMethod':
          return SettlementMethodTypeTransformer().decode(value);
        case 'SourceLinkInputDto':
          return SourceLinkInputDto.fromJson(value);
        case 'SourceLinkKind':
          return SourceLinkKindTypeTransformer().decode(value);
        case 'StoreBranchModel':
          return StoreBranchModel.fromJson(value);
        case 'StoreDetailModel':
          return StoreDetailModel.fromJson(value);
        case 'StoreHomeSummaryModel':
          return StoreHomeSummaryModel.fromJson(value);
        case 'StoreOnboardingStep':
          return StoreOnboardingStepTypeTransformer().decode(value);
        case 'StoreProposalDto':
          return StoreProposalDto.fromJson(value);
        case 'StoreProposalResultModel':
          return StoreProposalResultModel.fromJson(value);
        case 'StoreResultCreatorModel':
          return StoreResultCreatorModel.fromJson(value);
        case 'StoreResultModel':
          return StoreResultModel.fromJson(value);
        case 'StoreSourceLinkModel':
          return StoreSourceLinkModel.fromJson(value);
        case 'StoreStatus':
          return StoreStatusTypeTransformer().decode(value);
        case 'StoreSummaryModel':
          return StoreSummaryModel.fromJson(value);
        case 'SubmitContentDto':
          return SubmitContentDto.fromJson(value);
        case 'TrialBanner':
          return TrialBannerTypeTransformer().decode(value);
        case 'TrialInfoDto':
          return TrialInfoDto.fromJson(value);
        case 'TrialInfoModel':
          return TrialInfoModel.fromJson(value);
        case 'UnreadCountModel':
          return UnreadCountModel.fromJson(value);
        case 'UpdateNotificationSettingsDto':
          return UpdateNotificationSettingsDto.fromJson(value);
        case 'UpdateRoleDto':
          return UpdateRoleDto.fromJson(value);
        case 'UpdateStoreDto':
          return UpdateStoreDto.fromJson(value);
        case 'UpsertCreatorProfileDto':
          return UpsertCreatorProfileDto.fromJson(value);
        case 'UpsertPayoutAccountDto':
          return UpsertPayoutAccountDto.fromJson(value);
        case 'UsageRights':
          return UsageRightsTypeTransformer().decode(value);
        case 'UserRole':
          return UserRoleTypeTransformer().decode(value);
        case 'VoucherDefaultsModel':
          return VoucherDefaultsModel.fromJson(value);
        case 'VoucherInputDto':
          return VoucherInputDto.fromJson(value);
        case 'WalletAccountModel':
          return WalletAccountModel.fromJson(value);
        case 'WalletEntryKind':
          return WalletEntryKindTypeTransformer().decode(value);
        case 'WalletEntryModel':
          return WalletEntryModel.fromJson(value);
        case 'WalletModel':
          return WalletModel.fromJson(value);
        case 'WalletNextPayoutModel':
          return WalletNextPayoutModel.fromJson(value);
        default:
          dynamic match;
          if (value is List &&
              (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toList(growable: growable);
          }
          if (value is Set &&
              (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toSet();
          }
          if (value is Map &&
              (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(
                    v,
                    match,
                    growable: growable,
                  )),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.internalServerError,
        'Exception during deserialization.',
        error,
        trace,
      );
    }
    throw ApiException(
      HttpStatus.internalServerError,
      'Could not find a suitable class for deserialization',
    );
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String' ? message.json : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
      ? message.json
      : ApiClient.fromJson(
          json.decode(message.json),
          targetType,
          growable: message.growable,
        );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async =>
    value == null ? '' : json.encode(value);

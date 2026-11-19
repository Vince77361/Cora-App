//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class QueryParam {
  const QueryParam(this.name, this.value);

  final String name;
  final String value;

  @override
  String toString() =>
      '${Uri.encodeQueryComponent(name)}=${Uri.encodeQueryComponent(value)}';
}

// Ported from the Java version.
Iterable<QueryParam> _queryParams(
  String collectionFormat,
  String name,
  dynamic value,
) {
  // Assertions to run in debug mode only.
  assert(name.isNotEmpty, 'Parameter cannot be an empty string.');

  final params = <QueryParam>[];

  if (value is List) {
    if (collectionFormat == 'multi') {
      return value.map(
        (dynamic v) => QueryParam(name, parameterToString(v)),
      );
    }

    // Default collection format is 'csv'.
    if (collectionFormat.isEmpty) {
      collectionFormat = 'csv'; // ignore: parameter_assignments
    }

    final delimiter = _delimiters[collectionFormat] ?? ',';

    params.add(QueryParam(
      name,
      value.map<dynamic>(parameterToString).join(delimiter),
    ));
  } else if (value != null) {
    params.add(QueryParam(name, parameterToString(value)));
  }

  return params;
}

/// Format the given parameter object into a [String].
String parameterToString(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is AdvanceOnboardingStep) {
    return AdvanceOnboardingStepTypeTransformer().encode(value).toString();
  }
  if (value is ApplicationStatus) {
    return ApplicationStatusTypeTransformer().encode(value).toString();
  }
  if (value is BrandProgressNote) {
    return BrandProgressNoteTypeTransformer().encode(value).toString();
  }
  if (value is BrandUsageRights) {
    return BrandUsageRightsTypeTransformer().encode(value).toString();
  }
  if (value is CampaignListCardKind) {
    return CampaignListCardKindTypeTransformer().encode(value).toString();
  }
  if (value is CampaignStatus) {
    return CampaignStatusTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationKind) {
    return CollaborationKindTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationNextAction) {
    return CollaborationNextActionTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationRole) {
    return CollaborationRoleTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationScope) {
    return CollaborationScopeTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationStage) {
    return CollaborationStageTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationStepKey) {
    return CollaborationStepKeyTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationStepState) {
    return CollaborationStepStateTypeTransformer().encode(value).toString();
  }
  if (value is CollaborationViewReportStatus) {
    return CollaborationViewReportStatusTypeTransformer()
        .encode(value)
        .toString();
  }
  if (value is CompareField) {
    return CompareFieldTypeTransformer().encode(value).toString();
  }
  if (value is ContentDraftKind) {
    return ContentDraftKindTypeTransformer().encode(value).toString();
  }
  if (value is ContentFormat) {
    return ContentFormatTypeTransformer().encode(value).toString();
  }
  if (value is ContractProgress) {
    return ContractProgressTypeTransformer().encode(value).toString();
  }
  if (value is ContractStatus) {
    return ContractStatusTypeTransformer().encode(value).toString();
  }
  if (value is ConversationSection) {
    return ConversationSectionTypeTransformer().encode(value).toString();
  }
  if (value is ConversationStatus) {
    return ConversationStatusTypeTransformer().encode(value).toString();
  }
  if (value is DecisionTargetKind) {
    return DecisionTargetKindTypeTransformer().encode(value).toString();
  }
  if (value is DropReasonChoice) {
    return DropReasonChoiceTypeTransformer().encode(value).toString();
  }
  if (value is FeaturedPostKind) {
    return FeaturedPostKindTypeTransformer().encode(value).toString();
  }
  if (value is FeaturedPostSource) {
    return FeaturedPostSourceTypeTransformer().encode(value).toString();
  }
  if (value is FeeBand) {
    return FeeBandTypeTransformer().encode(value).toString();
  }
  if (value is IndustryCategory) {
    return IndustryCategoryTypeTransformer().encode(value).toString();
  }
  if (value is InterestState) {
    return InterestStateTypeTransformer().encode(value).toString();
  }
  if (value is InterestTab) {
    return InterestTabTypeTransformer().encode(value).toString();
  }
  if (value is MatchReason) {
    return MatchReasonTypeTransformer().encode(value).toString();
  }
  if (value is MessageKind) {
    return MessageKindTypeTransformer().encode(value).toString();
  }
  if (value is MyApplicationStatus) {
    return MyApplicationStatusTypeTransformer().encode(value).toString();
  }
  if (value is NotRequired) {
    return NotRequiredTypeTransformer().encode(value).toString();
  }
  if (value is NotificationGlyph) {
    return NotificationGlyphTypeTransformer().encode(value).toString();
  }
  if (value is NotificationTab) {
    return NotificationTabTypeTransformer().encode(value).toString();
  }
  if (value is NotificationTabFilter) {
    return NotificationTabFilterTypeTransformer().encode(value).toString();
  }
  if (value is OfferEndReason) {
    return OfferEndReasonTypeTransformer().encode(value).toString();
  }
  if (value is OfferEndStatus) {
    return OfferEndStatusTypeTransformer().encode(value).toString();
  }
  if (value is OfferParty) {
    return OfferPartyTypeTransformer().encode(value).toString();
  }
  if (value is OfferView) {
    return OfferViewTypeTransformer().encode(value).toString();
  }
  if (value is PassReason) {
    return PassReasonTypeTransformer().encode(value).toString();
  }
  if (value is PaymentMethod) {
    return PaymentMethodTypeTransformer().encode(value).toString();
  }
  if (value is PaymentStatus) {
    return PaymentStatusTypeTransformer().encode(value).toString();
  }
  if (value is PayoutStatus) {
    return PayoutStatusTypeTransformer().encode(value).toString();
  }
  if (value is ProductTrialDays) {
    return ProductTrialDaysTypeTransformer().encode(value).toString();
  }
  if (value is ProposalEndKind) {
    return ProposalEndKindTypeTransformer().encode(value).toString();
  }
  if (value is ProposalGroup) {
    return ProposalGroupTypeTransformer().encode(value).toString();
  }
  if (value is ProposalTab) {
    return ProposalTabTypeTransformer().encode(value).toString();
  }
  if (value is QuietHours) {
    return QuietHoursTypeTransformer().encode(value).toString();
  }
  if (value is ReceivedOfferTab) {
    return ReceivedOfferTabTypeTransformer().encode(value).toString();
  }
  if (value is RecommendedSource) {
    return RecommendedSourceTypeTransformer().encode(value).toString();
  }
  if (value is ReportReason) {
    return ReportReasonTypeTransformer().encode(value).toString();
  }
  if (value is ReportTargetKind) {
    return ReportTargetKindTypeTransformer().encode(value).toString();
  }
  if (value is RevisionScope) {
    return RevisionScopeTypeTransformer().encode(value).toString();
  }
  if (value is SavedDecision) {
    return SavedDecisionTypeTransformer().encode(value).toString();
  }
  if (value is SendableMessageKind) {
    return SendableMessageKindTypeTransformer().encode(value).toString();
  }
  if (value is SettlementMethod) {
    return SettlementMethodTypeTransformer().encode(value).toString();
  }
  if (value is SourceLinkKind) {
    return SourceLinkKindTypeTransformer().encode(value).toString();
  }
  if (value is StoreInterestTab) {
    return StoreInterestTabTypeTransformer().encode(value).toString();
  }
  if (value is StoreOnboardingStep) {
    return StoreOnboardingStepTypeTransformer().encode(value).toString();
  }
  if (value is StoreStatus) {
    return StoreStatusTypeTransformer().encode(value).toString();
  }
  if (value is SwipeDecisionKind) {
    return SwipeDecisionKindTypeTransformer().encode(value).toString();
  }
  if (value is SwipeTargetKind) {
    return SwipeTargetKindTypeTransformer().encode(value).toString();
  }
  if (value is TermsAgreement) {
    return TermsAgreementTypeTransformer().encode(value).toString();
  }
  if (value is TermsField) {
    return TermsFieldTypeTransformer().encode(value).toString();
  }
  if (value is TermsProposer) {
    return TermsProposerTypeTransformer().encode(value).toString();
  }
  if (value is TrialBanner) {
    return TrialBannerTypeTransformer().encode(value).toString();
  }
  if (value is UsageRights) {
    return UsageRightsTypeTransformer().encode(value).toString();
  }
  if (value is UserRole) {
    return UserRoleTypeTransformer().encode(value).toString();
  }
  if (value is ViewReportSource) {
    return ViewReportSourceTypeTransformer().encode(value).toString();
  }
  if (value is ViewReportStatus) {
    return ViewReportStatusTypeTransformer().encode(value).toString();
  }
  if (value is WalletEntryKind) {
    return WalletEntryKindTypeTransformer().encode(value).toString();
  }
  return value.toString();
}

/// Returns the decoded body as UTF-8 if the given headers indicate an 'application/json'
/// content type. Otherwise, returns the decoded body as decoded by dart:http package.
Future<String> _decodeBodyBytes(Response response) async {
  final contentType = response.headers['content-type'];
  return contentType != null &&
          contentType.toLowerCase().startsWith('application/json')
      ? response.bodyBytes.isEmpty
          ? ''
          : utf8.decode(response.bodyBytes)
      : response.body;
}

/// Returns a valid [T] value found at the specified Map [key], null otherwise.
T? mapValueOfType<T>(dynamic map, String key) {
  final dynamic value = map is Map ? map[key] : null;
  if (T == double && value is int) {
    return value.toDouble() as T;
  }
  return value is T ? value : null;
}

/// Returns a valid Map<K, V> found at the specified Map [key], null otherwise.
Map<K, V>? mapCastOfType<K, V>(dynamic map, String key) {
  final dynamic value = map is Map ? map[key] : null;
  return value is Map ? value.cast<K, V>() : null;
}

/// Returns a valid [DateTime] found at the specified Map [key], null otherwise.
DateTime? mapDateTime(dynamic map, String key, [String? pattern]) {
  final dynamic value = map is Map ? map[key] : null;
  if (value != null) {
    int? millis;
    if (value is int) {
      millis = value;
    } else if (value is String) {
      if (_isEpochMarker(pattern)) {
        millis = int.tryParse(value);
      } else {
        return DateTime.tryParse(value);
      }
    }
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  }
  return null;
}

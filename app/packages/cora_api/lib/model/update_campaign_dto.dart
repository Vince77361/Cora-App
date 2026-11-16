//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpdateCampaignDto {
  /// Returns a new [UpdateCampaignDto] instance.
  UpdateCampaignDto({
    this.budget,
    this.fee,
    this.format,
    this.headline,
    this.mustInclude = const [],
    this.notRequired = const [],
    this.productProvided,
    this.startFrom,
    this.trialDays,
  });

  /// 고친 뒤에도 제작비 이상이어야 한다.
  ///
  /// Minimum value: 10000
  /// Maximum value: 100000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? budget;

  /// Minimum value: 10000
  /// Maximum value: 10000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? fee;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ContentFormat? format;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? headline;

  List<String> mustInclude;

  List<NotRequired> notRequired;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? productProvided;

  /// 바꿀 때만 한국 시간 오늘 이후여야 한다. 그대로 보내면 통과한다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startFrom;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ProductTrialDays? trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateCampaignDto &&
          other.budget == budget &&
          other.fee == fee &&
          other.format == format &&
          other.headline == headline &&
          _deepEquality.equals(other.mustInclude, mustInclude) &&
          _deepEquality.equals(other.notRequired, notRequired) &&
          other.productProvided == productProvided &&
          other.startFrom == startFrom &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (budget == null ? 0 : budget!.hashCode) +
      (fee == null ? 0 : fee!.hashCode) +
      (format == null ? 0 : format!.hashCode) +
      (headline == null ? 0 : headline!.hashCode) +
      (mustInclude.hashCode) +
      (notRequired.hashCode) +
      (productProvided == null ? 0 : productProvided!.hashCode) +
      (startFrom == null ? 0 : startFrom!.hashCode) +
      (trialDays == null ? 0 : trialDays!.hashCode);

  @override
  String toString() =>
      'UpdateCampaignDto[budget=$budget, fee=$fee, format=$format, headline=$headline, mustInclude=$mustInclude, notRequired=$notRequired, productProvided=$productProvided, startFrom=$startFrom, trialDays=$trialDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.budget != null) {
      json[r'budget'] = this.budget;
    } else {
      json[r'budget'] = null;
    }
    if (this.fee != null) {
      json[r'fee'] = this.fee;
    } else {
      json[r'fee'] = null;
    }
    if (this.format != null) {
      json[r'format'] = this.format;
    } else {
      json[r'format'] = null;
    }
    if (this.headline != null) {
      json[r'headline'] = this.headline;
    } else {
      json[r'headline'] = null;
    }
    json[r'mustInclude'] = this.mustInclude;
    json[r'notRequired'] = this.notRequired;
    if (this.productProvided != null) {
      json[r'productProvided'] = this.productProvided;
    } else {
      json[r'productProvided'] = null;
    }
    if (this.startFrom != null) {
      json[r'startFrom'] = _dateFormatter.format(this.startFrom!);
    } else {
      json[r'startFrom'] = null;
    }
    if (this.trialDays != null) {
      json[r'trialDays'] = this.trialDays;
    } else {
      json[r'trialDays'] = null;
    }
    return json;
  }

  /// Returns a new [UpdateCampaignDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateCampaignDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateCampaignDto(
        budget: mapValueOfType<int>(json, r'budget'),
        fee: mapValueOfType<int>(json, r'fee'),
        format: ContentFormat.fromJson(json[r'format']),
        headline: mapValueOfType<String>(json, r'headline'),
        mustInclude: json[r'mustInclude'] is Iterable
            ? (json[r'mustInclude'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        notRequired: NotRequired.listFromJson(json[r'notRequired']),
        productProvided: mapValueOfType<bool>(json, r'productProvided'),
        startFrom: mapDateTime(json, r'startFrom', r''),
        trialDays: ProductTrialDays.fromJson(json[r'trialDays']),
      );
    }
    return null;
  }

  static List<UpdateCampaignDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateCampaignDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateCampaignDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateCampaignDto> mapFromJson(dynamic json) {
    final map = <String, UpdateCampaignDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateCampaignDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateCampaignDto-objects as value to a dart map
  static Map<String, List<UpdateCampaignDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateCampaignDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateCampaignDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}

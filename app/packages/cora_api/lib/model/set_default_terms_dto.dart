//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SetDefaultTermsDto {
  /// Returns a new [SetDefaultTermsDto] instance.
  SetDefaultTermsDto({
    required this.format,
    required this.rewardType,
    this.voucherName,
    this.voucherValue,
  });

  ContentFormat format;

  RewardType rewardType;

  /// 식사권이 보상에 들어갈 때만 쓴다. 없으면 \"2인 식사권\".
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? voucherName;

  /// 식사권이 보상에 들어갈 때만 쓴다. 없으면 40000.
  ///
  /// Minimum value: 1000
  /// Maximum value: 1000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? voucherValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetDefaultTermsDto &&
          other.format == format &&
          other.rewardType == rewardType &&
          other.voucherName == voucherName &&
          other.voucherValue == voucherValue;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format.hashCode) +
      (rewardType.hashCode) +
      (voucherName == null ? 0 : voucherName!.hashCode) +
      (voucherValue == null ? 0 : voucherValue!.hashCode);

  @override
  String toString() =>
      'SetDefaultTermsDto[format=$format, rewardType=$rewardType, voucherName=$voucherName, voucherValue=$voucherValue]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'format'] = this.format;
    json[r'rewardType'] = this.rewardType;
    if (this.voucherName != null) {
      json[r'voucherName'] = this.voucherName;
    } else {
      json[r'voucherName'] = null;
    }
    if (this.voucherValue != null) {
      json[r'voucherValue'] = this.voucherValue;
    } else {
      json[r'voucherValue'] = null;
    }
    return json;
  }

  /// Returns a new [SetDefaultTermsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetDefaultTermsDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "SetDefaultTermsDto[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "SetDefaultTermsDto[format]" has a null value in JSON.');
        assert(json.containsKey(r'rewardType'),
            'Required key "SetDefaultTermsDto[rewardType]" is missing from JSON.');
        assert(json[r'rewardType'] != null,
            'Required key "SetDefaultTermsDto[rewardType]" has a null value in JSON.');
        return true;
      }());

      return SetDefaultTermsDto(
        format: ContentFormat.fromJson(json[r'format'])!,
        rewardType: RewardType.fromJson(json[r'rewardType'])!,
        voucherName: mapValueOfType<String>(json, r'voucherName'),
        voucherValue: mapValueOfType<int>(json, r'voucherValue'),
      );
    }
    return null;
  }

  static List<SetDefaultTermsDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SetDefaultTermsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetDefaultTermsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetDefaultTermsDto> mapFromJson(dynamic json) {
    final map = <String, SetDefaultTermsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetDefaultTermsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetDefaultTermsDto-objects as value to a dart map
  static Map<String, List<SetDefaultTermsDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SetDefaultTermsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetDefaultTermsDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'format',
    'rewardType',
  };
}

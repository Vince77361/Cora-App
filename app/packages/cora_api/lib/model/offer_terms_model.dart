//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class OfferTermsModel {
  /// Returns a new [OfferTermsModel] instance.
  OfferTermsModel({
    required this.format,
    required this.perViewAmount,
    required this.perViewCap,
    required this.rewardType,
    required this.voucherName,
    required this.voucherValue,
  });

  ContentFormat format;

  int? perViewAmount;

  int? perViewCap;

  RewardType rewardType;

  String? voucherName;

  int? voucherValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferTermsModel &&
          other.format == format &&
          other.perViewAmount == perViewAmount &&
          other.perViewCap == perViewCap &&
          other.rewardType == rewardType &&
          other.voucherName == voucherName &&
          other.voucherValue == voucherValue;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format.hashCode) +
      (perViewAmount == null ? 0 : perViewAmount!.hashCode) +
      (perViewCap == null ? 0 : perViewCap!.hashCode) +
      (rewardType.hashCode) +
      (voucherName == null ? 0 : voucherName!.hashCode) +
      (voucherValue == null ? 0 : voucherValue!.hashCode);

  @override
  String toString() =>
      'OfferTermsModel[format=$format, perViewAmount=$perViewAmount, perViewCap=$perViewCap, rewardType=$rewardType, voucherName=$voucherName, voucherValue=$voucherValue]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'format'] = this.format;
    if (this.perViewAmount != null) {
      json[r'perViewAmount'] = this.perViewAmount;
    } else {
      json[r'perViewAmount'] = null;
    }
    if (this.perViewCap != null) {
      json[r'perViewCap'] = this.perViewCap;
    } else {
      json[r'perViewCap'] = null;
    }
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

  /// Returns a new [OfferTermsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OfferTermsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "OfferTermsModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "OfferTermsModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'perViewAmount'),
            'Required key "OfferTermsModel[perViewAmount]" is missing from JSON.');
        assert(json.containsKey(r'perViewCap'),
            'Required key "OfferTermsModel[perViewCap]" is missing from JSON.');
        assert(json.containsKey(r'rewardType'),
            'Required key "OfferTermsModel[rewardType]" is missing from JSON.');
        assert(json[r'rewardType'] != null,
            'Required key "OfferTermsModel[rewardType]" has a null value in JSON.');
        assert(json.containsKey(r'voucherName'),
            'Required key "OfferTermsModel[voucherName]" is missing from JSON.');
        assert(json.containsKey(r'voucherValue'),
            'Required key "OfferTermsModel[voucherValue]" is missing from JSON.');
        return true;
      }());

      return OfferTermsModel(
        format: ContentFormat.fromJson(json[r'format'])!,
        perViewAmount: mapValueOfType<int>(json, r'perViewAmount'),
        perViewCap: mapValueOfType<int>(json, r'perViewCap'),
        rewardType: RewardType.fromJson(json[r'rewardType'])!,
        voucherName: mapValueOfType<String>(json, r'voucherName'),
        voucherValue: mapValueOfType<int>(json, r'voucherValue'),
      );
    }
    return null;
  }

  static List<OfferTermsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OfferTermsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OfferTermsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OfferTermsModel> mapFromJson(dynamic json) {
    final map = <String, OfferTermsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OfferTermsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OfferTermsModel-objects as value to a dart map
  static Map<String, List<OfferTermsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OfferTermsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OfferTermsModel.listFromJson(
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
    'perViewAmount',
    'perViewCap',
    'rewardType',
    'voucherName',
    'voucherValue',
  };
}

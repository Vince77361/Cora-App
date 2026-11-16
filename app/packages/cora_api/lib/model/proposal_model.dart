//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposalModel {
  /// Returns a new [ProposalModel] instance.
  ProposalModel({
    required this.brandName,
    required this.brandPhotoUrl,
    required this.campaignId,
    required this.contentPhotoUrl,
    required this.contentTitle,
    required this.fee,
    required this.format,
    required this.note,
    required this.performance,
    required this.productProvided,
  });

  String brandName;

  String? brandPhotoUrl;

  String campaignId;

  String? contentPhotoUrl;

  String? contentTitle;

  /// 제안이 붙어 있으면 제안의 제작비, 없으면 캠페인의 제작비.
  int fee;

  ContentFormat format;

  /// 브랜드가 붙인 글(좋아한 점). 조건 제안만 붙었으면 null.
  String? note;

  /// 제안에 붙은 성과 추가. 없으면 null.
  ProposalPerformanceModel? performance;

  /// 제안이 붙어 있으면 제안의 값, 없으면 캠페인의 값.
  bool productProvided;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalModel &&
          other.brandName == brandName &&
          other.brandPhotoUrl == brandPhotoUrl &&
          other.campaignId == campaignId &&
          other.contentPhotoUrl == contentPhotoUrl &&
          other.contentTitle == contentTitle &&
          other.fee == fee &&
          other.format == format &&
          other.note == note &&
          other.performance == performance &&
          other.productProvided == productProvided;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brandName.hashCode) +
      (brandPhotoUrl == null ? 0 : brandPhotoUrl!.hashCode) +
      (campaignId.hashCode) +
      (contentPhotoUrl == null ? 0 : contentPhotoUrl!.hashCode) +
      (contentTitle == null ? 0 : contentTitle!.hashCode) +
      (fee.hashCode) +
      (format.hashCode) +
      (note == null ? 0 : note!.hashCode) +
      (performance == null ? 0 : performance!.hashCode) +
      (productProvided.hashCode);

  @override
  String toString() =>
      'ProposalModel[brandName=$brandName, brandPhotoUrl=$brandPhotoUrl, campaignId=$campaignId, contentPhotoUrl=$contentPhotoUrl, contentTitle=$contentTitle, fee=$fee, format=$format, note=$note, performance=$performance, productProvided=$productProvided]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'brandName'] = this.brandName;
    if (this.brandPhotoUrl != null) {
      json[r'brandPhotoUrl'] = this.brandPhotoUrl;
    } else {
      json[r'brandPhotoUrl'] = null;
    }
    json[r'campaignId'] = this.campaignId;
    if (this.contentPhotoUrl != null) {
      json[r'contentPhotoUrl'] = this.contentPhotoUrl;
    } else {
      json[r'contentPhotoUrl'] = null;
    }
    if (this.contentTitle != null) {
      json[r'contentTitle'] = this.contentTitle;
    } else {
      json[r'contentTitle'] = null;
    }
    json[r'fee'] = this.fee;
    json[r'format'] = this.format;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.performance != null) {
      json[r'performance'] = this.performance;
    } else {
      json[r'performance'] = null;
    }
    json[r'productProvided'] = this.productProvided;
    return json;
  }

  /// Returns a new [ProposalModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposalModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brandName'),
            'Required key "ProposalModel[brandName]" is missing from JSON.');
        assert(json[r'brandName'] != null,
            'Required key "ProposalModel[brandName]" has a null value in JSON.');
        assert(json.containsKey(r'brandPhotoUrl'),
            'Required key "ProposalModel[brandPhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'campaignId'),
            'Required key "ProposalModel[campaignId]" is missing from JSON.');
        assert(json[r'campaignId'] != null,
            'Required key "ProposalModel[campaignId]" has a null value in JSON.');
        assert(json.containsKey(r'contentPhotoUrl'),
            'Required key "ProposalModel[contentPhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'contentTitle'),
            'Required key "ProposalModel[contentTitle]" is missing from JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "ProposalModel[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "ProposalModel[fee]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "ProposalModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "ProposalModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'note'),
            'Required key "ProposalModel[note]" is missing from JSON.');
        assert(json.containsKey(r'performance'),
            'Required key "ProposalModel[performance]" is missing from JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "ProposalModel[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "ProposalModel[productProvided]" has a null value in JSON.');
        return true;
      }());

      return ProposalModel(
        brandName: mapValueOfType<String>(json, r'brandName')!,
        brandPhotoUrl: mapValueOfType<String>(json, r'brandPhotoUrl'),
        campaignId: mapValueOfType<String>(json, r'campaignId')!,
        contentPhotoUrl: mapValueOfType<String>(json, r'contentPhotoUrl'),
        contentTitle: mapValueOfType<String>(json, r'contentTitle'),
        fee: mapValueOfType<int>(json, r'fee')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        note: mapValueOfType<String>(json, r'note'),
        performance: ProposalPerformanceModel.fromJson(json[r'performance']),
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
      );
    }
    return null;
  }

  static List<ProposalModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposalModel> mapFromJson(dynamic json) {
    final map = <String, ProposalModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposalModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposalModel-objects as value to a dart map
  static Map<String, List<ProposalModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposalModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposalModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brandName',
    'brandPhotoUrl',
    'campaignId',
    'contentPhotoUrl',
    'contentTitle',
    'fee',
    'format',
    'note',
    'performance',
    'productProvided',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreResultModel {
  /// Returns a new [StoreResultModel] instance.
  StoreResultModel({
    required this.creator,
    required this.fixedCash,
    required this.fixedCashOnly,
    required this.format,
    required this.multiplierTenths,
    required this.payout,
    required this.postUrl,
    required this.postedAt,
    required this.refund,
    required this.usualViews,
    required this.views,
  });

  StoreResultCreatorModel creator;

  /// 고정 현금(원). 없으면 0.
  int fixedCash;

  /// 고정 현금만 있던 협업이면 true. 조회수를 세지 않아 조회수와 비교 상자가 없다.
  bool fixedCashOnly;

  ContentFormat format;

  /// 평소 대비 배수를 10배 한 정수(31 = 3.1배, 소수 첫째 자리까지 내림). 평소 조회수가 없으면 null.
  int? multiplierTenths;

  /// 크리에이터 지급액(원).
  int payout;

  /// 크리에이터가 낸 게시 링크.
  String postUrl;

  /// 크리에이터가 게시 링크를 낸 시각(ISO 8601).
  DateTime postedAt;

  /// 사장님께 환불한 금액(원).
  int refund;

  /// 가게 인스타그램 계정의 평소 조회수. 링크가 없거나 읽지 못했으면 null이고, 그러면 비교 상자를 숨긴다.
  int? usualViews;

  /// 정산에 쓴 최종 조회수. 조회수를 세지 않은 협업은 null.
  int? views;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreResultModel &&
          other.creator == creator &&
          other.fixedCash == fixedCash &&
          other.fixedCashOnly == fixedCashOnly &&
          other.format == format &&
          other.multiplierTenths == multiplierTenths &&
          other.payout == payout &&
          other.postUrl == postUrl &&
          other.postedAt == postedAt &&
          other.refund == refund &&
          other.usualViews == usualViews &&
          other.views == views;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (creator.hashCode) +
      (fixedCash.hashCode) +
      (fixedCashOnly.hashCode) +
      (format.hashCode) +
      (multiplierTenths == null ? 0 : multiplierTenths!.hashCode) +
      (payout.hashCode) +
      (postUrl.hashCode) +
      (postedAt.hashCode) +
      (refund.hashCode) +
      (usualViews == null ? 0 : usualViews!.hashCode) +
      (views == null ? 0 : views!.hashCode);

  @override
  String toString() =>
      'StoreResultModel[creator=$creator, fixedCash=$fixedCash, fixedCashOnly=$fixedCashOnly, format=$format, multiplierTenths=$multiplierTenths, payout=$payout, postUrl=$postUrl, postedAt=$postedAt, refund=$refund, usualViews=$usualViews, views=$views]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'creator'] = this.creator;
    json[r'fixedCash'] = this.fixedCash;
    json[r'fixedCashOnly'] = this.fixedCashOnly;
    json[r'format'] = this.format;
    if (this.multiplierTenths != null) {
      json[r'multiplierTenths'] = this.multiplierTenths;
    } else {
      json[r'multiplierTenths'] = null;
    }
    json[r'payout'] = this.payout;
    json[r'postUrl'] = this.postUrl;
    json[r'postedAt'] = this.postedAt.toUtc().toIso8601String();
    json[r'refund'] = this.refund;
    if (this.usualViews != null) {
      json[r'usualViews'] = this.usualViews;
    } else {
      json[r'usualViews'] = null;
    }
    if (this.views != null) {
      json[r'views'] = this.views;
    } else {
      json[r'views'] = null;
    }
    return json;
  }

  /// Returns a new [StoreResultModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreResultModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creator'),
            'Required key "StoreResultModel[creator]" is missing from JSON.');
        assert(json[r'creator'] != null,
            'Required key "StoreResultModel[creator]" has a null value in JSON.');
        assert(json.containsKey(r'fixedCash'),
            'Required key "StoreResultModel[fixedCash]" is missing from JSON.');
        assert(json[r'fixedCash'] != null,
            'Required key "StoreResultModel[fixedCash]" has a null value in JSON.');
        assert(json.containsKey(r'fixedCashOnly'),
            'Required key "StoreResultModel[fixedCashOnly]" is missing from JSON.');
        assert(json[r'fixedCashOnly'] != null,
            'Required key "StoreResultModel[fixedCashOnly]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "StoreResultModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "StoreResultModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'multiplierTenths'),
            'Required key "StoreResultModel[multiplierTenths]" is missing from JSON.');
        assert(json.containsKey(r'payout'),
            'Required key "StoreResultModel[payout]" is missing from JSON.');
        assert(json[r'payout'] != null,
            'Required key "StoreResultModel[payout]" has a null value in JSON.');
        assert(json.containsKey(r'postUrl'),
            'Required key "StoreResultModel[postUrl]" is missing from JSON.');
        assert(json[r'postUrl'] != null,
            'Required key "StoreResultModel[postUrl]" has a null value in JSON.');
        assert(json.containsKey(r'postedAt'),
            'Required key "StoreResultModel[postedAt]" is missing from JSON.');
        assert(json[r'postedAt'] != null,
            'Required key "StoreResultModel[postedAt]" has a null value in JSON.');
        assert(json.containsKey(r'refund'),
            'Required key "StoreResultModel[refund]" is missing from JSON.');
        assert(json[r'refund'] != null,
            'Required key "StoreResultModel[refund]" has a null value in JSON.');
        assert(json.containsKey(r'usualViews'),
            'Required key "StoreResultModel[usualViews]" is missing from JSON.');
        assert(json.containsKey(r'views'),
            'Required key "StoreResultModel[views]" is missing from JSON.');
        return true;
      }());

      return StoreResultModel(
        creator: StoreResultCreatorModel.fromJson(json[r'creator'])!,
        fixedCash: mapValueOfType<int>(json, r'fixedCash')!,
        fixedCashOnly: mapValueOfType<bool>(json, r'fixedCashOnly')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        multiplierTenths: mapValueOfType<int>(json, r'multiplierTenths'),
        payout: mapValueOfType<int>(json, r'payout')!,
        postUrl: mapValueOfType<String>(json, r'postUrl')!,
        postedAt: mapDateTime(json, r'postedAt', r'')!,
        refund: mapValueOfType<int>(json, r'refund')!,
        usualViews: mapValueOfType<int>(json, r'usualViews'),
        views: mapValueOfType<int>(json, r'views'),
      );
    }
    return null;
  }

  static List<StoreResultModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreResultModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreResultModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreResultModel> mapFromJson(dynamic json) {
    final map = <String, StoreResultModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreResultModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreResultModel-objects as value to a dart map
  static Map<String, List<StoreResultModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreResultModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreResultModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'creator',
    'fixedCash',
    'fixedCashOnly',
    'format',
    'multiplierTenths',
    'payout',
    'postUrl',
    'postedAt',
    'refund',
    'usualViews',
    'views',
  };
}

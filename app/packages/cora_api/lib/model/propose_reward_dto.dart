//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposeRewardDto {
  /// Returns a new [ProposeRewardDto] instance.
  ProposeRewardDto({
    required this.baseVersion,
    required this.fee,
    this.performance,
    required this.productProvided,
  });

  /// 내가 보고 있던 판본 번호. 최신이 아니면 409 STALE_VERSION이다.
  ///
  /// Minimum value: 1
  int baseVersion;

  /// 제작비(원). 1만 원 단위, 10000~10000000.
  int fee;

  /// 성과 추가. 없으면 null. 블로그 글에는 붙일 수 없다.
  RewardPerformanceDto? performance;

  /// 제품 제공 여부.
  bool productProvided;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposeRewardDto &&
          other.baseVersion == baseVersion &&
          other.fee == fee &&
          other.performance == performance &&
          other.productProvided == productProvided;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (baseVersion.hashCode) +
      (fee.hashCode) +
      (performance == null ? 0 : performance!.hashCode) +
      (productProvided.hashCode);

  @override
  String toString() =>
      'ProposeRewardDto[baseVersion=$baseVersion, fee=$fee, performance=$performance, productProvided=$productProvided]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'baseVersion'] = this.baseVersion;
    json[r'fee'] = this.fee;
    if (this.performance != null) {
      json[r'performance'] = this.performance;
    } else {
      json[r'performance'] = null;
    }
    json[r'productProvided'] = this.productProvided;
    return json;
  }

  /// Returns a new [ProposeRewardDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposeRewardDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'baseVersion'),
            'Required key "ProposeRewardDto[baseVersion]" is missing from JSON.');
        assert(json[r'baseVersion'] != null,
            'Required key "ProposeRewardDto[baseVersion]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "ProposeRewardDto[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "ProposeRewardDto[fee]" has a null value in JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "ProposeRewardDto[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "ProposeRewardDto[productProvided]" has a null value in JSON.');
        return true;
      }());

      return ProposeRewardDto(
        baseVersion: mapValueOfType<int>(json, r'baseVersion')!,
        fee: mapValueOfType<int>(json, r'fee')!,
        performance: RewardPerformanceDto.fromJson(json[r'performance']),
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
      );
    }
    return null;
  }

  static List<ProposeRewardDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposeRewardDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposeRewardDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposeRewardDto> mapFromJson(dynamic json) {
    final map = <String, ProposeRewardDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposeRewardDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposeRewardDto-objects as value to a dart map
  static Map<String, List<ProposeRewardDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposeRewardDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposeRewardDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'baseVersion',
    'fee',
    'productProvided',
  };
}

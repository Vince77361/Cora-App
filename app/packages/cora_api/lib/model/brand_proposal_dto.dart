//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class BrandProposalDto {
  /// Returns a new [BrandProposalDto] instance.
  BrandProposalDto({
    required this.fee,
    this.performance,
    required this.productProvided,
  });

  /// 제작비(원). 1만 원 단위, 10000~10000000.
  int fee;

  /// 성과 추가. 없으면 null. 캠페인 형식이 블로그 글이면 받지 않는다.
  ProposalPerformanceDto? performance;

  /// 제품 제공 여부.
  bool productProvided;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandProposalDto &&
          other.fee == fee &&
          other.performance == performance &&
          other.productProvided == productProvided;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (fee.hashCode) +
      (performance == null ? 0 : performance!.hashCode) +
      (productProvided.hashCode);

  @override
  String toString() =>
      'BrandProposalDto[fee=$fee, performance=$performance, productProvided=$productProvided]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'fee'] = this.fee;
    if (this.performance != null) {
      json[r'performance'] = this.performance;
    } else {
      json[r'performance'] = null;
    }
    json[r'productProvided'] = this.productProvided;
    return json;
  }

  /// Returns a new [BrandProposalDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BrandProposalDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fee'),
            'Required key "BrandProposalDto[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "BrandProposalDto[fee]" has a null value in JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "BrandProposalDto[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "BrandProposalDto[productProvided]" has a null value in JSON.');
        return true;
      }());

      return BrandProposalDto(
        fee: mapValueOfType<int>(json, r'fee')!,
        performance: ProposalPerformanceDto.fromJson(json[r'performance']),
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
      );
    }
    return null;
  }

  static List<BrandProposalDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BrandProposalDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BrandProposalDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BrandProposalDto> mapFromJson(dynamic json) {
    final map = <String, BrandProposalDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BrandProposalDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BrandProposalDto-objects as value to a dart map
  static Map<String, List<BrandProposalDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BrandProposalDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BrandProposalDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fee',
    'productProvided',
  };
}

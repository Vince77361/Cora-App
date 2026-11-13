//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RewardInputDto {
  /// Returns a new [RewardInputDto] instance.
  RewardInputDto({
    this.fixedCash,
    this.perView,
    this.voucher,
  });

  /// 고정 현금(원). 없으면 0.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? fixedCash;

  PerViewInputDto? perView;

  VoucherInputDto? voucher;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardInputDto &&
          other.fixedCash == fixedCash &&
          other.perView == perView &&
          other.voucher == voucher;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (fixedCash == null ? 0 : fixedCash!.hashCode) +
      (perView == null ? 0 : perView!.hashCode) +
      (voucher == null ? 0 : voucher!.hashCode);

  @override
  String toString() =>
      'RewardInputDto[fixedCash=$fixedCash, perView=$perView, voucher=$voucher]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.fixedCash != null) {
      json[r'fixedCash'] = this.fixedCash;
    } else {
      json[r'fixedCash'] = null;
    }
    if (this.perView != null) {
      json[r'perView'] = this.perView;
    } else {
      json[r'perView'] = null;
    }
    if (this.voucher != null) {
      json[r'voucher'] = this.voucher;
    } else {
      json[r'voucher'] = null;
    }
    return json;
  }

  /// Returns a new [RewardInputDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RewardInputDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return RewardInputDto(
        fixedCash: mapValueOfType<int>(json, r'fixedCash'),
        perView: PerViewInputDto.fromJson(json[r'perView']),
        voucher: VoucherInputDto.fromJson(json[r'voucher']),
      );
    }
    return null;
  }

  static List<RewardInputDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RewardInputDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RewardInputDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RewardInputDto> mapFromJson(dynamic json) {
    final map = <String, RewardInputDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RewardInputDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RewardInputDto-objects as value to a dart map
  static Map<String, List<RewardInputDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RewardInputDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RewardInputDto.listFromJson(
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

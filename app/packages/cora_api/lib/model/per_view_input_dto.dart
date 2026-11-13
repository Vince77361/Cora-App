//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PerViewInputDto {
  /// Returns a new [PerViewInputDto] instance.
  PerViewInputDto({
    this.cap,
    this.ratePerThousand,
  });

  /// 조회수 수당 상한(원). 없으면 가게의 모집 조건, 그것도 없으면 60000.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? cap;

  /// 조회수 단가(1,000회당 원). 없으면 가게의 모집 조건, 그것도 없으면 2000.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? ratePerThousand;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerViewInputDto &&
          other.cap == cap &&
          other.ratePerThousand == ratePerThousand;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cap == null ? 0 : cap!.hashCode) +
      (ratePerThousand == null ? 0 : ratePerThousand!.hashCode);

  @override
  String toString() =>
      'PerViewInputDto[cap=$cap, ratePerThousand=$ratePerThousand]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.cap != null) {
      json[r'cap'] = this.cap;
    } else {
      json[r'cap'] = null;
    }
    if (this.ratePerThousand != null) {
      json[r'ratePerThousand'] = this.ratePerThousand;
    } else {
      json[r'ratePerThousand'] = null;
    }
    return json;
  }

  /// Returns a new [PerViewInputDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PerViewInputDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PerViewInputDto(
        cap: mapValueOfType<int>(json, r'cap'),
        ratePerThousand: mapValueOfType<int>(json, r'ratePerThousand'),
      );
    }
    return null;
  }

  static List<PerViewInputDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PerViewInputDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PerViewInputDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PerViewInputDto> mapFromJson(dynamic json) {
    final map = <String, PerViewInputDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PerViewInputDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PerViewInputDto-objects as value to a dart map
  static Map<String, List<PerViewInputDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PerViewInputDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PerViewInputDto.listFromJson(
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

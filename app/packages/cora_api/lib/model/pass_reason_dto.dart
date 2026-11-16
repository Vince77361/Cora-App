//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PassReasonDto {
  /// Returns a new [PassReasonDto] instance.
  PassReasonDto({
    required this.reason,
    required this.targetId,
    required this.targetKind,
  });

  PassReason reason;

  String targetId;

  SwipeTargetKind targetKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassReasonDto &&
          other.reason == reason &&
          other.targetId == targetId &&
          other.targetKind == targetKind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (reason.hashCode) + (targetId.hashCode) + (targetKind.hashCode);

  @override
  String toString() =>
      'PassReasonDto[reason=$reason, targetId=$targetId, targetKind=$targetKind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'reason'] = this.reason;
    json[r'targetId'] = this.targetId;
    json[r'targetKind'] = this.targetKind;
    return json;
  }

  /// Returns a new [PassReasonDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PassReasonDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'reason'),
            'Required key "PassReasonDto[reason]" is missing from JSON.');
        assert(json[r'reason'] != null,
            'Required key "PassReasonDto[reason]" has a null value in JSON.');
        assert(json.containsKey(r'targetId'),
            'Required key "PassReasonDto[targetId]" is missing from JSON.');
        assert(json[r'targetId'] != null,
            'Required key "PassReasonDto[targetId]" has a null value in JSON.');
        assert(json.containsKey(r'targetKind'),
            'Required key "PassReasonDto[targetKind]" is missing from JSON.');
        assert(json[r'targetKind'] != null,
            'Required key "PassReasonDto[targetKind]" has a null value in JSON.');
        return true;
      }());

      return PassReasonDto(
        reason: PassReason.fromJson(json[r'reason'])!,
        targetId: mapValueOfType<String>(json, r'targetId')!,
        targetKind: SwipeTargetKind.fromJson(json[r'targetKind'])!,
      );
    }
    return null;
  }

  static List<PassReasonDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PassReasonDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PassReasonDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PassReasonDto> mapFromJson(dynamic json) {
    final map = <String, PassReasonDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PassReasonDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PassReasonDto-objects as value to a dart map
  static Map<String, List<PassReasonDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PassReasonDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PassReasonDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reason',
    'targetId',
    'targetKind',
  };
}

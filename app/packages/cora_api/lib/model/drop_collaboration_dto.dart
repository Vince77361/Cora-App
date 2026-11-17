//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class DropCollaborationDto {
  /// Returns a new [DropCollaborationDto] instance.
  DropCollaborationDto({
    required this.reason,
  });

  /// 그만두는 이유. 서버에만 남고 상대에게는 알리지 않는다(상대는 \"이번에는 함께하기 어렵대요.\"만 본다).
  DropReasonChoice reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropCollaborationDto && other.reason == reason;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (reason.hashCode);

  @override
  String toString() => 'DropCollaborationDto[reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'reason'] = this.reason;
    return json;
  }

  /// Returns a new [DropCollaborationDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DropCollaborationDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'reason'),
            'Required key "DropCollaborationDto[reason]" is missing from JSON.');
        assert(json[r'reason'] != null,
            'Required key "DropCollaborationDto[reason]" has a null value in JSON.');
        return true;
      }());

      return DropCollaborationDto(
        reason: DropReasonChoice.fromJson(json[r'reason'])!,
      );
    }
    return null;
  }

  static List<DropCollaborationDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DropCollaborationDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DropCollaborationDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DropCollaborationDto> mapFromJson(dynamic json) {
    final map = <String, DropCollaborationDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DropCollaborationDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DropCollaborationDto-objects as value to a dart map
  static Map<String, List<DropCollaborationDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DropCollaborationDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DropCollaborationDto.listFromJson(
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
  };
}

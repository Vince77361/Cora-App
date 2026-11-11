//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class AdvanceOnboardingDto {
  /// Returns a new [AdvanceOnboardingDto] instance.
  AdvanceOnboardingDto({
    required this.step,
  });

  AdvanceOnboardingStep step;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvanceOnboardingDto && other.step == step;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (step.hashCode);

  @override
  String toString() => 'AdvanceOnboardingDto[step=$step]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'step'] = this.step;
    return json;
  }

  /// Returns a new [AdvanceOnboardingDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdvanceOnboardingDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'step'),
            'Required key "AdvanceOnboardingDto[step]" is missing from JSON.');
        assert(json[r'step'] != null,
            'Required key "AdvanceOnboardingDto[step]" has a null value in JSON.');
        return true;
      }());

      return AdvanceOnboardingDto(
        step: AdvanceOnboardingStep.fromJson(json[r'step'])!,
      );
    }
    return null;
  }

  static List<AdvanceOnboardingDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AdvanceOnboardingDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdvanceOnboardingDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdvanceOnboardingDto> mapFromJson(dynamic json) {
    final map = <String, AdvanceOnboardingDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdvanceOnboardingDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdvanceOnboardingDto-objects as value to a dart map
  static Map<String, List<AdvanceOnboardingDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AdvanceOnboardingDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdvanceOnboardingDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'step',
  };
}

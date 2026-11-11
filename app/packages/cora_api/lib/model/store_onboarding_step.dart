//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum StoreOnboardingStep {
  PAGE._(r'PAGE'),
  DRAFTS._(r'DRAFTS'),
  TERMS._(r'TERMS'),
  DONE._(r'DONE'),
  ;

  /// Instantiate a new enum with the provided value.
  const StoreOnboardingStep._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [StoreOnboardingStep] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static StoreOnboardingStep? fromJson(dynamic value) =>
      StoreOnboardingStepTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [StoreOnboardingStep]
  /// that were successfully decoded from the passed [JSON][json].
  static List<StoreOnboardingStep> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreOnboardingStep>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreOnboardingStep.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [StoreOnboardingStep] to String,
/// and [decode] dynamic data back to [StoreOnboardingStep].
class StoreOnboardingStepTypeTransformer {
  factory StoreOnboardingStepTypeTransformer() =>
      _instance ??= const StoreOnboardingStepTypeTransformer._();

  const StoreOnboardingStepTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(StoreOnboardingStep data) => data._value;

  /// Returns the instance of [StoreOnboardingStep] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  StoreOnboardingStep? decode(dynamic data, {bool allowNull = true}) {
    if (data is StoreOnboardingStep) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PAGE':
          return StoreOnboardingStep.PAGE;
        case r'DRAFTS':
          return StoreOnboardingStep.DRAFTS;
        case r'TERMS':
          return StoreOnboardingStep.TERMS;
        case r'DONE':
          return StoreOnboardingStep.DONE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static StoreOnboardingStepTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// USER는 내가 참가한 방의 상대, CONVERSATION은 내가 참가한 방이다.
enum ReportTargetKind {
  USER._(r'USER'),
  CONVERSATION._(r'CONVERSATION'),
  ;

  /// Instantiate a new enum with the provided value.
  const ReportTargetKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ReportTargetKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ReportTargetKind? fromJson(dynamic value) =>
      ReportTargetKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ReportTargetKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ReportTargetKind> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ReportTargetKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReportTargetKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ReportTargetKind] to String,
/// and [decode] dynamic data back to [ReportTargetKind].
class ReportTargetKindTypeTransformer {
  factory ReportTargetKindTypeTransformer() =>
      _instance ??= const ReportTargetKindTypeTransformer._();

  const ReportTargetKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ReportTargetKind data) => data._value;

  /// Returns the instance of [ReportTargetKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ReportTargetKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is ReportTargetKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'USER':
          return ReportTargetKind.USER;
        case r'CONVERSATION':
          return ReportTargetKind.CONVERSATION;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ReportTargetKindTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum ConversationStatus {
  REQUESTED._(r'REQUESTED'),
  OPEN._(r'OPEN'),
  DECLINED._(r'DECLINED'),
  CLOSED._(r'CLOSED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ConversationStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ConversationStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ConversationStatus? fromJson(dynamic value) =>
      ConversationStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ConversationStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ConversationStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConversationStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ConversationStatus] to String,
/// and [decode] dynamic data back to [ConversationStatus].
class ConversationStatusTypeTransformer {
  factory ConversationStatusTypeTransformer() =>
      _instance ??= const ConversationStatusTypeTransformer._();

  const ConversationStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ConversationStatus data) => data._value;

  /// Returns the instance of [ConversationStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ConversationStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is ConversationStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'REQUESTED':
          return ConversationStatus.REQUESTED;
        case r'OPEN':
          return ConversationStatus.OPEN;
        case r'DECLINED':
          return ConversationStatus.DECLINED;
        case r'CLOSED':
          return ConversationStatus.CLOSED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ConversationStatusTypeTransformer? _instance;
}

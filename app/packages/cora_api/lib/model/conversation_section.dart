//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// REQUEST: 내가 답해야 하는 메시지 요청(목록 맨 위에 모인다). 그 밖은 NORMAL.
enum ConversationSection {
  REQUEST._(r'REQUEST'),
  NORMAL._(r'NORMAL'),
  ;

  /// Instantiate a new enum with the provided value.
  const ConversationSection._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ConversationSection] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ConversationSection? fromJson(dynamic value) =>
      ConversationSectionTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ConversationSection]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ConversationSection> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConversationSection>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationSection.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ConversationSection] to String,
/// and [decode] dynamic data back to [ConversationSection].
class ConversationSectionTypeTransformer {
  factory ConversationSectionTypeTransformer() =>
      _instance ??= const ConversationSectionTypeTransformer._();

  const ConversationSectionTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ConversationSection data) => data._value;

  /// Returns the instance of [ConversationSection] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ConversationSection? decode(dynamic data, {bool allowNull = true}) {
    if (data is ConversationSection) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'REQUEST':
          return ConversationSection.REQUEST;
        case r'NORMAL':
          return ConversationSection.NORMAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ConversationSectionTypeTransformer? _instance;
}

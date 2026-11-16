//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 현재 단계 줄의 보조 글. WAITING_OTHER_CONFIRM: 상대의 동의를 기다림, WAITING_CONTRACT: 계약을 진행해야 함.
enum BrandProgressNote {
  WAITING_OTHER_CONFIRM._(r'WAITING_OTHER_CONFIRM'),
  WAITING_CONTRACT._(r'WAITING_CONTRACT'),
  ;

  /// Instantiate a new enum with the provided value.
  const BrandProgressNote._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [BrandProgressNote] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static BrandProgressNote? fromJson(dynamic value) =>
      BrandProgressNoteTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [BrandProgressNote]
  /// that were successfully decoded from the passed [JSON][json].
  static List<BrandProgressNote> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BrandProgressNote>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BrandProgressNote.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BrandProgressNote] to String,
/// and [decode] dynamic data back to [BrandProgressNote].
class BrandProgressNoteTypeTransformer {
  factory BrandProgressNoteTypeTransformer() =>
      _instance ??= const BrandProgressNoteTypeTransformer._();

  const BrandProgressNoteTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(BrandProgressNote data) => data._value;

  /// Returns the instance of [BrandProgressNote] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BrandProgressNote? decode(dynamic data, {bool allowNull = true}) {
    if (data is BrandProgressNote) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WAITING_OTHER_CONFIRM':
          return BrandProgressNote.WAITING_OTHER_CONFIRM;
        case r'WAITING_CONTRACT':
          return BrandProgressNote.WAITING_CONTRACT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static BrandProgressNoteTypeTransformer? _instance;
}

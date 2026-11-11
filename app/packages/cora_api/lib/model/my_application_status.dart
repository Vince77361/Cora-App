//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 내가 이 가게에 낸 지금 살아 있는 지원의 상태. 없으면 NONE.
enum MyApplicationStatus {
  NONE._(r'NONE'),
  APPLIED._(r'APPLIED'),
  OFFERED._(r'OFFERED'),
  ;

  /// Instantiate a new enum with the provided value.
  const MyApplicationStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MyApplicationStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MyApplicationStatus? fromJson(dynamic value) =>
      MyApplicationStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MyApplicationStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MyApplicationStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MyApplicationStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MyApplicationStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MyApplicationStatus] to String,
/// and [decode] dynamic data back to [MyApplicationStatus].
class MyApplicationStatusTypeTransformer {
  factory MyApplicationStatusTypeTransformer() =>
      _instance ??= const MyApplicationStatusTypeTransformer._();

  const MyApplicationStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MyApplicationStatus data) => data._value;

  /// Returns the instance of [MyApplicationStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MyApplicationStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is MyApplicationStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NONE':
          return MyApplicationStatus.NONE;
        case r'APPLIED':
          return MyApplicationStatus.APPLIED;
        case r'OFFERED':
          return MyApplicationStatus.OFFERED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MyApplicationStatusTypeTransformer? _instance;
}

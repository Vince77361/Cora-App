//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// CONNECTED_ACCOUNT: 연결한 인스타그램 계정에서 읽음, CAPTURE_PENDING: 캡처 자료(계산 전에 캡처가 제출된 상태, 또는 캡처로 만든 계산의 확인 전), CAPTURE_CONFIRMED: 캡처 자료(확정됨).
enum ViewReportSource {
  CONNECTED_ACCOUNT._(r'CONNECTED_ACCOUNT'),
  CAPTURE_PENDING._(r'CAPTURE_PENDING'),
  CAPTURE_CONFIRMED._(r'CAPTURE_CONFIRMED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ViewReportSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ViewReportSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ViewReportSource? fromJson(dynamic value) =>
      ViewReportSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ViewReportSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ViewReportSource> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ViewReportSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewReportSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ViewReportSource] to String,
/// and [decode] dynamic data back to [ViewReportSource].
class ViewReportSourceTypeTransformer {
  factory ViewReportSourceTypeTransformer() =>
      _instance ??= const ViewReportSourceTypeTransformer._();

  const ViewReportSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ViewReportSource data) => data._value;

  /// Returns the instance of [ViewReportSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ViewReportSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is ViewReportSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CONNECTED_ACCOUNT':
          return ViewReportSource.CONNECTED_ACCOUNT;
        case r'CAPTURE_PENDING':
          return ViewReportSource.CAPTURE_PENDING;
        case r'CAPTURE_CONFIRMED':
          return ViewReportSource.CAPTURE_CONFIRMED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ViewReportSourceTypeTransformer? _instance;
}

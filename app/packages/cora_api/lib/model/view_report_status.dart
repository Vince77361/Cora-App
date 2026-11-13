//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// COUNTING: 집계 중(계산 없음), UNCONFIRMED: 계산이 나왔고 확인을 기다림, CONFIRMED: 확인되어 정산됨, DISPUTED: 이의가 걸려 돈이 그대로 보관됨.
enum ViewReportStatus {
  COUNTING._(r'COUNTING'),
  UNCONFIRMED._(r'UNCONFIRMED'),
  CONFIRMED._(r'CONFIRMED'),
  DISPUTED._(r'DISPUTED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ViewReportStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ViewReportStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ViewReportStatus? fromJson(dynamic value) =>
      ViewReportStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ViewReportStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ViewReportStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ViewReportStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewReportStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ViewReportStatus] to String,
/// and [decode] dynamic data back to [ViewReportStatus].
class ViewReportStatusTypeTransformer {
  factory ViewReportStatusTypeTransformer() =>
      _instance ??= const ViewReportStatusTypeTransformer._();

  const ViewReportStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ViewReportStatus data) => data._value;

  /// Returns the instance of [ViewReportStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ViewReportStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is ViewReportStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'COUNTING':
          return ViewReportStatus.COUNTING;
        case r'UNCONFIRMED':
          return ViewReportStatus.UNCONFIRMED;
        case r'CONFIRMED':
          return ViewReportStatus.CONFIRMED;
        case r'DISPUTED':
          return ViewReportStatus.DISPUTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ViewReportStatusTypeTransformer? _instance;
}

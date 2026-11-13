//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중.
enum CollaborationViewReportStatus {
  NONE._(r'NONE'),
  COUNTING._(r'COUNTING'),
  UNCONFIRMED._(r'UNCONFIRMED'),
  CONFIRMED._(r'CONFIRMED'),
  DISPUTED._(r'DISPUTED'),
  ;

  /// Instantiate a new enum with the provided value.
  const CollaborationViewReportStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CollaborationViewReportStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CollaborationViewReportStatus? fromJson(dynamic value) =>
      CollaborationViewReportStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CollaborationViewReportStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CollaborationViewReportStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationViewReportStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationViewReportStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CollaborationViewReportStatus] to String,
/// and [decode] dynamic data back to [CollaborationViewReportStatus].
class CollaborationViewReportStatusTypeTransformer {
  factory CollaborationViewReportStatusTypeTransformer() =>
      _instance ??= const CollaborationViewReportStatusTypeTransformer._();

  const CollaborationViewReportStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(CollaborationViewReportStatus data) => data._value;

  /// Returns the instance of [CollaborationViewReportStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CollaborationViewReportStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is CollaborationViewReportStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NONE':
          return CollaborationViewReportStatus.NONE;
        case r'COUNTING':
          return CollaborationViewReportStatus.COUNTING;
        case r'UNCONFIRMED':
          return CollaborationViewReportStatus.UNCONFIRMED;
        case r'CONFIRMED':
          return CollaborationViewReportStatus.CONFIRMED;
        case r'DISPUTED':
          return CollaborationViewReportStatus.DISPUTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CollaborationViewReportStatusTypeTransformer? _instance;
}

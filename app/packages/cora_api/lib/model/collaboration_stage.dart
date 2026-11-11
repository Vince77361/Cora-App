//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum CollaborationStage {
  AWAITING_PAYMENT._(r'AWAITING_PAYMENT'),
  FUNDED._(r'FUNDED'),
  COUNTING._(r'COUNTING'),
  SETTLED._(r'SETTLED'),
  REFUNDED._(r'REFUNDED'),
  CANCELLED._(r'CANCELLED'),
  INQUIRY._(r'INQUIRY'),
  MATCHED._(r'MATCHED'),
  NEGOTIATING._(r'NEGOTIATING'),
  AGREED._(r'AGREED'),
  CONTRACTED._(r'CONTRACTED'),
  GUIDED._(r'GUIDED'),
  REVIEWING._(r'REVIEWING'),
  APPROVED._(r'APPROVED'),
  PUBLISHED._(r'PUBLISHED'),
  DROPPED._(r'DROPPED'),
  HALTED._(r'HALTED'),
  ;

  /// Instantiate a new enum with the provided value.
  const CollaborationStage._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CollaborationStage] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CollaborationStage? fromJson(dynamic value) =>
      CollaborationStageTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CollaborationStage]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CollaborationStage> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationStage>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationStage.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CollaborationStage] to String,
/// and [decode] dynamic data back to [CollaborationStage].
class CollaborationStageTypeTransformer {
  factory CollaborationStageTypeTransformer() =>
      _instance ??= const CollaborationStageTypeTransformer._();

  const CollaborationStageTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(CollaborationStage data) => data._value;

  /// Returns the instance of [CollaborationStage] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CollaborationStage? decode(dynamic data, {bool allowNull = true}) {
    if (data is CollaborationStage) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'AWAITING_PAYMENT':
          return CollaborationStage.AWAITING_PAYMENT;
        case r'FUNDED':
          return CollaborationStage.FUNDED;
        case r'COUNTING':
          return CollaborationStage.COUNTING;
        case r'SETTLED':
          return CollaborationStage.SETTLED;
        case r'REFUNDED':
          return CollaborationStage.REFUNDED;
        case r'CANCELLED':
          return CollaborationStage.CANCELLED;
        case r'INQUIRY':
          return CollaborationStage.INQUIRY;
        case r'MATCHED':
          return CollaborationStage.MATCHED;
        case r'NEGOTIATING':
          return CollaborationStage.NEGOTIATING;
        case r'AGREED':
          return CollaborationStage.AGREED;
        case r'CONTRACTED':
          return CollaborationStage.CONTRACTED;
        case r'GUIDED':
          return CollaborationStage.GUIDED;
        case r'REVIEWING':
          return CollaborationStage.REVIEWING;
        case r'APPROVED':
          return CollaborationStage.APPROVED;
        case r'PUBLISHED':
          return CollaborationStage.PUBLISHED;
        case r'DROPPED':
          return CollaborationStage.DROPPED;
        case r'HALTED':
          return CollaborationStage.HALTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CollaborationStageTypeTransformer? _instance;
}

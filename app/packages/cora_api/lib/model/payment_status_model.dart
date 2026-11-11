//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PaymentStatusModel {
  /// Returns a new [PaymentStatusModel] instance.
  PaymentStatusModel({
    required this.status,
  });

  /// 결제 완료 여부는 결제창의 결과가 아니라 서버가 PG에서 받은 통지로 정해진다. 앱은 창이 닫힌 뒤 이 값을 묻는다.
  PaymentStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusModel && other.status == status;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (status.hashCode);

  @override
  String toString() => 'PaymentStatusModel[status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [PaymentStatusModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentStatusModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'),
            'Required key "PaymentStatusModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "PaymentStatusModel[status]" has a null value in JSON.');
        return true;
      }());

      return PaymentStatusModel(
        status: PaymentStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<PaymentStatusModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PaymentStatusModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentStatusModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentStatusModel> mapFromJson(dynamic json) {
    final map = <String, PaymentStatusModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentStatusModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentStatusModel-objects as value to a dart map
  static Map<String, List<PaymentStatusModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PaymentStatusModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentStatusModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
  };
}

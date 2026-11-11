//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PaymentCreatedModel {
  /// Returns a new [PaymentCreatedModel] instance.
  PaymentCreatedModel({
    required this.checkoutUrl,
    required this.paymentId,
  });

  /// 앱이 여는 결제창 주소.
  String checkoutUrl;

  String paymentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentCreatedModel &&
          other.checkoutUrl == checkoutUrl &&
          other.paymentId == paymentId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (checkoutUrl.hashCode) + (paymentId.hashCode);

  @override
  String toString() =>
      'PaymentCreatedModel[checkoutUrl=$checkoutUrl, paymentId=$paymentId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'checkoutUrl'] = this.checkoutUrl;
    json[r'paymentId'] = this.paymentId;
    return json;
  }

  /// Returns a new [PaymentCreatedModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentCreatedModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'checkoutUrl'),
            'Required key "PaymentCreatedModel[checkoutUrl]" is missing from JSON.');
        assert(json[r'checkoutUrl'] != null,
            'Required key "PaymentCreatedModel[checkoutUrl]" has a null value in JSON.');
        assert(json.containsKey(r'paymentId'),
            'Required key "PaymentCreatedModel[paymentId]" is missing from JSON.');
        assert(json[r'paymentId'] != null,
            'Required key "PaymentCreatedModel[paymentId]" has a null value in JSON.');
        return true;
      }());

      return PaymentCreatedModel(
        checkoutUrl: mapValueOfType<String>(json, r'checkoutUrl')!,
        paymentId: mapValueOfType<String>(json, r'paymentId')!,
      );
    }
    return null;
  }

  static List<PaymentCreatedModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PaymentCreatedModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentCreatedModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentCreatedModel> mapFromJson(dynamic json) {
    final map = <String, PaymentCreatedModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentCreatedModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentCreatedModel-objects as value to a dart map
  static Map<String, List<PaymentCreatedModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PaymentCreatedModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentCreatedModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checkoutUrl',
    'paymentId',
  };
}

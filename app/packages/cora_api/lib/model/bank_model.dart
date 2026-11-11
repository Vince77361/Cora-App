//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class BankModel {
  /// Returns a new [BankModel] instance.
  BankModel({
    required this.code,
    required this.fullName,
    required this.name,
  });

  /// 금융결제원 은행 코드(세 자리).
  String code;

  /// 계좌 화면에 보이는 이름. 예: 국민은행
  String fullName;

  /// 고르는 목록에 쓰는 이름. 예: 국민
  String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankModel &&
          other.code == code &&
          other.fullName == fullName &&
          other.name == name;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (code.hashCode) + (fullName.hashCode) + (name.hashCode);

  @override
  String toString() => 'BankModel[code=$code, fullName=$fullName, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'code'] = this.code;
    json[r'fullName'] = this.fullName;
    json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [BankModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BankModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'),
            'Required key "BankModel[code]" is missing from JSON.');
        assert(json[r'code'] != null,
            'Required key "BankModel[code]" has a null value in JSON.');
        assert(json.containsKey(r'fullName'),
            'Required key "BankModel[fullName]" is missing from JSON.');
        assert(json[r'fullName'] != null,
            'Required key "BankModel[fullName]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "BankModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "BankModel[name]" has a null value in JSON.');
        return true;
      }());

      return BankModel(
        code: mapValueOfType<String>(json, r'code')!,
        fullName: mapValueOfType<String>(json, r'fullName')!,
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<BankModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BankModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BankModel> mapFromJson(dynamic json) {
    final map = <String, BankModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BankModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BankModel-objects as value to a dart map
  static Map<String, List<BankModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BankModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BankModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'fullName',
    'name',
  };
}

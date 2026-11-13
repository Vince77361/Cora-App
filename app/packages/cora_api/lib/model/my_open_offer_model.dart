//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MyOpenOfferModel {
  /// Returns a new [MyOpenOfferModel] instance.
  MyOpenOfferModel({
    required this.id,
    required this.latestVersion,
    required this.myTurn,
  });

  String id;

  /// 가장 새 판본의 번호.
  int latestVersion;

  /// 내가 응답할 차례이면 true. 내 방식으로 새 판본을 낼 수 있다.
  bool myTurn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyOpenOfferModel &&
          other.id == id &&
          other.latestVersion == latestVersion &&
          other.myTurn == myTurn;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (latestVersion.hashCode) + (myTurn.hashCode);

  @override
  String toString() =>
      'MyOpenOfferModel[id=$id, latestVersion=$latestVersion, myTurn=$myTurn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'latestVersion'] = this.latestVersion;
    json[r'myTurn'] = this.myTurn;
    return json;
  }

  /// Returns a new [MyOpenOfferModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MyOpenOfferModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "MyOpenOfferModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "MyOpenOfferModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'latestVersion'),
            'Required key "MyOpenOfferModel[latestVersion]" is missing from JSON.');
        assert(json[r'latestVersion'] != null,
            'Required key "MyOpenOfferModel[latestVersion]" has a null value in JSON.');
        assert(json.containsKey(r'myTurn'),
            'Required key "MyOpenOfferModel[myTurn]" is missing from JSON.');
        assert(json[r'myTurn'] != null,
            'Required key "MyOpenOfferModel[myTurn]" has a null value in JSON.');
        return true;
      }());

      return MyOpenOfferModel(
        id: mapValueOfType<String>(json, r'id')!,
        latestVersion: mapValueOfType<int>(json, r'latestVersion')!,
        myTurn: mapValueOfType<bool>(json, r'myTurn')!,
      );
    }
    return null;
  }

  static List<MyOpenOfferModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MyOpenOfferModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MyOpenOfferModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MyOpenOfferModel> mapFromJson(dynamic json) {
    final map = <String, MyOpenOfferModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MyOpenOfferModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MyOpenOfferModel-objects as value to a dart map
  static Map<String, List<MyOpenOfferModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MyOpenOfferModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MyOpenOfferModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'latestVersion',
    'myTurn',
  };
}

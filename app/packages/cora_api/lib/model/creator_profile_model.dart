//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatorProfileModel {
  /// Returns a new [CreatorProfileModel] instance.
  CreatorProfileModel({
    required this.contentFocus,
    required this.displayName,
    required this.followers,
    required this.instagramConnected,
    required this.instagramHandle,
    required this.photoUrl,
    required this.regionSido,
    required this.regionSigungu,
    required this.userId,
  });

  String? contentFocus;

  String displayName;

  /// 연결한 계정의 팔로워 수. 연결이 없거나 읽지 못했으면 null.
  int? followers;

  /// 인스타그램 계정을 연결했으면 true.
  bool instagramConnected;

  String? instagramHandle;

  String? photoUrl;

  String regionSido;

  String? regionSigungu;

  String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatorProfileModel &&
          other.contentFocus == contentFocus &&
          other.displayName == displayName &&
          other.followers == followers &&
          other.instagramConnected == instagramConnected &&
          other.instagramHandle == instagramHandle &&
          other.photoUrl == photoUrl &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu &&
          other.userId == userId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentFocus == null ? 0 : contentFocus!.hashCode) +
      (displayName.hashCode) +
      (followers == null ? 0 : followers!.hashCode) +
      (instagramConnected.hashCode) +
      (instagramHandle == null ? 0 : instagramHandle!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (regionSido.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode) +
      (userId.hashCode);

  @override
  String toString() =>
      'CreatorProfileModel[contentFocus=$contentFocus, displayName=$displayName, followers=$followers, instagramConnected=$instagramConnected, instagramHandle=$instagramHandle, photoUrl=$photoUrl, regionSido=$regionSido, regionSigungu=$regionSigungu, userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentFocus != null) {
      json[r'contentFocus'] = this.contentFocus;
    } else {
      json[r'contentFocus'] = null;
    }
    json[r'displayName'] = this.displayName;
    if (this.followers != null) {
      json[r'followers'] = this.followers;
    } else {
      json[r'followers'] = null;
    }
    json[r'instagramConnected'] = this.instagramConnected;
    if (this.instagramHandle != null) {
      json[r'instagramHandle'] = this.instagramHandle;
    } else {
      json[r'instagramHandle'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'regionSido'] = this.regionSido;
    if (this.regionSigungu != null) {
      json[r'regionSigungu'] = this.regionSigungu;
    } else {
      json[r'regionSigungu'] = null;
    }
    json[r'userId'] = this.userId;
    return json;
  }

  /// Returns a new [CreatorProfileModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatorProfileModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contentFocus'),
            'Required key "CreatorProfileModel[contentFocus]" is missing from JSON.');
        assert(json.containsKey(r'displayName'),
            'Required key "CreatorProfileModel[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "CreatorProfileModel[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'followers'),
            'Required key "CreatorProfileModel[followers]" is missing from JSON.');
        assert(json.containsKey(r'instagramConnected'),
            'Required key "CreatorProfileModel[instagramConnected]" is missing from JSON.');
        assert(json[r'instagramConnected'] != null,
            'Required key "CreatorProfileModel[instagramConnected]" has a null value in JSON.');
        assert(json.containsKey(r'instagramHandle'),
            'Required key "CreatorProfileModel[instagramHandle]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CreatorProfileModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "CreatorProfileModel[regionSido]" is missing from JSON.');
        assert(json[r'regionSido'] != null,
            'Required key "CreatorProfileModel[regionSido]" has a null value in JSON.');
        assert(json.containsKey(r'regionSigungu'),
            'Required key "CreatorProfileModel[regionSigungu]" is missing from JSON.');
        assert(json.containsKey(r'userId'),
            'Required key "CreatorProfileModel[userId]" is missing from JSON.');
        assert(json[r'userId'] != null,
            'Required key "CreatorProfileModel[userId]" has a null value in JSON.');
        return true;
      }());

      return CreatorProfileModel(
        contentFocus: mapValueOfType<String>(json, r'contentFocus'),
        displayName: mapValueOfType<String>(json, r'displayName')!,
        followers: mapValueOfType<int>(json, r'followers'),
        instagramConnected: mapValueOfType<bool>(json, r'instagramConnected')!,
        instagramHandle: mapValueOfType<String>(json, r'instagramHandle'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        regionSido: mapValueOfType<String>(json, r'regionSido')!,
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
        userId: mapValueOfType<String>(json, r'userId')!,
      );
    }
    return null;
  }

  static List<CreatorProfileModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatorProfileModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatorProfileModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatorProfileModel> mapFromJson(dynamic json) {
    final map = <String, CreatorProfileModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatorProfileModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatorProfileModel-objects as value to a dart map
  static Map<String, List<CreatorProfileModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatorProfileModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatorProfileModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contentFocus',
    'displayName',
    'followers',
    'instagramConnected',
    'instagramHandle',
    'photoUrl',
    'regionSido',
    'regionSigungu',
    'userId',
  };
}

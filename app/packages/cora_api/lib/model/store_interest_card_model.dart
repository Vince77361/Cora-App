//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreInterestCardModel {
  /// Returns a new [StoreInterestCardModel] instance.
  StoreInterestCardModel({
    required this.contentFocus,
    required this.creatorId,
    required this.followers,
    required this.headline,
    required this.mutual,
    required this.name,
    required this.photoUrl,
    required this.representativePhotoUrl,
    required this.shortName,
  });

  /// 분야.
  String? contentFocus;

  String creatorId;

  /// 인스타그램 팔로워 수. 연동하지 않았으면 null.
  int? followers;

  /// 대표 게시물 1번의 한 줄. 게시물이 없거나 한 줄이 비었으면 null. 이상형 월드컵 카드가 쓴다.
  String? headline;

  /// 서로 관심: 내가 하트를 보냈고 그 크리에이터가 이 가게에 살아 있는 지원(APPLIED·OFFERED)을 가졌다. 저장 탭에서는 늘 false다.
  bool mutual;

  /// 크리에이터의 활동 이름.
  String name;

  String? photoUrl;

  /// 대표 게시물 1번의 사진(영상이면 썸네일). 없으면 null. photoUrl(프로필 사진)과 다르다.
  String? representativePhotoUrl;

  /// \"{X}의 …\" 꼴이면 X, 아니면 이름 전체. 버튼 글자에 쓴다.
  String shortName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreInterestCardModel &&
          other.contentFocus == contentFocus &&
          other.creatorId == creatorId &&
          other.followers == followers &&
          other.headline == headline &&
          other.mutual == mutual &&
          other.name == name &&
          other.photoUrl == photoUrl &&
          other.representativePhotoUrl == representativePhotoUrl &&
          other.shortName == shortName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentFocus == null ? 0 : contentFocus!.hashCode) +
      (creatorId.hashCode) +
      (followers == null ? 0 : followers!.hashCode) +
      (headline == null ? 0 : headline!.hashCode) +
      (mutual.hashCode) +
      (name.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (representativePhotoUrl == null ? 0 : representativePhotoUrl!.hashCode) +
      (shortName.hashCode);

  @override
  String toString() =>
      'StoreInterestCardModel[contentFocus=$contentFocus, creatorId=$creatorId, followers=$followers, headline=$headline, mutual=$mutual, name=$name, photoUrl=$photoUrl, representativePhotoUrl=$representativePhotoUrl, shortName=$shortName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentFocus != null) {
      json[r'contentFocus'] = this.contentFocus;
    } else {
      json[r'contentFocus'] = null;
    }
    json[r'creatorId'] = this.creatorId;
    if (this.followers != null) {
      json[r'followers'] = this.followers;
    } else {
      json[r'followers'] = null;
    }
    if (this.headline != null) {
      json[r'headline'] = this.headline;
    } else {
      json[r'headline'] = null;
    }
    json[r'mutual'] = this.mutual;
    json[r'name'] = this.name;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    if (this.representativePhotoUrl != null) {
      json[r'representativePhotoUrl'] = this.representativePhotoUrl;
    } else {
      json[r'representativePhotoUrl'] = null;
    }
    json[r'shortName'] = this.shortName;
    return json;
  }

  /// Returns a new [StoreInterestCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreInterestCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contentFocus'),
            'Required key "StoreInterestCardModel[contentFocus]" is missing from JSON.');
        assert(json.containsKey(r'creatorId'),
            'Required key "StoreInterestCardModel[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "StoreInterestCardModel[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'followers'),
            'Required key "StoreInterestCardModel[followers]" is missing from JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "StoreInterestCardModel[headline]" is missing from JSON.');
        assert(json.containsKey(r'mutual'),
            'Required key "StoreInterestCardModel[mutual]" is missing from JSON.');
        assert(json[r'mutual'] != null,
            'Required key "StoreInterestCardModel[mutual]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "StoreInterestCardModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "StoreInterestCardModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "StoreInterestCardModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'representativePhotoUrl'),
            'Required key "StoreInterestCardModel[representativePhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'shortName'),
            'Required key "StoreInterestCardModel[shortName]" is missing from JSON.');
        assert(json[r'shortName'] != null,
            'Required key "StoreInterestCardModel[shortName]" has a null value in JSON.');
        return true;
      }());

      return StoreInterestCardModel(
        contentFocus: mapValueOfType<String>(json, r'contentFocus'),
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        followers: mapValueOfType<int>(json, r'followers'),
        headline: mapValueOfType<String>(json, r'headline'),
        mutual: mapValueOfType<bool>(json, r'mutual')!,
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        representativePhotoUrl:
            mapValueOfType<String>(json, r'representativePhotoUrl'),
        shortName: mapValueOfType<String>(json, r'shortName')!,
      );
    }
    return null;
  }

  static List<StoreInterestCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreInterestCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreInterestCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreInterestCardModel> mapFromJson(dynamic json) {
    final map = <String, StoreInterestCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreInterestCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreInterestCardModel-objects as value to a dart map
  static Map<String, List<StoreInterestCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreInterestCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreInterestCardModel.listFromJson(
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
    'creatorId',
    'followers',
    'headline',
    'mutual',
    'name',
    'photoUrl',
    'representativePhotoUrl',
    'shortName',
  };
}
